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

@Suite struct DeprecatedFeatureTests {
  let client = newClient()

  @Test func listDeprecatedFeatures() async throws {
    let features = try await client.listDeprecatedFeatures()
    for feature in features {
      #expect(!feature.name.isEmpty)
    }
  }

  @Test func listDeprecatedFeaturesInUse() async throws {
    let features = try await client.listDeprecatedFeaturesInUse()
    for feature in features {
      #expect(!feature.name.isEmpty)
    }
  }
}
