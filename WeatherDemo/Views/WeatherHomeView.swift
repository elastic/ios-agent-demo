/*
 * Licensed to Elasticsearch B.V. under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch B.V. licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 */

import SwiftUI

struct WeatherHomeView: View {
  @State private var selectedCity = City.berlin
  @State private var showCrashConfirmation = false

  var body: some View {
    NavigationStack {
      List {
        Section {
          Picker("City", selection: $selectedCity) {
            ForEach(City.allCases) { city in
              Text(city.rawValue).tag(city)
            }
          }
          .pickerStyle(.menu)

          NavigationLink(value: ForecastRequest(city: selectedCity)) {
            Label("Show forecast", systemImage: "arrow.right.circle.fill")
              .font(.headline)
          }
          .simultaneousGesture(
            TapGesture().onEnded {
              DemoTelemetry.recordNavigation(city: selectedCity)
            })
        } header: {
          Text("Choose a city")
        } footer: {
          Text("New York is rejected on purpose to demonstrate a correlated backend error.")
        }

        Section("What this demonstrates") {
          ScenarioRow(
            icon: "point.3.connected.trianglepath.dotted",
            title: "Distributed tracing",
            detail: "The URLSession request continues through the instrumented backend."
          )
          ScenarioRow(
            icon: "text.alignleft",
            title: "Custom telemetry",
            detail:
              "The app adds a parent span, correlated logs, and span attributes."
          )
          ScenarioRow(
            icon: "cpu",
            title: "Automatic signals",
            detail: "Lifecycle, CPU, memory, navigation, network, and crash telemetry are enabled."
          )
        }
      }
      .navigationTitle("Elastic Weather")
      .navigationDestination(for: ForecastRequest.self) { request in
        ForecastView(request: request)
      }
      .toolbar {
        Button(role: .destructive) {
          showCrashConfirmation = true
        } label: {
          Label("Crash the app", systemImage: "exclamationmark.octagon.fill")
        }
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
}

struct ScenarioRow: View {
  let icon: String
  let title: String
  let detail: String

  var body: some View {
    Label {
      VStack(alignment: .leading, spacing: 3) {
        Text(title)
          .font(.headline)
        Text(detail)
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
    } icon: {
      Image(systemName: icon)
        .foregroundStyle(Color.accentColor)
    }
    .padding(.vertical, 3)
  }
}
