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

@Suite struct UserTagsTests {
  let decoder = JSONDecoder()

  @Test func decodesFromArray() throws {
    let json = #"["administrator", "monitoring"]"#.data(using: .utf8)!
    let tags = try decoder.decode(UserTags.self, from: json)
    #expect(tags.values == ["administrator", "monitoring"])
    #expect(tags.isAdministrator)
    #expect(tags.isMonitoring)
  }

  @Test func decodesFromCommaSeparatedString() throws {
    let json = #""administrator, management""#.data(using: .utf8)!
    let tags = try decoder.decode(UserTags.self, from: json)
    #expect(tags.values == ["administrator", "management"])
    #expect(tags.isAdministrator)
    #expect(tags.isManagement)
  }

  @Test func decodesEmptyString() throws {
    let json = #""""#.data(using: .utf8)!
    let tags = try decoder.decode(UserTags.self, from: json)
    #expect(tags.values.isEmpty)
    #expect(!tags.isAdministrator)
  }

  @Test func decodesEmptyArray() throws {
    let json = "[]".data(using: .utf8)!
    let tags = try decoder.decode(UserTags.self, from: json)
    #expect(tags.values.isEmpty)
  }

  @Test func administratorImpliesMonitoringAndPolicymaker() throws {
    let json = #"["administrator"]"#.data(using: .utf8)!
    let tags = try decoder.decode(UserTags.self, from: json)
    #expect(tags.isAdministrator)
    #expect(tags.isMonitoring)
    #expect(tags.isPolicymaker)
    #expect(tags.isManagement)
  }

  @Test func monitoringImpliesManagement() throws {
    let json = #"["monitoring"]"#.data(using: .utf8)!
    let tags = try decoder.decode(UserTags.self, from: json)
    #expect(!tags.isAdministrator)
    #expect(tags.isMonitoring)
    #expect(tags.isManagement)
  }
}
