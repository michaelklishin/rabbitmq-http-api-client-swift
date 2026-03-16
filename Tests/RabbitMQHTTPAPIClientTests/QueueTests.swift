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

@Suite struct QueueTests {
  let client = newClient()

  @Test func listQueuesContainsDeclaredQueue() async throws {
    try await withTestVhost("list-queues") { vh in
      let name = "swift.test.list-all"
      try await client.declareQueue(QueueParams.classicQueue(name, in: vh))

      let found = try await pollUntil {
        let queues = try await client.listQueues()
        return queues.contains { $0.name == name && $0.vhost == vh }
      }
      #expect(found, "Declared queue should appear in global listing")

      let foundInVhost = try await pollUntil {
        let queues = try await client.listQueues(in: vh)
        return queues.contains { $0.name == name }
      }
      #expect(foundInVhost, "Declared queue should appear in vhost listing")
    }
  }

  @Test func declareAndDeleteClassicQueue() async throws {
    try await withTestVhost("classic-queue") { vh in
      let name = "swift.test.classic"
      let params = QueueParams.classicQueue(name, in: vh)
      try await client.declareQueue(params)

      let info = try await client.getQueueInfo(name, in: vh)
      #expect(info.name == name)
      #expect(info.vhost == vh)
      #expect(info.durable == true)
      #expect(info.queueType == .classic)

      try await client.deleteQueue(name, in: vh)
      do {
        _ = try await client.getQueueInfo(name, in: vh)
        Issue.record("Expected not found")
      } catch let error as ClientError where error.isNotFound {
        // expected
      }
    }
  }

  @Test func declareAndDeleteQuorumQueue() async throws {
    try await withTestVhost("quorum-queue") { vh in
      let name = "swift.test.quorum"
      let params = QueueParams.quorumQueue(name, in: vh)
      try await client.declareQueue(params)

      let info = try await client.getQueueInfo(name, in: vh)
      #expect(info.name == name)
      #expect(info.durable == true)
      #expect(info.queueType == .quorum)
    }
  }

  @Test func declareAndDeleteStream() async throws {
    try await withTestVhost("stream-queue") { vh in
      let name = "swift.test.stream"
      let params = QueueParams.stream(name, in: vh)
      try await client.declareQueue(params)

      let info = try await client.getQueueInfo(name, in: vh)
      #expect(info.name == name)
      #expect(info.queueType == .stream)
    }
  }

  @Test func declareQueueWithArguments() async throws {
    try await withTestVhost("queue-args") { vh in
      let name = "swift.test.args"
      let params = QueueParams.classicQueue(
        name, in: vh,
        arguments: ["x-max-length": .int(5000), "x-message-ttl": .int(60000)])
      try await client.declareQueue(params)

      let info = try await client.getQueueInfo(name, in: vh)
      #expect(info.name == name)
      #expect(info.arguments?["x-max-length"] == .int(5000))
      #expect(info.arguments?["x-message-ttl"] == .int(60000))
    }
  }

  @Test func listQueuesInVhost() async throws {
    try await withTestVhost("list-queues-vh") { vh in
      let name = "swift.test.list"
      try await client.declareQueue(QueueParams.classicQueue(name, in: vh))

      let found = try await pollUntil {
        let queues = try await client.listQueues(in: vh)
        return queues.contains { $0.name == name }
      }
      #expect(found, "Declared queue should appear in vhost listing")
    }
  }

  @Test func purgeQueue() async throws {
    try await withTestVhost("purge-queue") { vh in
      let name = "swift.test.purge"
      let params = QueueParams.classicQueue(name, in: vh)
      try await client.declareQueue(params)

      try await client.publishMessage("test", to: "", routingKey: name, in: vh)

      let appeared = try await pollUntil {
        let q = try await client.getQueueInfo(name, in: vh)
        return (q.messages ?? 0) > 0
      }
      #expect(appeared, "Message should appear in queue")

      try await client.purgeQueue(name, in: vh)

      let purged = try await pollUntil {
        let q = try await client.getQueueInfo(name, in: vh)
        return (q.messagesReady ?? 0) == 0
      }
      #expect(purged, "Queue should be empty after purge")
    }
  }

  @Test func deleteQueueIdempotently() async throws {
    try await client.deleteQueue("nonexistent-q-\(UUID())", in: testVhost, idempotently: true)
  }

  @Test func deleteNonexistentQueueFails() async throws {
    do {
      try await client.deleteQueue("nonexistent-q-\(UUID())", in: testVhost, idempotently: false)
      Issue.record("Expected not found")
    } catch let error as ClientError where error.isNotFound {
      // expected
    }
  }

  @Test func getNonexistentQueueFails() async throws {
    do {
      _ = try await client.getQueueInfo("nonexistent-q-\(UUID())", in: testVhost)
      Issue.record("Expected not found")
    } catch let error as ClientError where error.isNotFound {
      // expected
    }
  }
}
