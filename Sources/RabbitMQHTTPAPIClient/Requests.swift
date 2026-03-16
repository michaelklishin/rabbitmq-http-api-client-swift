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

// MARK: - Queue Params

public struct QueueParams: Sendable, Encodable {
  public let name: String
  public let vhost: String
  public let durable: Bool
  public let exclusive: Bool
  public let autoDelete: Bool
  public let arguments: [String: JSONValue]?

  enum CodingKeys: String, CodingKey {
    case durable, exclusive, arguments
    case autoDelete = "auto_delete"
  }

  public static func classicQueue(
    _ name: String, in vhost: String, durable: Bool = true,
    arguments: [String: JSONValue]? = nil
  ) -> QueueParams {
    var args = arguments ?? [:]
    args["x-queue-type"] = .string("classic")
    return QueueParams(
      name: name, vhost: vhost, durable: durable,
      exclusive: false, autoDelete: false, arguments: args)
  }

  public static func quorumQueue(
    _ name: String, in vhost: String,
    arguments: [String: JSONValue]? = nil
  ) -> QueueParams {
    var args = arguments ?? [:]
    args["x-queue-type"] = .string("quorum")
    return QueueParams(
      name: name, vhost: vhost, durable: true,
      exclusive: false, autoDelete: false, arguments: args)
  }

  public static func stream(
    _ name: String, in vhost: String,
    arguments: [String: JSONValue]? = nil
  ) -> QueueParams {
    var args = arguments ?? [:]
    args["x-queue-type"] = .string("stream")
    return QueueParams(
      name: name, vhost: vhost, durable: true,
      exclusive: false, autoDelete: false, arguments: args)
  }
}

// MARK: - Exchange Params

public struct ExchangeParams: Sendable, Encodable {
  public let name: String
  public let vhost: String
  public let type: String
  public let durable: Bool
  public let autoDelete: Bool
  public let `internal`: Bool
  public let arguments: [String: JSONValue]?

  enum CodingKeys: String, CodingKey {
    case type, durable, arguments
    case autoDelete = "auto_delete"
    case `internal` = "internal"
  }

  public static func fanout(
    _ name: String, in vhost: String, durable: Bool = true,
    arguments: [String: JSONValue]? = nil
  ) -> ExchangeParams {
    ExchangeParams(
      name: name, vhost: vhost, type: "fanout",
      durable: durable, autoDelete: false, internal: false, arguments: arguments)
  }

  public static func topic(
    _ name: String, in vhost: String, durable: Bool = true,
    arguments: [String: JSONValue]? = nil
  ) -> ExchangeParams {
    ExchangeParams(
      name: name, vhost: vhost, type: "topic",
      durable: durable, autoDelete: false, internal: false, arguments: arguments)
  }

  public static func direct(
    _ name: String, in vhost: String, durable: Bool = true,
    arguments: [String: JSONValue]? = nil
  ) -> ExchangeParams {
    ExchangeParams(
      name: name, vhost: vhost, type: "direct",
      durable: durable, autoDelete: false, internal: false, arguments: arguments)
  }

  public static func headers(
    _ name: String, in vhost: String, durable: Bool = true,
    arguments: [String: JSONValue]? = nil
  ) -> ExchangeParams {
    ExchangeParams(
      name: name, vhost: vhost, type: "headers",
      durable: durable, autoDelete: false, internal: false, arguments: arguments)
  }
}

// MARK: - Virtual Host Params

public struct VirtualHostParams: Sendable, Encodable {
  public let name: String
  public let description: String?
  public let tags: [String]?
  public let defaultQueueType: String?

  enum CodingKeys: String, CodingKey {
    case description, tags
    case defaultQueueType = "default_queue_type"
  }

  public init(
    name: String, description: String? = nil,
    tags: [String]? = nil, defaultQueueType: String? = nil
  ) {
    self.name = name
    self.description = description
    self.tags = tags
    self.defaultQueueType = defaultQueueType
  }
}

// MARK: - User Params

public struct UserParams: Sendable, Encodable {
  public let name: String
  public let password: String?
  public let passwordHash: String?
  public let hashingAlgorithm: String?
  public let tags: [String]

  enum CodingKeys: String, CodingKey {
    case password, tags
    case passwordHash = "password_hash"
    case hashingAlgorithm = "hashing_algorithm"
  }

  public static func withPassword(
    _ name: String, password: String, tags: [String] = []
  ) -> UserParams {
    UserParams(
      name: name, password: password, passwordHash: nil,
      hashingAlgorithm: nil, tags: tags)
  }

  public static func withPasswordHash(
    _ name: String, hash: String, algorithm: String = "rabbit_password_hashing_sha256",
    tags: [String] = []
  ) -> UserParams {
    UserParams(
      name: name, password: nil, passwordHash: hash,
      hashingAlgorithm: algorithm, tags: tags)
  }
}

// MARK: - Permission Params

public struct PermissionParams: Sendable, Encodable {
  public let user: String
  public let vhost: String
  public let configure: String
  public let write: String
  public let read: String

