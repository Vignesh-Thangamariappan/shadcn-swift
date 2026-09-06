// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "shadcn-swift",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "shadcn-swift", targets: ["ShadcnSwiftCLI"]),
        .executable(name: "shadcn-swift-mcp", targets: ["ShadcnSwiftMCP"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
        .package(url: "https://github.com/modelcontextprotocol/swift-sdk.git", from: "0.11.0")
    ],
    targets: [
        .target(
            name: "ShadcnSwiftKit"
        ),
        .executableTarget(
            name: "ShadcnSwiftCLI",
            dependencies: [
                "ShadcnSwiftKit",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .executableTarget(
            name: "ShadcnSwiftMCP",
            dependencies: [
                "ShadcnSwiftKit",
                .product(name: "MCP", package: "swift-sdk")
            ]
        ),
        .testTarget(
            name: "ShadcnSwiftKitTests",
            dependencies: ["ShadcnSwiftKit"]
        )
    ]
)
