// swift-tools-version: 6.1
// Umbrella package: aggregates packages/* for remote SPM consumers and root `swift test`.
// Each package under packages/ also has its own Package.swift for isolated development.

import CompilerPluginSupport
import PackageDescription

let package = Package(
  name: "swift_monorepo",
  platforms: [.macOS(.v13), .iOS(.v16), .tvOS(.v16), .watchOS(.v9), .macCatalyst(.v16)],
  products: [
    .library(
      name: "JsonCodable",
      targets: ["JsonCodable"]
    ),
    .executable(
      name: "JsonCodableClient",
      targets: ["JsonCodableClient"]
    ),
    .library(
      name: "Navigator",
      targets: ["Navigator"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0")
  ],
  targets: [
    .macro(
      name: "JsonCodableMacros",
      dependencies: [
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
      ],
      path: "packages/JsonCodable/Sources/JsonCodableMacros"
    ),
    .target(
      name: "JsonCodable",
      dependencies: ["JsonCodableMacros"],
      path: "packages/JsonCodable/Sources/JsonCodable"
    ),
    .executableTarget(
      name: "JsonCodableClient",
      dependencies: ["JsonCodable"],
      path: "packages/JsonCodable/Sources/JsonCodableClient",
      resources: [.process("user.json")]
    ),
    .testTarget(
      name: "JsonCodableTests",
      dependencies: [
        "JsonCodable",
        "JsonCodableMacros",
        .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
      ],
      path: "packages/JsonCodable/Tests/JsonCodableTests"
    ),
    .target(
      name: "Navigator",
      path: "packages/Navigator/Sources/Navigator"
    ),
    .testTarget(
      name: "NavigatorTests",
      dependencies: ["Navigator"],
      path: "packages/Navigator/Tests/NavigatorTests"
    ),
  ]
)
