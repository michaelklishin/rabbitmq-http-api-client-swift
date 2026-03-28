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

// MARK: - Cluster Overview

public struct ClusterOverview: Sendable, Decodable {
  public let managementVersion: String?
  public let productVersion: String?
  public let productName: String?
  public let rabbitmqVersion: String?
  public let clusterName: String?
  public let clusterTags: [String: String]?
  public let nodeTags: [String: String]?
  public let erlangVersion: String?
  public let erlangFullVersion: String?
  public let node: String?
  public let listeners: [Listener]?
  public let messageStats: MessageStats?
  public let queueTotals: QueueTotals?
  public let objectTotals: ObjectTotals?
  public let churnRates: ChurnRates?

  enum CodingKeys: String, CodingKey {
    case managementVersion = "management_version"
    case productVersion = "product_version"
    case productName = "product_name"
    case rabbitmqVersion = "rabbitmq_version"
    case clusterName = "cluster_name"
    case clusterTags = "cluster_tags"
    case nodeTags = "node_tags"
    case erlangVersion = "erlang_version"
    case erlangFullVersion = "erlang_full_version"
    case node, listeners
    case messageStats = "message_stats"
    case queueTotals = "queue_totals"
    case objectTotals = "object_totals"
    case churnRates = "churn_rates"
  }
}

public struct ClusterIdentity: Sendable, Codable {
  public let name: String
  public init(name: String) { self.name = name }
}

// MARK: - Nodes

public struct ClusterNode: Sendable, Decodable {
  public let name: String
  public let type: String?
  public let running: Bool?
  public let memUsed: Int?
  public let memLimit: Int?
  public let memAlarm: Bool?
  public let diskFree: Int?
  public let diskFreeLimit: Int?
  public let diskFreeAlarm: Bool?
  public let fdUsed: Int?
  public let fdTotal: Int?
  public let socketsUsed: Int?
  public let socketsTotal: Int?
  public let processesUsed: Int?
  public let processesTotal: Int?
  public let uptime: Int?
  public let runQueue: Int?
  public let processors: Int?
  public let osProcessId: String?
  public let erlangVersion: String?
  public let enabledPlugins: [String]?

  enum CodingKeys: String, CodingKey {
    case name, type, running, uptime, processors
    case memUsed = "mem_used"
    case memLimit = "mem_limit"
    case memAlarm = "mem_alarm"
    case diskFree = "disk_free"
    case diskFreeLimit = "disk_free_limit"
    case diskFreeAlarm = "disk_free_alarm"
    case fdUsed = "fd_used"
    case fdTotal = "fd_total"
    case socketsUsed = "sockets_used"
    case socketsTotal = "sockets_total"
    case processesUsed = "proc_used"
    case processesTotal = "proc_total"
    case runQueue = "run_queue"
    case osProcessId = "os_pid"
    case erlangVersion = "erlang_version"
    case enabledPlugins = "enabled_plugins"
  }
}

public struct NodeMemoryFootprint: Sendable, Decodable {
  public let memory: NodeMemoryBreakdown?
}

public struct NodeMemoryBreakdown: Sendable, Decodable {
  public let total: MemoryValue?
  public let connectionReaders: MemoryValue?
  public let connectionWriters: MemoryValue?
  public let queueProcs: MemoryValue?
  public let plugins: MemoryValue?
  public let mnesia: MemoryValue?
  public let binary: MemoryValue?
  public let code: MemoryValue?
  public let atom: MemoryValue?

  enum CodingKeys: String, CodingKey {
    case total, plugins, mnesia, binary, code, atom
    case connectionReaders = "connection_readers"
    case connectionWriters = "connection_writers"
    case queueProcs = "queue_procs"
  }
}

public struct MemoryValue: Sendable, Decodable {
  public let bytes: Int?

  public init(from decoder: any Decoder) throws {
    if let c = try? decoder.singleValueContainer(), let v = try? c.decode(Int.self) {
      self.bytes = v
    } else {
      let c = try decoder.container(keyedBy: CodingKeys.self)
      self.bytes = try c.decodeIfPresent(Int.self, forKey: .bytes)
    }
  }

  enum CodingKeys: String, CodingKey { case bytes }
}

// MARK: - Listener

public struct Listener: Sendable, Decodable {
  public let node: String?
  public let `protocol`: String
  public let ipAddress: String?
  public let port: Int
  public let tls: Bool?

