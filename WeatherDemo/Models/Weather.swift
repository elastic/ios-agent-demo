/*
 * Licensed to Elasticsearch B.V. under one or more contributor
 * license agreements. Elasticsearch B.V. licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 */

import Foundation

enum City: String, CaseIterable, Identifiable {
  case berlin = "Berlin"
  case london = "London"
  case paris = "Paris"
  case newYork = "New York"

  var id: String { rawValue }
}

struct ForecastRequest: Hashable {
  let city: City
}

struct ForecastResponse: Decodable {
  let currentWeather: CurrentWeather

  enum CodingKeys: String, CodingKey {
    case currentWeather = "current_weather"
  }
}

struct CurrentWeather: Decodable {
  let temperature: Double
}

enum WeatherClientError: LocalizedError {
  case invalidURL
  case invalidResponse
  case backend(statusCode: Int, message: String)

  var errorDescription: String? {
    switch self {
    case .invalidURL:
      return "The backend URL is invalid."
    case .invalidResponse:
      return "The backend returned an invalid response."
    case let .backend(statusCode, message):
      return "Backend error \(statusCode): \(message)"
    }
  }
}
