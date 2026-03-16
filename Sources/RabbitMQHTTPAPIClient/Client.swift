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

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

/// An async client for the RabbitMQ HTTP API.
///
/// ```swift
/// let client = Client(endpoint: "http://localhost:15672/api", username: "guest", password: "guest")
/// let nodes = try await client.listNodes()
/// let queues = try await client.listQueues(in: "/")
/// let info = try await client.getQueueInfo("my-queue", in: "/")
/// ```
public struct Client: Sendable {
  public static let version = "0.7.0"

  let endpoint: String
  let username: String
  let password: String
  let session: URLSession
  let retrySettings: RetrySettings
  let decoder: JSONDecoder
  let encoder: JSONEncoder
  let authHeader: String

  public init(
    endpoint: String = "http://localhost:15672/api",
    username: String = "guest",
    password: String = "guest",
    session: URLSession? = nil,
    retrySettings: RetrySettings = RetrySettings()
  ) {
    self.endpoint = endpoint.hasSuffix("/") ? String(endpoint.dropLast()) : endpoint
    self.username = username
    self.password = password
    self.session = session ?? .shared
    self.retrySettings = retrySettings
    self.decoder = JSONDecoder()
    self.encoder = JSONEncoder()
    self.authHeader = "Basic \(Data("\(username):\(password)".utf8).base64EncodedString())"
  }

  // MARK: - Overview

  /// Returns cluster overview information: node name, version, statistics, listeners.
  public func overview() async throws -> ClusterOverview {
    try await get("overview")
  }

  /// Returns the RabbitMQ version of the API endpoint.
  public func serverVersion() async throws -> String {
    let ov: ClusterOverview = try await get("overview")
    return ov.rabbitmqVersion ?? ov.productVersion ?? "unknown"
  }

  // MARK: - Nodes

  /// Lists all cluster nodes.
  public func listNodes() async throws -> [ClusterNode] {
    try await get("nodes")
  }

  /// Returns information about a specific cluster node.
  public func getNodeInfo(_ name: String) async throws -> ClusterNode {
    try await get(path("nodes", name))
  }

  /// Returns memory usage breakdown for a cluster node.
  public func getNodeMemoryFootprint(_ name: String) async throws -> NodeMemoryFootprint {
    try await get(path("nodes", name, "memory"))
  }

  // MARK: - Virtual Hosts

  /// Lists all virtual hosts.
  public func listVirtualHosts() async throws -> [VirtualHostInfo] {
    try await get("vhosts")
  }

  /// Returns information about a virtual host.
  public func getVirtualHost(_ name: String) async throws -> VirtualHostInfo {
    try await get(path("vhosts", name))
  }

  /// Creates a virtual host or updates its metadata.
  public func createVirtualHost(_ params: VirtualHostParams) async throws {
    try await put(path("vhosts", params.name), body: params)
  }

  /// Deletes a virtual host and all its contents.
  public func deleteVirtualHost(_ name: String, idempotently: Bool = false) async throws {
    try await delete(path("vhosts", name), idempotent: idempotently)
  }

  /// Enables deletion protection for a virtual host (RabbitMQ 4.1+).
  public func enableVirtualHostDeletionProtection(_ name: String) async throws {
    try await postEmpty(path("vhosts", name, "deletion", "protection"))
  }

  /// Disables deletion protection for a virtual host (RabbitMQ 4.1+).
  public func disableVirtualHostDeletionProtection(_ name: String) async throws {
    try await delete(path("vhosts", name, "deletion", "protection"), idempotent: false)
  }

  // MARK: - Queues

  /// Lists all queues and streams across the cluster.
  public func listQueues() async throws -> [QueueInfo] {
    try await get("queues")
  }

  /// Lists all queues and streams in a virtual host.
  public func listQueues(in vhost: String) async throws -> [QueueInfo] {
    try await get(path("queues", vhost))
  }

  /// Returns information about a queue or stream.
  public func getQueueInfo(_ name: String, in vhost: String) async throws -> QueueInfo {
    try await get(path("queues", vhost, name))
  }

  /// Declares a queue.
  public func declareQueue(_ params: QueueParams) async throws {
    try await put(path("queues", params.vhost, params.name), body: params)
  }

  /// Deletes a queue.
  public func deleteQueue(_ name: String, in vhost: String, idempotently: Bool = false)
    async throws
  {
    try await delete(path("queues", vhost, name), idempotent: idempotently)
  }

  /// Purges a queue (removes all ready messages).
  public func purgeQueue(_ name: String, in vhost: String) async throws {
    try await delete(path("queues", vhost, name, "contents"), idempotent: false)
  }

  /// Lists only classic queues across the cluster.
  public func listClassicQueues() async throws -> [QueueInfo] {
    try await listQueues().filter { $0.queueType == .classic }
  }

  /// Lists only classic queues in a virtual host.
  public func listClassicQueues(in vhost: String) async throws -> [QueueInfo] {
    try await listQueues(in: vhost).filter { $0.queueType == .classic }
  }