  public var supportedProtocol: SupportedProtocol {
    SupportedProtocol(from: `protocol`)
  }

  enum CodingKeys: String, CodingKey {
    case node, port, tls
    case `protocol` = "protocol"
    case ipAddress = "ip_address"
  }
}

// MARK: - Statistics

public struct MessageStats: Sendable, Decodable {
  public let publish: Int?
  public let confirm: Int?
  public let ack: Int?
  public let deliver: Int?
  public let deliverNoAck: Int?
  public let get: Int?
  public let getNoAck: Int?
  public let redeliver: Int?
  public let diskReads: Int?
  public let diskWrites: Int?

  enum CodingKeys: String, CodingKey {
    case publish, confirm, ack, deliver, get, redeliver
    case deliverNoAck = "deliver_no_ack"
    case getNoAck = "get_no_ack"
    case diskReads = "disk_reads"
    case diskWrites = "disk_writes"
  }
}

public struct QueueTotals: Sendable, Decodable {
  public let messages: Int?
  public let messagesReady: Int?
  public let messagesUnacknowledged: Int?

  enum CodingKeys: String, CodingKey {
    case messages
    case messagesReady = "messages_ready"
    case messagesUnacknowledged = "messages_unacknowledged"
  }
}

public struct ObjectTotals: Sendable, Decodable {
  public let channels: Int?
  public let connections: Int?
  public let consumers: Int?
  public let exchanges: Int?
  public let queues: Int?
}

public struct ChurnRates: Sendable, Decodable {
  public let connectionCreated: Int?
  public let connectionClosed: Int?
  public let channelCreated: Int?
  public let channelClosed: Int?
  public let queueDeclared: Int?
  public let queueCreated: Int?
  public let queueDeleted: Int?

  enum CodingKeys: String, CodingKey {
    case connectionCreated = "connection_created"
    case connectionClosed = "connection_closed"
    case channelCreated = "channel_created"
    case channelClosed = "channel_closed"
    case queueDeclared = "queue_declared"
    case queueCreated = "queue_created"
    case queueDeleted = "queue_deleted"
  }
}

// MARK: - Virtual Host

public struct VirtualHostInfo: Sendable, Decodable {
  public let name: String
  public let description: String?
  public let tags: [String]?
  public let defaultQueueType: String?
  public let tracing: Bool?
  public let metadata: VirtualHostMetadata?

  enum CodingKeys: String, CodingKey {
    case name, description, tags, tracing, metadata
    case defaultQueueType = "default_queue_type"
  }
}

public struct VirtualHostMetadata: Sendable, Decodable {
  public let description: String?
  public let tags: [String]?
  public let defaultQueueType: String?

  enum CodingKeys: String, CodingKey {
    case description, tags
    case defaultQueueType = "default_queue_type"
  }
}

public struct VirtualHostLimitsInfo: Sendable, Decodable {
  public let vhost: String
  public let value: [String: Int]
}

// MARK: - Queue

public struct QueueInfo: Sendable, Decodable {
  public let name: String
  public let vhost: String
  public let durable: Bool
  public let exclusive: Bool
  public let autoDelete: Bool
  public let type: String?
  public let state: String?
  public let node: String?
  public let messages: Int?
  public let messagesReady: Int?
  public let messagesUnacknowledged: Int?
  public let consumers: Int?
  public let memory: Int?
  public let policy: String?
  public let arguments: [String: JSONValue]?

  public var queueType: QueueType {
    QueueType(from: type ?? "classic")
  }

  enum CodingKeys: String, CodingKey {
    case name, vhost, durable, exclusive, type, state, node
    case messages, consumers, memory, policy, arguments
    case autoDelete = "auto_delete"
    case messagesReady = "messages_ready"
    case messagesUnacknowledged = "messages_unacknowledged"
  }
}

// MARK: - Exchange

public struct ExchangeInfo: Sendable, Decodable {
  public let name: String
  public let vhost: String
  public let type: String
  public let durable: Bool
  public let autoDelete: Bool
  public let `internal`: Bool?
  public let arguments: [String: JSONValue]?

  public var exchangeType: ExchangeType {
    ExchangeType(rawValue: type)
  }

  enum CodingKeys: String, CodingKey {
    case name, vhost, type, durable, arguments
    case autoDelete = "auto_delete"
    case `internal` = "internal"
  }
}

// MARK: - Binding

