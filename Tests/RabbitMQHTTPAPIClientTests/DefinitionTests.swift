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

@Suite struct DefinitionTests {
  let client = newClient()

  @Test func exportDefinitions() async throws {
    let json = try await client.exportDefinitions()
    #expect(!json.isEmpty)
    #expect(json.contains("rabbitmq_version"))
    #expect(json.contains("vhosts"))
  }

  @Test func exportVhostDefinitions() async throws {
    let json = try await client.exportDefinitions(of: testVhost)
    #expect(!json.isEmpty)
  }

  @Test func importClusterDefinitions() async throws {
    try await withTestVhost("def-import") { vh in
      let qName = "swift.test.def.import"
      let json = """
        {"queues": [{"name": "\(qName)", "vhost": "\(vh)", \
        "durable": true, "auto_delete": false, \
        "arguments": {"x-queue-type": "classic"}}]}
        """
      try await client.importDefinitions(json)

      let info = try await client.getQueueInfo(qName, in: vh)
      #expect(info.name == qName)
    }
  }

  @Test func importVhostDefinitions() async throws {
    try await withTestVhost("def-vh-import") { vh in
      let qName = "swift.test.vhdef"
      let json = """
        {"queues": [{"name": "\(qName)", "vhost": "\(vh)", \
        "durable": true, "auto_delete": false, \
        "arguments": {"x-queue-type": "classic"}}]}
        """
      try await client.importDefinitions(json, into: vh)

      try await awaitMetricEmission()

      let info = try await client.getQueueInfo(qName, in: vh)
      #expect(info.name == qName)
    }
  }
}
