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

@Suite struct LimitTests {
  let client = newClient()

  @Test func setAndClearUserLimits() async throws {
    let username = "swift.test.lim.\(UUID().uuidString.prefix(8))"
    try await client.createUser(.withPassword(username, password: "test-pass", tags: []))

    try await client.setUserLimit(username, .maxConnections, value: 10)
    try await client.setUserLimit(username, .maxChannels, value: 100)

    let limits = try await client.listUserLimits(username)
    #expect(!limits.isEmpty)
    let connLimit = limits.first { $0.value["max-connections"] != nil }
    #expect(connLimit?.value["max-connections"] == 10)
    let chanLimit = limits.first { $0.value["max-channels"] != nil }
    #expect(chanLimit?.value["max-channels"] == 100)

    let foundInAll = try await pollUntil {
      let allLimits = try await client.listAllUserLimits()
      return allLimits.contains { $0.user == username }
    }
    #expect(foundInAll, "User limits should appear in cluster-wide listing")

    try await client.clearUserLimit(username, .maxConnections)
    try await client.clearUserLimit(username, .maxChannels)

    let afterClear = try await client.listUserLimits(username)
    let remaining = afterClear.flatMap { $0.value.keys }
    #expect(!remaining.contains("max-connections"))
    #expect(!remaining.contains("max-channels"))

    try await client.deleteUser(username)
  }

  @Test func setAndClearVirtualHostLimits() async throws {
    let vhost = "swift.tests.vhlim.\(UUID().uuidString.prefix(8))"
    try await client.createVirtualHost(VirtualHostParams(name: vhost))

    try await client.setVirtualHostLimit(vhost, .maxConnections, value: 1000)
    try await client.setVirtualHostLimit(vhost, .maxQueues, value: 5000)

    let limits = try await client.listVirtualHostLimits(vhost)
    #expect(!limits.isEmpty)
    let connLimit = limits.first { $0.value["max-connections"] != nil }
    #expect(connLimit?.value["max-connections"] == 1000)
    let queueLimit = limits.first { $0.value["max-queues"] != nil }
    #expect(queueLimit?.value["max-queues"] == 5000)

    let foundInAll = try await pollUntil {
      let allLimits = try await client.listAllVirtualHostLimits()
      return allLimits.contains { $0.vhost == vhost }
    }
    #expect(foundInAll, "Vhost limits should appear in cluster-wide listing")

    try await client.clearVirtualHostLimit(vhost, .maxConnections)
    try await client.clearVirtualHostLimit(vhost, .maxQueues)

    try await client.deleteVirtualHost(vhost)
  }
}
