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

@Suite struct ShovelTests {
  let client = newClient()

  @Test func declareAndDeleteShovel() async throws {
    try await withTestVhost("shovel-crud") { vh in
      let name = "swift-shovel"
      let srcQueue = "swift-shovel-src"
      let destQueue = "swift-shovel-dest"

      try await client.declareQueue(.classicQueue(srcQueue, in: vh))
      try await client.declareQueue(.classicQueue(destQueue, in: vh))

      let params = ShovelParams(
        name: name, vhost: vh,
        value: .init(
          srcUri: "amqp://", srcQueue: srcQueue,
          destUri: "amqp://", destQueue: destQueue,
          reconnectDelay: 5, ackMode: "on-confirm",
          srcPrefetchCount: 50))
      try await client.declareShovel(params)

      let found = try await pollUntil {
        let shovels = try await client.listShovels(in: vh)
        return shovels.contains { $0.name == name }
      }
      #expect(found, "Shovel should appear in listing")

      let info = try await client.getShovel(name, in: vh)
      #expect(info.name == name)
      #expect(info.value?.srcQueue == srcQueue)
      #expect(info.value?.destQueue == destQueue)

      try await client.deleteShovel(name, in: vh)

      let gone = try await pollUntil {
        let shovels = try await client.listShovels(in: vh)
        return !shovels.contains { $0.name == name }
      }
      #expect(gone, "Deleted shovel should disappear")
    }
  }

  @Test func listShovels() async throws {
    let _: [ShovelStatusInfo] = try await client.listShovels()
  }

  @Test func declareAmqp091QueueShovel() async throws {
    try await withTestVhost("shovel-091q") { vh in
      let srcQueue = "swift-091-src"
      let destQueue = "swift-091-dest"
      try await client.declareQueue(.classicQueue(srcQueue, in: vh))
      try await client.declareQueue(.classicQueue(destQueue, in: vh))

      let params = ShovelParams.amqp091QueueShovel(
        "swift-091-shovel", in: vh,
        srcUri: "amqp://", srcQueue: srcQueue,
        destUri: "amqp://", destQueue: destQueue,
        prefetchCount: 100)
      try await client.declareShovel(params)

      let found = try await pollUntil {
        let shovels = try await client.listShovels(in: vh)
        return shovels.contains { $0.name == "swift-091-shovel" }
      }
      #expect(found, "AMQP 0-9-1 queue shovel should appear in listing")

      let info = try await client.getShovel("swift-091-shovel", in: vh)
      #expect(info.value?.srcProtocol == "amqp091")
      #expect(info.value?.destProtocol == "amqp091")
    }
  }

  @Test func declareAmqp091ExchangeShovel() async throws {
    try await withTestVhost("shovel-091x") { vh in
      try await client.declareExchange(.fanout("swift-091-src-x", in: vh))
      try await client.declareExchange(.fanout("swift-091-dest-x", in: vh))

      let params = ShovelParams.amqp091ExchangeShovel(
        "swift-091x-shovel", in: vh,
        srcUri: "amqp://", srcExchange: "swift-091-src-x",
        destUri: "amqp://", destExchange: "swift-091-dest-x",
        ackMode: .onPublish)
      try await client.declareShovel(params)

      let found = try await pollUntil {
        let shovels = try await client.listShovels(in: vh)
        return shovels.contains { $0.name == "swift-091x-shovel" }
      }
      #expect(found, "AMQP 0-9-1 exchange shovel should appear in listing")
    }
  }

  @Test func deleteShovelIdempotently() async throws {
    try await client.deleteShovel(
      "nonexistent-shovel-\(UUID().uuidString.prefix(8))",
      in: testVhost, idempotently: true)
  }
}
