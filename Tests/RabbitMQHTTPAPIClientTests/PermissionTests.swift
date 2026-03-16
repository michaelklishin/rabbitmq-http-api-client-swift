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

@Suite struct PermissionTests {
  let client = newClient()

  @Test func listPermissions() async throws {
    let perms = try await client.listPermissions()
    #expect(!perms.isEmpty)
    #expect(perms.contains { $0.user == "guest" && $0.vhost == "/" })
  }

  @Test func listPermissionsInVhost() async throws {
    let perms = try await client.listPermissions(in: testVhost)
    #expect(!perms.isEmpty)
  }

  @Test func getPermissions() async throws {
    let perms = try await client.getPermissions(of: "guest", in: testVhost)
    #expect(perms.user == "guest")
    #expect(perms.configure == ".*")
  }

  @Test func listPermissionsOfUser() async throws {
    let perms = try await client.listPermissions(of: "guest")
    #expect(!perms.isEmpty)
    #expect(perms.contains { $0.vhost == "/" })
  }

  @Test func grantAndClearPermissions() async throws {
    let user = "swift-perm-\(UUID().uuidString.prefix(8))"
    try? await client.deleteUser(user, idempotently: true)

    try await client.createUser(
      UserParams.withPassword(user, password: "s3cret", tags: ["management"]))

    let params = PermissionParams(
      user: user, vhost: testVhost,
      configure: "^swift\\.", write: "^swift\\.", read: ".*")
    try await client.grantPermissions(params)

    let perms = try await client.getPermissions(of: user, in: testVhost)
    #expect(perms.configure == "^swift\\.")
    #expect(perms.read == ".*")

    try await client.clearPermissions(of: user, in: testVhost)
    try await client.deleteUser(user)
  }
}