  /// Lists only quorum queues across the cluster.
  public func listQuorumQueues() async throws -> [QueueInfo] {
    try await listQueues().filter { $0.queueType == .quorum }
  }

  /// Lists only quorum queues in a virtual host.
  public func listQuorumQueues(in vhost: String) async throws -> [QueueInfo] {
    try await listQueues(in: vhost).filter { $0.queueType == .quorum }
  }

  /// Lists only streams across the cluster.
  public func listStreams() async throws -> [QueueInfo] {
    try await listQueues().filter { $0.queueType == .stream }
  }

  /// Lists only streams in a virtual host.
  public func listStreams(in vhost: String) async throws -> [QueueInfo] {
    try await listQueues(in: vhost).filter { $0.queueType == .stream }
  }

  // MARK: - Exchanges

  /// Lists all exchanges across the cluster.
  public func listExchanges() async throws -> [ExchangeInfo] {
    try await get("exchanges")
  }

  /// Lists all exchanges in a virtual host.
  public func listExchanges(in vhost: String) async throws -> [ExchangeInfo] {
    try await get(path("exchanges", vhost))
  }

  /// Returns information about an exchange.
  public func getExchangeInfo(_ name: String, in vhost: String) async throws -> ExchangeInfo {
    try await get(path("exchanges", vhost, name))
  }

  /// Declares an exchange.
  public func declareExchange(_ params: ExchangeParams) async throws {
    try await put(path("exchanges", params.vhost, params.name), body: params)
  }

  /// Deletes an exchange.
  public func deleteExchange(_ name: String, in vhost: String, idempotently: Bool = false)
    async throws
  {
    try await delete(path("exchanges", vhost, name), idempotent: idempotently)
  }

  // MARK: - Bindings

  /// Lists all bindings across the cluster.
  public func listBindings() async throws -> [BindingInfo] {
    try await get("bindings")
  }

  /// Lists all bindings in a virtual host.
  public func listBindings(in vhost: String) async throws -> [BindingInfo] {
    try await get(path("bindings", vhost))
  }

  /// Lists all bindings of a queue.
  public func listQueueBindings(_ queue: String, in vhost: String) async throws -> [BindingInfo] {
    try await get(path("queues", vhost, queue, "bindings"))
  }

  /// Lists bindings where the exchange is the source.
  public func listExchangeBindingsAsSource(_ exchange: String, in vhost: String) async throws
    -> [BindingInfo]
  {
    try await get(path("exchanges", vhost, exchange, "bindings", "source"))
  }

  /// Lists bindings where the exchange is the destination.
  public func listExchangeBindingsAsDestination(_ exchange: String, in vhost: String) async throws
    -> [BindingInfo]
  {
    try await get(path("exchanges", vhost, exchange, "bindings", "destination"))
  }

  /// Binds a queue to an exchange.
  public func bindQueue(
    _ queue: String, to exchange: String, in vhost: String,
    routingKey: String? = nil, arguments: [String: JSONValue]? = nil
  ) async throws {
    let body = BindingBody(routingKey: routingKey, arguments: arguments)
    try await post(path("bindings", vhost, "e", exchange, "q", queue), body: body)
  }

  /// Binds an exchange to another exchange.
  public func bindExchange(
    _ destination: String, to source: String, in vhost: String,
    routingKey: String? = nil, arguments: [String: JSONValue]? = nil
  ) async throws {
    let body = BindingBody(routingKey: routingKey, arguments: arguments)
    try await post(path("bindings", vhost, "e", source, "e", destination), body: body)
  }

  /// Deletes a queue binding.
  public func deleteQueueBinding(
    _ queue: String, from exchange: String, in vhost: String,
    propertiesKey: String, idempotently: Bool = false
  ) async throws {
    try await delete(
      path("bindings", vhost, "e", exchange, "q", queue, propertiesKey),
      idempotent: idempotently)
  }

  /// Lists bindings between a specific exchange and queue.
  public func listQueueBindingsBetween(
    _ queue: String, and exchange: String, in vhost: String
  ) async throws -> [BindingInfo] {
    try await get(path("bindings", vhost, "e", exchange, "q", queue))
  }

  /// Lists bindings between two exchanges.
  public func listExchangeBindingsBetween(
    source: String, destination: String, in vhost: String
  ) async throws -> [BindingInfo] {
    try await get(path("bindings", vhost, "e", source, "e", destination))
  }

  /// Deletes an exchange-to-exchange binding.
  public func deleteExchangeBinding(
    _ destination: String, from source: String, in vhost: String,
    propertiesKey: String, idempotently: Bool = false
  ) async throws {
    try await delete(
      path("bindings", vhost, "e", source, "e", destination, propertiesKey),
      idempotent: idempotently)
  }

  // MARK: - Connections

  /// Lists all connections across the cluster.
  public func listConnections() async throws -> [ConnectionInfo] {
    try await get("connections")
  }

  /// Lists connections in a virtual host.
  public func listConnections(in vhost: String) async throws -> [ConnectionInfo] {
    try await get(path("vhosts", vhost, "connections"))
  }

