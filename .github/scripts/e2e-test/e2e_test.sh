#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
REPO_ROOT=$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)
BUILD_DIR="$REPO_ROOT/build/e2e"
CACHE_DIR="$REPO_ROOT/.ci-cache/elastic"
RUNTIME_DIR="$BUILD_DIR/runtime"
DERIVED_DATA_DIR="$BUILD_DIR/DerivedData"

ELASTIC_VERSION=${ELASTIC_VERSION:-9.4.2}
ELASTICSEARCH_URL=http://127.0.0.1:9200
COLLECTOR_HOST=127.0.0.1
COLLECTOR_PORT=4318
BACKEND_URL=http://127.0.0.1:8080/v1
APP_SERVICE_NAME=weather-demo-ios
BACKEND_SERVICE_NAME=weather-demo-backend
APP_BUNDLE_ID=co.elastic.edot.ios.demo
TEST_RUN_ID="ios-${GITHUB_RUN_ID:-local}-${GITHUB_RUN_ATTEMPT:-0}-$(date +%s)"

elasticsearch_pid=""
collector_pid=""
backend_pid=""
simulator_udid=""

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Required command not found: $1" >&2
    exit 1
  fi
}

wait_for_url() {
  local url="$1"
  local label="$2"
  local timeout="${3:-120}"
  local elapsed=0

  until curl --fail --silent "$url" >/dev/null 2>&1; do
    if [ "$elapsed" -ge "$timeout" ]; then
      echo "Timed out waiting for $label at $url" >&2
      return 1
    fi
    sleep 2
    elapsed=$((elapsed + 2))
  done
}

wait_for_port() {
  local host="$1"
  local port="$2"
  local label="$3"
  local timeout="${4:-120}"
  local elapsed=0

  until nc -z "$host" "$port" >/dev/null 2>&1; do
    if [ "$elapsed" -ge "$timeout" ]; then
      echo "Timed out waiting for $label at $host:$port" >&2
      return 1
    fi
    sleep 2
    elapsed=$((elapsed + 2))
  done
}

download_archive() {
  local url="$1"
  local archive="$2"

  if [ ! -f "$archive" ]; then
    echo "Downloading $(basename "$archive")..."
    curl --fail --location --retry 3 --retry-delay 2 --output "$archive" "$url"
  fi

  if [ ! -f "${archive}.sha512" ]; then
    curl --fail --location --retry 3 --retry-delay 2 \
      --output "${archive}.sha512" "${url}.sha512"
  fi

  local expected
  expected=$(awk '{print $1}' "${archive}.sha512")
  local actual
  actual=$(shasum -a 512 "$archive" | awk '{print $1}')
  if [ "$expected" != "$actual" ]; then
    echo "Checksum verification failed for $archive" >&2
    exit 1
  fi
}

service_filter() {
  local service_name="$1"
  jq -nc --arg service "$service_name" --arg run_id "$TEST_RUN_ID" '[
    {
      bool: {
        should: [
          {term: {"resource.attributes.service.name": $service}},
          {term: {"service.name": $service}}
        ],
        minimum_should_match: 1
      }
    },
    {
      bool: {
        should: [
          {term: {"resource.attributes.test.run_id": $run_id}},
          {term: {"test.run_id": $run_id}}
        ],
        minimum_should_match: 1
      }
    }
  ]'
}

span_query() {
  local service_name="$1"
  local span_name="$2"
  local filters
  filters=$(service_filter "$service_name")
  jq -nc --argjson filters "$filters" --arg span_name "$span_name" '{
    size: 1,
    sort: [{"@timestamp": "desc"}],
    query: {
      bool: {
        filter: ($filters + [{term: {name: $span_name}}])
      }
    }
  }'
}

log_query() {
  local service_name="$1"
  local message="$2"
  local filters
  filters=$(service_filter "$service_name")
  jq -nc --argjson filters "$filters" --arg message "$message" '{
    size: 1,
    sort: [{"@timestamp": "desc"}],
    query: {
      bool: {
        filter: ($filters + [{
          bool: {
            should: [
              {match_phrase: {"body.text": $message}},
              {match_phrase: {body: $message}},
              {match_phrase: {message: $message}}
            ],
            minimum_should_match: 1
          }
        }])
      }
    }
  }'
}

