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

@Suite struct JSONValueTests {
  let decoder = JSONDecoder()
  let encoder = JSONEncoder()

  @Test func decodeString() throws {
    let json = #""hello""#.data(using: .utf8)!
    let value = try decoder.decode(JSONValue.self, from: json)
    #expect(value == .string("hello"))
  }

  @Test func decodeInt() throws {
    let json = "42".data(using: .utf8)!
    let value = try decoder.decode(JSONValue.self, from: json)
    #expect(value == .int(42))
  }

  @Test func decodeBool() throws {
    let json = "true".data(using: .utf8)!
    let value = try decoder.decode(JSONValue.self, from: json)
    #expect(value == .bool(true))
  }

  @Test func decodeDouble() throws {
    let json = "3.14".data(using: .utf8)!
    let value = try decoder.decode(JSONValue.self, from: json)
    #expect(value == .double(3.14))
  }

  @Test func decodeNull() throws {
    let json = "null".data(using: .utf8)!
    let value = try decoder.decode(JSONValue.self, from: json)
    #expect(value == .null)
  }

  @Test func decodeArray() throws {
    let json = "[1, 2, 3]".data(using: .utf8)!
    let value = try decoder.decode(JSONValue.self, from: json)
    #expect(value == .array([.int(1), .int(2), .int(3)]))
  }

  @Test func decodeObject() throws {
    let json = #"{"key": "value"}"#.data(using: .utf8)!
    let value = try decoder.decode(JSONValue.self, from: json)
    #expect(value == .object(["key": .string("value")]))
  }

  @Test func roundTrip() throws {
    let original: JSONValue = .object([
      "name": .string("test"),
      "count": .int(42),
      "active": .bool(true),
      "tags": .array([.string("a"), .string("b")]),
      "extra": .null,
    ])
    let data = try encoder.encode(original)
    let decoded = try decoder.decode(JSONValue.self, from: data)
    #expect(decoded == original)
  }

  @Test func hashableConformance() {
    var set = Set<JSONValue>()
    set.insert(.string("hello"))
    set.insert(.int(42))
    set.insert(.string("hello"))
    #expect(set.count == 2)
  }
}
