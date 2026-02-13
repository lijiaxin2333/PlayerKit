// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ListKit",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "ListKit",
            targets: ["ListKit"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/Instagram/IGListKit", from: "5.0.0")
    ],
    targets: [
        .target(
            name: "ListKit",
            dependencies: [
                .product(name: "IGListKit", package: "IGListKit")
            ],
            path: "Sources/ListKit"
        )
    ]
)
