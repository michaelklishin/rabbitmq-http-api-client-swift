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

@Suite struct ConnectionTests {
  let client = newClient()

  @Test func listConnectionsIncludesOpenConnection() async throws {
    let conn = try await Connection.open()
    _ = try await conn.openChannel()

    let found = try await pollUntil {
      let connections = try await client.listConnections()
      return connections.contains { $0.user == "guest" }
    }
    #expect(found, "Open connection should appear in listing")

    try await conn.close()
  }

  @Test func listConnectionsInVhost() async throws {
    let conn = try await Connection.open()
    _ = try await conn.openChannel()

    let found = try await pollUntil {
      let connections = try await client.listConnections(in: testVhost)
      return !connections.isEmpty
    }
    #expect(found, "Connection should appear in vhost listing")

    try await conn.close()
  }

  @Test func getConnectionInfo() async throws {
    let username = "swift-conninfo-\(UUID().uuidString.prefix(8))"
    try await client.createUser(.withPassword(username, password: "s3cret", tags: []))
    try await client.grantPermissions(PermissionParams(user: username, vhost: testVhost))

    let conn = try await Connection.open(
      host: "localhost", port: 5672, virtualHost: "/",
      username: username, password: "s3cret")
    _ = try await conn.openChannel()

    let found = try await pollUntil {
      let connections = try await client.listConnections()
      guard let connName = connections.first(where: { $0.user == username })?.name else {
        return false
      }
      let info = try await client.getConnectionInfo(connName)
      return info.user == username && info.vhost == "/"
    }
    #expect(found, "Should retrieve connection info")

    try await conn.close()
    try await client.deleteUser(username, idempotently: true)
  }

  @Test func closeConnection() async throws {
    let username = "swift-close-\(UUID().uuidString.prefix(8))"
    try await client.createUser(.withPassword(username, password: "s3cret", tags: []))
    try await client.grantPermissions(PermissionParams(user: username, vhost: testVhost))

    let conn = try await Connection.open(
      host: "localhost", port: 5672, virtualHost: "/",
      username: username, password: "s3cret")
    _ = try await conn.openChannel()

    let found = try await pollUntil {
      let connections = try await client.listConnections()
      return connections.contains { $0.user == username }
    }
    #expect(found)

    let connections = try await client.listConnections()
    let connName = connections.first { $0.user == username }!.name
    try await client.closeConnection(connName, reason: "test cleanup")

    let closed = try await pollUntil {
      let conns = try await client.listConnections()
      return !conns.contains { $0.name == connName }
    }
    #expect(closed, "Closed connection should disappear from listing")

    try await client.deleteUser(username, idempotently: true)
  }

  @Test func listUserConnections() async throws {
    let conn = try await Connection.open()
    _ = try await conn.openChannel()

    let found = try await pollUntil {
      let conns = try await client.listUserConnections("guest")
      return !conns.isEmpty
    }
    #expect(found, "User connections should be listed")

    try await conn.close()
  }
}
