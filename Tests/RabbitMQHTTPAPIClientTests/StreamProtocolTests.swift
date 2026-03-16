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

@Suite struct StreamProtocolTests {
  let client = newClient()

  @Test func listStreamPublishers() async throws {
    let _: [StreamPublisherInfo] = try await client.listStreamPublishers()
  }

  @Test func listStreamPublishersInVhost() async throws {
    let _: [StreamPublisherInfo] = try await client.listStreamPublishers(in: testVhost)
  }

  @Test func listStreamConsumers() async throws {
    let _: [StreamConsumerInfo] = try await client.listStreamConsumers()
  }

  @Test func listStreamConsumersInVhost() async throws {
    let _: [StreamConsumerInfo] = try await client.listStreamConsumers(in: testVhost)
  }

  @Test func listStreamConnections() async throws {
    let _: [ConnectionInfo] = try await client.listStreamConnections()
  }

  @Test func listStreamConnectionsInVhost() async throws {
    let _: [ConnectionInfo] = try await client.listStreamConnections(in: testVhost)
  }
}
