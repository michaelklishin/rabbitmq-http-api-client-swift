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

@Suite struct VirtualHostTests {
  let client = newClient()
  let vhostName = "swift.tests.vhost.\(UUID().uuidString.prefix(8))"

  @Test func listVirtualHosts() async throws {
    let vhosts = try await client.listVirtualHosts()
    #expect(!vhosts.isEmpty)
    #expect(vhosts.contains { $0.name == "/" })
  }

  @Test func getDefaultVirtualHost() async throws {
    let vh = try await client.getVirtualHost("/")
    #expect(vh.name == "/")
  }

  @Test func createAndDeleteVirtualHost() async throws {
    let params = VirtualHostParams(
      name: vhostName, description: "test vhost", tags: ["swift", "test"])
    try await client.createVirtualHost(params)

    let vh = try await client.getVirtualHost(vhostName)
    #expect(vh.name == vhostName)

    try await client.deleteVirtualHost(vhostName)
    do {
      _ = try await client.getVirtualHost(vhostName)
      Issue.record("Expected not found error")
    } catch let error as ClientError where error.isNotFound {
      // expected
    }
  }

  @Test func deleteVirtualHostIdempotently() async throws {
    try await client.deleteVirtualHost("nonexistent-vhost-\(UUID())", idempotently: true)
  }

  @Test func deleteNonexistentVirtualHostFails() async throws {
    do {
      try await client.deleteVirtualHost("nonexistent-vhost-\(UUID())", idempotently: false)
      Issue.record("Expected not found error")
    } catch let error as ClientError where error.isNotFound {
      // expected
    }
  }

  @Test func updateVirtualHost() async throws {
    let name = "swift.tests.update-vh.\(UUID().uuidString.prefix(8))"
    try await client.createVirtualHost(VirtualHostParams(name: name))

    try await client.createVirtualHost(
      VirtualHostParams(
        name: name, description: "updated description", tags: ["updated"]))

    let vh = try await client.getVirtualHost(name)
    #expect(vh.name == name)

    try await client.deleteVirtualHost(name)
  }

  @Test func createVirtualHostWithDefaultQueueType() async throws {
    let name = "swift.tests.dqt.\(UUID().uuidString.prefix(8))"
    try await client.createVirtualHost(
      VirtualHostParams(
        name: name, defaultQueueType: "quorum"))

    let vh = try await client.getVirtualHost(name)
    #expect(vh.name == name)

    try await client.deleteVirtualHost(name)
  }

  @Test func vhostDeletionProtection() async throws {
    let name = "swift.tests.dp.\(UUID().uuidString.prefix(8))"
    try await client.createVirtualHost(VirtualHostParams(name: name))

    try await client.enableVirtualHostDeletionProtection(name)

    do {
      try await client.deleteVirtualHost(name)
      Issue.record("Expected deletion to fail due to protection")
    } catch {
    }

    try await client.disableVirtualHostDeletionProtection(name)
    try await client.deleteVirtualHost(name)
  }
}
