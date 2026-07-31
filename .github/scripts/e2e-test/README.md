# CI end-to-end test

The end-to-end test runs the real SwiftUI application in an iOS Simulator and confirms that its
telemetry reaches Elasticsearch.

## What it validates

The test:

1. Starts Elasticsearch and the EDOT Collector as native macOS processes.
2. Downloads and starts the released instrumented backend JAR.
3. Builds, installs, and launches the iOS application in a fresh Simulator.
4. Runs a test-only app scenario that creates manual telemetry and requests a Berlin forecast.
5. Verifies an iOS startup span and log in Elasticsearch.
6. Verifies that the app's forecast span and a backend span share the same trace ID.
7. Intentionally crashes the app, relaunches it, and verifies the persisted crash event.

Every query includes a unique `test.run_id` resource attribute, so telemetry from another run
cannot satisfy the assertions.

## Run locally

The test requires macOS, Xcode with an iOS Simulator runtime, Java 17 or newer, `curl`, and `jq`.
Docker is not required.

From the repository root:

```sh
.github/scripts/e2e-test/e2e_test.sh
```

The first run downloads the pinned Elasticsearch and EDOT Collector archives to the ignored
`.ci-cache/elastic/` directory and the backend JAR to `.ci-cache/backend/`. Set `ELASTIC_VERSION` or
`BACKEND_VERSION` to test another matching version.

## Failure artifacts

Results and diagnostics are stored under `build/e2e/`, including:

- Elasticsearch, Collector, backend, and Simulator logs.
- The Elasticsearch documents used by each assertion.
- Simulator system logs captured on failure.