  /// Returns information about a connection.
  public func getConnectionInfo(_ name: String) async throws -> ConnectionInfo {
    try await get(path("connections", name))
  }

  /// Closes a connection.
  public func closeConnection(
    _ name: String, reason: String? = nil, idempotently: Bool = false
  ) async throws {
    var headers: [String: String] = [:]
    if let r = reason { headers["X-Reason"] = r }
    try await delete(path("connections", name), idempotent: idempotently, headers: headers)
  }

  /// Lists connections of a specific user.
  public func listUserConnections(_ username: String) async throws -> [UserConnectionInfo] {
    try await get(path("connections", "username", username))
  }

  /// Closes all connections of a specific user.
  public func closeUserConnections(
    _ username: String, reason: String? = nil, idempotently: Bool = false
  ) async throws {
    var headers: [String: String] = [:]
    if let r = reason { headers["X-Reason"] = r }
    try await delete(
      path("connections", "username", username),
      idempotent: idempotently, headers: headers)
  }

  /// Lists all stream connections.
  public func listStreamConnections() async throws -> [ConnectionInfo] {
    try await get("stream/connections")
  }

  /// Lists stream connections in a virtual host.
  public func listStreamConnections(in vhost: String) async throws -> [ConnectionInfo] {
    try await get(path("stream", "connections", vhost))
  }

  // MARK: - Channels

  /// Lists all channels across the cluster.
  public func listChannels() async throws -> [ChannelInfo] {
    try await get("channels")
  }

  /// Lists channels in a virtual host.
  public func listChannels(in vhost: String) async throws -> [ChannelInfo] {
    try await get(path("vhosts", vhost, "channels"))
  }

  /// Returns information about a channel.
  public func getChannelInfo(_ name: String) async throws -> ChannelInfo {
    try await get(path("channels", name))
  }

  /// Lists channels on a specific connection.
  public func listChannels(on connection: String) async throws -> [ChannelInfo] {
    try await get(path("connections", connection, "channels"))
  }

  // MARK: - Consumers

  /// Lists all consumers across the cluster.
  public func listConsumers() async throws -> [ConsumerInfo] {
    try await get("consumers")
  }

  /// Lists consumers in a virtual host.
  public func listConsumers(in vhost: String) async throws -> [ConsumerInfo] {
    try await get(path("consumers", vhost))
  }

  // MARK: - Users

  /// Lists all users in the internal database.
  public func listUsers() async throws -> [UserInfo] {
    try await get("users")
  }

  /// Returns information about a user.
  public func getUser(_ name: String) async throws -> UserInfo {
    try await get(path("users", name))
  }

  /// Returns information about the authenticated user.
  public func whoami() async throws -> CurrentUserInfo {
    try await get("whoami")
  }

  /// Creates or updates a user.
  public func createUser(_ params: UserParams) async throws {
    try await put(path("users", params.name), body: params)
  }

  /// Deletes a user.
  public func deleteUser(_ name: String, idempotently: Bool = false) async throws {
    try await delete(path("users", name), idempotent: idempotently)
  }

  /// Deletes multiple users in bulk.
  public func deleteUsers(_ names: [String]) async throws {
    struct BulkDelete: Encodable {
      let users: [String]
    }
    try await post(path("users", "bulk-delete"), body: BulkDelete(users: names))
  }

  /// Lists users that have no permissions in any virtual host.
  public func listUsersWithoutPermissions() async throws -> [UserInfo] {
    try await get("users/without-permissions")
  }

  // MARK: - Permissions

  /// Lists all permissions in the cluster.
  public func listPermissions() async throws -> [PermissionInfo] {
    try await get("permissions")
  }

  /// Lists permissions in a virtual host.
  public func listPermissions(in vhost: String) async throws -> [PermissionInfo] {
    try await get(path("vhosts", vhost, "permissions"))
  }

  /// Lists permissions of a specific user.
  public func listPermissions(of user: String) async throws -> [PermissionInfo] {
    try await get(path("users", user, "permissions"))
  }

  /// Gets permissions for a user in a virtual host.
  public func getPermissions(of user: String, in vhost: String) async throws -> PermissionInfo {
    try await get(path("permissions", vhost, user))
  }

  /// Grants permissions to a user in a virtual host.
  public func grantPermissions(_ params: PermissionParams) async throws {
    try await put(path("permissions", params.vhost, params.user), body: params)
  }

  /// Revokes permissions for a user in a virtual host.
  public func clearPermissions(
    of user: String, in vhost: String, idempotently: Bool = false
  ) async throws {
    try await delete(path("permissions", vhost, user), idempotent: idempotently)
  }

  // MARK: - Topic Permissions

  /// Lists all topic permissions across the cluster.
  public func listTopicPermissions() async throws -> [TopicPermissionInfo] {
    try await get("topic-permissions")
  }

  /// Lists topic permissions in a virtual host.
  public func listTopicPermissions(in vhost: String) async throws -> [TopicPermissionInfo] {
    try await get(path("vhosts", vhost, "topic-permissions"))
  }

