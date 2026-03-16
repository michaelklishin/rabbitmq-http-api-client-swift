// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "RabbitMQHTTPAPIClient",
  platforms: [
    .macOS(.v14),
    .iOS(.v17),
    .tvOS(.v17),
    .watchOS(.v10),
  ],
  products: [
    .library(
      name: "RabbitMQHTTPAPIClient",
      targets: ["RabbitMQHTTPAPIClient"]),
  ],
  dependencies: [
    .package(url: "https://github.com/michaelklishin/bunny-swift.git", branch: "main"),
  ],
  targets: [
    .target(
      name: "RabbitMQHTTPAPIClient",
      swiftSettings: [
        .swiftLanguageMode(.v6),
      ]),
    .testTarget(
      name: "RabbitMQHTTPAPIClientTests",
      dependencies: [
        "RabbitMQHTTPAPIClient",
        .product(name: "BunnySwift", package: "bunny-swift"),
      ],
      swiftSettings: [
        .swiftLanguageMode(.v6),
      ]),
    .testTarget(
      name: "UnitTests",
      dependencies: ["RabbitMQHTTPAPIClient"],
      swiftSettings: [
        .swiftLanguageMode(.v6),
      ]),
  ]
)
