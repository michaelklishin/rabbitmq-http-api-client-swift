# Instructions for AI Agents

## Overview

This is a Swift 6 client for the [RabbitMQ HTTP API](https://www.rabbitmq.com/docs/management#http-api).
It provides an async client for managing and monitoring RabbitMQ clusters via the HTTP API.

See [CONTRIBUTING.md](./CONTRIBUTING.md) for test running instructions and development setup.

## Target Swift Version

This library targets Swift 6 and uses strict concurrency checking (`swift-6` language mode).

## Build System

This is a Swift Package Manager project. Standard SPM commands apply:

 * `swift build` to build
 * `swift test` to run tests
 * `swift test --filter {pattern}` to run a subset of tests
 * `swift package resolve` to resolve dependencies

Always run `swift build` before making changes to verify the codebase compiles cleanly.
If compilation fails, investigate and fix compilation errors before proceeding with any modifications.

### Linting and Formatting

 * Use [swift-format](https://github.com/swiftlang/swift-format) for code formatting: `swift-format format --in-place --recursive Sources/ Tests/`
 * Use [swift-format](https://github.com/swiftlang/swift-format) for lint checking: `swift-format lint --recursive Sources/ Tests/`

Configure formatting rules in `.swift-format` at the project root.

## The Client

This library provides an async client that uses Swift's structured concurrency (`async`/`await`).
All client methods are `async` and are designed to be used with Swift's concurrency model.

The client should be `Sendable` and safe to use from multiple concurrent tasks.

## Key Files

 * Client: `Sources/RabbitMQHTTPAPIClient/Client.swift`
 * Domain models (responses): `Sources/RabbitMQHTTPAPIClient/Responses/`
 * Request parameter types: `Sources/RabbitMQHTTPAPIClient/Requests/`
 * `Package.swift` for dependencies and targets
 * `README.md`: not just a `README`, it also acts as a poor person's documentation guide with lots of code examples

## Test Suite Layout

 * Integration tests: `Tests/RabbitMQHTTPAPIClientTests/` (require a running RabbitMQ node with the management plugin)
 * Unit tests: `Tests/UnitTests/` (no RabbitMQ needed)
 * Property-based tests: `Tests/PropertyBasedTests/` (no RabbitMQ needed)

### Running Tests

Tests require a RabbitMQ node with the management plugin enabled.

Use the [RabbitMQ community OCI image](https://github.com/docker-library/rabbitmq):

```shell
docker run -it --rm --name rabbitmq -p 5672:5672 -p 15672:15672 rabbitmq:4-management

# in a separate shell
# Configure the broker for faster stats emission and create test vhost
SWIFT_HTTP_API_CLIENT_RABBITMQCTL="DOCKER:rabbitmq" bin/ci/before_build.sh

swift test
```

### Test Filters

To run a specific test class or method:

 * `swift test --filter RabbitMQHTTPAPIClientTests` to run all integration tests
 * `swift test --filter UnitTests` to run all unit tests
 * `swift test --filter PropertyBasedTests` to run all property-based tests
 * `swift test --filter RabbitMQHTTPAPIClientTests.QueueTests/testListQueues` to run a specific test method

### Property-based Tests

Property-based tests are written using [SwiftCheck](https://github.com/typelift/SwiftCheck) and
use a naming convention: they begin with `prop_`.

To run the property-based tests specifically, use `swift test --filter PropertyBasedTests`.

## Dependencies

 * HTTP client: use [swift-http-client](https://github.com/swift-server/async-http-client) (AsyncHTTPClient) or Foundation's `URLSession`
 * JSON: use `Codable` with `JSONEncoder`/`JSONDecoder` (Foundation, no external dependency needed)
 * Property-based testing: [SwiftCheck](https://github.com/typelift/SwiftCheck)
 * Assertions in tests: use XCTest or [Swift Testing](https://developer.apple.com/documentation/testing) (`import Testing`)

Prefer Swift Testing (`import Testing`, `@Test`, `#expect`) over XCTest for new tests when possible.

## Source of Domain Knowledge

 * [RabbitMQ HTTP API Reference](https://www.rabbitmq.com/docs/http-api-reference)
 * [RabbitMQ Documentation](https://www.rabbitmq.com/docs/)
 * Rust client (sibling repo): `../rabbitmq-http-api-client-rs.git` for API design reference
 * Java client (sibling repo): `../hop.git` for API coverage reference

Treat the RabbitMQ documentation as the ultimate first party source of truth.

## Change Log

If asked to perform change log updates, consult and modify `CHANGELOG.md` and stick to its
existing writing style.

## Releases

### How to Roll (Produce) a New Release

Since this is a Swift Package, releases are driven by git tags. Swift Package Manager
resolves versions from tags.

To produce a new release:

 1. Update the changelog: replace `(in development)` with today's date, e.g. `(Feb 20, 2026)`. Make sure all notable changes since the previous release are listed
 2. Commit with the message `0.N.0` (just the version number, nothing else)
 3. Tag the commit: `git tag v0.N.0`
 4. Add a new `## v0.(N+1).0 (in development)` section to `CHANGELOG.md` with `No changes yet.` underneath
 5. Commit with the message `Bump dev version`
 6. Push: `git push && git push --tags`

### GitHub Actions

For verifying YAML file syntax, use `yq`, Ruby or Python YAML modules (whichever is available).

## Comments

 * Only add very important comments, both in tests and in the implementation
 * Keep comments concise and to the point

## Git Commits

 * Do not commit changes automatically without explicit permission to do so
 * Never add yourself as a git commit coauthor
 * Never mention yourself in commit messages in any way (no "Generated by", no AI tool links, etc)

## Writing Style Guide

 * Never add full stops to Markdown list items
 * Use backticks for variable names, method names, and type names
 * Show complete, compilable code examples when possible
 * Avoid "foo", "bar" and similar dummy variable names or values. "conn", "ch", "q", "s", and "x" are OK
   in code examples when they refer to a connection, a channel, a queue, a stream or an exchange
   that play a key role in the example
 * "virtual host" in documentation, even if `vhost` is used in the code
 * Client methods use specific parameter names: `in:`, `of:`, `for:`, do not change them
