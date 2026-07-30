# iOS application

The `WeatherDemo` target is a SwiftUI iOS 16+ application instrumented with
[EDOT iOS](https://github.com/elastic/apm-agent-ios).

The agent starts in `WeatherDemoApp.swift`. Local endpoints and the OpenTelemetry service name are
defined in `Configuration/DemoConfiguration.swift` and `Info.plist`. Manual OpenTelemetry examples
are grouped in `Telemetry/DemoTelemetry.swift`.

The checked-in Xcode project uses EDOT iOS `2.0.2` and OpenTelemetry Swift Core `2.3.0` or later.