backend_trace_query() {
  local trace_id="$1"
  local filters
  filters=$(service_filter "$BACKEND_SERVICE_NAME")
  jq -nc --argjson filters "$filters" --arg trace_id "$trace_id" '{
    size: 1,
    sort: [{"@timestamp": "desc"}],
    query: {
      bool: {
        filter: ($filters + [{
          bool: {
            should: [
              {term: {"trace.id": $trace_id}},
              {term: {trace_id: $trace_id}}
            ],
            minimum_should_match: 1
          }
        }])
      }
    }
  }'
}

crash_query() {
  local filters
  filters=$(service_filter "$APP_SERVICE_NAME")
  jq -nc --argjson filters "$filters" '{
    size: 1,
    sort: [{"@timestamp": "desc"}],
    query: {
      bool: {
        filter: ($filters + [{
          bool: {
            should: [
              {term: {"event.name": "crash"}},
              {term: {event_name: "crash"}},
              {term: {"attributes.otel.event.name": "crash"}}
            ],
            minimum_should_match: 1
          }
        }])
      }
    }
  }'
}

es_search() {
  local index="$1"
  local query="$2"
  local response

  response=$(curl --fail --silent --show-error \
    -H "Content-Type: application/json" \
    --data "$query" \
    "$ELASTICSEARCH_URL/$index/_search")

  if [ "$(echo "$response" | jq -r '.hits.total.value // 0')" -lt 1 ]; then
    return 1
  fi
  echo "$response" | jq -c '.hits.hits[0]'
}

es_wait_for_item() {
  local index="$1"
  local query="$2"
  local label="$3"
  local timeout="${4:-180}"
  local elapsed=0

  while [ "$elapsed" -lt "$timeout" ]; do
    local result
    if result=$(es_search "$index" "$query"); then
      echo "$result"
      return 0
    fi
    echo "  ${elapsed}s/${timeout}s — waiting for $label..." >&2
    sleep 5
    elapsed=$((elapsed + 5))
  done

  echo "Timed out waiting for $label" >&2
  return 1
}

launch_app() {
  local mode="$1"
  local log_prefix="$2"
  local launch_output

  : > "$BUILD_DIR/${log_prefix}.stdout.log"
  : > "$BUILD_DIR/${log_prefix}.stderr.log"

  launch_output=$(
    SIMCTL_CHILD_OTEL_RESOURCE_ATTRIBUTES="service.name=$APP_SERVICE_NAME,deployment.environment.name=ci,test.run_id=$TEST_RUN_ID" \
    SIMCTL_CHILD_WEATHER_DEMO_E2E_MODE="$mode" \
      xcrun simctl launch \
        --terminate-running-process \
        --stdout="$BUILD_DIR/${log_prefix}.stdout.log" \
        --stderr="$BUILD_DIR/${log_prefix}.stderr.log" \
        "$simulator_udid" \
        "$APP_BUNDLE_ID"
  )

  echo "${launch_output##*: }"
}

assert_not_empty() {
  local value="$1"
  local message="$2"
  if [ -z "$value" ] || [ "$value" = "null" ]; then
    echo "$message" >&2
    exit 1
  fi
}

print_failure_diagnostics() {
  echo "=== E2E failure diagnostics ===" >&2
  curl --silent "$ELASTICSEARCH_URL/_cluster/health?pretty" >&2 2>/dev/null || true

  if [ -n "$simulator_udid" ]; then
    xcrun simctl spawn "$simulator_udid" log show \
      --style compact \
      --last 10m \
      --predicate 'process == "WeatherDemo"' \
      > "$BUILD_DIR/simulator-system.log" 2>&1 || true
  fi

  local file
  for file in \
    "$BUILD_DIR/elasticsearch.log" \
    "$BUILD_DIR/collector.log" \
    "$BUILD_DIR/backend.log" \
    "$BUILD_DIR/app-telemetry.stderr.log" \
    "$BUILD_DIR/app-crash.stderr.log" \
    "$BUILD_DIR/app-relaunch.stderr.log"; do
    if [ -f "$file" ]; then
      echo "--- Last 100 lines of $(basename "$file") ---" >&2
      tail -n 100 "$file" >&2 || true
    fi
  done
  echo "=== End E2E failure diagnostics ===" >&2
}

cleanup() {
  local exit_code=$?
  trap - EXIT

  if [ "$exit_code" -ne 0 ]; then
    print_failure_diagnostics
  fi

  if [ -n "$simulator_udid" ]; then
    xcrun simctl shutdown "$simulator_udid" >/dev/null 2>&1 || true
    xcrun simctl delete "$simulator_udid" >/dev/null 2>&1 || true
  fi

  local pid
  for pid in "$backend_pid" "$collector_pid" "$elasticsearch_pid"; do
    if [ -n "$pid" ]; then
      kill "$pid" >/dev/null 2>&1 || true
      wait "$pid" >/dev/null 2>&1 || true
    fi
  done

  rm -rf "$RUNTIME_DIR" "$DERIVED_DATA_DIR"

  exit "$exit_code"
}

