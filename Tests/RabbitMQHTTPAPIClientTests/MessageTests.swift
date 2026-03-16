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

@Suite struct MessageTests {
  let client = newClient()

  @Test func publishAndGetMessage() async throws {
    try await withTestVhost("msg-pub") { vh in
      let qName = "swift.test.msg"
      try await client.declareQueue(QueueParams.classicQueue(qName, in: vh))

      let result = try await client.publishMessage(
        "hello from swift", to: "", routingKey: qName, in: vh)
      #expect(result.routed)

      try await awaitMetricEmission()

      let messages = try await client.getMessages(from: qName, in: vh)
      #expect(!messages.isEmpty)
      #expect(messages[0].payload == "hello from swift")
      #expect(messages[0].routingKey == qName)
    }
  }

  @Test func publishMultipleAndGetMessages() async throws {
    try await withTestVhost("msg-multi") { vh in
      let qName = "swift.test.multi-msg"
      try await client.declareQueue(QueueParams.classicQueue(qName, in: vh))

      for i in 1...3 {
        try await client.publishMessage("msg-\(i)", to: "", routingKey: qName, in: vh)
      }

      let appeared = try await pollUntil {
        let q = try await client.getQueueInfo(qName, in: vh)
        return (q.messages ?? 0) >= 3
      }
      #expect(appeared, "Messages should appear in queue")

      let messages = try await client.getMessages(from: qName, in: vh, count: 3)
      #expect(messages.count == 3)
    }
  }

  @Test func publishToExchangeWithRoutingKey() async throws {
    try await withTestVhost("msg-route") { vh in
      let qName = "swift.test.routed"
      let xName = "swift.test.route-x"

      try await client.declareQueue(QueueParams.classicQueue(qName, in: vh))
      try await client.declareExchange(ExchangeParams.direct(xName, in: vh))
      try await client.bindQueue(qName, to: xName, in: vh, routingKey: "rk.test")

      let result = try await client.publishMessage(
        "routed message", to: xName, routingKey: "rk.test", in: vh)
      #expect(result.routed)

      let appeared = try await pollUntil {
        let q = try await client.getQueueInfo(qName, in: vh)
        return (q.messages ?? 0) > 0
      }
      #expect(appeared, "Routed message should appear")

      let messages = try await client.getMessages(from: qName, in: vh)
      #expect(messages[0].payload == "routed message")
      #expect(messages[0].exchange == xName)
    }
  }
}
