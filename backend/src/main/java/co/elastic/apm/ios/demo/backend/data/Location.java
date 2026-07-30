/*
 * Licensed to Elasticsearch B.V. under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch B.V. licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 */
package co.elastic.apm.ios.demo.backend.data;

public record Location(double latitude, double longitude) {
  public double getLatitude() {
    return latitude;
  }

  public double getLongitude() {
    return longitude;
  }
}
