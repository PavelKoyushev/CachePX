// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CachePX",
    platforms: [
        .iOS(.v15),
        .macCatalyst(.v15)
    ],
    products: [
        .library(
            name: "CachePX",
            targets: [
                "CachePX"
            ]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/PavelKoyushev/OpenCV-package", from: "5.1.0")
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
                .product(name: "OpenCV", package: "OpenCV-package")
            ],
            path: "Sources/CachePXCore",
            publicHeadersPath: "."
        )
    ]
)