trap cleanup EXIT

for command in curl git java jq nc shasum tar xcodebuild xcrun; do
  require_command "$command"
done

mkdir -p "$BUILD_DIR" "$CACHE_DIR" "$RUNTIME_DIR"

case "$(uname -m)" in
  arm64) elastic_arch=aarch64 ;;
  x86_64) elastic_arch=x86_64 ;;
  *)
    echo "Unsupported macOS architecture: $(uname -m)" >&2
    exit 1
    ;;
esac

elasticsearch_archive="$CACHE_DIR/elasticsearch-$ELASTIC_VERSION-darwin-$elastic_arch.tar.gz"
collector_archive="$CACHE_DIR/elastic-agent-$ELASTIC_VERSION-darwin-$elastic_arch.tar.gz"

download_archive \
  "https://artifacts.elastic.co/downloads/elasticsearch/$(basename "$elasticsearch_archive")" \
  "$elasticsearch_archive"
download_archive \
  "https://artifacts.elastic.co/downloads/beats/elastic-agent/$(basename "$collector_archive")" \
  "$collector_archive"

echo "Extracting Elastic distributions..."
tar -xzf "$elasticsearch_archive" -C "$RUNTIME_DIR"
tar -xzf "$collector_archive" -C "$RUNTIME_DIR"

elasticsearch_home="$RUNTIME_DIR/elasticsearch-$ELASTIC_VERSION"
collector_home="$RUNTIME_DIR/elastic-agent-$ELASTIC_VERSION-darwin-$elastic_arch"
xattr -dr com.apple.quarantine "$elasticsearch_home" "$collector_home" 2>/dev/null || true

echo "Starting Elasticsearch..."
ES_JAVA_OPTS="-Xms512m -Xmx512m" \
  "$elasticsearch_home/bin/elasticsearch" \
  -Ediscovery.type=single-node \
  -Expack.security.enabled=false \
  -Expack.security.autoconfiguration.enabled=false \
  -Expack.ml.enabled=false \
  -Ecluster.routing.allocation.disk.threshold_enabled=false \
  > "$BUILD_DIR/elasticsearch.log" 2>&1 &
elasticsearch_pid=$!
wait_for_url "$ELASTICSEARCH_URL" Elasticsearch 180

echo "Starting EDOT Collector..."
ELASTIC_ENDPOINT="$ELASTICSEARCH_URL" \
  "$collector_home/otelcol" \
  --config "$SCRIPT_DIR/otel.yml" \
  > "$BUILD_DIR/collector.log" 2>&1 &
collector_pid=$!
wait_for_port "$COLLECTOR_HOST" "$COLLECTOR_PORT" "EDOT Collector" 120

echo "Downloading and starting backend..."
BACKEND_VERSION="0.0.1"
backend_jar="$CACHE_DIR/backend-${BACKEND_VERSION}.jar"
backend_release_url="https://github.com/elastic/shared-otel-sdk-demo/releases/download/backend/v${BACKEND_VERSION}"

if [ ! -f "$backend_jar" ]; then
  curl --fail --location --retry 3 --retry-delay 2 \
    --output "$backend_jar" "$backend_release_url/backend-${BACKEND_VERSION}.jar"
fi
if [ ! -f "${backend_jar}.sha256" ]; then
  curl --fail --location --retry 3 --retry-delay 2 \
    --output "${backend_jar}.sha256" "$backend_release_url/backend-${BACKEND_VERSION}.jar.sha256"
fi
(cd "$CACHE_DIR" && shasum -a 256 -c "backend-${BACKEND_VERSION}.jar.sha256")

OTEL_SERVICE_NAME="$BACKEND_SERVICE_NAME" \
OTEL_RESOURCE_ATTRIBUTES="deployment.environment.name=ci,test.run_id=$TEST_RUN_ID" \
OTEL_EXPORTER_OTLP_ENDPOINT="http://$COLLECTOR_HOST:$COLLECTOR_PORT" \
OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf \
  java -jar "$backend_jar" \
  > "$BUILD_DIR/backend.log" 2>&1 &
