# A Swift Client for the RabbitMQ HTTP API

This is a Swift 6 client for the [RabbitMQ HTTP API](https://www.rabbitmq.com/docs/management#http-api)
heavily inspired by its [Rust counterpart](https://github.com/michaelklishin/rabbitmq-http-api-rs/) that powers
[modern `rabbitmqadmin`](https://www.rabbitmq.com/docs/management-cli).

If you are looking for am AMQP 0-9-1 client for Swift 6, see [`michaelklishin/bunny-swift`](https://github.com/michaelklishin/bunny-swift/).

## Project Maturity

This library is reasonably mature.

Before `1.0.0`, breaking API changes can and will be introduced.

## Supported RabbitMQ Series

This library targets RabbitMQ 4.x and 3.13.x.

All older series have [reached End of Life](https://www.rabbitmq.com/release-information).

## Swift Version

This library requires Swift 6 and uses strict concurrency checking (`swift-6` language mode).

## Installation

Add this to `Package.swift`:

```swift
.package(url: "https://github.com/rabbitmq/rabbitmq-http-api-client-swift.git", from: "0.7.0")
```

And to your target dependencies:

```swift
.product(name: "RabbitMQHTTPAPIClient", package: "rabbitmq-http-api-client-swift")
```

## Async Client

The async client uses Swift's structured concurrency with `async`/`await`. All client methods are `async throws` and designed for concurrent use.

### Instantiate a Client

```swift
import RabbitMQHTTPAPIClient

let client = Client(
  endpoint: "http://localhost:15672/api",
  username: "guest",
  password: "guest"
)

let nodes = try await client.listNodes()
```

The client uses `Foundation.URLSession` under the hood and is `Sendable`, safe to use from multiple concurrent tasks.

### Default Endpoint and Credentials

The default endpoint is `http://localhost:15672/api`, username is `guest`, and password is `guest`.

```swift
let client = Client()
let overview = try await client.overview()
```

### Configuring Retries and Timeouts

Pass `RetrySettings` to configure retry behavior:

```swift
import RabbitMQHTTPAPIClient

let retrySettings = RetrySettings(maxAttempts: 3, delayMs: 500)
let client = Client(
  endpoint: "http://localhost:15672/api",
  username: "guest",
  password: "guest",
  retrySettings: retrySettings
)
```

Default retry behavior is `maxAttempts: 3` with `delayMs: 0`.

### Custom URLSession

Pass a custom `URLSession` for advanced configuration:

```swift
var config = URLSessionConfiguration.default
// Timeout for individual request/response (not including connection time)
config.timeoutIntervalForRequest = 30
// Timeout for total resource (connection + request + response)
config.timeoutIntervalForResource = 60
config.waitsForConnectivity = true

let session = URLSession(configuration: config)
let client = Client(
  endpoint: "http://localhost:15672/api",
  username: "guest",
  password: "guest",
  session: session
)
```

## Cluster and Node Operations

### Get Cluster Overview

```swift
let overview = try await client.overview()
```

Returns cluster overview including node name, version, statistics, and listeners.

### Get RabbitMQ Version

```swift
let version = try await client.serverVersion()
```

### List Cluster Nodes

```swift
let nodes = try await client.listNodes()
```

### Get Node Information

```swift
let node = try await client.getNodeInfo("rabbit@hostname")
```

### Node Memory Footprint

```swift
let footprint = try await client.getNodeMemoryFootprint("rabbit@hostname")
```

Returns a per-category [memory footprint breakdown](https://www.rabbitmq.com/docs/memory-use), in bytes and as percentages.

### Get Cluster Name

```swift
let identity = try await client.getClusterName()
```

### Set Cluster Name

```swift
try await client.setClusterName("my-cluster")
```

### Cluster Tags

[Cluster tags](https://www.rabbitmq.com/docs/parameters#cluster-tags) are arbitrary key-value pairs for the cluster:

```swift
let tags = try await client.getClusterTags()

let newTags = ["environment": "production", "region": "us-east-1"]
try await client.setClusterTags(newTags)

try await client.clearClusterTags()
```

## Virtual Host Operations

[Virtual hosts](https://www.rabbitmq.com/docs/vhosts) group and isolate resources.

### List Virtual Hosts

```swift
let vhosts = try await client.listVirtualHosts()
```

### Get Virtual Host

```swift
let vhost = try await client.getVirtualHost("/")
```

### Create Virtual Host

```swift
let params = VirtualHostParams(
  name: "my-vhost",
  description: "Production vhost",
  tags: ["production", "critical"],
  defaultQueueType: "quorum"
)
try await client.createVirtualHost(params)
```

### Delete Virtual Host

```swift
try await client.deleteVirtualHost("my-vhost", idempotently: false)
```

Set `idempotently: true` to ignore 404 errors if the vhost doesn't exist.

### Virtual Host Deletion Protection

```swift
try await client.enableVirtualHostDeletionProtection("my-vhost")
try await client.disableVirtualHostDeletionProtection("my-vhost")
```

## User Operations

### List Users

```swift
let users = try await client.listUsers()
```

### Get User

```swift
let user = try await client.getUser("my-user")
```

### Get Current User

```swift
let currentUser = try await client.whoami()
```

### Create User

```swift
let params = UserParams(
  name: "new-user",
  password: "s3cRe7"
)
try await client.createUser(params)
```

Users can be created with a plaintext password or a password hash. To use a hash:

```swift
let params = UserParams(
  name: "new-user",
  passwordHash: "base64EncodedHash",
  hashingAlgorithm: "SHA-256"
)
try await client.createUser(params)
```

### Delete User

```swift
try await client.deleteUser("new-user", idempotently: false)
```

### Delete Multiple Users

```swift
try await client.deleteUsers(["user1", "user2", "user3"])
```

### List Users Without Permissions

```swift
let unusedUsers = try await client.listUsersWithoutPermissions()
```

## Connection Operations

### List Connections

```swift
let connections = try await client.listConnections()
```

### List Connections in a Virtual Host

```swift
let vhostConnections = try await client.listConnections(in: "/")
```

### Get Connection

```swift
let connection = try await client.getConnectionInfo("connection-name")
```

### Close Connection

```swift
try await client.closeConnection(
  "connection-name",
  reason: "closing for maintenance",
  idempotently: false
)
```

### List Stream Connections

```swift
let streamConnections = try await client.listStreamConnections()
let vhostStreamConnections = try await client.listStreamConnections(in: "/")
```

### User Connections

```swift
let userConnections = try await client.listUserConnections("username")
try await client.closeUserConnections("username", reason: "session expired")
```

## Queue Operations

### List Queues

```swift
let allQueues = try await client.listQueues()
let vhostQueues = try await client.listQueues(in: "/")
```

### List Queues by Type

```swift
let classicQueues = try await client.listClassicQueues()
let classicVhostQueues = try await client.listClassicQueues(in: "/")

let quorumQueues = try await client.listQuorumQueues()
let quorumVhostQueues = try await client.listQuorumQueues(in: "/")

let streams = try await client.listStreams()
let vhostStreams = try await client.listStreams(in: "/")
```

### Get Queue Properties and Metrics

```swift
let queueInfo = try await client.getQueueInfo("my-queue", in: "/")
```

### Declare a Classic Queue

```swift
let params = QueueParams.classicQueue("my-queue", in: "/")
try await client.declareQueue(params)
```

Pass custom arguments:

```swift
var args: [String: JSONValue] = [:]
args["x-message-ttl"] = .int(3600000)
args["x-max-length"] = .int(10000)

let params = QueueParams.classicQueue("my-queue", in: "/", arguments: args)
try await client.declareQueue(params)
```

### Declare a Quorum Queue

[Quorum queues](https://www.rabbitmq.com/docs/quorum-queues) are replicated, data safety-oriented queues based on the Raft consensus algorithm:

```swift
let params = QueueParams.quorumQueue("my-qq", in: "/")
try await client.declareQueue(params)
```

With custom arguments:

```swift
var args: [String: JSONValue] = [:]
args["x-max-length"] = .int(10000)
args["x-single-active-consumer"] = .bool(true)

let params = QueueParams.quorumQueue("my-qq", in: "/", arguments: args)
try await client.declareQueue(params)
```

### Declare a Stream

[Streams](https://www.rabbitmq.com/docs/streams) are persistent, replicated append-only logs with non-destructive consumer semantics:

```swift
let params = QueueParams.stream("my-stream", in: "/")
try await client.declareQueue(params)
```

With retention settings:

```swift
var args: [String: JSONValue] = [:]
args["x-max-age"] = .string("7D")
args["x-max-length-bytes"] = .int(10_000_000_000)

let params = QueueParams.stream("my-stream", in: "/", arguments: args)
try await client.declareQueue(params)
```

### Purge Queue

```swift
try await client.purgeQueue("my-queue", in: "/")
```

### Delete Queue

```swift
try await client.deleteQueue("my-queue", in: "/", idempotently: false)
```

### Batch Queue Deletion

```swift
try await client.deleteQueue("queue-1", in: "/")
try await client.deleteQueue("queue-2", in: "/")
try await client.deleteQueue("queue-3", in: "/")
```

## Exchange Operations

### List Exchanges

```swift
let exchanges = try await client.listExchanges()
let vhostExchanges = try await client.listExchanges(in: "/")
```

### Get Exchange Properties and Metrics

```swift
let exchangeInfo = try await client.getExchangeInfo("my-exchange", in: "/")
```

### Declare an Exchange

Use the type-safe factory methods:

```swift
let params = ExchangeParams.direct("my-exchange", in: "/")
try await client.declareExchange(params)

let params = ExchangeParams.topic("my-topic", in: "/")
try await client.declareExchange(params)

let params = ExchangeParams.fanout("my-fanout", in: "/")
try await client.declareExchange(params)

let params = ExchangeParams.headers("my-headers", in: "/")
try await client.declareExchange(params)
```

With arguments:

```swift
var args: [String: JSONValue] = [:]
args["x-message-ttl"] = .int(3600000)

let params = ExchangeParams.topic("my-topic", in: "/", arguments: args)
try await client.declareExchange(params)
```

### Delete Exchange

```swift
try await client.deleteExchange("my-exchange", in: "/", idempotently: false)
```

## Binding Operations

Bindings connect exchanges to queues or other exchanges.

### List Bindings

```swift
let bindings = try await client.listBindings()
let vhostBindings = try await client.listBindings(in: "/")
```

### List Queue Bindings

```swift
let queueBindings = try await client.listQueueBindings("my-queue", in: "/")
```

### List Exchange Bindings

```swift
let asSource = try await client.listExchangeBindingsAsSource("my-exchange", in: "/")
let asDestination = try await client.listExchangeBindingsAsDestination("my-exchange", in: "/")
```

### Bind Queue to Exchange

```swift
try await client.bindQueue(
  "my-queue",
  to: "my-exchange",
  in: "/",
  routingKey: "routing.key"
)
```

With arguments:

```swift
try await client.bindQueue(
  "my-queue",
  to: "my-exchange",
  in: "/",
  routingKey: "routing.key",
  arguments: ["x-match": .string("all")]
)
```

### Bind Exchange to Exchange

```swift
try await client.bindExchange(
  "destination-exchange",
  to: "source-exchange",
  in: "/",
  routingKey: "routing.key"
)
```

### Delete Binding

```swift
try await client.deleteQueueBinding(
  "my-queue",
  from: "my-exchange",
  in: "/",
  propertiesKey: "routing.key",
  idempotently: false
)
```

## Channel Operations

### List Channels

```swift
let channels = try await client.listChannels()
let vhostChannels = try await client.listChannels(in: "/")
```

### Get Channel

```swift
let channelInfo = try await client.getChannelInfo("channel-name")
```

### List Channels on Connection

```swift
let connectionChannels = try await client.listChannels(on: "connection-name")
```

## Consumer Operations

### List Consumers

```swift
let consumers = try await client.listConsumers()
let vhostConsumers = try await client.listConsumers(in: "/")
```

## Permission Operations

### List Permissions

```swift
let allPermissions = try await client.listPermissions()
let vhostPermissions = try await client.listPermissions(in: "/")
let userPermissions = try await client.listPermissions(of: "username")
```

### Get Permission

```swift
let permissions = try await client.getPermissions(of: "username", in: "/")
```

### Grant Permissions

```swift
let params = PermissionParams(
  vhost: "/",
  username: "my-user",
  configure: ".*",
  read: ".*",
  write: ".*"
)
try await client.grantPermissions(params)
```

### Clear Permissions

```swift
try await client.clearPermissions(of: "username", in: "/", idempotently: false)
```

## Topic Permission Operations

[Topic permissions](https://www.rabbitmq.com/docs/access-control#topic-permissions) control access to topics in exchanges.

### List Topic Permissions

```swift
let allTopicPerms = try await client.listTopicPermissions()
let vhostTopicPerms = try await client.listTopicPermissions(in: "/")
let userTopicPerms = try await client.listTopicPermissions(of: "username")
```

### Get Topic Permission

```swift
let topicPerms = try await client.getTopicPermissions(of: "username", in: "/", exchange: "my-exchange")
```

### Grant Topic Permissions

```swift
let params = TopicPermissionParams(
  vhost: "/",
  username: "my-user",
  exchange: "my-exchange",
  write: ".*",
  read: ".*"
)
try await client.grantTopicPermissions(params)
```

### Clear Topic Permissions

Clears all topic permissions for a user in a virtual host:

```swift
try await client.clearTopicPermissions(
  of: "username",
  in: "/",
  idempotently: false
)
```

## Policy Operations

[Policies](https://www.rabbitmq.com/docs/policies) dynamically configure queue and exchange properties using pattern matching.

### List Policies

```swift
let policies = try await client.listPolicies()
let vhostPolicies = try await client.listPolicies(in: "/")
```

### Get Policy

```swift
let policy = try await client.getPolicy("my-policy", in: "/")
```

### Declare a Policy

```swift
var definition: [String: JSONValue] = [:]
definition["max-length"] = .int(10000)
definition["overflow"] = .string("reject-publish")

let params = PolicyParams(
  vhost: "/",
  name: "my-policy",
  pattern: "^my-.*",
  definition: definition,
  priority: 0,
  applyTo: .queues
)
try await client.declarePolicy(params)
```

### Delete Policy

```swift
try await client.deletePolicy("my-policy", in: "/", idempotently: false)
```

## Operator Policy Operations

Operator policies are system-wide policies for operators to apply without input from users.

### List Operator Policies

```swift
let opPolicies = try await client.listOperatorPolicies()
let vhostOpPolicies = try await client.listOperatorPolicies(in: "/")
```

### Declare Operator Policy

```swift
var definition: [String: JSONValue] = [:]
definition["delivery-limit"] = .int(5)

let params = PolicyParams(
  vhost: "/",
  name: "op-policy",
  pattern: "^.*",
  definition: definition,
  priority: 100,
  applyTo: .queues
)
try await client.declareOperatorPolicy(params)
```

### Delete Operator Policy

```swift
try await client.deleteOperatorPolicy("op-policy", in: "/", idempotently: false)
```

## Pagination

Some list operations support pagination:

```swift
let page = PaginationParams(page: 1, pageSize: 100)
let queuesPage = try await client.listQueues(page: page)

let nextPage = PaginationParams(page: 2, pageSize: 100)
let moreQueues = try await client.listQueues(page: nextPage)
```

Iterate all pages:

```swift
var allQueues: [QueueInfo] = []
var page = 1

while true {
  let params = PaginationParams(page: page, pageSize: 100)
  let result = try await client.listQueues(page: params)
  allQueues.append(contentsOf: result.items)

  if !result.hasMore {
    break
  }
  page += 1
}
```

Paginated operations include: `listQueues`, `listConnections`, and `listExchanges`.

## Health Checks

### Cluster Alarms

```swift
try await client.healthCheckClusterAlarms()
```

### Local Alarms

```swift
try await client.healthCheckLocalAlarms()
```

### Quorum Critical

```swift
try await client.healthCheckNodeIsQuorumCritical()
```

### Port Listener

```swift
try await client.healthCheckPortListener(5672)
```

### Protocol Listener

```swift
try await client.healthCheckProtocolListener(.amqp)
try await client.healthCheckProtocolListener(.stream)
try await client.healthCheckProtocolListener(.mqtt)
```

### Virtual Hosts

```swift
try await client.healthCheckVirtualHosts()
```

## Feature Flags

### List Feature Flags

```swift
let flags = try await client.listFeatureFlags()
```

### Enable Feature Flag

```swift
try await client.enableFeatureFlag("feature-name")
```

### Enable All Stable Feature Flags

```swift
try await client.enableAllStableFeatureFlags()
```

## Definition Operations

### Export Definitions

```swift
let json = try await client.exportDefinitions()
```

Export vhost-specific definitions:

```swift
let vhostJson = try await client.exportDefinitions(of: "/")
```

### Import Definitions

```swift
try await client.importDefinitions(jsonString)
```

Import into a specific vhost:

```swift
try await client.importDefinitions(jsonString, into: "/")
```

## Message Operations

Message operations are for testing only and not recommended for production use.

### Publish Message

```swift
try await client.publishMessage(
  "test message",
  to: "my-exchange",
  routingKey: "test.key",
  in: "/"
)
```

### Get Messages

```swift
let messages = try await client.getMessages(
  from: "my-queue",
  in: "/",
  count: 10,
  requeue: true
)
```

## User Limits

### List All User Limits

```swift
let limits = try await client.listAllUserLimits()
```

### List User Limits

```swift
let userLimits = try await client.listUserLimits("username")
```

### Set User Limit

```swift
try await client.setUserLimit("username", .maxConnections, value: 100)
```

### Clear User Limit

```swift
try await client.clearUserLimit("username", .maxConnections)
```

## Virtual Host Limits

### List All Virtual Host Limits

```swift
let limits = try await client.listAllVirtualHostLimits()
```

### List Virtual Host Limits

```swift
let vhostLimits = try await client.listVirtualHostLimits("/")
```

### Set Virtual Host Limit

```swift
try await client.setVirtualHostLimit("/", .maxQueues, value: 10000)
```

### Clear Virtual Host Limit

```swift
try await client.clearVirtualHostLimit("/", .maxQueues)
```

## Deprecated Features

### List Deprecated Features

```swift
let allDeprecated = try await client.listDeprecatedFeatures()
```

### List Deprecated Features In Use

```swift
let inUse = try await client.listDeprecatedFeaturesInUse()
```

## Rebalancing

### Rebalance Queue Leaders

```swift
try await client.rebalanceQueueLeaders()
```

## Plugin Operations

### List Node Plugins

```swift
let plugins = try await client.listNodePlugins("rabbit@hostname")
```

### List All Cluster Plugins

```swift
let clusterPlugins = try await client.listAllClusterPlugins()
```

## Runtime Parameters

### List Runtime Parameters

```swift
let allParams = try await client.listRuntimeParameters()
```

List by component:

```swift
let federationParams = try await client.listRuntimeParameters(component: "federation")
```

List for component in vhost:

```swift
let vhostFedParams = try await client.listRuntimeParameters(component: "federation", in: "/")
```

### Get Runtime Parameter

```swift
let param = try await client.getRuntimeParameter(
  "upstream",
  of: "federation",
  in: "/"
)
```

### Set Runtime Parameter

```swift
var value: [String: JSONValue] = [:]
value["uri"] = .string("amqp://upstream-host")
value["ack-mode"] = .string("on-confirm")

let params = RuntimeParameterParams(
  component: "federation",
  name: "my-upstream",
  vhost: "/",
  value: value
)
try await client.upsertRuntimeParameter(params)
```

### Delete Runtime Parameter

```swift
try await client.deleteRuntimeParameter(
  "my-upstream",
  of: "federation",
  in: "/",
  idempotently: false
)
```

## Global Parameters

### List Global Parameters

```swift
let globals = try await client.listGlobalParameters()
```

### Get Global Parameter

```swift
let param = try await client.getGlobalParameter("my-param")
```

### Set Global Parameter

```swift
var value: [String: JSONValue] = [:]
value["key"] = .string("value")

let params = GlobalParameterParams(
  name: "my-param",
  value: value
)
try await client.upsertGlobalParameter(params)
```

### Delete Global Parameter

```swift
try await client.deleteGlobalParameter("my-param", idempotently: false)
```

## Federation

[Federation](https://www.rabbitmq.com/docs/federation) links RabbitMQ brokers together to distribute messages.

### List Federation Upstreams

```swift
let upstreams = try await client.listFederationUpstreams()
let vhostUpstreams = try await client.listFederationUpstreams(in: "/")
```

### Get Federation Upstream

```swift
let upstream = try await client.getFederationUpstream("my-upstream", in: "/")
```

### Declare Federation Upstream

```swift
let params = FederationUpstreamParams(
  name: "my-upstream",
  vhost: "/",
  definition: ["uri": .string("amqp://upstream-host")]
)
try await client.declareFederationUpstream(params)
```

### Delete Federation Upstream

```swift
try await client.deleteFederationUpstream("my-upstream", in: "/", idempotently: false)
```

### Federation Links

```swift
let links = try await client.listFederationLinks()
let vhostLinks = try await client.listFederationLinks(in: "/")
```

## Shovels

[Shovels](https://www.rabbitmq.com/docs/shovel) move messages from a source to a destination.

### List Shovels

```swift
let shovels = try await client.listShovels()
let vhostShovels = try await client.listShovels(in: "/")
```

### Get Shovel

```swift
let shovel = try await client.getShovel("my-shovel", in: "/")
```

### Declare Shovel

Type-safe factory methods for common shovel configurations:

```swift
let params = ShovelParams.amqp091QueueShovel(
  name: "my-shovel",
  vhost: "/",
  sourceUri: "amqp://source-host",
  destinationUri: "amqp://dest-host",
  sourceQueue: "src-queue",
  destinationQueue: "dst-queue"
)
try await client.declareShovel(params)
```

Or for shoveling from exchange to queue:

```swift
let params = ShovelParams.amqp091ExchangeShovel(
  name: "my-shovel",
  vhost: "/",
  sourceUri: "amqp://source-host",
  sourceExchange: "src-exchange",
  destinationUri: "amqp://dest-host",
  destinationQueue: "dst-queue"
)
try await client.declareShovel(params)
```

### Delete Shovel

```swift
try await client.deleteShovel("my-shovel", in: "/", idempotently: false)
```

## Stream Publishers and Consumers

### List Stream Publishers

All cluster publishers:

```swift
let allPublishers = try await client.listStreamPublishers()
```

By virtual host:

```swift
let vhostPublishers = try await client.listStreamPublishers(in: "/")
```

By stream and virtual host:

```swift
let streamPublishers = try await client.listStreamPublishers(of: "my-stream", in: "/")
```

By connection and virtual host:

```swift
let connectionPublishers = try await client.listStreamPublishers(on: "connection-name", in: "/")
```

### List Stream Consumers

All cluster consumers:

```swift
let allConsumers = try await client.listStreamConsumers()
```

By virtual host:

```swift
let vhostConsumers = try await client.listStreamConsumers(in: "/")
```

By connection and virtual host:

```swift
let connectionConsumers = try await client.listStreamConsumers(on: "connection-name", in: "/")
```

### Get Stream Connection Info

```swift
let connInfo = try await client.getStreamConnectionInfo("connection-name")
```

## Authentication and OAuth

### OAuth Configuration

```swift
let oauthConfig = try await client.oauthConfiguration()
```

### Auth Attempt Statistics

```swift
let stats = try await client.authAttemptStatistics(user: "username", in: "/")
```

## Tanzu RabbitMQ Schema Definition Sync

These operations are specific to Tanzu RabbitMQ deployments.

### Enable Schema Definition Sync

```swift
try await client.enableSchemaDefinitionSync()
try await client.enableSchemaDefinitionSync(on: "rabbit@hostname")
```

### Disable Schema Definition Sync

```swift
try await client.disableSchemaDefinitionSync()
try await client.disableSchemaDefinitionSync(on: "rabbit@hostname")
```

### Schema Definition Sync Status

```swift
let status = try await client.schemaDefinitionSyncStatus()
let nodeStatus = try await client.schemaDefinitionSyncStatus(on: "rabbit@hostname")
```

### Warm Standby Replication Status

```swift
let replStatus = try await client.warmStandbyReplicationStatus()
```

## Error Handling

The client throws errors from the `ClientError` enum which includes cases like `badRequest`, `unauthorized`, `notFound`, `conflict`, and `serverError`:

```swift
do {
  try await client.getQueueInfo("my-queue", in: "/")
} catch let error as ClientError {
  switch error {
  case .notFound:
    print("Queue not found")
  case .unauthorized:
    print("Authentication failed")
  case .conflict:
    print("Resource already exists")
  case .badRequest(let reason):
    print("Bad request: \(reason)")
  case .serverError(let statusCode, let body):
    print("Server error \(statusCode): \(body)")
  default:
    print("Client error: \(error)")
  }
} catch {
  print("Other error: \(error)")
}
```

## Idempotent Deletes

Deletion operations accept an `idempotently` parameter. When `true`, the client returns success even if the resource doesn't exist (404):

```swift
try await client.deleteQueue("my-queue", in: "/", idempotently: true)
try await client.deleteUser("my-user", idempotently: true)
```

## JSONValue

The `JSONValue` enum provides type-safe construction of JSON values for arguments and definitions:

```swift
var args: [String: JSONValue] = [:]
args["x-max-length"] = .int(10000)
args["x-overflow"] = .string("reject-publish")
args["x-single-active-consumer"] = .bool(true)
args["x-dead-letter-strategy"] = .object(["type": .string("at-most-once")])

let params = QueueParams.quorumQueue("my-queue", in: "/", arguments: args)
try await client.declareQueue(params)
```

## Security & TLS Configuration

The client delegates TLS and certificate handling to URLSession, following Apple's design patterns.
[Peer certificate chain verification](https://www.rabbitmq.com/docs/ssl#peer-verification) using system root CA certificates
is **enabled by default** for HTTPS endpoints.

### Default Peer Certificate Chain Verification

```swift
// Automatically verifies the server's certificate chain and rejects invalid/self-signed certs
let client = Client(
  endpoint: "https://rabbitmq.example.com:15671/api",
  username: "guest",
  password: "guest"
)
```

### Certificate Pinning (Custom Peer Certificate Chain Verification)

Restrict connections to specific certificates for additional security:

```swift
import Foundation

class PinningDelegate: NSObject, URLSessionDelegate {
  let pinnedCertificates: [SecCertificate]

  init(certificates: [Data]) {
    self.pinnedCertificates = certificates.compactMap { data in
      SecCertificateCreateWithData(nil, data as CFData)
    }
  }

  func urlSession(
    _ session: URLSession,
    didReceive challenge: URLAuthenticationChallenge,
    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
  ) {
    guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
          let serverTrust = challenge.protectionSpace.serverTrust else {
      completionHandler(.cancelAuthenticationChallenge, nil)
      return
    }

    // Validate the server's trust chain against the system root CAs first
    var secResult = SecTrustResultType.invalid
    let status = SecTrustEvaluate(serverTrust, &secResult)
    guard status == errSecSuccess else {
      completionHandler(.cancelAuthenticationChallenge, nil)
      return
    }

    // Then verify that at least one certificate in the chain matches a pinned certificate
    for i in 0..<SecTrustGetCertificateCount(serverTrust) {
      if let cert = SecTrustGetCertificateAtIndex(serverTrust, i) {
        for pinnedCert in pinnedCertificates {
          if cert == pinnedCert {
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
            return
          }
        }
      }
    }

    // If no pinned certificate matched, reject the connection
    completionHandler(.cancelAuthenticationChallenge, nil)
  }
}

let certData = try Data(contentsOf: URL(fileURLWithPath: "/path/to/server.cer"))
let config = URLSessionConfiguration.default
let session = URLSession(configuration: config, delegate: PinningDelegate(certificates: [certData]), delegateQueue: nil)

let client = Client(
  endpoint: "https://rabbitmq.example.com:15671/api",
  username: "guest",
  password: "guest",
  session: session
)
```

### Mutual TLS (Mutual Peer Certificate Chain Verification), Client Certificate Configuration

Use client certificates for mTLS (mutual [peer certificate chain verification](https://www.rabbitmq.com/docs/ssl#peer-verification)):

```swift
class ClientCertificateDelegate: NSObject, URLSessionDelegate {
  let identity: SecIdentity
  let certificate: SecCertificate

  init(pkcs12Data: Data, password: String) throws {
    // Extract client identity and certificate from a PKCS#12 file
    var importResult: CFArray?
    let status = SecPKCS12Import(
      pkcs12Data as CFData,
      [kSecImportExportPassphrase as String: password] as CFDictionary,
      &importResult
    )

    guard status == errSecSuccess,
          let result = importResult as? [[String: Any]],
          let firstItem = result.first,
          let identity = firstItem[kSecImportItemIdentity as String] as? SecIdentity,
          let cert = firstItem[kSecImportItemCertificate as String] as? SecCertificate
    else {
      throw NSError(domain: "ClientCert", code: Int(status))
    }

    self.identity = identity
    self.certificate = cert
  }

  func urlSession(
    _ session: URLSession,
    didReceive challenge: URLAuthenticationChallenge,
    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
  ) {
    // Respond only to client certificate requests; delegate all other challenges
    if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodClientCertificate {
      let credential = URLCredential(
        identity: identity,
        certificates: [certificate],
        persistence: .forSession
      )
      completionHandler(.useCredential, credential)
    } else {
      completionHandler(.performDefaultHandling, nil)
    }
  }
}

let pkcs12Data = try Data(contentsOf: URL(fileURLWithPath: "/path/to/client.p12"))
let delegate = try ClientCertificateDelegate(pkcs12Data: pkcs12Data, password: "password")
let config = URLSessionConfiguration.default
let session = URLSession(configuration: config, delegate: delegate, delegateQueue: nil)

let client = Client(
  endpoint: "https://rabbitmq.example.com:15671/api",
  username: "guest",
  password: "guest",
  session: session
)
```

### Self-Signed Certificates (Testing Only)

⚠️ Self-signed certificate use should be limited to development and testing environments.
Consider using [`tls-gen`](https://github.com/rabbitmq/tls-gen) to generate a self-signed CA and certificate chains
for local development.

```swift
class SelfSignedDelegate: NSObject, URLSessionDelegate {
  func urlSession(
    _ session: URLSession,
    didReceive challenge: URLAuthenticationChallenge,
    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
  ) {
    // IMPORTANT: This effectively disables peer certificate chain verification by accepting any and every server certificate
    // chain. Use this configuration in development and testing environments, NOT in production.
    if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
       let serverTrust = challenge.protectionSpace.serverTrust {
      completionHandler(.useCredential, URLCredential(trust: serverTrust))
    } else {
      completionHandler(.performDefaultHandling, nil)
    }
  }
}

let session = URLSession(
  configuration: .default,
  delegate: SelfSignedDelegate(),
  delegateQueue: nil
)

let client = Client(
  endpoint: "https://localhost:15671/api",
  username: "guest",
  password: "guest",
  session: session
)
```

## License

Copyright (C) 2025-2026 Michael S. Klishin and Contributors

Licensed under the Apache License, Version 2.0. See LICENSE for details.