  /// Lists topic permissions of a specific user.
  public func listTopicPermissions(of user: String) async throws -> [TopicPermissionInfo] {
    try await get(path("users", user, "topic-permissions"))
  }

  /// Gets topic permissions for a user in a virtual host.
  public func getTopicPermissions(
    of user: String, in vhost: String
  ) async throws -> [TopicPermissionInfo] {
    try await get(path("topic-permissions", vhost, user))
  }

  /// Grants topic permissions to a user.
  public func grantTopicPermissions(_ params: TopicPermissionParams) async throws {
    try await put(path("topic-permissions", params.vhost, params.user), body: params)
  }

  /// Revokes topic permissions for a user in a virtual host.
  public func clearTopicPermissions(
    of user: String, in vhost: String, idempotently: Bool = false
  ) async throws {
    try await delete(path("topic-permissions", vhost, user), idempotent: idempotently)
  }

  // MARK: - Policies

  /// Lists all policies in the cluster.
  public func listPolicies() async throws -> [PolicyInfo] {
    try await get("policies")
  }

  /// Lists policies in a virtual host.
  public func listPolicies(in vhost: String) async throws -> [PolicyInfo] {
    try await get(path("policies", vhost))
  }

  /// Gets a specific policy.
  public func getPolicy(_ name: String, in vhost: String) async throws -> PolicyInfo {
    try await get(path("policies", vhost, name))
  }

  /// Declares a policy.
  public func declarePolicy(_ params: PolicyParams) async throws {
    try await put(path("policies", params.vhost, params.name), body: params)
  }

  /// Deletes a policy.
  public func deletePolicy(
    _ name: String, in vhost: String, idempotently: Bool = false
  ) async throws {
    try await delete(path("policies", vhost, name), idempotent: idempotently)
  }

  // MARK: - Operator Policies

  /// Lists all operator policies across the cluster.
  public func listOperatorPolicies() async throws -> [PolicyInfo] {
    try await get("operator-policies")
  }

  /// Lists operator policies in a virtual host.
  public func listOperatorPolicies(in vhost: String) async throws -> [PolicyInfo] {
    try await get(path("operator-policies", vhost))
  }

  /// Gets a specific operator policy.
  public func getOperatorPolicy(_ name: String, in vhost: String) async throws -> PolicyInfo {
    try await get(path("operator-policies", vhost, name))
  }

  /// Declares an operator policy.
  public func declareOperatorPolicy(_ params: PolicyParams) async throws {
    try await put(path("operator-policies", params.vhost, params.name), body: params)
  }

  /// Deletes an operator policy.
  public func deleteOperatorPolicy(
    _ name: String, in vhost: String, idempotently: Bool = false
  ) async throws {
    try await delete(path("operator-policies", vhost, name), idempotent: idempotently)
  }

  // MARK: - Health Checks

  /// Checks for cluster-wide resource alarms.
  public func healthCheckClusterAlarms() async throws {
    try await healthCheck("health/checks/alarms")
  }

  /// Checks for resource alarms on the target node.
  public func healthCheckLocalAlarms() async throws {
    try await healthCheck("health/checks/local-alarms")
  }

  /// Checks whether the target node is critical for quorum of any queues.
  public func healthCheckNodeIsQuorumCritical() async throws {
    try await healthCheck("health/checks/node-is-quorum-critical")
  }

  /// Checks if a specific port has an active listener.
  public func healthCheckPortListener(_ port: Int) async throws {
    try await healthCheck(path("health", "checks", "port-listener", String(port)))
  }

  /// Checks if a specific protocol listener is active.
  public func healthCheckProtocolListener(_ proto: SupportedProtocol) async throws {
    try await healthCheck(path("health", "checks", "protocol-listener", proto.stringValue))
  }

  /// Checks that all virtual hosts and their running nodes are available.
  public func healthCheckVirtualHosts() async throws {
    try await healthCheck("health/checks/virtual-hosts")
  }

  // MARK: - Feature Flags

  /// Lists all feature flags.
  public func listFeatureFlags() async throws -> [FeatureFlagInfo] {
    try await get("feature-flags")
  }

  /// Enables a feature flag.
  public func enableFeatureFlag(_ name: String) async throws {
    try await putEmpty(path("feature-flags", name, "enable"))
  }

  /// Enables all stable feature flags that are currently disabled.
  public func enableAllStableFeatureFlags() async throws {
    let flags = try await listFeatureFlags()
    for flag in flags where flag.state == .disabled && flag.stability == .stable {
      try await enableFeatureFlag(flag.name)
    }
  }

  // MARK: - Definitions

  /// Exports cluster-wide definitions as a JSON string.
  public func exportDefinitions() async throws -> String {
    try await getString("definitions")
  }

  /// Exports definitions for a virtual host as a JSON string.
  public func exportDefinitions(of vhost: String) async throws -> String {
    try await getString(path("definitions", vhost))
  }

  /// Imports cluster-wide definitions from a JSON string.
  public func importDefinitions(_ json: String) async throws {
    try await postData("definitions", body: Data(json.utf8))
  }

