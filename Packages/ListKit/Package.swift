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
        .package(url: "https://github.com/Instagram/IGListKit", from: "5.0.0"),
        .package(path: "../PlayerKit")
    ],
    targets: [
        .target(
            name: "ListKit",
            dependencies: [
                .product(name: "IGListKit", package: "IGListKit"),
                .product(name: "PlayerKit", package: "PlayerKit")
            ],
            path: "Sources/ListKit"
        )
    ]
)
