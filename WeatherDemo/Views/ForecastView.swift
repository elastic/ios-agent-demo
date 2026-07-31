/*
 * Licensed to Elasticsearch B.V. under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch B.V. licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 */

import SwiftUI

struct ForecastView: View {
  private enum Phase {
    case loading
    case success(Double)
    case failure(String)
  }

  let request: ForecastRequest

  @State private var phase = Phase.loading
  private let client = WeatherClient()

  var body: some View {
    Group {
      switch phase {
      case .loading:
        loadingView
      case let .success(temperature):
        successView(temperature: temperature)
      case let .failure(message):
        failureView(message: message)
      }
    }
    .navigationTitle(request.city.rawValue)
    .navigationBarTitleDisplayMode(.inline)
    .task {
      await load()
    }
  }

  private var loadingView: some View {
    VStack(spacing: 16) {
      ProgressView()
        .controlSize(.large)
      Text("Fetching forecast for \(request.city.rawValue)…")
        .foregroundStyle(.secondary)
    }
  }

  private func successView(temperature: Double) -> some View {
    ZStack {
      LinearGradient(
        colors: WeatherFormatting.gradientColors(for: temperature),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .ignoresSafeArea()

      VStack(spacing: 14) {
        Image(systemName: WeatherFormatting.icon(for: temperature))
          .font(.system(size: 90, weight: .thin))
        Text(request.city.rawValue)
          .font(.title)
        Text(temperature.formatted(.number.precision(.fractionLength(1))) + " °C")
          .font(.system(size: 62, weight: .thin, design: .rounded))
        Text(WeatherFormatting.description(for: temperature))
          .font(.title3)
        Link("Weather data by Open-Meteo.com", destination: URL(string: "https://open-meteo.com/")!)
          .font(.footnote)
          .padding(.top, 22)
      }
      .foregroundStyle(.white)
    }
  }

  private func failureView(message: String) -> some View {
    VStack(spacing: 16) {
      Image(systemName: "exclamationmark.triangle")
        .font(.system(size: 54))
        .foregroundStyle(.orange)
      Text("Couldn’t load forecast")
        .font(.title2.bold())
      Text("The request for \(request.city.rawValue) failed.")
        .foregroundStyle(.secondary)
      Text(message)
        .font(.caption)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .textSelection(.enabled)
        .padding(.horizontal)
      Button("Try again") {
        Task { await load() }
      }
      .buttonStyle(.borderedProminent)
    }
    .padding()
  }

  @MainActor
  private func load() async {
    phase = .loading
    do {
      let response = try await client.forecast(for: request)
      phase = .success(response.currentWeather.temperature)
    } catch {
      phase = .failure(error.localizedDescription)
    }
  }
}
