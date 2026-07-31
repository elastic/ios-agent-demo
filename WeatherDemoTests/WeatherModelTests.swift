/*
 * Licensed to Elasticsearch B.V. under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch B.V. licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 */

import XCTest

@testable import WeatherDemo

final class WeatherModelTests: XCTestCase {
  func testForecastResponseDecodesOpenMeteoPayload() throws {
    let payload = Data(
      """
      {
        "latitude": 52.52,
        "current_weather": {
          "temperature": 21.3,
          "windspeed": 11.9
        }
      }
      """.utf8)

    let response = try JSONDecoder().decode(ForecastResponse.self, from: payload)

    XCTAssertEqual(response.currentWeather.temperature, 21.3, accuracy: 0.001)
  }

  func testForecastRequestDefaultsToNoDelay() {
    XCTAssertEqual(ForecastRequest(city: .berlin).delayMilliseconds, 0)
    XCTAssertEqual(ForecastRequest(city: .berlin, delayMilliseconds: 2500).delayMilliseconds, 2500)
  }

  func testCityIdentifiersMatchBackendQueryValues() {
    XCTAssertEqual(City.allCases.map(\.id), ["Berlin", "London", "Paris", "New York"])
  }

  func testBackendErrorDescriptionIncludesStatusAndMessage() {
    let error = WeatherClientError.backend(statusCode: 400, message: "City not supported")

    XCTAssertEqual(error.errorDescription, "Backend error 400: City not supported")
  }
}
