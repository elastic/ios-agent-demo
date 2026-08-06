#!/bin/sh
set -eu

BASEDIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
SIMULATOR_ARCH=$(uname -m)

echo "Checking package resolution"
"$BASEDIR/.github/scripts/check-package-resolution.sh"

echo "Linting Swift sources"
swift format lint --strict --recursive "$BASEDIR/WeatherDemo" "$BASEDIR/WeatherDemoTests"

echo "Selecting an iPhone Simulator"
SIMULATOR_ID=$(
  xcrun simctl list devices available --json |
    jq -r '[.devices[] | .[] | select(.name | startswith("iPhone"))] | first | .udid'
)
if [ -z "$SIMULATOR_ID" ] || [ "$SIMULATOR_ID" = "null" ]; then
  echo "No available iPhone Simulator found" >&2
  exit 1
fi

echo "Running unit tests (Debug)"
xcodebuild \
  -quiet \
  -project "$BASEDIR/WeatherDemo.xcodeproj" \
  -scheme WeatherDemo \
  -configuration Debug \
  -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
  -derivedDataPath "$BASEDIR/.derived-data" \
  CODE_SIGNING_ALLOWED=NO \
  test

echo "Building the app (Release)"
xcodebuild \
  -quiet \
  -project "$BASEDIR/WeatherDemo.xcodeproj" \
  -scheme WeatherDemo \
  -configuration Release \
  -sdk iphonesimulator \
  -destination "generic/platform=iOS Simulator" \
  -derivedDataPath "$BASEDIR/.derived-data" \
  CODE_SIGNING_ALLOWED=NO \
  ONLY_ACTIVE_ARCH=YES \
  ARCHS="$SIMULATOR_ARCH" \
  build
