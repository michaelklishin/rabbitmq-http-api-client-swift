// Copyright (C) 2025-2026 Michael S. Klishin and Contributors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation
import RabbitMQHTTPAPIClient
import Testing

@Suite struct ExchangeTests {
  let client = newClient()

  @Test func listExchangesContainsDefaults() async throws {
    let found = try await pollUntil {
      let exchanges = try await client.listExchanges()
      return !exchanges.isEmpty
        && exchanges.contains { $0.name == "amq.direct" }
        && exchanges.contains { $0.name == "amq.fanout" }
        && exchanges.contains { $0.name == "amq.topic" }
    }
    #expect(found, "Default exchanges should appear in listing")
  }

  @Test func listExchangesInVhostContainsDefaults() async throws {
    let found = try await pollUntil {
      let exchanges = try await client.listExchanges(in: testVhost)
      return exchanges.contains { $0.name == "amq.direct" }
    }
    #expect(found, "Default exchange should appear in vhost listing")
  }

  @Test func declareAndDeleteFanoutExchange() async throws {
    try await withTestVhost("fanout-x") { vh in
      let name = "swift.test.fanout"
      let params = ExchangeParams.fanout(name, in: vh)
      try await client.declareExchange(params)

      let info = try await client.getExchangeInfo(name, in: vh)
      #expect(info.name == name)
      #expect(info.type == "fanout")
      #expect(info.durable == true)

      try await client.deleteExchange(name, in: vh)
    }
  }

  @Test func declareAndDeleteTopicExchange() async throws {
    try await withTestVhost("topic-x") { vh in
      let name = "swift.test.topic"
      let params = ExchangeParams.topic(name, in: vh)
      try await client.declareExchange(params)

      let info = try await client.getExchangeInfo(name, in: vh)
      #expect(info.name == name)
      #expect(info.type == "topic")
    }
  }

  @Test func declareAndDeleteDirectExchange() async throws {
    try await withTestVhost("direct-x") { vh in
      let name = "swift.test.direct"
      let params = ExchangeParams.direct(name, in: vh)
      try await client.declareExchange(params)

      let info = try await client.getExchangeInfo(name, in: vh)
      #expect(info.name == name)
      #expect(info.type == "direct")
    }
  }

  @Test func declareAndDeleteHeadersExchange() async throws {
    try await withTestVhost("headers-x") { vh in
      let name = "swift.test.headers"
      let params = ExchangeParams.headers(name, in: vh)
      try await client.declareExchange(params)

      let info = try await client.getExchangeInfo(name, in: vh)
      #expect(info.name == name)
      #expect(info.type == "headers")
    }
  }

  @Test func declareExchangeWithArguments() async throws {
    try await withTestVhost("x-args") { vh in
      let name = "swift.test.args.x"
      let params = ExchangeParams.direct(
        name, in: vh,
        arguments: ["alternate-exchange": .string("amq.fanout")])
      try await client.declareExchange(params)

      let info = try await client.getExchangeInfo(name, in: vh)
      #expect(info.name == name)
      #expect(info.arguments?["alternate-exchange"] == .string("amq.fanout"))
    }
  }

  @Test func deleteExchangeIdempotently() async throws {
    try await client.deleteExchange("nonexistent-x-\(UUID())", in: testVhost, idempotently: true)
  }

  @Test func getNonexistentExchangeFails() async throws {
    do {
      _ = try await client.getExchangeInfo("nonexistent-x-\(UUID())", in: testVhost)
      Issue.record("Expected not found")
    } catch let error as ClientError where error.isNotFound {
      // expected
    }
  }
}
