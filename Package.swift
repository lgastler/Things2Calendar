// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Things2Calendar",
    platforms: [
        .macOS(.v14) // EventKit requestFullAccessToEvents requires macOS 14+
    ],
    products: [
        .executable(
            name: "Things2Calendar",
            targets: ["Things2Calendar"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.1"),
    ],
    targets: [
        .executableTarget(
            name: "Things2Calendar",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Sources"
        ),
    ]
)
