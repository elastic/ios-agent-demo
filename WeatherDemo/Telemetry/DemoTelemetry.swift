/*
 * Licensed to Elasticsearch B.V. under one or more contributor
 * license agreements. Elasticsearch B.V. licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 */

import Foundation
import OpenTelemetryApi

enum DemoTelemetry {
  private static var tracer: any Tracer {
    OpenTelemetry.instance.tracerProvider.get(
      instrumentationName: DemoConfiguration.instrumentationScope,
      instrumentationVersion: "1.0.0"
    )
  }

  private static var logger: OpenTelemetryApi.Logger {
    OpenTelemetry.instance.loggerProvider.get(
      instrumentationScopeName: DemoConfiguration.instrumentationScope
    )
  }

  static func recordAppLaunch() {
    tracer.spanBuilder(spanName: "Creating app")
      .setAttribute(key: "app.demo", value: true)
      .withActiveSpan { span in
        emitLog(
          "Weather demo started",
          severity: .info,
          attributes: ["app.demo": .bool(true)],
          spanContext: span.context
        )
      }
  }

  static func recordNavigation(city: City) {
    emitLog(
      "Show forecast tapped",
      severity: .info,
      attributes: ["city": .string(city.rawValue)]
    )
  }

  static func withSpan<T>(
    name: String,
    attributes: [String: AttributeValue] = [:],
    operation: (any SpanBase) async throws -> T
  ) async throws -> T {
    let builder = tracer.spanBuilder(spanName: name)
    attributes.forEach { builder.setAttribute(key: $0.key, value: $0.value) }

    return try await builder.withActiveSpan { span in
      do {
        let result = try await operation(span)
        span.status = .ok
        return result
      } catch {
        (span as? any Span)?.recordException(error)
        span.status = .error(description: error.localizedDescription)
        emitLog(
          "Operation failed: \(error.localizedDescription)",
          severity: .error,
          attributes: attributes,
          spanContext: span.context
        )
        throw error
      }
    }
  }

  static func emitLog(
    _ message: String,
    severity: Severity,
    attributes: [String: AttributeValue] = [:],
    spanContext: SpanContext? = nil
  ) {
    let builder = logger.logRecordBuilder()
      .setTimestamp(Date())
      .setSeverity(severity)
      .setBody(.string(message))
      .setAttributes(attributes)

    if let spanContext {
      _ = builder.setSpanContext(spanContext)
    }
    builder.emit()
  }

  static func crash() -> Never {
    emitLog(
      "Intentional crash requested",
      severity: .fatal,
      attributes: ["demo.action": .string("intentional-crash")]
    )
    fatalError("Intentional crash from the EDOT iOS demo")
  }
}
