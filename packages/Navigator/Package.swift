// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "Navigator",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .macCatalyst(.v16),
    ],
    products: [
        .library(
            name: "Navigator",
            targets: ["Navigator"]
        ),
    ],
    targets: [
        .target(
            name: "Navigator"
        ),
        .testTarget(
            name: "NavigatorTests",
            dependencies: ["Navigator"]
        ),
    ]
)