public struct BindingInfo: Sendable, Decodable {
  public let source: String
  public let destination: String
  public let destinationType: BindingDestinationType
  public let routingKey: String
  public let vhost: String
  public let propertiesKey: String?
  public let arguments: [String: JSONValue]?

  enum CodingKeys: String, CodingKey {
    case source, destination, vhost, arguments
    case destinationType = "destination_type"
    case routingKey = "routing_key"
    case propertiesKey = "properties_key"
  }
}

// MARK: - Connection

public struct ConnectionInfo: Sendable, Decodable {
  public let name: String
  public let node: String?
  public let state: String?
  public let type: String?
  public let channels: Int?
  public let user: String?
  public let vhost: String?
  public let peerHost: String?
  public let peerPort: Int?
  public let host: String?
  public let port: Int?
  public let `protocol`: String?
  public let ssl: Bool?
  public let connectedAt: Int?
  public let clientProperties: ClientProperties?

  public struct ClientProperties: Sendable, Decodable {
    public let connectionName: String?
    public let product: String?
    public let platform: String?
    public let version: String?

    enum CodingKeys: String, CodingKey {
      case product, platform, version
      case connectionName = "connection_name"
    }
  }

  enum CodingKeys: String, CodingKey {
    case name, node, state, type, channels, user, vhost
    case host, port, ssl
    case peerHost = "peer_host"
    case peerPort = "peer_port"
    case `protocol` = "protocol"
    case connectedAt = "connected_at"
    case clientProperties = "client_properties"
  }
}

public struct UserConnectionInfo: Sendable, Decodable {
  public let name: String
  public let user: String
  public let node: String?
  public let vhost: String?
}

// MARK: - Channel

public struct ChannelInfo: Sendable, Decodable {
  public let name: String
  public let node: String?
  public let number: Int?
  public let state: String?
  public let user: String?
  public let vhost: String?
  public let prefetchCount: Int?
  public let consumerCount: Int?
  public let messagesUnacknowledged: Int?
  public let confirm: Bool?
  public let connectionDetails: ChannelConnectionDetails?

  /// RabbitMQ returns connection_details as either a JSON object or an empty array.
  public struct ChannelConnectionDetails: Sendable, Decodable {
    public let name: String?
    public let peerHost: String?
    public let peerPort: Int?

    enum CodingKeys: String, CodingKey {
      case name
      case peerHost = "peer_host"
      case peerPort = "peer_port"
    }

    public init(from decoder: any Decoder) throws {
      if let container = try? decoder.container(keyedBy: CodingKeys.self) {
        name = try container.decodeIfPresent(String.self, forKey: .name)
        peerHost = try container.decodeIfPresent(String.self, forKey: .peerHost)
        peerPort = try container.decodeIfPresent(Int.self, forKey: .peerPort)
      } else {
        name = nil
        peerHost = nil
        peerPort = nil
      }
    }
  }

  enum CodingKeys: String, CodingKey {
    case name, node, number, state, user, vhost, confirm
    case prefetchCount = "prefetch_count"
    case consumerCount = "consumer_count"
    case messagesUnacknowledged = "messages_unacknowledged"
    case connectionDetails = "connection_details"
  }
}

// MARK: - Consumer

public struct ConsumerInfo: Sendable, Decodable {
  public let consumerTag: String
  public let exclusive: Bool
  public let ackRequired: Bool?
  public let prefetchCount: Int?
  public let active: Bool?
  public let queue: ConsumerQueueInfo
  public let channelDetails: ConsumerChannelDetails?

  public struct ConsumerQueueInfo: Sendable, Decodable {
    public let name: String
    public let vhost: String
  }

  public struct ConsumerChannelDetails: Sendable, Decodable {
    public let name: String?
    public let connectionName: String?
    public let node: String?

    enum CodingKeys: String, CodingKey {
      case name, node
      case connectionName = "connection_name"
    }
  }

  enum CodingKeys: String, CodingKey {
    case exclusive, active, queue
    case consumerTag = "consumer_tag"
    case ackRequired = "ack_required"
    case prefetchCount = "prefetch_count"
    case channelDetails = "channel_details"
  }
}

// MARK: - User

public struct UserInfo: Sendable, Decodable {
  public let name: String
  public let passwordHash: String?
  public let hashingAlgorithm: String?
  public let tags: UserTags

  enum CodingKeys: String, CodingKey {
    case name, tags
    case passwordHash = "password_hash"
    case hashingAlgorithm = "hashing_algorithm"
  }
}

