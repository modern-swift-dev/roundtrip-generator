// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "RoundtripGeneratorSample",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "cli", targets: ["cli"])
    ],
    dependencies: [
        .package(path: "../..")
    ],
    targets: [
        .executableTarget(
            name: "cli",
            dependencies: [
                .product(name: "SwiftApiGenerator", package: "roundtrip-generator"),
                .product(name: "SwiftVaporGenerator", package: "roundtrip-generator"),
                .product(name: "KotlinApiGenerator", package: "roundtrip-generator"),
                .product(name: "KotlinAndroidApiGenerator", package: "roundtrip-generator"),
                .product(name: "KotlinSpringBootGenerator", package: "roundtrip-generator"),
                .product(name: "OpenApiYamlGenerator", package: "roundtrip-generator"),
                .product(name: "TypeScriptApiGenerator", package: "roundtrip-generator")
            ],
            path: "src",
        )
    ],
    swiftLanguageModes: [.v6],
)
