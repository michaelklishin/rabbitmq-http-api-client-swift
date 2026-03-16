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

import BunnySwift
import Foundation
import RabbitMQHTTPAPIClient
import Testing

@Suite struct ConsumerTests {
  let client = newClient()

  @Test func listConsumersIncludesActiveConsumer() async throws {
    try await withTestVhost("consumer-list") { vh in
      let conn = try await Connection.open(
        host: "localhost", port: 5672, virtualHost: vh,
        username: testUsername, password: testPassword)
      let ch = try await conn.openChannel()

      let qName = "swift.test.consumer"
      let q = try await ch.queue(qName, durable: false, exclusive: false, autoDelete: false)
      _ = try await q.consume(acknowledgementMode: .automatic)

      let found = try await pollUntil {
        let consumers = try await client.listConsumers()
        return consumers.contains { $0.queue.name == qName }
      }
      #expect(found, "Consumer should appear in cluster-wide listing")

      try await conn.close()
    }
  }

  @Test func listConsumersInVhost() async throws {
    try await withTestVhost("consumer-vh") { vh in
      let conn = try await Connection.open(
        host: "localhost", port: 5672, virtualHost: vh,
        username: testUsername, password: testPassword)
      let ch = try await conn.openChannel()

      let qName = "swift.test.consumer-vh"
      let q = try await ch.queue(qName, durable: false, exclusive: false, autoDelete: false)
      _ = try await q.consume(acknowledgementMode: .automatic)

      let found = try await pollUntil {
        let consumers = try await client.listConsumers(in: vh)
        return consumers.contains { $0.queue.name == qName }
      }
      #expect(found, "Consumer should appear in vhost listing")

      try await conn.close()
    }
  }
}
