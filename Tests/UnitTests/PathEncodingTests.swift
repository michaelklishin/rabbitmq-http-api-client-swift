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

import Testing

@testable import RabbitMQHTTPAPIClient

@Suite struct PathEncodingTests {
  @Test func encodesSlash() {
    #expect(encodePathSegment("/") == "%2F")
  }

  @Test func encodesDefaultVhost() {
    let client = Client()
    let p = client.path("queues", "/", "my-queue")
    #expect(p == "queues/%2F/my-queue")
  }

  @Test func preservesAlphanumeric() {
    #expect(encodePathSegment("hello123") == "hello123")
  }

  @Test func preservesDashDotUnderscoreTilde() {
    #expect(encodePathSegment("-._~") == "-._~")
  }

  @Test func encodesSpaces() {
    #expect(encodePathSegment("my queue") == "my%20queue")
  }

  @Test func encodesSpecialCharacters() {
    #expect(encodePathSegment("a/b") == "a%2Fb")
    #expect(encodePathSegment("a:b") == "a%3Ab")
    #expect(encodePathSegment("a@b") == "a%40b")
  }

  @Test func encodesPercentSign() {
    #expect(encodePathSegment("100%") == "100%25")
  }

  @Test func encodesUnicode() {
    let encoded = encodePathSegment("café")
    #expect(encoded.contains("%"))
    #expect(!encoded.contains("é"))
  }
}