  enum CodingKeys: String, CodingKey {
    case configure, write, read
  }

  public init(
    user: String, vhost: String,
    configure: String = ".*", write: String = ".*", read: String = ".*"
  ) {
    self.user = user
    self.vhost = vhost
    self.configure = configure
    self.write = write
    self.read = read
  }
}

// MARK: - Topic Permission Params

public struct TopicPermissionParams: Sendable, Encodable {
  public let user: String
  public let vhost: String
  public let exchange: String
  public let write: String
  public let read: String

  enum CodingKeys: String, CodingKey {
    case exchange, write, read
  }

  public init(
    user: String, vhost: String, exchange: String,
    write: String = ".*", read: String = ".*"
  ) {
    self.user = user
    self.vhost = vhost
    self.exchange = exchange
    self.write = write
    self.read = read
  }
}

// MARK: - Policy Params

public struct PolicyParams: Sendable, Encodable {
  public let name: String
  public let vhost: String
  public let pattern: String
  public let applyTo: PolicyTarget
  public let priority: Int
  public let definition: [String: JSONValue]

  enum CodingKeys: String, CodingKey {
    case pattern, priority, definition
    case applyTo = "apply-to"
  }

  public init(
    name: String, vhost: String, pattern: String,
    applyTo: PolicyTarget = .queues, priority: Int = 0,
    definition: [String: JSONValue] = [:]
  ) {
    self.name = name
    self.vhost = vhost
    self.pattern = pattern
    self.applyTo = applyTo
    self.priority = priority
    self.definition = definition
  }
}

// MARK: - Binding Body

struct BindingBody: Sendable, Encodable {
  let routingKey: String?
  let arguments: [String: JSONValue]?

  enum CodingKeys: String, CodingKey {
    case routingKey = "routing_key"
    case arguments
  }
}

// MARK: - Runtime Parameter Params

public struct RuntimeParameterParams: Sendable, Encodable {
  public let name: String
  public let vhost: String
  public let component: String
  public let value: JSONValue

  public init(
    name: String, vhost: String, component: String, value: JSONValue
  ) {
    self.name = name
    self.vhost = vhost
    self.component = component
    self.value = value
  }
}

// MARK: - Global Parameter Params

public struct GlobalParameterParams: Sendable, Encodable {
  public let name: String
  public let value: JSONValue

  public init(name: String, value: JSONValue) {
    self.name = name
    self.value = value
  }
}

// MARK: - Shovel Params

public enum ShovelAcknowledgementMode: String, Sendable, Encodable {
  case onConfirm = "on-confirm"
  case onPublish = "on-publish"
  case noAck = "no-ack"
}

public struct ShovelParams: Sendable, Encodable {
  public let name: String
  public let vhost: String
  public let value: ShovelValue

  public struct ShovelValue: Sendable, Encodable {
    public let srcUri: String
    public let srcQueue: String?
    public let srcExchange: String?
    public let srcExchangeKey: String?
    public let destUri: String
    public let destQueue: String?
    public let destExchange: String?
    public let destExchangeKey: String?
    public let reconnectDelay: Int?
    public let ackMode: String?
    public let srcPrefetchCount: Int?
    public let srcDeleteAfter: String?
    public let srcProtocol: String?
    public let destProtocol: String?

    enum CodingKeys: String, CodingKey {
      case srcUri = "src-uri"
      case srcQueue = "src-queue"
      case srcExchange = "src-exchange"
      case srcExchangeKey = "src-exchange-key"
      case destUri = "dest-uri"
      case destQueue = "dest-queue"
      case destExchange = "dest-exchange"
      case destExchangeKey = "dest-exchange-key"
      case reconnectDelay = "reconnect-delay"
      case ackMode = "ack-mode"
      case srcPrefetchCount = "src-prefetch-count"
      case srcDeleteAfter = "src-delete-after"
      case srcProtocol = "src-protocol"
      case destProtocol = "dest-protocol"
    }

    public init(
      srcUri: String, srcQueue: String? = nil, srcExchange: String? = nil,
      srcExchangeKey: String? = nil, destUri: String,
      destQueue: String? = nil, destExchange: String? = nil,
      destExchangeKey: String? = nil, reconnectDelay: Int? = nil,
      ackMode: String? = nil, srcPrefetchCount: Int? = nil,
      srcDeleteAfter: String? = nil,
      srcProtocol: String? = nil, destProtocol: String? = nil
    ) {
      self.srcUri = srcUri
      self.srcQueue = srcQueue
      self.srcExchange = srcExchange
      self.srcExchangeKey = srcExchangeKey
      self.destUri = destUri
      self.destQueue = destQueue
      self.destExchange = destExchange
      self.destExchangeKey = destExchangeKey
      self.reconnectDelay = reconnectDelay
      self.ackMode = ackMode
      self.srcPrefetchCount = srcPrefetchCount
      self.srcDeleteAfter = srcDeleteAfter
      self.srcProtocol = srcProtocol
      self.destProtocol = destProtocol
    }
  }

