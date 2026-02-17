// swift-tools-version: 6.0

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "PlayerKit",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "PlayerKit",
            targets: ["PlayerKit"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "601.0.1")
    ],
    targets: [
        // 宏实现目标（编译器插件）
        .macro(
            name: "PlayerKitMacros",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ],
            path: "Sources/PlayerKitMacros"
        ),
        // 主库目标
        .target(
            name: "PlayerKit",
            dependencies: [
                "KTVHTTPCache",
                "PlayerKitMacros"
            ],
            path: "Sources/PlayerKit",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .binaryTarget(
            name: "KTVHTTPCache",
            path: "../../KTVHTTPCache.xcframework"
        )
    ]
)
