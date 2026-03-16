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

@Suite struct ClientErrorTests {
  @Test func notFoundProperties() {
    let err = ClientError.notFound
    #expect(err.isNotFound)
    #expect(err.isClientError)
    #expect(!err.isServerError)
    #expect(err.statusCode == 404)
    #expect(err.errorDetails == nil)
  }

  @Test func clientErrorProperties() throws {
    let url = URL(string: "http://localhost:15672/api/test")
    let json = #"{"error":"bad_request","reason":"test reason"}"#.data(using: .utf8)!
    let details = try JSONDecoder().decode(APIErrorDetails.self, from: json)
    let err = ClientError.clientError(statusCode: 400, url: url, body: nil, details: details)
    #expect(err.isClientError)
    #expect(!err.isNotFound)
    #expect(!err.isServerError)
    #expect(err.statusCode == 400)
    #expect(err.errorDetails?.message == "test reason")
  }

  @Test func serverErrorProperties() {
    let err = ClientError.serverError(statusCode: 500, url: nil, body: "fail", details: nil)
    #expect(err.isServerError)
    #expect(!err.isClientError)
    #expect(err.statusCode == 500)
  }

  @Test func conflictDetection() {
    let err = ClientError.clientError(statusCode: 409, url: nil, body: nil, details: nil)
    #expect(err.isConflict)
    #expect(!err.isUnauthorized)
  }

  @Test func unauthorizedDetection() {
    let err = ClientError.clientError(statusCode: 401, url: nil, body: nil, details: nil)
    #expect(err.isUnauthorized)
    #expect(!err.isConflict)
  }

  @Test func healthCheckFailedDescription() {
    let err = ClientError.healthCheckFailed(
      path: "health/checks/alarms", statusCode: 503, body: nil)
    #expect(err.description.contains("Health check failed"))
    #expect(err.description.contains("503"))
  }

  @Test func apiErrorDetailsDecoding() throws {
    let json = #"{"error":"bad_request","reason":"invalid field"}"#.data(using: .utf8)!
    let details = try JSONDecoder().decode(APIErrorDetails.self, from: json)
    #expect(details.error == "bad_request")
    #expect(details.reason == "invalid field")
    #expect(details.message == "invalid field")
  }
}
