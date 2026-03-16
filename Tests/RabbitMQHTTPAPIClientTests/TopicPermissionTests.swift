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

@Suite struct TopicPermissionTests {
  let client = newClient()

  @Test func grantListAndClearTopicPermissions() async throws {
    let username = "swift.test.tp.\(UUID().uuidString.prefix(8))"
    try await client.createUser(.withPassword(username, password: "test-pass", tags: []))
    try await client.grantPermissions(PermissionParams(user: username, vhost: testVhost))

    let params = TopicPermissionParams(
      user: username, vhost: testVhost, exchange: "amq.topic",
      write: "^pub\\.", read: "^sub\\.")
    try await client.grantTopicPermissions(params)

    let foundByUser = try await pollUntil {
      let byUser = try await client.listTopicPermissions(of: username)
      return byUser.contains { $0.exchange == "amq.topic" && $0.vhost == testVhost }
    }
    #expect(foundByUser, "Topic permission should appear in user listing")

    let byUser = try await client.listTopicPermissions(of: username)
    let matching = byUser.filter { $0.exchange == "amq.topic" && $0.vhost == testVhost }
    #expect(matching[0].write == "^pub\\.")
    #expect(matching[0].read == "^sub\\.")

    let specific = try await client.getTopicPermissions(of: username, in: testVhost)
    #expect(specific.contains { $0.exchange == "amq.topic" })

    let foundByVhost = try await pollUntil {
      let byVhost = try await client.listTopicPermissions(in: testVhost)
      return byVhost.contains { $0.user == username && $0.exchange == "amq.topic" }
    }
    #expect(foundByVhost, "Topic permission should appear in vhost listing")

    let foundInAll = try await pollUntil {
      let all = try await client.listTopicPermissions()
      return all.contains { $0.user == username }
    }
    #expect(foundInAll, "Topic permission should appear in cluster-wide listing")

    try await client.clearTopicPermissions(of: username, in: testVhost)

    let after = try await client.listTopicPermissions(of: username)
    #expect(!after.contains { $0.vhost == testVhost })

    try await client.deleteUser(username)
  }
}
