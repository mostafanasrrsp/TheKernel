// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "RadiateOSUI",
    platforms: [
        .macOS(.v11),
    ],
    products: [
        .executable(
            name: "radiateos-ui",
            targets: ["RadiateOSUI"]
        ),
    ],
    dependencies: [
        // Linux-compatible dependencies
    ],
    targets: [
        .executableTarget(
            name: "RadiateOSUI",
            dependencies: [],
            path: ".",
            sources: ["main.swift"],
            linkerSettings: [
                .linkedLibrary("X11"),
                .linkedLibrary("GL"),
                .linkedLibrary("pthread"),
            ]
        ),
    ]
)