public struct CurrentUserInfo: Sendable, Decodable {
  public let name: String
  public let tags: UserTags
}

/// User tags can be returned as a comma-separated string or an array, depending on server version.
public struct UserTags: Sendable, Hashable {
  public let values: [String]

  public var isAdministrator: Bool { values.contains("administrator") }
  public var isMonitoring: Bool { values.contains("monitoring") || isAdministrator }
  public var isManagement: Bool { values.contains("management") || isMonitoring }
  public var isPolicymaker: Bool { values.contains("policymaker") || isAdministrator }
}

extension UserTags: Codable {
  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    if let arr = try? container.decode([String].self) {
      values = arr
    } else if let str = try? container.decode(String.self) {
      values =
        str.isEmpty
        ? [] : str.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
    } else {
      values = []
    }
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(values)
  }
}

public struct UserLimitsInfo: Sendable, Decodable {
  public let user: String
  public let value: [String: Int]
}

// MARK: - Permission

public struct PermissionInfo: Sendable, Decodable {
  public let user: String
  public let vhost: String
  public let configure: String
  public let write: String
  public let read: String
}

public struct TopicPermissionInfo: Sendable, Decodable {
  public let user: String
  public let vhost: String
  public let exchange: String
  public let write: String
  public let read: String
}

// MARK: - Policy

public struct PolicyInfo: Sendable, Decodable {
  public let name: String
  public let vhost: String
  public let pattern: String
  public let applyTo: PolicyTarget
  public let priority: Int
  public let definition: [String: JSONValue]

  enum CodingKeys: String, CodingKey {
    case name, vhost, pattern, priority, definition
    case applyTo = "apply-to"
  }
}

// MARK: - Feature Flag

public enum FeatureFlagState: String, Sendable, Decodable {
  case enabled
  case disabled
  case stateChanging = "state_changing"
  case unavailable
}

public enum FeatureFlagStability: String, Sendable, Decodable {
  case required
  case stable
  case experimental
}

public struct FeatureFlagInfo: Sendable, Decodable {
  public let name: String
  public let state: FeatureFlagState
  public let stability: FeatureFlagStability?
  public let desc: String?
  public let docUrl: String?
  public let providedBy: String?

  enum CodingKeys: String, CodingKey {
    case name, state, stability, desc
    case docUrl = "doc_url"
    case providedBy = "provided_by"
  }
}

// MARK: - Messages

public struct MessageRouted: Sendable, Decodable {
  public let routed: Bool
}

public struct GetMessage: Sendable, Decodable {
  public let payload: String
  public let payloadEncoding: String
  public let exchange: String
  public let routingKey: String
  public let redelivered: Bool

  enum CodingKeys: String, CodingKey {
    case payload, exchange, redelivered
    case payloadEncoding = "payload_encoding"
    case routingKey = "routing_key"
  }
}

// MARK: - Deprecated Feature

public enum DeprecationPhase: String, Sendable, Decodable {
  case permittedByDefault = "permitted_by_default"
  case deniedByDefault = "denied_by_default"
  case disconnected
  case removed
}

public struct DeprecatedFeatureInfo: Sendable, Decodable {
  public let name: String
  public let description: String?
  public let deprecationPhase: DeprecationPhase?
  public let docUrl: String?
  public let providedBy: String?

  enum CodingKeys: String, CodingKey {
    case name, description
    case deprecationPhase = "deprecation_phase"
    case docUrl = "doc_url"
    case providedBy = "provided_by"
  }
}

// MARK: - Pagination

public struct PaginatedResponse<T: Sendable & Decodable>: Sendable, Decodable {
  public let page: Int
  public let pageCount: Int
  public let pageSize: Int
  public let filteredCount: Int
  public let itemCount: Int
  public let totalCount: Int
  public let items: [T]

  enum CodingKeys: String, CodingKey {
    case page, items
    case pageCount = "page_count"
    case pageSize = "page_size"
    case filteredCount = "filtered_count"
    case itemCount = "item_count"
    case totalCount = "total_count"
  }
}

// MARK: - Runtime Parameter

public struct RuntimeParameterInfo: Sendable, Decodable {
  public let name: String
  public let vhost: String
  public let component: String
  public let value: JSONValue
}

// MARK: - Global Parameter

public struct GlobalParameterInfo: Sendable, Decodable {
  public let name: String
  public let value: JSONValue
}

