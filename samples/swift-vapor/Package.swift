// swift-tools-version:6.0
// Generated code. Do not edit.
import PackageDescription

let package = Package(
    name: "GeneratedApi",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .library(name: "App", targets: ["App"]),
        .executable(name: "Run", targets: ["Run"])
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.121.4")
    ],
    targets: [
        .target(
            name: "App",
            dependencies: [
                .product(name: "Vapor", package: "vapor")
            ]
        ),
        .executableTarget(
            name: "Run",
            dependencies: [
                .target(name: "App")
            ]
        )
    ]
)
