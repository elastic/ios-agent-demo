/*
 * Licensed to Elasticsearch B.V. under one or more contributor
 * license agreements. Elasticsearch B.V. licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 */

import SwiftUI

/// Maps a temperature in degrees Celsius to the presentation used by `ForecastView`.
enum WeatherFormatting {
  static func icon(for temperature: Double) -> String {
    switch temperature {
    case 20...:
      return "sun.max"
    case 5...:
      return "cloud.sun"
    default:
      return "snowflake"
    }
  }

  static func description(for temperature: Double) -> String {
    switch temperature {
    case 30...:
      return "Hot"
    case 25...:
      return "Warm"
    case 15...:
      return "Mild"
    case 5...:
      return "Cool"
    case 0...:
      return "Chilly"
    default:
      return "Freezing"
    }
  }

  static func gradientColors(for temperature: Double) -> [Color] {
    switch temperature {
    case 25...:
      return [.orange, .yellow]
    case 10...:
      return [.green, .mint]
    case 0...:
      return [.blue, .cyan]
    default:
      return [.indigo, .purple]
    }
  }
}
