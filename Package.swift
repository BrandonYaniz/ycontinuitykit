// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "ContinuityKit",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "ContinuityKit", targets: ["ContinuityKit"])
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "7.0.0")
    ],
    targets: [
        .target(
            name: "ContinuityKit",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift")
            ],
            path: "yContinuityKit"
        ),
        .testTarget(
            name: "ContinuityKitTests",
            dependencies: ["ContinuityKit"],
            path: "yContinuityKitTests"
        )
    ]
)