// MARK: - Federation

public struct FederationLinkInfo: Sendable, Decodable {
  public let node: String?
  public let queue: String?
  public let exchange: String?
  public let upstreamQueue: String?
  public let upstreamExchange: String?
  public let type: String?
  public let vhost: String?
  public let upstream: String?
  public let status: String?
  public let localConnection: String?
  public let uri: String?
  public let timestamp: String?
  public let error: String?

  enum CodingKeys: String, CodingKey {
    case node, queue, exchange, type, vhost, upstream, status, uri, timestamp, error
    case upstreamQueue = "upstream_queue"
    case upstreamExchange = "upstream_exchange"
    case localConnection = "local_connection"
  }
}

// MARK: - Shovel

public struct ShovelInfo: Sendable, Decodable {
  public let name: String?
  public let vhost: String?
  public let component: String?
  public let value: ShovelDefinition?

  public struct ShovelDefinition: Sendable, Decodable {
    public let srcUri: String?
    public let srcQueue: String?
    public let srcExchange: String?
    public let srcExchangeKey: String?
    public let destUri: String?
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
  }
}

public struct ShovelStatusInfo: Sendable, Decodable {
  public let name: String
  public let vhost: String
  public let type: String?
  public let state: String?
  public let node: String?
}

// MARK: - Stream Publishers / Consumers

public struct StreamPublisherInfo: Sendable, Decodable {
  public let publisherId: Int?
  public let publisherName: String?
  public let reference: String?
  public let stream: String?
  public let connectionDetails: StreamConnectionDetails?

  public struct StreamConnectionDetails: Sendable, Decodable {
    public let name: String?
    public let peerHost: String?
    public let peerPort: Int?

    enum CodingKeys: String, CodingKey {
      case name
      case peerHost = "peer_host"
      case peerPort = "peer_port"
    }
  }

  enum CodingKeys: String, CodingKey {
    case stream, reference
    case publisherId = "publisher_id"
    case publisherName = "publisher_name"
    case connectionDetails = "connection_details"
  }
}

public struct StreamConsumerInfo: Sendable, Decodable {
  public let subscriptionId: Int?
  public let stream: String?
  public let active: Bool?
  public let connectionDetails: StreamPublisherInfo.StreamConnectionDetails?

  enum CodingKeys: String, CodingKey {
    case stream, active
    case subscriptionId = "subscription_id"
    case connectionDetails = "connection_details"
  }
}

// MARK: - Authentication

public struct OAuthConfiguration: Sendable, Decodable {
  public let oauthEnabled: Bool
  public let oauthClientId: String?
  public let oauthProviderUrl: String?

  enum CodingKeys: String, CodingKey {
    case oauthEnabled = "oauth_enabled"
    case oauthClientId = "oauth_client_id"
    case oauthProviderUrl = "oauth_provider_url"
  }
}

public struct AuthAttemptStatistics: Sendable, Decodable {
  public let `protocol`: SupportedProtocol
  public let allAttemptCount: Int
  public let failureCount: Int

  enum CodingKeys: String, CodingKey {
    case `protocol`
    case allAttemptCount = "auth_attempts"
    case failureCount = "auth_attempts_failed"
  }
}

// MARK: - Generic JSON Value

/// A type-erased JSON value for representing arguments and definitions.
public enum JSONValue: Sendable, Hashable {
  case string(String)
  case int(Int)
  case double(Double)
  case bool(Bool)
  case null
  case array([JSONValue])
  case object([String: JSONValue])
}

extension JSONValue: Codable {
  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    if container.decodeNil() {
      self = .null
    } else if let v = try? container.decode(Bool.self) {
      self = .bool(v)
    } else if let v = try? container.decode(Int.self) {
      self = .int(v)
    } else if let v = try? container.decode(Double.self) {
      self = .double(v)
    } else if let v = try? container.decode(String.self) {
      self = .string(v)
    } else if let v = try? container.decode([JSONValue].self) {
      self = .array(v)
    } else if let v = try? container.decode([String: JSONValue].self) {
      self = .object(v)
    } else {
      self = .null
    }
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case .string(let v): try container.encode(v)
    case .int(let v): try container.encode(v)
    case .double(let v): try container.encode(v)
    case .bool(let v): try container.encode(v)
    case .null: try container.encodeNil()
    case .array(let v): try container.encode(v)
    case .object(let v): try container.encode(v)
    }
  }
}
