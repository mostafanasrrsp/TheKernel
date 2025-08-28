// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "TheKernel",
    platforms: [
        .macOS(.v13), .iOS(.v16), .tvOS(.v16), .watchOS(.v9)
    ],
    products: [
        .library(name: "RadiateOS", targets: ["RadiateOS"])
    ],
    targets: [
        .target(name: "RadiateOS", path: "Sources/RadiateOS"),
        .testTarget(name: "RadiateOSTests", dependencies: ["RadiateOS"], path: "Tests/RadiateOSTests")
    ]
)

