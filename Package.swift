// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "shadcn-swift",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "shadcn-swift", targets: ["ShadcnSwiftCLI"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0")
    ],
    targets: [
        .executableTarget(
            name: "ShadcnSwiftCLI",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .testTarget(
            name: "ShadcnSwiftCLITests",
            dependencies: ["ShadcnSwiftCLI"]
        )
    ]
)
