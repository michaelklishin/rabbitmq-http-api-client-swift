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

@Suite struct RuntimeParameterTests {
  let client = newClient()

  @Test func listRuntimeParameters() async throws {
    let _: [RuntimeParameterInfo] = try await client.listRuntimeParameters()
  }

  @Test func upsertAndDeleteRuntimeParameter() async throws {
    try await withTestVhost("rt-param-crud") { vh in
      let name = "swift-test-upstream"
      let value: JSONValue = .object([
        "uri": .string("amqp://localhost")
      ])
      let params = RuntimeParameterParams(
        name: name, vhost: vh, component: "federation-upstream",
        value: value)
      try await client.upsertRuntimeParameter(params)

      let found = try await pollUntil {
        let all = try await client.listRuntimeParameters(
          of: "federation-upstream", in: vh)
        return all.contains { $0.name == name }
      }
      #expect(found, "Runtime parameter should appear in listing")

      let info = try await client.getRuntimeParameter(
        name, of: "federation-upstream", in: vh)
      #expect(info.name == name)
      #expect(info.component == "federation-upstream")

      try await client.deleteRuntimeParameter(
        name, of: "federation-upstream", in: vh)

      let gone = try await pollUntil {
        let all = try await client.listRuntimeParameters(
          of: "federation-upstream", in: vh)
        return !all.contains { $0.name == name }
      }
      #expect(gone, "Deleted runtime parameter should disappear")
    }
  }

  @Test func listRuntimeParametersOfComponent() async throws {
    try await withTestVhost("rt-param-comp") { vh in
      let name = "swift-test-upstream"
      let params = RuntimeParameterParams(
        name: name, vhost: vh, component: "federation-upstream",
        value: .object(["uri": .string("amqp://localhost")]))
      try await client.upsertRuntimeParameter(params)

      let found = try await pollUntil {
        let all = try await client.listRuntimeParameters(of: "federation-upstream")
        return all.contains { $0.name == name }
      }
      #expect(found)
    }
  }
}
