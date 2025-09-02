// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CachePX",
    platforms: [
        .iOS(.v14),
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "CachePX",
            targets: [
                "CachePX"
            ]
        )
    ],
    targets: [
        .target(
            name: "CachePX",
            dependencies: [
                "CachePXCore"
            ]
        ),
        .target(
            name: "CachePXCore",
            dependencies: [
                "OpenCV"
            ],
            path: "Sources/CachePXCore",
            publicHeadersPath: "."
        ),
        .binaryTarget(
            name: "OpenCV",
            path: "Frameworks/opencv2.xcframework"
        )
    ]
)
