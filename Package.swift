// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "calverge-cli",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "calverge",
            targets: ["calverge"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.1"),
    ],
    targets: [
        .executableTarget(
            name: "calverge",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Sources"
        ),
    ]
)
