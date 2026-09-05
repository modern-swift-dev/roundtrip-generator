---
title: "Roundtrip Generator"
description: "Describe an API once in Swift and generate clients, server scaffolding, and OpenAPI documentation."
---

# Roundtrip Generator

Describe an API once in Swift and generate clients, server scaffolding, and OpenAPI documentation.

[Read the API generation tutorial](/docs/roundtrip-generator/documentation/api-generation/) or [browse all API references](/docs/roundtrip-generator/documentation/).

## Generate seven output formats

- **SwiftApiGenerator**: Swift clients using RoundTrip and RoundTripREST.
- **SwiftVaporGenerator**: Vapor server projects and generated server files.
- **KotlinApiGenerator**: Kotlin Multiplatform clients.
- **KotlinAndroidApiGenerator**: Native Android clients using Retrofit and OkHttp.
- **KotlinSpringBootGenerator**: Spring Boot server projects.
- **TypeScriptApiGenerator**: TypeScript clients with optional TanStack Query helpers.
- **OpenApiYamlGenerator**: OpenAPI YAML.
- **GeneratorModels**: Shared API description types.
- **GeneratorBuilder**: Shared text-generation primitives.

## Get started

Use Swift 6.2 or later and macOS 15 or later for the included generator executable. The package depends on SwiftSyntax 603.0.2 or later within the 603.x release series.

Build an `ApiPackage` with `GeneratorModels`, then pass it to a generator to write output. Generated Swift clients depend on [roundtrip-swift](https://github.com/modern-swift-dev/roundtrip-swift); generated Vapor servers depend on Vapor.

The [tutorial](/docs/roundtrip-generator/documentation/api-generation/) covers all seven output formats, runtime dependencies, typed builder closures, output policies, and integration with existing projects.

## Samples and validation

The repository includes a sample executable that generates all seven formats. Run `./samples/generate.sh` from the repository root to regenerate samples, compile TypeScript, and validate OpenAPI. This command requires zsh, Swift, npm, and the `redocly` CLI.

See the [repository README](https://github.com/modern-swift-dev/roundtrip-generator/blob/main/README.md) for sample commands and platform validation requirements.