backend_pid=$!
wait_for_url "$BACKEND_URL/health" backend 120

echo "Creating iOS Simulator..."
runtime_id=$(
  xcrun simctl list runtimes -j |
    jq -r '[.runtimes[] | select(.isAvailable == true and (.identifier | contains(".iOS-")))]
      | sort_by(.version | split(".") | map(tonumber))
      | last
      | .identifier'
)
device_type_id=$(
  xcrun simctl list devicetypes -j |
    jq -r '[.devicetypes[] | select(.name | startswith("iPhone"))] | first | .identifier'
)
assert_not_empty "$runtime_id" "No available iOS Simulator runtime found"
assert_not_empty "$device_type_id" "No iPhone Simulator device type found"

simulator_udid=$(xcrun simctl create "WeatherDemo E2E $TEST_RUN_ID" "$device_type_id" "$runtime_id")
xcrun simctl boot "$simulator_udid"
xcrun simctl bootstatus "$simulator_udid" -b

echo "Building and installing iOS app..."
xcodebuild -quiet \
  -project "$REPO_ROOT/WeatherDemo.xcodeproj" \
  -scheme WeatherDemo \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination "platform=iOS Simulator,id=$simulator_udid" \
  -derivedDataPath "$DERIVED_DATA_DIR" \
  CODE_SIGNING_ALLOWED=NO \
  build

app_path="$DERIVED_DATA_DIR/Build/Products/Debug-iphonesimulator/WeatherDemo.app"
xcrun simctl install "$simulator_udid" "$app_path"

echo "Launching telemetry scenario..."
launch_app telemetry app-telemetry >/dev/null

startup_span=$(es_wait_for_item \
  "traces-*" \
  "$(span_query "$APP_SERVICE_NAME" "Creating app")" \
  "iOS startup span")
startup_log=$(es_wait_for_item \
  "logs-*" \
  "$(log_query "$APP_SERVICE_NAME" "Weather demo started")" \
  "iOS startup log")
forecast_span=$(es_wait_for_item \
  "traces-*" \
  "$(span_query "$APP_SERVICE_NAME" "Fetch city forecast")" \
  "iOS forecast span")

trace_id=$(echo "$forecast_span" | jq -r '._source.trace.id // ._source.trace_id // empty')
assert_not_empty "$trace_id" "The iOS forecast span has no trace ID"

backend_span=$(es_wait_for_item \
  "traces-*" \
  "$(backend_trace_query "$trace_id")" \
  "backend span in distributed trace")
backend_trace_id=$(echo "$backend_span" | jq -r '._source.trace.id // ._source.trace_id // empty')
if [ "$trace_id" != "$backend_trace_id" ]; then
  echo "App trace ID '$trace_id' does not match backend trace ID '$backend_trace_id'" >&2
  exit 1
fi

echo "$startup_span" | jq . > "$BUILD_DIR/app-startup-span.json"
echo "$startup_log" | jq . > "$BUILD_DIR/app-startup-log.json"
echo "$forecast_span" | jq . > "$BUILD_DIR/app-forecast-span.json"
echo "$backend_span" | jq . > "$BUILD_DIR/backend-span.json"

echo "Triggering intentional iOS crash..."
xcrun simctl terminate "$simulator_udid" "$APP_BUNDLE_ID" >/dev/null 2>&1 || true
crash_pid=$(launch_app crash app-crash)

crash_detected=false
for _ in $(seq 1 20); do
  if ! kill -0 "$crash_pid" >/dev/null 2>&1; then
    crash_detected=true
    break
  fi
  sleep 1
done
if [ "$crash_detected" != true ]; then
  echo "The app did not exit after the intentional crash" >&2
  exit 1
fi

echo "Relaunching app to export persisted crash report..."
launch_app export app-relaunch >/dev/null
crash_event=$(es_wait_for_item \
  "logs-*" \
  "$(crash_query)" \
  "iOS crash event")

exception_type=$(
  echo "$crash_event" |
    jq -r '._source.attributes."exception.type" // ._source.exception.type // empty'
)
stacktrace=$(
  echo "$crash_event" |
    jq -r '._source.attributes."exception.stacktrace" // ._source.exception.stacktrace // empty'
)
assert_not_empty "$exception_type" "The iOS crash event has no exception.type"
assert_not_empty "$stacktrace" "The iOS crash event has no exception.stacktrace"
echo "$crash_event" | jq . > "$BUILD_DIR/crash-event.json"

echo "E2E test succeeded for run ID $TEST_RUN_ID"