  enum CodingKeys: String, CodingKey {
    case value
  }

  public init(name: String, vhost: String, value: ShovelValue) {
    self.name = name
    self.vhost = vhost
    self.value = value
  }

  /// Creates an AMQP 0-9-1 queue-to-queue shovel.
  public static func amqp091QueueShovel(
    _ name: String, in vhost: String,
    srcUri: String, srcQueue: String,
    destUri: String, destQueue: String,
    ackMode: ShovelAcknowledgementMode = .onConfirm,
    reconnectDelay: Int? = nil, prefetchCount: Int? = nil,
    deleteAfter: String? = nil
  ) -> ShovelParams {
    ShovelParams(
      name: name, vhost: vhost,
      value: .init(
        srcUri: srcUri, srcQueue: srcQueue,
        destUri: destUri, destQueue: destQueue,
        reconnectDelay: reconnectDelay, ackMode: ackMode.rawValue,
        srcPrefetchCount: prefetchCount, srcDeleteAfter: deleteAfter,
        srcProtocol: "amqp091", destProtocol: "amqp091"))
  }

  /// Creates an AMQP 0-9-1 exchange-to-exchange shovel.
  public static func amqp091ExchangeShovel(
    _ name: String, in vhost: String,
    srcUri: String, srcExchange: String, srcExchangeKey: String? = nil,
    destUri: String, destExchange: String, destExchangeKey: String? = nil,
    ackMode: ShovelAcknowledgementMode = .onConfirm,
    reconnectDelay: Int? = nil, prefetchCount: Int? = nil
  ) -> ShovelParams {
    ShovelParams(
      name: name, vhost: vhost,
      value: .init(
        srcUri: srcUri, srcExchange: srcExchange,
        srcExchangeKey: srcExchangeKey,
        destUri: destUri, destExchange: destExchange,
        destExchangeKey: destExchangeKey,
        reconnectDelay: reconnectDelay, ackMode: ackMode.rawValue,
        srcPrefetchCount: prefetchCount,
        srcProtocol: "amqp091", destProtocol: "amqp091"))
  }

  /// Creates an AMQP 1.0 shovel using source/destination addresses.
  public static func amqp10Shovel(
    _ name: String, in vhost: String,
    srcUri: String, srcAddress: String,
    destUri: String, destAddress: String,
    ackMode: ShovelAcknowledgementMode = .onConfirm,
    reconnectDelay: Int? = nil, prefetchCount: Int? = nil
  ) -> ShovelParams {
    ShovelParams(
      name: name, vhost: vhost,
      value: .init(
        srcUri: srcUri, srcQueue: srcAddress,
        destUri: destUri, destQueue: destAddress,
        reconnectDelay: reconnectDelay, ackMode: ackMode.rawValue,
        srcPrefetchCount: prefetchCount,
        srcProtocol: "amqp10", destProtocol: "amqp10"))
  }
}

// MARK: - Federation Upstream Params

public struct FederationUpstreamParams: Sendable, Encodable {
  public let name: String
  public let vhost: String
  public let value: FederationUpstreamValue

  public struct FederationUpstreamValue: Sendable, Encodable {
    public let uri: String
    public let prefetchCount: Int?
    public let reconnectDelay: Int?
    public let ackMode: String?
    public let exchange: String?
    public let queue: String?
    public let expires: Int?
    public let messageTTL: Int?
    public let maxHops: Int?
    public let trustUserId: Bool?

    enum CodingKeys: String, CodingKey {
      case uri, exchange, queue, expires
      case prefetchCount = "prefetch-count"
      case reconnectDelay = "reconnect-delay"
      case ackMode = "ack-mode"
      case messageTTL = "message-ttl"
      case maxHops = "max-hops"
      case trustUserId = "trust-user-id"
    }

    public init(
      uri: String, prefetchCount: Int? = nil, reconnectDelay: Int? = nil,
      ackMode: String? = nil, exchange: String? = nil, queue: String? = nil,
      expires: Int? = nil, messageTTL: Int? = nil, maxHops: Int? = nil,
      trustUserId: Bool? = nil
    ) {
      self.uri = uri
      self.prefetchCount = prefetchCount
      self.reconnectDelay = reconnectDelay
      self.ackMode = ackMode
      self.exchange = exchange
      self.queue = queue
      self.expires = expires
      self.messageTTL = messageTTL
      self.maxHops = maxHops
      self.trustUserId = trustUserId
    }
  }

  enum CodingKeys: String, CodingKey {
    case value
  }

  public init(name: String, vhost: String, value: FederationUpstreamValue) {
    self.name = name
    self.vhost = vhost
    self.value = value
  }
}

// MARK: - Pagination Params

public struct PaginationParams: Sendable {
  public let page: Int
  public let pageSize: Int

  public init(page: Int = 1, pageSize: Int = 100) {
    self.page = page
    self.pageSize = min(pageSize, 500)
  }

  var queryString: String {
    "page=\(page)&page_size=\(pageSize)"
  }
}
