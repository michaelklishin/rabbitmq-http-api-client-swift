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

let endpoint =
  ProcessInfo.processInfo.environment["RABBITMQ_HTTP_API_ENDPOINT"]
  ?? "http://127.0.0.1:15672/api"
let testUsername = "guest"
let testPassword = "guest"
let testVhost = "/"

func newClient() -> Client {
  Client(
    endpoint: endpoint,
    username: testUsername,
    password: testPassword,
    retrySettings: RetrySettings(maxAttempts: 2, delayMs: 500)
  )
}

/// Stats in RabbitMQ are emitted asynchronously.
/// For tests, we often need to wait until a resource appears in the listing.
func awaitMetricEmission(ms: UInt64 = 1500) async throws {
  try await Task.sleep(nanoseconds: ms * 1_000_000)
}

/// Creates a dedicated virtual host for test isolation.
/// Deleting the vhost cleans up all queues, exchanges, bindings, policies inside it.
func withTestVhost(
  _ prefix: String,
  _ body: @Sendable (_ vh: String) async throws -> Void
) async throws {
  let client = newClient()
  let vh = "swift.tests.\(prefix).\(UUID().uuidString.prefix(8))"
  try? await client.deleteVirtualHost(vh, idempotently: true)
  try await client.createVirtualHost(VirtualHostParams(name: vh))
  try await client.grantPermissions(PermissionParams(user: testUsername, vhost: vh))
  do {
    try await body(vh)
  } catch {
    try? await client.deleteVirtualHost(vh, idempotently: true)
    throw error
  }
  try await client.deleteVirtualHost(vh, idempotently: true)
}

/// Polls until a condition is met or timeout expires.
/// Errors in the condition are treated as "not yet" and retried.
func pollUntil(
  timeout: TimeInterval = 10, interval: TimeInterval = 0.5,
  _ condition: @Sendable () async throws -> Bool
) async throws -> Bool {
  let deadline = Date().addingTimeInterval(timeout)
  while Date() < deadline {
    do {
      if try await condition() { return true }
    } catch {
    }
    try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
  }
  return false
}
