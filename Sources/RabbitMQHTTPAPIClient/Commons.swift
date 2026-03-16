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

// MARK: - Exchange Type

public enum ExchangeType: String, Sendable, Codable, Hashable {
  case fanout
  case topic
  case direct
  case headers
  case consistentHashing = "x-consistent-hash"
  case modulusHash = "x-modulus-hash"
  case random = "x-random"
  case localRandom = "x-local-random"
  case jmsTopic = "x-jms-topic"
  case recentHistory = "x-recent-history"
  case delayedMessage = "x-delayed-message"
  case messageDeduplication = "x-message-deduplication"
}

// MARK: - Queue Type

public enum QueueType: String, Sendable, Codable, Hashable {
  case classic
  case quorum
  case stream

  public init(from string: String) {
    switch string.lowercased() {
    case "classic": self = .classic
    case "quorum": self = .quorum
    case "stream": self = .stream
    default: self = .classic
    }
  }
}

// MARK: - Binding Destination Type

public enum BindingDestinationType: String, Sendable, Codable, Hashable {
  case queue
  case exchange
}

// MARK: - Policy Target

public enum PolicyTarget: String, Sendable, Codable, Hashable {
  case queues
  case classicQueues = "classic_queues"
  case quorumQueues = "quorum_queues"
  case streams
  case exchanges
  case all
}

// MARK: - Supported Protocol

public enum SupportedProtocol: Sendable, Hashable {
  case clustering
  case amqp
  case amqpTLS
  case stream
  case streamTLS
  case mqtt
  case mqttTLS
  case stomp
  case stompTLS
  case http
  case httpTLS
  case prometheus
  case prometheusTLS
  case other(String)

  public var stringValue: String {
    switch self {
    case .clustering: "clustering"
    case .amqp: "amqp"
    case .amqpTLS: "amqp/ssl"
    case .stream: "stream"
    case .streamTLS: "stream/ssl"
    case .mqtt: "mqtt"
    case .mqttTLS: "mqtt/ssl"
    case .stomp: "stomp"
    case .stompTLS: "stomp/ssl"
    case .http: "http"
    case .httpTLS: "https"
    case .prometheus: "http/prometheus"
    case .prometheusTLS: "https/prometheus"
    case .other(let s): s
    }
  }

  public init(from string: String) {
    switch string {
    case "clustering": self = .clustering
    case "amqp", "amqp091", "amqp10": self = .amqp
    case "amqp/ssl": self = .amqpTLS
    case "stream": self = .stream
    case "stream/ssl": self = .streamTLS
    case "mqtt": self = .mqtt
    case "mqtt/ssl": self = .mqttTLS
    case "stomp": self = .stomp
    case "stomp/ssl": self = .stompTLS
    case "http": self = .http
    case "https": self = .httpTLS
    case "http/prometheus": self = .prometheus
    case "https/prometheus": self = .prometheusTLS
    default: self = .other(string)
    }
  }
}

extension SupportedProtocol: Codable {
  public init(from decoder: any Decoder) throws {
    let raw = try decoder.singleValueContainer().decode(String.self)
    self.init(from: raw)
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(stringValue)
  }
}

// MARK: - Limit Targets

public enum VirtualHostLimitTarget: String, Sendable, Codable {
  case maxConnections = "max-connections"
  case maxQueues = "max-queues"
}

public enum UserLimitTarget: String, Sendable, Codable {
  case maxConnections = "max-connections"
  case maxChannels = "max-channels"
}

// MARK: - Retry Settings

public struct RetrySettings: Sendable {
  public var maxAttempts: Int
  public var delayMs: UInt64

  public init(maxAttempts: Int = 0, delayMs: UInt64 = 1000) {
    self.maxAttempts = maxAttempts
    self.delayMs = delayMs
  }
}
