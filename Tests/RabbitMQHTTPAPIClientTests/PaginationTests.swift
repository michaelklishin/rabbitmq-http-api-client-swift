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

@Suite struct PaginationTests {
  let client = newClient()

  @Test func listExchangesPaginated() async throws {
    let page = PaginationParams(page: 1, pageSize: 5)
    let result = try await client.listExchanges(page: page)
    #expect(result.page == 1)
    #expect(result.pageSize == 5)
    #expect(result.totalCount > 0, "Should have at least default exchanges")
    #expect(!result.items.isEmpty)
  }

  @Test func listExchangesInVhostPaginated() async throws {
    let page = PaginationParams(page: 1, pageSize: 5)
    let result = try await client.listExchanges(in: testVhost, page: page)
    #expect(result.page == 1)
    #expect(!result.items.isEmpty)
  }

  @Test func listQueuesPaginated() async throws {
    let page = PaginationParams(page: 1, pageSize: 5)
    let result = try await client.listQueues(page: page)
    #expect(result.page == 1)
    #expect(result.pageSize == 5)
    #expect(result.totalCount >= 0)
    #expect(result.pageCount >= 0)
    #expect(result.items.count <= 5)
  }

  @Test func listQueuesInVhostPaginated() async throws {
    let page = PaginationParams(page: 1, pageSize: 5)
    let result = try await client.listQueues(in: testVhost, page: page)
    #expect(result.page == 1)
    #expect(result.pageSize == 5)
  }

  @Test func paginatesThroughPages() async throws {
    let page1 = try await client.listExchanges(page: PaginationParams(page: 1, pageSize: 2))
    #expect(page1.page == 1)
    #expect(page1.items.count <= 2)

    if page1.pageCount > 1 {
      let page2 = try await client.listExchanges(page: PaginationParams(page: 2, pageSize: 2))
      #expect(page2.page == 2)
      #expect(page2.items.count <= 2)
      let page1Names = Set(page1.items.map(\.name))
      let page2Names = Set(page2.items.map(\.name))
      #expect(page1Names.isDisjoint(with: page2Names), "Pages should have different items")
    }
  }

  @Test func listConnectionsPaginated() async throws {
    let page = PaginationParams(page: 1, pageSize: 100)
    let result = try await client.listConnections(page: page)
    #expect(result.page == 1)
    #expect(result.pageSize == 100)
  }

  @Test func paginationParamsClampPageSize() async throws {
    let page = PaginationParams(page: 1, pageSize: 9999)
    #expect(page.pageSize == 500, "Page size should be clamped to 500")
  }
}
