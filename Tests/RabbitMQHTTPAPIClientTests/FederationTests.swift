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

@Suite struct FederationTests {
  let client = newClient()

  @Test func declareAndDeleteFederationUpstream() async throws {
    try await withTestVhost("fed-crud") { vh in
      let name = "swift-fed-upstream"
      let params = FederationUpstreamParams(
        name: name, vhost: vh,
        value: .init(uri: "amqp://localhost", prefetchCount: 10, reconnectDelay: 5))
      try await client.declareFederationUpstream(params)

      let found = try await pollUntil {
        let upstreams = try await client.listFederationUpstreams(in: vh)
        return upstreams.contains { $0.name == name }
      }
      #expect(found, "Federation upstream should appear in listing")

      let info = try await client.getFederationUpstream(name, in: vh)
      #expect(info.name == name)
      #expect(info.component == "federation-upstream")

      try await client.deleteFederationUpstream(name, in: vh)

      let gone = try await pollUntil {
        let upstreams = try await client.listFederationUpstreams(in: vh)
        return !upstreams.contains { $0.name == name }
      }
      #expect(gone, "Deleted upstream should disappear")
    }
  }

  @Test func listFederationUpstreams() async throws {
    try await withTestVhost("fed-list") { vh in
      let name = "swift-fed-list"
      let params = FederationUpstreamParams(
        name: name, vhost: vh,
        value: .init(uri: "amqp://localhost"))
      try await client.declareFederationUpstream(params)

      let found = try await pollUntil {
        let upstreams = try await client.listFederationUpstreams()
        return upstreams.contains { $0.name == name }
      }
      #expect(found, "Upstream should appear in cluster-wide listing")
    }
  }

  @Test func listFederationLinks() async throws {
    let _: [FederationLinkInfo] = try await client.listFederationLinks()
  }

  @Test func listFederationLinksInVhost() async throws {
    let _: [FederationLinkInfo] = try await client.listFederationLinks(in: testVhost)
  }
}
