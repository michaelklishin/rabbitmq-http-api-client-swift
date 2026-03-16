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

@Suite struct PluginTests {
  let client = newClient()

  @Test func listAllClusterPlugins() async throws {
    let plugins = try await client.listAllClusterPlugins()
    #expect(!plugins.isEmpty)
    #expect(plugins.contains("rabbitmq_management"))
  }

  @Test func listNodePlugins() async throws {
    let nodes = try await client.listNodes()
    guard let first = nodes.first else {
      Issue.record("No nodes found")
      return
    }
    let plugins = try await client.listNodePlugins(first.name)
    #expect(!plugins.isEmpty)
    #expect(plugins.contains("rabbitmq_management"))
  }
}
