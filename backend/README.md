# Backend service

This module belongs to the [EDOT iOS demo](../README.md). It is a small Spring Boot service
instrumented at runtime with the Elastic Distribution of OpenTelemetry Java.

Endpoints:

- `GET /v1/health`
- `GET /v1/forecast?city=Berlin&delayMs=0`

`Berlin`, `London`, and `Paris` are supported. Other cities intentionally produce an error.
`delayMs` is capped at five seconds and exists only to make a slow distributed trace easy to find.
