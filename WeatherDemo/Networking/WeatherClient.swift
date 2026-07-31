/*
 * Licensed to Elasticsearch B.V. under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch B.V. licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 */

import Foundation
import OpenTelemetryApi

struct WeatherClient {
  private let session: URLSession
  private let baseURL: URL

  init(
    session: URLSession = .shared,
    baseURL: URL = DemoConfiguration.backendURL
  ) {
    self.session = session
    self.baseURL = baseURL
  }

  func forecast(for request: ForecastRequest) async throws -> ForecastResponse {
    let spanAttributes: [String: AttributeValue] = [
      "city": .string(request.city.rawValue)
    ]

    return try await DemoTelemetry.withSpan(
      name: "Fetch city forecast",
      attributes: spanAttributes
    ) { _ in
      guard
        var components = URLComponents(
          url: baseURL.appendingPathComponent("forecast"),
          resolvingAgainstBaseURL: false
        )
      else {
        throw WeatherClientError.invalidURL
      }

      components.queryItems = [
        URLQueryItem(name: "city", value: request.city.rawValue)
      ]

      guard let url = components.url else {
        throw WeatherClientError.invalidURL
      }

      let (data, response) = try await session.data(from: url)
      guard let httpResponse = response as? HTTPURLResponse else {
        throw WeatherClientError.invalidResponse
      }
      guard (200..<300).contains(httpResponse.statusCode) else {
        let message = String(data: data, encoding: .utf8) ?? "No response body"
        throw WeatherClientError.backend(
          statusCode: httpResponse.statusCode,
          message: message
        )
      }

      return try JSONDecoder().decode(ForecastResponse.self, from: data)
    }
  }
}
