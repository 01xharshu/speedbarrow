// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SpeedBarrow",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "SpeedBarrow", targets: ["SpeedBarrow"])
    ],
    targets: [
        .executableTarget(
            name: "SpeedBarrow",
            path: ".",
            exclude: ["README.md"]
        )
    ]
)
