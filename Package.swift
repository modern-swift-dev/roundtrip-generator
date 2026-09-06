// swift-tools-version:6.2
import PackageDescription

let testSwiftSettings: [SwiftSetting] = [
    .enableExperimentalFeature("StrictConcurrency"),
    .enableUpcomingFeature("MemberImportVisibility")
]

let swiftSettings: [SwiftSetting] = testSwiftSettings + [
    .enableUpcomingFeature("ExistentialAny")
]

let package = Package(
    name: "RoundtripGenerator",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .tvOS(.v18),
        .watchOS(.v11),
        .visionOS(.v2)
    ],
    products: [
        .library(name: "SwiftApiGenerator", targets: ["SwiftApiGenerator"]),
        .library(name: "SwiftVaporGenerator", targets: ["SwiftVaporGenerator"]),
        .library(name: "KotlinApiGenerator", targets: ["KotlinApiGenerator"]),
        .library(name: "KotlinAndroidApiGenerator", targets: ["KotlinAndroidApiGenerator"]),
        .library(name: "KotlinSpringBootGenerator", targets: ["KotlinSpringBootGenerator"]),
        .library(name: "TypeScriptApiGenerator", targets: ["TypeScriptApiGenerator"]),
        .library(name: "OpenApiYamlGenerator", targets: ["OpenApiYamlGenerator"]),
        .library(name: "GeneratorModels", targets: ["GeneratorModels"]),
        .library(name: "GeneratorBuilder", targets: ["GeneratorBuilder"])
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "603.0.2"),
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", exact: "1.5.0")
    ],
    targets: [
        .target(
            name: "GeneratorBuilder",
            dependencies: [],
            path: "Sources/GeneratorBuilder",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "GeneratorModels",
            dependencies: ["GeneratorBuilder"],
            path: "Sources/GeneratorModels",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SwiftApiGenerator",
            dependencies: [
                "GeneratorBuilder",
                "GeneratorModels",
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "SwiftBasicFormat", package: "swift-syntax")
            ],
            path: "Sources/SwiftApiGenerator",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SwiftVaporGenerator",
            dependencies: [
                "GeneratorBuilder",
                "GeneratorModels",
                "SwiftApiGenerator",
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "SwiftBasicFormat", package: "swift-syntax")
            ],
            path: "Sources/SwiftVaporGenerator",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "KotlinApiGenerator",
            dependencies: [
                "GeneratorBuilder",
                "GeneratorModels"
            ],
            path: "Sources/KotlinApiGenerator",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "KotlinAndroidApiGenerator",
            dependencies: [
                "GeneratorBuilder",
                "GeneratorModels"
            ],
            path: "Sources/KotlinAndroidApiGenerator",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "KotlinSpringBootGenerator",
            dependencies: [
                "GeneratorBuilder",
                "GeneratorModels"
            ],
            path: "Sources/KotlinSpringBootGenerator",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "TypeScriptApiGenerator",
            dependencies: [
                "GeneratorBuilder",
                "GeneratorModels"
            ],
            path: "Sources/TypeScriptApiGenerator",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "OpenApiYamlGenerator",
            dependencies: [
                "GeneratorBuilder",
                "GeneratorModels"
            ],
            path: "Sources/OpenApiYamlGenerator",
            swiftSettings: swiftSettings
        ),
        // MARK: - Test Targets
        .testTarget(
            name: "GeneratorBuilderTests",
            dependencies: ["GeneratorBuilder"],
            swiftSettings: testSwiftSettings
        ),
        .testTarget(
            name: "GeneratorModelsTests",
            dependencies: ["GeneratorModels"],
            swiftSettings: testSwiftSettings
        ),
        .testTarget(
            name: "KotlinApiGeneratorTests",
            dependencies: [
                "GeneratorBuilder",
                "GeneratorModels",
                "KotlinApiGenerator"
            ],
            path: "Tests/KotlinApiGeneratorTests",
            swiftSettings: testSwiftSettings
        ),
        .testTarget(
            name: "KotlinAndroidApiGeneratorTests",
            dependencies: [
                "GeneratorBuilder",
                "GeneratorModels",
                "KotlinAndroidApiGenerator"
            ],
            path: "Tests/KotlinAndroidApiGeneratorTests",
            swiftSettings: testSwiftSettings
        ),
        .testTarget(
            name: "KotlinSpringBootGeneratorTests",
            dependencies: [
                "GeneratorBuilder",
                "GeneratorModels",
                "KotlinSpringBootGenerator"
            ],
            path: "Tests/KotlinSpringBootGeneratorTests",
            swiftSettings: testSwiftSettings
        ),
        .testTarget(
            name: "TypeScriptApiGeneratorTests",
            dependencies: [
                "GeneratorBuilder",
                "GeneratorModels",
                "TypeScriptApiGenerator"
            ],
            path: "Tests/TypeScriptApiGeneratorTests",
            swiftSettings: testSwiftSettings
        ),
        .testTarget(
            name: "SwiftApiGeneratorTests",
            dependencies: [
                "GeneratorBuilder",
                "GeneratorModels",
                "SwiftApiGenerator"
            ],
            path: "Tests/SwiftApiGeneratorTests",
            swiftSettings: testSwiftSettings
        ),
        .testTarget(
            name: "SwiftVaporGeneratorTests",
            dependencies: [
                "GeneratorBuilder",
                "GeneratorModels",
                "SwiftVaporGenerator"
            ],
            path: "Tests/SwiftVaporGeneratorTests",
            swiftSettings: testSwiftSettings
        ),
        .testTarget(
            name: "OpenApiYamlGeneratorTests",
            dependencies: [
                "GeneratorBuilder",
                "GeneratorModels",
                "OpenApiYamlGenerator"
            ],
            path: "Tests/OpenApiYamlGeneratorTests",
            swiftSettings: testSwiftSettings
        )
    ],
    swiftLanguageModes: [.v6]
)
