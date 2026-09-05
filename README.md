# Roundtrip Generator

Describe an API once in Swift and generate clients, server scaffolding, and OpenAPI documentation.

Read the [published documentation](https://modern-swift-dev.github.io/docs/roundtrip-generator/) for the API generation tutorial and API references.

## Products

- `SwiftApiGenerator`: Swift clients using [RoundTrip and RoundTripREST](https://github.com/modern-swift-dev/roundtrip-swift).
- `SwiftVaporGenerator`: Vapor server projects and generated server files.
- `KotlinApiGenerator`: Kotlin Multiplatform clients.
- `KotlinAndroidApiGenerator`: native Android clients using Retrofit and OkHttp.
- `KotlinSpringBootGenerator`: Spring Boot server projects.
- `TypeScriptApiGenerator`: TypeScript clients with optional TanStack Query helpers.
- `OpenApiYamlGenerator`: OpenAPI YAML.
- `GeneratorModels`: shared API description types.
- `GeneratorBuilder`: shared text-generation primitives.

## Usage

Use Swift 6.2 or later and macOS 15 or later for the included generator executable. The package depends on SwiftSyntax 603.0.2 or later within the 603.x release series. Add this package to your executable's `Package.swift`:

```swift
.package(path: "../roundtrip-generator")
```

Add the products you need to the executable target:

```swift
.product(name: "GeneratorModels", package: "roundtrip-generator"),
.product(name: "SwiftApiGenerator", package: "roundtrip-generator")
```

Build an `ApiPackage` with `GeneratorModels`, then pass it to a generator to write output. The [API generation tutorial](docs/api-generation.md) covers all seven output formats and their runtime dependencies. Generated Swift clients depend on `roundtrip-swift`; generated Vapor servers depend on Vapor.

A small schema can use typed builder closures and default imports:

```swift
import Foundation
import GeneratorModels
import SwiftApiGenerator

let user = ApiTypeSchema.object("User") {
    ApiModelProperty.string("name")
    ApiModelProperty.string("email").optional
}

let package = ApiPackage(
    name: "Example",
    targetDirUrl: URL(fileURLWithPath: "Generated")
) {
    ApiModule(name: "Admin") {
        ApiService(name: "Users", references: [user]) {
            .get(name: "list", path: .relative("/users"), response: .array(user.asRef))
        }
    }
}

try ApiPackageGenerator(package: package).write(outputPolicy: .replaceManagedFiles)
```

Array initializers remain supported. Reuse a contract with `package.output(to:)`, inspect output with `generatedFiles()`, and add type mappings with `.mapping(...)`. Project generators provide `.standaloneProject(...)` and `.existingProject(...)` options. See the tutorial's [migration notes](docs/api-generation.md#migration-notes) for required URL properties and removal of field-selection helpers.

The sample executable generates all seven formats. Run it from the `samples` directory because output paths are relative to the working directory:

```sh
(cd samples && swift run --package-path cli cli)
```

To generate from the repository root and validate TypeScript and OpenAPI together, use:

```sh
./samples/generate.sh
```

The script requires zsh, Swift, npm, and the `redocly` CLI. Generated output is checked in under `samples`.

To regenerate only the native Android client:

```sh
(cd samples && swift run --package-path cli cli --android-only)
```

## Validation

```sh
swift test
swift build --package-path samples/cli
swift build --package-path samples/swift-client
swift build --package-path samples/swift-vapor
./samples/kotlin/gradlew -p samples/kotlin build
./samples/kotlin/gradlew -p samples/android build
./samples/kotlin/gradlew -p samples/spring build
```

The Gradle builds require a compatible JDK. The Android client build also requires Android SDK 36 (`ANDROID_HOME` or `local.properties`). Run `./samples/generate.sh` to also compile TypeScript and validate OpenAPI; it regenerates the sample files and HTML documentation.