  /// Imports definitions into a virtual host from a JSON string.
  public func importDefinitions(_ json: String, into vhost: String) async throws {
    try await postData(path("definitions", vhost), body: Data(json.utf8))
  }

  // MARK: - Messages (for testing only)

  /// Publishes a message to an exchange via the HTTP API.
  @discardableResult
  public func publishMessage(
    _ payload: String, to exchange: String, routingKey: String,
    in vhost: String = "/"
  ) async throws -> MessageRouted {
    struct Body: Encodable {
      let routingKey: String
      let payload: String
      let payloadEncoding: String
      let properties: [String: String]

      enum CodingKeys: String, CodingKey {
        case routingKey = "routing_key"
        case payload
        case payloadEncoding = "payload_encoding"
        case properties
      }
    }
    let body = Body(
      routingKey: routingKey, payload: payload,
      payloadEncoding: "string", properties: [:])
    return try await post(path("exchanges", vhost, exchange, "publish"), body: body)
  }

  /// Gets messages from a queue without consuming them.
  public func getMessages(
    from queue: String, in vhost: String = "/",
    count: Int = 1, requeue: Bool = true
  ) async throws -> [GetMessage] {
    struct Body: Encodable {
      let count: Int
      let ackmode: String
      let encoding: String
    }
    let ackmode = requeue ? "ack_requeue_true" : "ack_requeue_false"
    let body = Body(count: count, ackmode: ackmode, encoding: "auto")
    return try await post(path("queues", vhost, queue, "get"), body: body)
  }

  // MARK: - User Limits

  /// Lists all user limits across the cluster.
  public func listAllUserLimits() async throws -> [UserLimitsInfo] {
    try await get("user-limits")
  }

  /// Lists limits for a specific user.
  public func listUserLimits(_ username: String) async throws -> [UserLimitsInfo] {
    try await get(path("user-limits", username))
  }

  /// Sets a limit for a user.
  public func setUserLimit(
    _ username: String, _ limit: UserLimitTarget, value: Int
  ) async throws {
    struct Body: Encodable { let value: Int }
    try await put(path("user-limits", username, limit.rawValue), body: Body(value: value))
  }

  /// Clears a limit for a user.
  public func clearUserLimit(_ username: String, _ limit: UserLimitTarget) async throws {
    try await delete(path("user-limits", username, limit.rawValue), idempotent: true)
  }

  // MARK: - Virtual Host Limits

  /// Lists all virtual host limits across the cluster.
  public func listAllVirtualHostLimits() async throws -> [VirtualHostLimitsInfo] {
    try await get("vhost-limits")
  }

  /// Lists limits for a specific virtual host.
  public func listVirtualHostLimits(_ vhost: String) async throws -> [VirtualHostLimitsInfo] {
    try await get(path("vhost-limits", vhost))
  }

  /// Sets a limit for a virtual host.
  public func setVirtualHostLimit(
    _ vhost: String, _ limit: VirtualHostLimitTarget, value: Int
  ) async throws {
    struct Body: Encodable { let value: Int }
    try await put(path("vhost-limits", vhost, limit.rawValue), body: Body(value: value))
  }

  /// Clears a limit for a virtual host.
  public func clearVirtualHostLimit(_ vhost: String, _ limit: VirtualHostLimitTarget) async throws {
    try await delete(path("vhost-limits", vhost, limit.rawValue), idempotent: true)
  }

  // MARK: - Deprecated Features

  /// Lists all deprecated features (RabbitMQ 3.13+).
  public func listDeprecatedFeatures() async throws -> [DeprecatedFeatureInfo] {
    try await get("deprecated-features")
  }

  /// Lists deprecated features currently in use (RabbitMQ 3.13+).
  public func listDeprecatedFeaturesInUse() async throws -> [DeprecatedFeatureInfo] {
    try await get("deprecated-features/used")
  }

  // MARK: - Rebalancing

  /// Triggers a queue leader rebalance across the cluster.
  public func rebalanceQueueLeaders() async throws {
    try await postEmpty("rebalance/queues")
  }

  // MARK: - Plugins

  /// Lists plugins enabled on a specific node.
  public func listNodePlugins(_ name: String) async throws -> [String] {
    let node: ClusterNode = try await get(path("nodes", name))
    return node.enabledPlugins ?? []
  }

  /// Lists plugins enabled across all cluster nodes, deduplicated and sorted.
  public func listAllClusterPlugins() async throws -> [String] {
    let nodes: [ClusterNode] = try await get("nodes")
    return Set(nodes.flatMap { $0.enabledPlugins ?? [] }).sorted()
  }

  // MARK: - Cluster Name

  /// Returns the cluster name.
  public func getClusterName() async throws -> ClusterIdentity {
    try await get("cluster-name")
  }

  /// Sets the cluster name.
  public func setClusterName(_ name: String) async throws {
    try await put("cluster-name", body: ClusterIdentity(name: name))
  }

  // MARK: - Cluster Tags

