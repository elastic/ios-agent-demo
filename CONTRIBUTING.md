# Contributing

This document covers the tooling for changing the demo. To just run the demo, see
[README.md](README.md).

## Validate changes

```sh
./checks.sh
```

The script runs, in order:

1. `swift format lint --strict` over `WeatherDemo/` and `WeatherDemoTests/` using the repository
   `.swift-format` configuration. Fix findings with:

   ```sh
   swift format --in-place --recursive WeatherDemo WeatherDemoTests
   ```

2. The `WeatherDemoTests` unit tests, in Debug, on the first available iPhone Simulator.
3. A check that Xcode dependency resolution did not leave `Package.resolved` stale.
4. A code-signing-free Release build, which also proves that code outside `#if DEBUG` still
   compiles under the optimizer.

Requirements: Xcode 16 or newer (for `swift format`) and `jq`.

## Build configurations

- **Debug** is for interactive use in Xcode and for the unit tests (`@testable import` requires
  testability, which is enabled in Debug only).
- **Release** is what CI ships to the Simulator in the end-to-end test, so the tested app matches
  a real production build: optimized, stripped, with a separate dSYM. The end-to-end scenario
  hook (`WEATHER_DEMO_E2E_MODE`) is compiled in through the `E2E_HOOKS` Swift compilation
  condition, which CI passes as `SWIFT_ACTIVE_COMPILATION_CONDITIONS='$(inherited) E2E_HOOKS'`.
  A plain Release build does not contain the hook.

## Continuous integration

The `ci` workflow runs a change detector, two conditional jobs, and a gatekeeper:

- **changes** — detects whether the pull request or push contains anything other than Markdown.
- **checks** — runs `./checks.sh` (lint, unit tests, lockfile validation, Release build).
- **e2e** — runs `.github/scripts/e2e-test/e2e_test.sh`: starts native Elasticsearch and EDOT
  Collector processes, downloads and runs the released backend JAR, builds the app in **Release**,
  launches it on a throwaway Simulator, exercises the telemetry and crash scenarios, and queries
  Elasticsearch to verify an iOS startup span and log, a distributed trace shared by the iOS app
  and backend (same `trace.id`), and a persisted iOS crash report exported after relaunch. The
  job uploads `build/e2e/` diagnostics plus a `WeatherDemo.app.dSYM.zip` for symbolicating the
  crash report. See [`.github/scripts/e2e-test/README.md`](.github/scripts/e2e-test/README.md)
  for local execution.
- **ci** — aggregates the results as the branch-protection gate. For Markdown-only changes, it
  succeeds after `changes` while the two macOS jobs are skipped.

Markdown-only changes (`**/*.md`) skip the code-related macOS jobs, but the lightweight workflow
still runs so the required `ci` check reports success.

## Dependencies

Renovate manages the Swift package pins in `project.pbxproj` (via a custom regex manager — the
native Renovate Swift manager only reads `Package.swift`) and the SHA-pinned GitHub Actions. After
a package pin changes, refresh and commit the Xcode lockfile:

```sh
xcodebuild -resolvePackageDependencies -project WeatherDemo.xcodeproj -scheme WeatherDemo
git add WeatherDemo.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
```

`checks.sh` fails if Xcode changes `Package.resolved` during dependency resolution, preventing a
Renovate update from being merged with a stale lockfile.
