/*
 * Licensed to Elasticsearch B.V. under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch B.V. licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 */
package co.elastic.apm.ios.demo.backend.data;

import java.util.Objects;

public class CurrentWeatherResponse {
  double temperature;

  public double getTemperature() {
    return temperature;
  }

  @Override
  public boolean equals(Object other) {
    if (this == other) return true;
    if (other == null || getClass() != other.getClass()) return false;
    CurrentWeatherResponse that = (CurrentWeatherResponse) other;
    return Double.compare(that.temperature, temperature) == 0;
  }

  @Override
  public int hashCode() {
    return Objects.hash(temperature);
  }
}
