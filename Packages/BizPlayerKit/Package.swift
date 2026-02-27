// swift-tools-version: 6.0

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "BizPlayerKit",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "BizPlayerKit",
            targets: ["BizPlayerKit"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "601.0.1")
    ],
    targets: [
        // 宏实现目标（编译器插件）
        .macro(
            name: "BizPlayerKitMacros",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ],
            path: "Sources/BizPlayerKitMacros"
        ),
        // 主库目标
        .target(
            name: "BizPlayerKit",
            dependencies: [
                "KTVHTTPCache",
                "BizPlayerKitMacros"
            ],
            path: "Sources/BizPlayerKit",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .binaryTarget(
            name: "KTVHTTPCache",
            path: "../../KTVHTTPCache.xcframework"
        ),
        // 测试目标
        .testTarget(
            name: "BizPlayerKitTests",
            dependencies: ["BizPlayerKit"],
            path: "Tests/BizPlayerKitTests",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        )
    ]
)
