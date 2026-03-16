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

@Suite struct GlobalParameterTests {
  let client = newClient()

  @Test func listGlobalParameters() async throws {
    let _: [GlobalParameterInfo] = try await client.listGlobalParameters()
  }

  @Test func upsertAndDeleteGlobalParameter() async throws {
    let name = "swift-test-global-\(UUID().uuidString.prefix(8))"
    let params = GlobalParameterParams(
      name: name, value: .object(["key": .string("value")]))
    try await client.upsertGlobalParameter(params)

    let found = try await pollUntil {
      let all = try await client.listGlobalParameters()
      return all.contains { $0.name == name }
    }
    #expect(found, "Global parameter should appear in listing")

    let info = try await client.getGlobalParameter(name)
    #expect(info.name == name)

    try await client.deleteGlobalParameter(name)

    let gone = try await pollUntil {
      let all = try await client.listGlobalParameters()
      return !all.contains { $0.name == name }
    }
    #expect(gone, "Deleted global parameter should disappear")
  }

  @Test func clusterTags() async throws {
    try await client.clearClusterTags()

    let tags = ["zone": "us-east-1", "env": "test"]
    try await client.setClusterTags(tags)

    let retrieved = try await client.getClusterTags()
    #expect(retrieved["zone"] == "us-east-1")
    #expect(retrieved["env"] == "test")

    try await client.clearClusterTags()
  }
}
