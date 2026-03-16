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

@Suite struct MemoryValueTests {
  let decoder = JSONDecoder()

  @Test func decodesPlainInt() throws {
    let json = "12345".data(using: .utf8)!
    let value = try decoder.decode(MemoryValue.self, from: json)
    #expect(value.bytes == 12345)
  }

  @Test func decodesObjectWithBytesKey() throws {
    let json = #"{"bytes": 67890}"#.data(using: .utf8)!
    let value = try decoder.decode(MemoryValue.self, from: json)
    #expect(value.bytes == 67890)
  }

  @Test func decodesObjectWithMissingBytesKey() throws {
    let json = "{}".data(using: .utf8)!
    let value = try decoder.decode(MemoryValue.self, from: json)
    #expect(value.bytes == nil)
  }
}