  /// Returns the cluster tags.
  public func getClusterTags() async throws -> [String: String] {
    let param: GlobalParameterInfo = try await get("global-parameters/cluster_tags")
    guard case .object(let obj) = param.value else { return [:] }
    return obj.compactMapValues { v in
      if case .string(let s) = v { return s }
      return nil
    }
  }

  /// Sets the cluster tags.
  public func setClusterTags(_ tags: [String: String]) async throws {
    let params = GlobalParameterParams(
      name: "cluster_tags", value: .object(tags.mapValues { .string($0) }))
    try await put("global-parameters/cluster_tags", body: params)
  }

  /// Clears all cluster tags.
  public func clearClusterTags() async throws {
    try await delete("global-parameters/cluster_tags", idempotent: true)
  }

  // MARK: - Runtime Parameters

  /// Lists all runtime parameters.
  public func listRuntimeParameters() async throws -> [RuntimeParameterInfo] {
    try await get("parameters")
  }

  /// Lists runtime parameters for a component.
  public func listRuntimeParameters(
    of component: String
  ) async throws -> [RuntimeParameterInfo] {
    try await get(path("parameters", component))
  }

  /// Lists runtime parameters for a component in a virtual host.
  public func listRuntimeParameters(
    of component: String, in vhost: String
  ) async throws -> [RuntimeParameterInfo] {
    try await get(path("parameters", component, vhost))
  }

  /// Gets a specific runtime parameter.
  public func getRuntimeParameter(
    _ name: String, of component: String, in vhost: String
  ) async throws -> RuntimeParameterInfo {
    try await get(path("parameters", component, vhost, name))
  }

  /// Creates or updates a runtime parameter.
  public func upsertRuntimeParameter(_ params: RuntimeParameterParams) async throws {
    try await put(
      path("parameters", params.component, params.vhost, params.name),
      body: params)
  }

  /// Deletes a runtime parameter.
  public func deleteRuntimeParameter(
    _ name: String, of component: String, in vhost: String,
    idempotently: Bool = false
  ) async throws {
    try await delete(
      path("parameters", component, vhost, name), idempotent: idempotently)
  }

  // MARK: - Global Parameters

  /// Lists all global runtime parameters.
  public func listGlobalParameters() async throws -> [GlobalParameterInfo] {
    try await get("global-parameters")
  }

  /// Gets a specific global runtime parameter.
  public func getGlobalParameter(_ name: String) async throws -> GlobalParameterInfo {
    try await get(path("global-parameters", name))
  }

  /// Creates or updates a global runtime parameter.
  public func upsertGlobalParameter(_ params: GlobalParameterParams) async throws {
    try await put(path("global-parameters", params.name), body: params)
  }

  /// Deletes a global runtime parameter.
  public func deleteGlobalParameter(
    _ name: String, idempotently: Bool = false
  ) async throws {
    try await delete(path("global-parameters", name), idempotent: idempotently)
  }

  // MARK: - Federation

  /// Lists all federation upstreams across the cluster.
  public func listFederationUpstreams() async throws -> [RuntimeParameterInfo] {
    try await get("parameters/federation-upstream")
  }

  /// Lists federation upstreams in a virtual host.
  public func listFederationUpstreams(
    in vhost: String
  ) async throws -> [RuntimeParameterInfo] {
    try await get(path("parameters", "federation-upstream", vhost))
  }

  /// Gets a specific federation upstream.
  public func getFederationUpstream(
    _ name: String, in vhost: String
  ) async throws -> RuntimeParameterInfo {
    try await get(path("parameters", "federation-upstream", vhost, name))
  }

  /// Declares a federation upstream.
  public func declareFederationUpstream(_ params: FederationUpstreamParams) async throws {
    try await put(
      path("parameters", "federation-upstream", params.vhost, params.name),
      body: params)
  }

  /// Deletes a federation upstream.
  public func deleteFederationUpstream(
    _ name: String, in vhost: String, idempotently: Bool = false
  ) async throws {
    try await delete(
      path("parameters", "federation-upstream", vhost, name),
      idempotent: idempotently)
  }

  /// Lists all federation links across the cluster.
  public func listFederationLinks() async throws -> [FederationLinkInfo] {
    try await get("federation-links")
  }

  /// Lists federation links in a virtual host.
  public func listFederationLinks(
    in vhost: String
  ) async throws -> [FederationLinkInfo] {
    try await get(path("federation-links", vhost))
  }

  // MARK: - Shovels

  /// Lists all shovels across the cluster.
  public func listShovels() async throws -> [ShovelStatusInfo] {
    try await get("shovels")
  }

  /// Lists shovels in a virtual host.
  public func listShovels(in vhost: String) async throws -> [ShovelStatusInfo] {
    try await get(path("shovels", vhost))
  }

  /// Gets a shovel configuration.
  public func getShovel(
    _ name: String, in vhost: String
  ) async throws -> ShovelInfo {
    try await get(path("parameters", "shovel", vhost, name))
  }

  /// Declares a shovel.
  public func declareShovel(_ params: ShovelParams) async throws {
    try await put(
      path("parameters", "shovel", params.vhost, params.name),
      body: params)
  }

