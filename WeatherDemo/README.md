# iOS application

The `WeatherDemo` target is a SwiftUI iOS 16+ application instrumented with
[EDOT iOS](https://github.com/elastic/apm-agent-ios).

The agent starts in `WeatherDemoApp.swift`. Local endpoints are defined in
`Configuration/DemoConfiguration.swift`, and the OpenTelemetry service name is set in `Info.plist`.
Manual OpenTelemetry examples are grouped in `Telemetry/DemoTelemetry.swift`.

The EDOT iOS version is pinned in the Xcode project; the exact resolved dependency versions are
recorded in the checked-in `Package.resolved`.
