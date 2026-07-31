/*
 * Licensed to Elasticsearch B.V. under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch B.V. licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 */

import SwiftUI
import XCTest

@testable import WeatherDemo

final class WeatherFormattingTests: XCTestCase {
  func testIconBoundaries() {
    XCTAssertEqual(WeatherFormatting.icon(for: 35), "sun.max")
    XCTAssertEqual(WeatherFormatting.icon(for: 20), "sun.max")
    XCTAssertEqual(WeatherFormatting.icon(for: 19.9), "cloud.sun")
    XCTAssertEqual(WeatherFormatting.icon(for: 5), "cloud.sun")
    XCTAssertEqual(WeatherFormatting.icon(for: 4.9), "snowflake")
    XCTAssertEqual(WeatherFormatting.icon(for: -10), "snowflake")
  }

  func testDescriptionBoundaries() {
    XCTAssertEqual(WeatherFormatting.description(for: 30), "Hot")
    XCTAssertEqual(WeatherFormatting.description(for: 25), "Warm")
    XCTAssertEqual(WeatherFormatting.description(for: 15), "Mild")
    XCTAssertEqual(WeatherFormatting.description(for: 5), "Cool")
    XCTAssertEqual(WeatherFormatting.description(for: 0), "Chilly")
    XCTAssertEqual(WeatherFormatting.description(for: -0.1), "Freezing")
  }

  func testGradientBoundaries() {
    XCTAssertEqual(WeatherFormatting.gradientColors(for: 25), [.orange, .yellow])
    XCTAssertEqual(WeatherFormatting.gradientColors(for: 10), [.green, .mint])
    XCTAssertEqual(WeatherFormatting.gradientColors(for: 0), [.blue, .cyan])
    XCTAssertEqual(WeatherFormatting.gradientColors(for: -5), [.indigo, .purple])
  }
}
