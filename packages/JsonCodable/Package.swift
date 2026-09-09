// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "JsonCodable",
    platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6), .macCatalyst(.v13)],
    products: [
        .library(
            name: "JsonCodable",
            targets: ["JsonCodable"]
        ),
        .executable(
            name: "JsonCodableClient",
            targets: ["JsonCodableClient"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0"),
    ],
    targets: [
        .macro(
            name: "JsonCodableMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),

        .target(name: "JsonCodable", dependencies: ["JsonCodableMacros"]),

        .executableTarget(
            name: "JsonCodableClient",
            dependencies: ["JsonCodable"],
            resources: [.process("user.json")]
        ),

        .testTarget(
            name: "JsonCodableTests",
            dependencies: [
                "JsonCodable",
                "JsonCodableMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ]
)
