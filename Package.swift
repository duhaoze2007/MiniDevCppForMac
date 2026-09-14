// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MiniDevCpp",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "MiniDevCpp",
            path: "Sources",
            resources: [.process("Resources")],
            swiftSettings: [.swiftLanguageMode(.v5)]
        )
    ]
)