  /// Deletes a shovel.
  public func deleteShovel(
    _ name: String, in vhost: String, idempotently: Bool = false
  ) async throws {
    try await delete(
      path("parameters", "shovel", vhost, name), idempotent: idempotently)
  }

  // MARK: - Stream Publishers / Consumers

  /// Lists all stream publishers across the cluster.
  public func listStreamPublishers() async throws -> [StreamPublisherInfo] {
    try await get("stream/publishers")
  }

  /// Lists stream publishers in a virtual host.
  public func listStreamPublishers(
    in vhost: String
  ) async throws -> [StreamPublisherInfo] {
    try await get(path("stream", "publishers", vhost))
  }

  /// Lists stream publishers for a specific stream.
  public func listStreamPublishers(
    of stream: String, in vhost: String
  ) async throws -> [StreamPublisherInfo] {
    try await get(path("stream", "publishers", vhost, stream))
  }

  /// Lists stream publishers on a specific connection.
  public func listStreamPublishers(
    on connection: String, in vhost: String
  ) async throws -> [StreamPublisherInfo] {
    try await get(path("stream", "connections", vhost, connection, "publishers"))
  }

  /// Lists all stream consumers across the cluster.
  public func listStreamConsumers() async throws -> [StreamConsumerInfo] {
    try await get("stream/consumers")
  }

  /// Lists stream consumers in a virtual host.
  public func listStreamConsumers(
    in vhost: String
  ) async throws -> [StreamConsumerInfo] {
    try await get(path("stream", "consumers", vhost))
  }

  /// Lists stream consumers on a specific connection.
  public func listStreamConsumers(
    on connection: String, in vhost: String
  ) async throws -> [StreamConsumerInfo] {
    try await get(path("stream", "connections", vhost, connection, "consumers"))
  }

  /// Returns information about a specific stream connection.
  public func getStreamConnectionInfo(
    _ name: String, in vhost: String
  ) async throws -> ConnectionInfo {
    try await get(path("stream", "connections", vhost, name))
  }

  // MARK: - Authentication

  /// Returns the OAuth/authentication configuration.
  public func oauthConfiguration() async throws -> OAuthConfiguration {
    try await get("auth")
  }

  /// Returns authentication attempt statistics for a node.
  public func authAttemptStatistics(
    _ node: String
  ) async throws -> [AuthAttemptStatistics] {
    try await get(path("auth", "attempts", node))
  }

  // MARK: - Schema Definition Sync (Tanzu RabbitMQ)

  /// Enables schema definition sync across the cluster (Tanzu RabbitMQ).
  public func enableSchemaDefinitionSync() async throws {
    try await postEmpty("definitions/sync/enable")
  }

  /// Enables schema definition sync on a specific node (Tanzu RabbitMQ).
  public func enableSchemaDefinitionSync(on node: String) async throws {
    try await postEmpty(path("definitions", "sync", "enable", node))
  }

  /// Disables schema definition sync across the cluster (Tanzu RabbitMQ).
  public func disableSchemaDefinitionSync() async throws {
    try await postEmpty("definitions/sync/disable")
  }

  /// Disables schema definition sync on a specific node (Tanzu RabbitMQ).
  public func disableSchemaDefinitionSync(on node: String) async throws {
    try await postEmpty(path("definitions", "sync", "disable", node))
  }

  /// Returns schema definition sync status (Tanzu RabbitMQ).
  public func schemaDefinitionSyncStatus() async throws -> JSONValue {
    try await get("tanzu/osr/schema/status")
  }

  /// Returns schema definition sync status for a node (Tanzu RabbitMQ).
  public func schemaDefinitionSyncStatus(on node: String) async throws -> JSONValue {
    try await get(path("tanzu", "osr", "schema", "status", node))
  }

  /// Returns warm standby replication status (Tanzu RabbitMQ).
  public func warmStandbyReplicationStatus() async throws -> JSONValue {
    try await get("replication/status")
  }

  // MARK: - Paginated Listings

  /// Lists queues with pagination.
  public func listQueues(
    page: PaginationParams
  ) async throws -> PaginatedResponse<QueueInfo> {
    try await get("queues?\(page.queryString)")
  }

  /// Lists queues in a virtual host with pagination.
  public func listQueues(
    in vhost: String, page: PaginationParams
  ) async throws -> PaginatedResponse<QueueInfo> {
    try await get("\(path("queues", vhost))?\(page.queryString)")
  }

  /// Lists connections with pagination.
  public func listConnections(
    page: PaginationParams
  ) async throws -> PaginatedResponse<ConnectionInfo> {
    try await get("connections?\(page.queryString)")
  }

  /// Lists exchanges with pagination.
  public func listExchanges(
    page: PaginationParams
  ) async throws -> PaginatedResponse<ExchangeInfo> {
    try await get("exchanges?\(page.queryString)")
  }

