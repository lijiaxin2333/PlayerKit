// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "MixedListKit",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "MixedListKit",
            targets: ["MixedListKit"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/Instagram/IGListKit", from: "5.0.0"),
        .package(path: "../BizPlayerKit")
    ],
    targets: [
        .target(
            name: "MixedListKit",
            dependencies: [
                .product(name: "IGListKit", package: "IGListKit"),
                .product(name: "BizPlayerKit", package: "BizPlayerKit")
            ],
            path: "Sources/MixedListKit"
        )
    ]
)
