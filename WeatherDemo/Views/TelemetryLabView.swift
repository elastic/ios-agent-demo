/*
 * Licensed to Elasticsearch B.V. under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch B.V. licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 */

import SwiftUI

struct TelemetryLabView: View {
  @State private var scenarioIsRunning = false
  @State private var statusMessage: String?
  @State private var showCrashConfirmation = false

  var body: some View {
    NavigationStack {
      List {
        Section {
          actionButton(
            title: "Create custom span",
            icon: "point.topleft.down.to.point.bottomright.curvepath",
            disabled: scenarioIsRunning
          ) {
            scenarioIsRunning = true
            statusMessage = "Creating span…"
            Task {
              await DemoTelemetry.runManualScenario()
              await MainActor.run {
                scenarioIsRunning = false
                statusMessage = "Custom span and correlated log created."
              }
            }
          }

          actionButton(title: "Emit custom log", icon: "text.bubble") {
            DemoTelemetry.emitManualLog()
            statusMessage = "Warning log emitted."
          }

          actionButton(title: "Increment custom metric", icon: "chart.xyaxis.line") {
            DemoTelemetry.emitManualMetric()
            statusMessage = "demo.manual.actions incremented."
          }

          NavigationLink(value: ForecastRequest(city: .berlin, delayMilliseconds: 2_500)) {
            Label("Run slow distributed trace", systemImage: "tortoise")
          }

          Button(role: .destructive) {
            showCrashConfirmation = true
          } label: {
            Label("Crash the app", systemImage: "exclamationmark.octagon.fill")
          }
        } header: {
          Text("Signals")
        } footer: {
          if let statusMessage {
            Text(statusMessage)
          } else {
            Text("Use these actions to create easy-to-find examples in Kibana.")
          }
        }

        Section("Local endpoints") {
          EndpointRow(name: "OTLP/HTTP", url: DemoConfiguration.collectorURL)
          EndpointRow(name: "Weather backend", url: DemoConfiguration.backendURL)
        }

        Section("Crash reporting") {
          Text(
            "After the intentional crash, launch the app again. The agent exports the persisted crash report on the next startup."
          )
          .font(.subheadline)
          .foregroundStyle(.secondary)
        }
      }
      .navigationTitle("Telemetry Lab")
      .navigationDestination(for: ForecastRequest.self) { request in
        ForecastView(request: request)
      }
      .alert("Crash the app?", isPresented: $showCrashConfirmation) {
        Button("Cancel", role: .cancel) {}
        Button("Crash", role: .destructive) {
          DemoTelemetry.crash()
        }
      } message: {
        Text("This is intentional. Reopen the app afterward to export the crash report.")
      }
    }
  }

  private func actionButton(
    title: String,
    icon: String,
    disabled: Bool = false,
    action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      HStack {
        Label(title, systemImage: icon)
        if disabled {
          Spacer()
          ProgressView()
        }
      }
    }
    .disabled(disabled)
  }
}

private struct EndpointRow: View {
  let name: String
  let url: URL

  var body: some View {
    VStack(alignment: .leading, spacing: 3) {
      Text(name)
        .font(.headline)
      Text(url.absoluteString)
        .font(.caption.monospaced())
        .foregroundStyle(.secondary)
        .textSelection(.enabled)
    }
    .padding(.vertical, 2)
  }
}
