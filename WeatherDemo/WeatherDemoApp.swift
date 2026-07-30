/*
 * Licensed to Elasticsearch B.V. under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch B.V. licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 */

import ElasticApm
import SwiftUI
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    let agentConfiguration = AgentConfigBuilder()
      .withExportUrl(DemoConfiguration.collectorURL)
      .useConnectionType(.http)
      .withRemoteManagement(false)
      .build()

    let instrumentationConfiguration = InstrumentationConfigBuilder()
      .withCrashReporting(true)
      .withURLSessionInstrumentation(true)
      .withSystemMetrics(true)
      .withLifecycleEvents(true)
      .build()

    ElasticApmAgent.start(
      with: agentConfiguration,
      instrumentationConfiguration
    )
    DemoTelemetry.recordAppLaunch()
    return true
  }
}

@main
struct WeatherDemoApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

  var body: some Scene {
    WindowGroup {
      RootView()
    }
  }
}

private struct RootView: View {
  var body: some View {
    TabView {
      WeatherHomeView()
        .tabItem {
          Label("Weather", systemImage: "cloud.sun")
        }

      TelemetryLabView()
        .tabItem {
          Label("Telemetry", systemImage: "waveform.path.ecg")
        }
    }
    .tint(.elasticBlue)
  }
}

extension Color {
  static let elasticBlue = Color(red: 0.0, green: 0.47, blue: 0.55)
}