  /// Lists exchanges in a virtual host with pagination.
  public func listExchanges(
    in vhost: String, page: PaginationParams
  ) async throws -> PaginatedResponse<ExchangeInfo> {
    try await get("\(path("exchanges", vhost))?\(page.queryString)")
  }

  /// Lists channels with pagination.
  public func listChannels(
    page: PaginationParams
  ) async throws -> PaginatedResponse<ChannelInfo> {
    try await get("channels?\(page.queryString)")
  }

  // MARK: - Internal HTTP Methods

  func get<T: Decodable & Sendable>(_ urlPath: String) async throws -> T {
    let data = try await perform(urlPath, method: "GET")
    do {
      return try decoder.decode(T.self, from: data)
    } catch {
      throw ClientError.decodingFailed(
        underlying: error, body: String(data: data, encoding: .utf8))
    }
  }

  func getString(_ urlPath: String) async throws -> String {
    let data = try await perform(urlPath, method: "GET")
    return String(data: data, encoding: .utf8) ?? ""
  }

  private static let emptyBody = Data("{}".utf8)

  func put<T: Encodable>(_ urlPath: String, body: T) async throws {
    let bodyData = try encoder.encode(body)
    _ = try await perform(urlPath, method: "PUT", body: bodyData)
  }

  func putEmpty(_ urlPath: String) async throws {
    _ = try await perform(urlPath, method: "PUT", body: Self.emptyBody)
  }

  func postEmpty(_ urlPath: String) async throws {
    _ = try await perform(urlPath, method: "POST", body: Self.emptyBody)
  }

  func post<T: Encodable, R: Decodable & Sendable>(_ urlPath: String, body: T) async throws -> R {
    let bodyData = try encoder.encode(body)
    let data = try await perform(urlPath, method: "POST", body: bodyData)
    return try decoder.decode(R.self, from: data)
  }

  func post<T: Encodable>(_ urlPath: String, body: T) async throws {
    let bodyData = try encoder.encode(body)
    _ = try await perform(urlPath, method: "POST", body: bodyData)
  }

  func postData(_ urlPath: String, body: Data) async throws {
    _ = try await perform(urlPath, method: "POST", body: body)
  }

  func delete(
    _ urlPath: String, idempotent: Bool, headers: [String: String] = [:]
  ) async throws {
    do {
      _ = try await perform(urlPath, method: "DELETE", extraHeaders: headers)
    } catch let error as ClientError where idempotent && error.isNotFound {
      return
    }
  }

  func healthCheck(_ urlPath: String) async throws {
    let (data, response) = try await performRaw(urlPath, method: "GET")
    let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
    if (200..<300).contains(statusCode) { return }
    throw ClientError.healthCheckFailed(
      path: urlPath, statusCode: statusCode,
      body: String(data: data, encoding: .utf8))
  }

  // MARK: - Core HTTP

  func perform(
    _ urlPath: String, method: String,
    body: Data? = nil, extraHeaders: [String: String] = [:]
  ) async throws -> Data {
    var lastError: (any Error)?
    for attempt in 0...retrySettings.maxAttempts {
      do {
        let (data, response) = try await performRaw(
          urlPath, method: method, body: body, extraHeaders: extraHeaders)
        let httpResponse = response as? HTTPURLResponse
        let statusCode = httpResponse?.statusCode ?? 0
        try checkStatus(statusCode, data: data, url: httpResponse?.url)
        return data
      } catch {
        lastError = error
        if attempt < retrySettings.maxAttempts {
          try await Task.sleep(nanoseconds: retrySettings.delayMs * 1_000_000)
        }
      }
    }
    throw lastError!
  }

  func performRaw(
    _ urlPath: String, method: String,
    body: Data? = nil, extraHeaders: [String: String] = [:]
  ) async throws -> (Data, URLResponse) {
    let fullURL = "\(endpoint)/\(urlPath)"
    guard let url = URL(string: fullURL) else {
      throw ClientError.invalidEndpoint(fullURL)
    }
    var request = URLRequest(url: url, timeoutInterval: 60)
    request.httpMethod = method
    request.httpBody = body
    if body != nil {
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    }
    request.setValue(authHeader, forHTTPHeaderField: "Authorization")
    for (key, value) in extraHeaders {
      request.setValue(value, forHTTPHeaderField: key)
    }
    do {
      return try await session.data(for: request)
    } catch {
      throw ClientError.requestFailed(underlying: error)
    }
  }

  func checkStatus(_ statusCode: Int, data: Data, url: URL?) throws {
    if (200..<300).contains(statusCode) { return }

    let body = String(data: data, encoding: .utf8)
    let details = try? decoder.decode(APIErrorDetails.self, from: data)

    if statusCode == 404 {
      throw ClientError.notFound
    }
    if (400..<500).contains(statusCode) {
      throw ClientError.clientError(
        statusCode: statusCode, url: url, body: body, details: details)
    }
    if statusCode >= 500 {
      throw ClientError.serverError(
        statusCode: statusCode, url: url, body: body, details: details)
    }
  }

  func path(_ segments: String...) -> String {
    segments.map(encodePathSegment).joined(separator: "/")
  }
}
