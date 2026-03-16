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

@Suite struct ChannelConnectionDetailsTests {
  let decoder = JSONDecoder()

  @Test func decodesObject() throws {
    let json = #"{"name": "conn-1", "peer_host": "127.0.0.1", "peer_port": 54321}"#.data(
      using: .utf8)!
    let details = try decoder.decode(
      ChannelInfo.ChannelConnectionDetails.self, from: json)
    #expect(details.name == "conn-1")
    #expect(details.peerHost == "127.0.0.1")
    #expect(details.peerPort == 54321)
  }

  /// RabbitMQ returns connection_details as an empty array when a channel
  /// has no associated connection (e.g. internal channels).
  @Test func decodesEmptyArray() throws {
    let json = "[]".data(using: .utf8)!
    let details = try decoder.decode(
      ChannelInfo.ChannelConnectionDetails.self, from: json)
    #expect(details.name == nil)
    #expect(details.peerHost == nil)
    #expect(details.peerPort == nil)
  }

  @Test func decodesPartialObject() throws {
    let json = #"{"name": "conn-2"}"#.data(using: .utf8)!
    let details = try decoder.decode(
      ChannelInfo.ChannelConnectionDetails.self, from: json)
    #expect(details.name == "conn-2")
    #expect(details.peerHost == nil)
    #expect(details.peerPort == nil)
  }
}
