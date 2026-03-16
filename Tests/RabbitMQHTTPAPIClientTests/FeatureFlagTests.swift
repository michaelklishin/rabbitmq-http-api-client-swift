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

@Suite struct FeatureFlagTests {
  let client = newClient()

  @Test func listFeatureFlags() async throws {
    let flags = try await client.listFeatureFlags()
    #expect(!flags.isEmpty)
    for flag in flags {
      #expect(!flag.name.isEmpty)
    }
  }

  @Test func enableAllStableFeatureFlags() async throws {
    try await client.enableAllStableFeatureFlags()
  }
}
