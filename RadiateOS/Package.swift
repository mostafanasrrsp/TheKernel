
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "RadiateOS",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "RadiateOS",
            targets: ["RadiateOS"]),
    ],
    dependencies: [
        // Add any external dependencies here
    ],
    targets: [
        .target(
            name: "RadiateOS",
            dependencies: []),
        .testTarget(
            name: "RadiateOSTests",
            dependencies: ["RadiateOS"]),
    ]
)
