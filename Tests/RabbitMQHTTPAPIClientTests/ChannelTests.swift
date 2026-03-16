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

@Suite struct ChannelTests {
  let client = newClient()

  @Test func listChannelsIncludesOpenChannel() async throws {
    let conn = try await Connection.open()
    _ = try await conn.openChannel()

    let found = try await pollUntil {
      let channels = try await client.listChannels()
      return channels.contains { $0.user == "guest" }
    }
    #expect(found, "Open channel should appear in listing")

    try await conn.close()
  }

  @Test func listChannelsInVhost() async throws {
    let conn = try await Connection.open()
    _ = try await conn.openChannel()

    let found = try await pollUntil {
      let channels = try await client.listChannels(in: testVhost)
      return !channels.isEmpty
    }
    #expect(found, "Channel should appear in vhost listing")

    try await conn.close()
  }

  @Test func getChannelInfo() async throws {
    let username = "swift-chaninfo-\(UUID().uuidString.prefix(8))"
    try await client.createUser(.withPassword(username, password: "s3cret", tags: []))
    try await client.grantPermissions(PermissionParams(user: username, vhost: testVhost))

    let conn = try await Connection.open(
      host: "localhost", port: 5672, virtualHost: "/",
      username: username, password: "s3cret")
    _ = try await conn.openChannel()

    let found = try await pollUntil {
      let channels = try await client.listChannels()
      guard let channelName = channels.first(where: { $0.user == username })?.name else {
        return false
      }
      let info = try await client.getChannelInfo(channelName)
      return info.user == username && info.vhost == "/" && info.node != nil
    }
    #expect(found, "Should retrieve channel info")

    try await conn.close()
    try await client.deleteUser(username, idempotently: true)
  }

  @Test func listChannelsOnConnection() async throws {
    let username = "swift-chanconn-\(UUID().uuidString.prefix(8))"
    try await client.createUser(.withPassword(username, password: "s3cret", tags: []))
    try await client.grantPermissions(PermissionParams(user: username, vhost: testVhost))

    let conn = try await Connection.open(
      host: "localhost", port: 5672, virtualHost: "/",
      username: username, password: "s3cret")
    _ = try await conn.openChannel()
    _ = try await conn.openChannel()

    let found = try await pollUntil {
      let connections = try await client.listConnections()
      guard let connName = connections.first(where: { $0.user == username })?.name else {
        return false
      }
      let channels = try await client.listChannels(on: connName)
      return channels.count >= 2
    }
    #expect(found, "Both channels should appear on connection")

    try await conn.close()
    try await client.deleteUser(username, idempotently: true)
  }
}
