// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "PlayerKit",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "PlayerKit",
            targets: ["PlayerKit"]
        )
    ],
    targets: [
        .target(
            name: "PlayerKit",
            dependencies: ["KTVHTTPCache"],
            path: "Sources/PlayerKit",
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
        .binaryTarget(
            name: "KTVHTTPCache",
            path: "../../KTVHTTPCache.xcframework"
        )
    ]
)
