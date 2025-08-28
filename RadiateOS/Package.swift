// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "RadiateOS",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "RadiateOS",
            targets: ["RadiateOS"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "RadiateOS",
            dependencies: [],
            path: "RadiateOS",
            resources: [
                .process("Assets.xcassets")
            ]
        ),
        .testTarget(
            name: "RadiateOSTests",
            dependencies: ["RadiateOS"],
            path: "RadiateOSTests"
        )
    ]
)