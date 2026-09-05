// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "api",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v18),
        .macCatalyst(.v18),
        .macOS(.v15),
        .tvOS(.v18),
        .watchOS(.v11),
        .visionOS(.v2)
    ],
    products: [
        .library(name: "Api", targets: ["Api"])
    ],
    dependencies: [
        .package(url: "https://github.com/modern-swift-dev/roundtrip-swift.git", from: "1.0.1")
    ],
    targets: [
        .target(
            name: "Api",
            dependencies: [
                .product(name: "RoundTrip", package: "roundtrip-swift"),
                .product(name: "RoundTripREST", package: "roundtrip-swift")
            ],
            path: "src"
        )
    ],
    swiftLanguageModes: [.v6]
)
