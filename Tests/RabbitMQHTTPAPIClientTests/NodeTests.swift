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

import RabbitMQHTTPAPIClient
import Testing

@Suite struct NodeTests {
  let client = newClient()

  @Test func listNodes() async throws {
    let nodes = try await client.listNodes()
    #expect(!nodes.isEmpty)
    let node = nodes[0]
    #expect(node.name.contains("@"))
    #expect(node.running == true)
  }

  @Test func getNodeInfo() async throws {
    let nodes = try await client.listNodes()
    let name = nodes[0].name
    let node = try await client.getNodeInfo(name)
    #expect(node.name == name)
    #expect(node.running == true)
    #expect(node.erlangVersion != nil)
    #expect(node.fdUsed != nil)
    #expect(node.fdUsed! <= node.fdTotal!)
    #expect(node.processesUsed != nil)
    #expect(node.processesUsed! <= node.processesTotal!)
  }
}
