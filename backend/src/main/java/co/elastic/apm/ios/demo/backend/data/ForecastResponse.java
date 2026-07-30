/*
 * Licensed to Elasticsearch B.V. under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch B.V. licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 */
package co.elastic.apm.ios.demo.backend.data;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.util.Objects;

public class ForecastResponse {

  @JsonProperty("current_weather")
  CurrentWeatherResponse currentWeather;

  public CurrentWeatherResponse getCurrentWeather() {
    return currentWeather;
  }

  @Override
  public boolean equals(Object other) {
    if (this == other) return true;
    if (other == null || getClass() != other.getClass()) return false;
    ForecastResponse that = (ForecastResponse) other;
    return Objects.equals(currentWeather, that.currentWeather);
  }

  @Override
  public int hashCode() {
    return Objects.hash(currentWeather);
  }
}
