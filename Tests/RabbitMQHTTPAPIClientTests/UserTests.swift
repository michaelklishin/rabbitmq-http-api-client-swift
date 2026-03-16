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

@Suite struct UserTests {
  let client = newClient()

  @Test func listUsers() async throws {
    let users = try await client.listUsers()
    #expect(!users.isEmpty)
    #expect(users.contains { $0.name == "guest" })
  }

  @Test func getUser() async throws {
    let user = try await client.getUser("guest")
    #expect(user.name == "guest")
    #expect(user.tags.isAdministrator)
  }

  @Test func whoami() async throws {
    let me = try await client.whoami()
    #expect(me.name == "guest")
    #expect(me.tags.isAdministrator)
  }

  @Test func createAndDeleteUser() async throws {
    let name = "swift-test-\(UUID().uuidString.prefix(8))"
    try? await client.deleteUser(name, idempotently: true)

    let params = UserParams.withPassword(name, password: "s3cret", tags: ["management"])
    try await client.createUser(params)

    let user = try await client.getUser(name)
    #expect(user.name == name)
    #expect(user.tags.isManagement)

    try await client.deleteUser(name)
    do {
      _ = try await client.getUser(name)
      Issue.record("Expected not found")
    } catch let error as ClientError where error.isNotFound {
      // expected
    }
  }

  @Test func createUserWithAdministratorTag() async throws {
    let name = "swift-admin-\(UUID().uuidString.prefix(8))"
    try? await client.deleteUser(name, idempotently: true)

    let params = UserParams.withPassword(name, password: "s3cret", tags: ["administrator"])
    try await client.createUser(params)

    let user = try await client.getUser(name)
    #expect(user.tags.isAdministrator)
    #expect(user.tags.isMonitoring)
    #expect(user.tags.isPolicymaker)

    try await client.deleteUser(name)
  }

  @Test func deleteUserIdempotently() async throws {
    try await client.deleteUser("nonexistent-user-\(UUID())", idempotently: true)
  }

  @Test func getNonexistentUserFails() async throws {
    do {
      _ = try await client.getUser("nonexistent-user-\(UUID())")
      Issue.record("Expected not found")
    } catch let error as ClientError where error.isNotFound {
      // expected
    }
  }

  @Test func bulkDeleteUsers() async throws {
    let name1 = "swift-bulk1-\(UUID().uuidString.prefix(8))"
    let name2 = "swift-bulk2-\(UUID().uuidString.prefix(8))"
    try await client.createUser(.withPassword(name1, password: "pass", tags: []))
    try await client.createUser(.withPassword(name2, password: "pass", tags: []))

    try await client.deleteUsers([name1, name2])

    do {
      _ = try await client.getUser(name1)
      Issue.record("Expected not found")
    } catch let error as ClientError where error.isNotFound {
      // expected
    }
  }

  @Test func listUsersWithoutPermissions() async throws {
    let name = "swift-noperm-\(UUID().uuidString.prefix(8))"
    try await client.createUser(.withPassword(name, password: "pass", tags: []))

    let found = try await pollUntil {
      let users = try await client.listUsersWithoutPermissions()
      return users.contains { $0.name == name }
    }
    #expect(found, "User without permissions should appear in listing")

    try await client.deleteUser(name)
  }
}
