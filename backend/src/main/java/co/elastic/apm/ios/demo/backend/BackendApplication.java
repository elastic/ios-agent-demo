/*
 * Licensed to Elasticsearch B.V. under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch B.V. licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 */
package co.elastic.apm.ios.demo.backend;

import co.elastic.otel.agent.attach.RuntimeAttach;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class BackendApplication {

  public static void main(String[] args) {
    RuntimeAttach.attachJavaagentToCurrentJvm();
    SpringApplication.run(BackendApplication.class, args);
  }
}
