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

@Suite struct OperatorPolicyTests {
  let client = newClient()

  @Test func declareAndDeleteOperatorPolicy() async throws {
    try await withTestVhost("op-pol-crud") { vh in
      let name = "swift.test.op-pol"
      let params = PolicyParams(
        name: name, vhost: vh, pattern: "^swift\\.test\\.",
        applyTo: .queues, priority: 5,
        definition: ["max-length": .int(500)])
      try await client.declareOperatorPolicy(params)

      let policy = try await client.getOperatorPolicy(name, in: vh)
      #expect(policy.name == name)
      #expect(policy.pattern == "^swift\\.test\\.")
      #expect(policy.priority == 5)
      #expect(policy.definition["max-length"] == .int(500))

      try await client.deleteOperatorPolicy(name, in: vh)
      do {
        _ = try await client.getOperatorPolicy(name, in: vh)
        Issue.record("Expected not found")
      } catch let error as ClientError where error.isNotFound {
        // expected
      }
    }
  }

  @Test func listOperatorPolicies() async throws {
    try await withTestVhost("op-pol-list") { vh in
      let name = "swift.test.op-list"
      let params = PolicyParams(
        name: name, vhost: vh, pattern: "^never-match\\.",
        definition: ["max-length": .int(50)])
      try await client.declareOperatorPolicy(params)

      let found = try await pollUntil {
        let policies = try await client.listOperatorPolicies(in: vh)
        return policies.contains { $0.name == name }
      }
      #expect(found, "Operator policy should appear in vhost listing")
    }
  }
}
