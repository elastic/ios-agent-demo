/*
 * Licensed to Elasticsearch B.V. under one or more contributor
 * license agreements. Elasticsearch B.V. licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 */

import Foundation

enum DemoConfiguration {
  static let collectorURL = URL(string: "http://localhost:4318")!
  static let backendURL = URL(string: "http://localhost:8080/v1")!

  static let serviceName = "weather-demo-ios"
  static let instrumentationScope = "co.elastic.weather-demo"
}
