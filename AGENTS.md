# Instructions for AI Agents

## Overview

This is a Swift 6 client for the [RabbitMQ HTTP API](https://www.rabbitmq.com/docs/management#http-api).
It provides an async client for managing and monitoring RabbitMQ clusters via the HTTP API.

## Target Swift Version

This library targets Swift 6 and uses strict concurrency checking (`swift-6` language mode).

## Build and Test

This is a Swift Package Manager project:

```bash
swift build

swift-format format --in-place --recursive Sources/ Tests/
swift-format lint --recursive Sources/ Tests/

swift test
```

Always run `swift build` before making changes to verify the codebase compiles cleanly.
If compilation fails, investigate and fix compilation errors before proceeding with any modifications.

At the end of each task, run `swift-format format --in-place --recursive Sources/ Tests/`.

Configure formatting rules in `.swift-format` at the project root.

## Repository Layout

 * `Sources/RabbitMQHTTPAPIClient/Client.swift`: the async client
 * `Sources/RabbitMQHTTPAPIClient/Responses.swift`: domain models (response types)
 * `Sources/RabbitMQHTTPAPIClient/Requests.swift`: request parameter types
 * `Sources/RabbitMQHTTPAPIClient/Commons.swift`: shared enums and types
 * `Sources/RabbitMQHTTPAPIClient/Errors.swift`: error types
 * `Sources/RabbitMQHTTPAPIClient/PathEncoding.swift`: RFC 3986 path segment encoding
 * `Package.swift`: dependencies and targets
 * `README.md`: not just a `README`, it also acts as a poor person's documentation guide with lots of code examples

## The Client

This library provides an async client that uses Swift's structured concurrency (`async`/`await`).
All client methods are `async` and are designed to be used with Swift's concurrency model.

The client is `Sendable` and safe to use from multiple concurrent tasks.

## Key Dependencies

 * HTTP: Foundation's `URLSession` (no external HTTP client dependency)
 * JSON: `Codable` with `JSONEncoder`/`JSONDecoder` (Foundation)
 * Testing: [Swift Testing](https://developer.apple.com/documentation/testing) (`import Testing`, `@Test`, `#expect`)
 * Property-based testing: [SwiftCheck](https://github.com/typelift/SwiftCheck)

Prefer Swift Testing over XCTest for new tests.

## Test Suite Layout

 * Integration tests: `Tests/RabbitMQHTTPAPIClientTests/` (require a running RabbitMQ node with the management plugin)
 * Unit tests: `Tests/UnitTests/` (no RabbitMQ needed)
 * Property-based tests: `Tests/PropertyBasedTests/` (no RabbitMQ needed)

### Running Tests

Integration tests require a RabbitMQ node with the management plugin enabled.

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

 * Only add important comments that express the non-obvious intent, both in tests and in the implementation
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
