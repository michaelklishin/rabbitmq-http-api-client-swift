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

@Suite struct PolicyTests {
  let client = newClient()

  @Test func declareAndDeletePolicy() async throws {
    try await withTestVhost("policy-crud") { vh in
      let name = "swift.test.policy"
      let params = PolicyParams(
        name: name, vhost: vh, pattern: "^swift\\.test\\.",
        applyTo: .queues, priority: 10,
        definition: ["message-ttl": .int(60000)])
      try await client.declarePolicy(params)

      let policy = try await client.getPolicy(name, in: vh)
      #expect(policy.name == name)
      #expect(policy.pattern == "^swift\\.test\\.")
      #expect(policy.applyTo == .queues)
      #expect(policy.priority == 10)
      #expect(policy.definition["message-ttl"] == .int(60000))

      try await client.deletePolicy(name, in: vh)
      do {
        _ = try await client.getPolicy(name, in: vh)
        Issue.record("Expected not found")
      } catch let error as ClientError where error.isNotFound {
        // expected
      }
    }
  }

  @Test func listPoliciesInVhost() async throws {
    try await withTestVhost("policy-list") { vh in
      let name = "swift.test.list-pol"
      let params = PolicyParams(
        name: name, vhost: vh, pattern: "^never-match\\.",
        definition: ["max-length": .int(100)])
      try await client.declarePolicy(params)

      let foundInVhost = try await pollUntil {
        let policies = try await client.listPolicies(in: vh)
        return policies.contains { $0.name == name }
      }
      #expect(foundInVhost, "Policy should appear in vhost listing")

      let foundInAll = try await pollUntil {
        let policies = try await client.listPolicies()
        return policies.contains { $0.name == name }
      }
      #expect(foundInAll, "Policy should appear in cluster-wide listing")
    }
  }

  @Test func declarePolicyForExchanges() async throws {
    try await withTestVhost("policy-exchanges") { vh in
      let name = "swift.test.x-pol"
      let params = PolicyParams(
        name: name, vhost: vh, pattern: "^swift\\.test\\.",
        applyTo: .exchanges, priority: 5,
        definition: ["alternate-exchange": .string("amq.fanout")])
      try await client.declarePolicy(params)

      let policy = try await client.getPolicy(name, in: vh)
      #expect(policy.applyTo == .exchanges)
      #expect(policy.definition["alternate-exchange"] == .string("amq.fanout"))
    }
  }

  @Test func deletePolicyIdempotently() async throws {
    try await client.deletePolicy("nonexistent-pol-\(UUID())", in: testVhost, idempotently: true)
  }
}
