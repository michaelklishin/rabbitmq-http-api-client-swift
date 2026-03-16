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

public struct APIErrorDetails: Sendable, Equatable, Decodable {
  public let error: String?
  public let reason: String?

  public var message: String? {
    reason ?? error
  }
}

public enum ClientError: Error, Sendable {
  case clientError(statusCode: Int, url: URL?, body: String?, details: APIErrorDetails?)
  case serverError(statusCode: Int, url: URL?, body: String?, details: APIErrorDetails?)
  case notFound
  case healthCheckFailed(path: String, statusCode: Int, body: String?)
  case multipleMatchingBindings
  case requestFailed(underlying: any Error & Sendable)
  case decodingFailed(underlying: any Error & Sendable, body: String?)
  case invalidEndpoint(String)

  public var isNotFound: Bool {
    switch self {
    case .notFound: true
    case .clientError(let code, _, _, _): code == 404
    default: false
    }
  }

  public var isConflict: Bool {
    if case .clientError(let code, _, _, _) = self { return code == 409 }
    return false
  }

  public var isUnauthorized: Bool {
    if case .clientError(let code, _, _, _) = self { return code == 401 }
    return false
  }

  public var isClientError: Bool {
    switch self {
    case .clientError, .notFound: true
    default: false
    }
  }

  public var isServerError: Bool {
    if case .serverError = self { return true }
    return false
  }

  public var statusCode: Int? {
    switch self {
    case .clientError(let code, _, _, _): code
    case .serverError(let code, _, _, _): code
    case .healthCheckFailed(_, let code, _): code
    case .notFound: 404
    default: nil
    }
  }

  public var errorDetails: APIErrorDetails? {
    switch self {
    case .clientError(_, _, _, let d): d
    case .serverError(_, _, _, let d): d
    default: nil
    }
  }
}

extension ClientError: CustomStringConvertible {
  public var description: String {
    switch self {
    case .clientError(let code, let url, _, let details):
      if let msg = details?.message {
        return "Client error \(code) at \(url?.absoluteString ?? "?"): \(msg)"
      }
      return "Client error \(code) at \(url?.absoluteString ?? "?")"
    case .serverError(let code, let url, _, let details):
      if let msg = details?.message {
        return "Server error \(code) at \(url?.absoluteString ?? "?"): \(msg)"
      }
      return "Server error \(code) at \(url?.absoluteString ?? "?")"
    case .notFound:
      return "Not found (404)"
    case .healthCheckFailed(let path, let code, _):
      return "Health check failed at \(path) with status \(code)"
    case .multipleMatchingBindings:
      return "Multiple matching bindings found"
    case .requestFailed(let e):
      return "Request failed: \(e)"
    case .decodingFailed(let e, _):
      return "Decoding failed: \(e)"
    case .invalidEndpoint(let e):
      return "Invalid endpoint: \(e)"
    }
  }
}
