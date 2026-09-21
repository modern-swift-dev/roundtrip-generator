# Code Generator Tutorial

This tutorial explains how to describe one REST API model in Swift and generate client, server, and documentation artifacts for existing projects.

## What It Generates

- `SwiftApiGenerator`: Swift REST client source files.
- `SwiftVaporGenerator`: Vapor server project scaffolding, controllers, request models, service protocols, runtime files, and optional `Package.swift`, run target, and Dockerfile.
- `KotlinApiGenerator`: Kotlin Multiplatform client project with generated runtime, Koin module, Gradle files, models, operations, and API services.
- `KotlinAndroidApiGenerator`: Android library using Retrofit, OkHttp, kotlinx.serialization, suspend services, and optional Koin bindings and mocks.
- `KotlinSpringBootGenerator`: Kotlin Spring Boot server project with controllers, service interfaces, request models, runtime files, application entry point, and Gradle files.
- `TypeScriptApiGenerator`: TypeScript client package, with optional TanStack Query helpers.
- `OpenApiYamlGenerator`: OpenAPI YAML file for documentation, contract review, and external tooling.
- `GeneratorModels`: public API description model types shared by every generator.
- `GeneratorBuilder`: small string/node builder primitives used internally by generators.

## Recommended Integration Shape

Use a dedicated generator executable instead of describing APIs inside application targets directly.

```text
YourRepo/
  api-generator/        Swift executable package, depends on roundtrip-generator
  ios-app/
  web-app/
  backend/
  generated/
```

That executable imports `GeneratorModels` plus the generator targets you need, builds one `ApiPackage`, and writes output into controlled generated directories. Commit the API description source. Commit generated output only if that matches your project workflow.

Generated output policy differs by generator:

- Swift client `ApiPackageGenerator.write()` atomically replaces `targetDirUrl` by default. Use `write(outputPolicy: .replaceManagedFiles)` to preserve handwritten files, or `.neverOverwriteExisting` to reject collisions. Keep whole-directory replacement confined to generated-only directories.
- Kotlin, TypeScript, Spring Boot, and Vapor generators use managed-file overwrite policies. Their default is to replace generated/managed files and avoid silently taking ownership of normal user files.
- Swift client generation writes source files only. You own the consuming `Package.swift` and any external dependencies.
- Vapor, Kotlin, Spring Boot, TypeScript, and OpenAPI generators can write broader project files depending on their options.

## Add the Generator to a Swift Executable

For local development, add this repository as a path dependency from your generator executable:

```swift
// api-generator/Package.swift
// swift-tools-version:6.2
import PackageDescription

let package = Package(
    name: "api-generator",
    platforms: [
        .macOS(.v15)
    ],
    dependencies: [
        .package(path: "../roundtrip-generator")
    ],
    targets: [
        .executableTarget(
            name: "ApiGenerator",
            dependencies: [
                .product(name: "GeneratorModels", package: "roundtrip-generator"),
                .product(name: "SwiftApiGenerator", package: "roundtrip-generator"),
                .product(name: "TypeScriptApiGenerator", package: "roundtrip-generator"),
                .product(name: "OpenApiYamlGenerator", package: "roundtrip-generator")
            ]
        )
    ],
    swiftLanguageModes: [.v6]
)
```

If you consume this package from Git, replace the path dependency with your repository URL and version, branch, or revision.

## First API Definition

Create a small executable that describes one resource and generates a Swift client.

```swift
import Foundation
import GeneratorModels
import SwiftApiGenerator

let output = URL(fileURLWithPath: "../ios-app/GeneratedApi/Sources/Api")

let user = ApiTypeSchema.object("User") {
    ApiModelProperty.string("name")
    ApiModelProperty.string("email").optional
}

let createUser = ApiTypeSchema.object(
    typeName: "CreateUserRequest",
    properties: [
        .string("name"),
        .string("email")
    ]
)

let usersDefinition = ApiService(
    name: "Users",
    operations: [
        .get(
            name: "get",
            path: .relative("/users/{user_id}"),
            security: .secured,
            parameters: [
                .path("user_id", .int64(), propertyName: "userId")
            ],
            response: user.asRef
        ),
        .post(
            name: "create",
            path: .relative("/users"),
            security: .secured,
            request: createUser.asRef,
            response: user.asRef,
            acceptableStatuses: [200, 201]
        )
    ],
    references: [
        user,
        createUser
    ]
)

let package = ApiPackage(
    name: "Example",
    targetDirUrl: output,
    modules: [
        ApiModule(name: "Admin", definitions: [usersDefinition])
    ]
)

try ApiPackageGenerator(package: package).write()
```

Run the executable:

```sh
swift run --package-path api-generator ApiGenerator
```

## Model Concepts

`ApiPackage` is the top-level contract. It contains modules, shared types, imported modules, output location, and generation flags. Reference and import collections default to empty. The Swift client generator supplies `Foundation`, `RoundTrip`, and `RoundTripREST` imports; use `imports` for additional dependencies.

`ApiModule` groups definitions and module-level shared models. Module names are used in directory structure and generated type names.

`ApiService` groups operations for one API surface, usually close to one backend service or controller. Definition names are used in generated file names and type names.

`ApiOperation` describes one endpoint: name, method, path, security, parameters, request type, response type, acceptable statuses, and extra imports. Convenience constructors exist for common verbs, including `get`, `post`, `postMultipart`, `patch`, `put`, and `delete`.

`ApiTypeSchema` describes generated or referenced payload types. Common shapes include objects, arrays, enums, dictionaries, binary/file payloads, dynamic objects, references, and generic references.

`ApiParameter` describes path, query, header, and cookie parameters. Parameters can be optional or immutable, can use custom property names, and can hold defaults depending on the data type.

`ApiAuthorizationHeaderPolicy` controls whether the generator injects authorization-related parameters. Secured operations include the predefined `Authorization` header parameter.

## Typed Collection Builders

Array initializers and typed builder closures are interchangeable. Builders accept single values, reusable arrays, `if`/`else`, and `for` loops while preserving declaration order:

```swift
let auditProperties: [ApiModelProperty] = [.date("created_at")]
let includeAudit = true

let project = ApiTypeSchema.object("Project") {
    .string("name")
    if includeAudit {
        auditProperties
    }
}

let projects = ApiService(name: "Projects", references: [project]) {
    .get(name: "list", path: .relative("/projects"), response: .array(project.asRef))
}

let module = ApiModule(name: "Admin") {
    projects
}

let package = ApiPackage(name: "Example", targetDirUrl: output) {
    module
}
```

`ApiRestResourceGroup` also accepts a resource builder closure. Each closure accepts only its schema element type; a property cannot accidentally appear in an operations block. Use explicit names such as `ApiModelProperty.string(...)` for consecutive declarations: Swift parses consecutive leading-dot expressions as one chained expression. Array initializers retain their usual `.string(...)` shorthand.

## Model Ownership and References

Declare a model once and reuse that value when registering it and creating `.asRef`:

```swift
let user = ApiTypeSchema.object("User") { .string("name") }
let users = ApiService(name: "Users", references: [user]) {
    .get(name: "get", path: .relative("/users"), response: user.asRef)
}
```

Choose the owner based on where the model is used:

| Declaration | Ownership |
| --- | --- |
| `ApiService(references:)` | Generated for that service definition |
| `ApiModule(references:)` | Generated once for that module |
| `ApiPackage(references:)` | Generated at the package root |
| `ApiPackage(commonReferences:)` | Supplied by another package; not generated here |
| `ApiPackage(referencedModules:)` | Modules supplied by parent packages |

`.asRef` references a declaration; it does not register it. Separately constructing another object named `User` creates another model identity. Swift validation reports the module, definition, operation, and missing type, with guidance when a same-named declaration has a different identity.

For externally supplied types without a schema declaration, use `.reference(typeName: "ExternalUser", strict: false)` and provide the target's imports/type mapping. Keep scope explicit to control generated names and ownership.

## Customize Type Mappings

Kotlin, Android, Spring Boot, and TypeScript options provide `.mapping(...)`. It preserves unrelated defaults and replaces an existing mapping with the same API type name:

```swift
let options = TypeScriptGeneratorOptions()
    .mapping(.init(
        apiTypeName: "ExternalUser",
        typeScriptType: "ExternalUser",
        imports: ["import type { ExternalUser } from \"domain-models\";"]
    ))
```

Passing `typeMappings:` to the initializer still replaces the entire mapping list. Use the fluent helper for normal additions and overrides.

## Preview Generated Output

All seven generators expose `generatedFiles()` so you can inspect relative paths and contents before writing:

```swift
let generator = ApiPackageGenerator(package: package)
for file in try generator.generatedFiles() {
    print(file.relativePath)
}
try generator.write(outputPolicy: .replaceManagedFiles)
```

Preview does not create or modify the destination. Swift writing validates automatically; a separate `ApiPackageValidator` call is only needed for an explicit Swift validation step. Swift managed writes reject collisions with handwritten files, remove stale marked generated Swift sources, and publish the result atomically.

## Manual Operations

Use manual operations when endpoint shape does not match a conventional REST resource.

```swift
let receipt = ApiTypeSchema.object(
    typeName: "UploadReceipt",
    properties: [
        .string("id"),
        .string("state")
    ]
)

let upload = ApiOperation.postMultipart(
    name: "uploadMultipart",
    path: .relative("/uploads/multipart"),
    security: .secured,
    parameters: [
        .query("compress", .bool(false)).optional,
        .header("X-Trace-Id", .string(), propertyName: "traceId").optional
    ],
    multiParts: [
        "file",
        "metadata"
    ],
    response: receipt.asRef,
    acceptableStatuses: [200, 201]
)
```

Useful path forms:

- `.relative("/users/{user_id}")`: relative API path with generated path substitution.
- `.absolute(...)`: absolute path when the generated request should keep a full URL.
- `.runtime`: path supplied by runtime/request values.

Use `extraImports` on an operation when only that generated operation needs an import.

## REST Resource Shorthand

`ApiRestResource` and `ApiRestResourceGroup` generate conventional create, update, patch, delete, get, and list operations from one resource declaration.

```swift
let project = ApiTypeSchema.object(
    typeName: "Project",
    properties: [
        .string("name"),
        .string("description").optional
    ]
)

let adminModule = ApiRestResourceGroup(
    name: "Admin",
    resources: [
        ApiRestResource(
            dataType: project,
            metadataProperties: [
                .date("createdAt"),
                .date("updatedAt")
            ]
        )
    ]
)
.module()
```

Default generated operations:

- `POST /project`: create.
- `PUT /project/{project_id}`: update.
- `PATCH /project/{project_id}`: patch.
- `DELETE /project/{project_id}`: delete.
- `GET /project/{project_id}`: get.
- `GET /project`: list.

For paged list operations, the generated response is `PagedResults<IdentifiedResource>`. For non-paged lists, the response is `[IdentifiedResource]`.

Conventional resource operations remain unsecured by default. Set `security: .secured` on a resource to add authorization parameters to its conventional operations. Custom `subOperations` keep their own security setting and are generated under the resource id path unless they use an absolute or runtime path.

Configure common conventions in one declaration:

```swift
let users = ApiRestResource(
    dataType: user,
    identifier: .uuid("id", pathParameterName: "user_id"),
    operationTypes: .readOnly,
    path: "/users",
    security: .secured
)
```

The typed identifier configures both the model property and path parameter representation. UUID identifiers use UUID model properties and string path parameters. `metadataProperties` defaults to empty. `.readOnly` selects get and list; `.crud` retains the conventional six operations. For explicit list behavior, use `.list(pagination: .array)` or `.list(pagination: .pagedResults)`. `.retrievable` is the correctly spelled alias for the legacy `.retievable` case. Path overrides also apply when nesting resources; model names and generated type names stay independent of URL paths.

## Generate Multiple Targets from One Model

Use one base `ApiPackage`, then call `output(to:)` for each destination. Copies retain model identities and reference scopes. Generator options remain target-specific.

```swift
import Foundation
import GeneratorModels
import SwiftApiGenerator
import TypeScriptApiGenerator
import OpenApiYamlGenerator

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)

let basePackage = ApiPackage(
    name: "Example",
    targetDirUrl: root.appendingPathComponent("generated/swift"),
    modules: [
        adminModule
    ]
)

try ApiPackageGenerator(package: basePackage).write()

let typeScriptPackage = basePackage.output(
    to: root.appendingPathComponent("generated/typescript")
)

try TypeScriptApiPackageGenerator(
    package: typeScriptPackage,
    options: TypeScriptGeneratorOptions(
        packageName: "example-api",
        packageVersion: "1.0.0",
        flavor: .tanStackQuery
    )
).write()

let openApiPackage = basePackage.output(
    to: root.appendingPathComponent("generated/openapi")
)

try OpenApiYamlPackageGenerator(
    package: openApiPackage,
    options: OpenApiYamlGeneratorOptions(
        title: "Example API",
        version: "1.0.0",
        servers: ["https://api.example.com"]
    )
).write()
```

The sample executable in `samples/cli` uses this pattern for Swift, Kotlin Multiplatform, Android, Spring Boot, TypeScript, OpenAPI, and Vapor output.

## Standalone and Existing Projects

Kotlin Multiplatform, Android, Spring Boot, TypeScript, and Vapor options expose named factories. `.standaloneProject(...)` retains the existing default scaffolding. `.existingProject(...)` emits generated sources and runtime support while the host owns project configuration:

```swift
try TypeScriptApiPackageGenerator(
    package: basePackage.output(to: root.appendingPathComponent("web-app")),
    options: .existingProject(sourceDirectory: "src/api", flavor: .tanStackQuery)
).write()
```

Use the full initializer with `layout: .existingProject` when you need additional configuration, such as a custom overwrite policy or optional mocks. Fluent mapping overrides preserve the selected layout.

| Target | Existing-project source location, relative to `targetDirUrl` | Host-owned setup |
| --- | --- | --- |
| Kotlin Multiplatform | `src/commonMain/kotlin/<basePackage>` | Existing module Gradle configuration and dependencies |
| Android | `src/main/kotlin/<basePackage>` | Existing module Gradle configuration, manifest, dependencies |
| Spring Boot | `src/main/kotlin/<basePackage>` | Gradle configuration and application entry point |
| TypeScript | Configured `sourceDirectory` | `package.json`, `tsconfig.json`, root exports, flavor dependencies |
| Vapor | `Sources/<moduleName>` | Manifest, `configure.swift`, run target, Dockerfile |

For Kotlin Multiplatform and Android, point `targetDirUrl` at the existing module root. For Vapor, register the generated routes from your application's configuration. Existing-project mode does not delete earlier standalone scaffolding; remove any obsolete project files deliberately when migrating layouts.

TypeScript standalone generation also supports custom directories such as `src/client` and `lib/client`, with matching package exports and compiler paths. The generator rejects paths that collide with its own files.

## Swift Client Integration

The Swift client generator writes only source files into `targetDirUrl`. The generated package manifest stays under your control.

Minimal consuming package shape:

```swift
// GeneratedApi/Package.swift
// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "GeneratedApi",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(name: "GeneratedApi", targets: ["GeneratedApi"])
    ],
    dependencies: [
        .package(url: "https://github.com/modern-swift-dev/roundtrip-swift.git", from: "1.0.1")
    ],
    targets: [
        .target(
            name: "GeneratedApi",
            dependencies: [
                .product(name: "RoundTrip", package: "roundtrip-swift"),
                .product(name: "RoundTripREST", package: "roundtrip-swift")
            ],
            path: "Sources/GeneratedApi"
        )
    ],
    swiftLanguageModes: [.v6]
)
```

Add any additional modules listed in `ApiPackage.imports` to your target dependencies. The generator adds the required `Foundation`, `RoundTrip`, and `RoundTripREST` imports automatically; the consuming manifest must still declare the RoundTrip products.

Recommended setup:

- Generate into a directory that contains only generated Swift files.
- Keep `Package.swift` and hand-written adapters outside `targetDirUrl`.
- Run the generator before `swift build` in CI.
- Run `swift test` or `swift build` for the consuming package after generation.

## Kotlin Multiplatform Client Integration

Use `KotlinApiPackageGenerator` for a generated KMP client project.

```swift
import KotlinApiGenerator

try KotlinApiPackageGenerator(
    package: kotlinPackage,
    options: KotlinGeneratorOptions(
        basePackage: "com.example.api",
        gradle: KotlinGradleOptions(
            projectName: "example-api",
            moduleName: "generated-api",
            namespace: "com.example.api",
            group: "com.example",
            version: "1.0.0"
        ),
        generateRuntime: true,
        generateKoinModule: true
    )
).write()
```

By default this writes a Gradle project with module `generated-api`, source under `generated-api/src/commonMain/kotlin`, runtime files, models, operation builders, API services, and Koin wiring.

Integration choices:

- Standalone generated project: publish the generated module to your internal Maven repository.
- Included build: include the generated project from an app Gradle build.
- Monorepo module: generate into a checked-in module directory and wire it from your root `settings.gradle.kts`.

Use `KotlinGradleOptions(overwritePolicy: .neverOverwriteExisting)` if you want generation to fail instead of replacing existing files.

## Native Kotlin Android Client Integration

Use `KotlinAndroidApiPackageGenerator` for an Android library built with Retrofit, OkHttp, kotlinx.serialization, and coroutine `suspend` services.

```swift
import KotlinAndroidApiGenerator

try KotlinAndroidApiPackageGenerator(
    package: androidPackage,
    options: KotlinAndroidGeneratorOptions(
        basePackage: "com.example.api",
        gradle: KotlinAndroidGradleOptions(
            projectName: "example-android-api",
            moduleName: "generated-api",
            group: "com.example",
            version: "1.0.0",
            artifactId: "example-android-api"
        ),
        generateRuntime: true,
        generateKoinModule: false,
        generateMocks: false
    )
).write()
```

The generated module uses `src/main/kotlin`, an Internet-permission manifest, AGP 9.2.1 built-in Kotlin, compile SDK 36, and minimum SDK 23. Its version catalog pins Retrofit 3.0.0 and OkHttp 4.12.0; `KotlinAndroidGradleOptions` exposes dependency versions. Kotlin and the serialization compiler plugin share one version. Java 17 bytecode, a Java 21 toolchain, and core library desugaring support the minimum Android version. The project includes ktlint configuration and a Maven `release` publication. ktlint checks handwritten tests and build scripts; generated main sources are excluded, with their deterministic formatting covered by generator tests.

Create a client with an app-owned `OkHttpClient` and suspend configuration providers:

```kotlin
val client = createRestClient(
    httpClient = OkHttpClient(),
    baseUrlProvider = BaseUrlProvider { "https://api.example.com" },
    apiKeyProvider = ApiKeyProvider { tokenStore.currentToken() },
    defaultHttpHeaderProvider = DefaultHttpHeaderProvider {
        mapOf("Accept-Language" to "en")
    },
    json = Json { ignoreUnknownKeys = true },
)
```

Pass this client to the generated service implementation. Each service interface exposes suspend functions with named, typed parameters and request bodies, including schema defaults. Typed responses return `ApiOperationResult<T>`: `value` contains the decoded model, and `response` retains status, headers, MIME type, and body bytes. Binary and bodyless operations return `ApiResponse`. Calls enforce the operation's declared acceptable statuses, including explicitly accepted non-2xx responses; coroutine cancellation propagates to the caller. Observe the client's shared `errors` flow for API failures.

Set `generateKoinModule: true` to generate `apiKoinModule(...)` bindings for services and module aggregates. Koin is optional; direct client construction works without it. Set `generateMocks: true` to generate service mocks with suspend handlers, recorded calls, and `resetMock()` support. Both options default to `false`.

File operations accept `ApiUploadSource.Bytes`, `ApiUploadSource.FileSource`, or `ApiUploadSource.ContentUri`. For example:

```kotlin
val upload = ApiUploadSource.ContentUri(uri, context.contentResolver)
// Pass upload as the generated file operation's body argument.
```

The runtime streams file and content-URI uploads, opens and closes each input stream, and supports unknown content lengths. The app supplies the `ContentResolver`, obtains and retains any required URI permission, and owns the `OkHttpClient` lifecycle. Upload operations expose an optional progress callback. Multipart parts support the same upload sources.

Generate and build the checked-in Android sample using the repository's Gradle 9.5.1 wrapper and an installed Android SDK:

```sh
(cd samples && swift run --package-path cli cli --android-only)
./samples/kotlin/gradlew -p samples/android build
```

For a separate generated project, use Gradle 9.5.1 or provision its wrapper. Publish the release artifact to Maven or include the generated module in your Android build. Managed-file protection and `KotlinAndroidGradleOptions(overwritePolicy: .neverOverwriteExisting)` follow the existing Kotlin generator's conventions.

## TypeScript Backend Integration

Use `TypeScriptBackendApiPackageGenerator` for an Express 5 and Zod 4 backend package. Generated routes support secured, optional-authentication, and unsecured relative operations. They parse and validate wire input, convert it to a mapped DTO for an application-owned handler, validate and serialize the handler result, and strip undeclared fields at both boundaries.

```swift
import TypeScriptBackendGenerator

try TypeScriptBackendApiPackageGenerator(
    package: backendPackage,
    options: .standaloneProject(packageName: "example-backend")
).write()
```

The generated package exposes `registerGeneratedRoutes(app:handlers:)` from `src/generated/routes.ts`. Register it in an existing Express application after choosing the application's error boundary:

```ts
import express from "express";
import { registerGeneratedRoutes } from "./generated/routes.js";

const app = express();
registerGeneratedRoutes(app, {
    adminUsersCreate: async (input) => input
});
```

Authentication and request context remain application-owned. Supply a request policy for every secured or optional-authentication policy used by the package; registration fails before installing routes when either required policy is missing. An unsecured policy is optional, and unsecured handlers receive `undefined` when it is omitted.

```ts
const integration = {
    secured: {
        middleware: [requireSession],
        context: (_request, response) => ({
            user: response.locals.user,
            requestId: response.locals.requestId
        })
    },
    optional: {
        middleware: [loadOptionalSession],
        context: (_request, response) => ({
            user: response.locals.user ?? null,
            requestId: response.locals.requestId
        })
    },
    unsecured: {
        context: (_request, response) => ({ requestId: response.locals.requestId })
    }
};

const handlers: GeneratedHandlers<{}, typeof integration> = {
    adminUsersCreate: async (input, context) => saveUser(context.user, input)
};

registerGeneratedRoutes(app, handlers, undefined, { integration });
```

For each operation, policy middleware runs in declaration order, followed by context resolution, the route-local body parser, generated input validation, the endpoint handler, generated output validation, and response serialization. Middleware may finish the response without calling `next`, which prevents context resolution and business logic from running. Context types are inferred independently for secured, optional-authentication, and unsecured handlers.

Application middleware, context resolvers, and endpoint handlers retain their original thrown errors. Generated input and output validation failures reach the Express error boundary as `GeneratedValidationError`, with `operationId`, `phase` (`"input"` or `"output"`), and `cause`. Install application error middleware after generated route registration to choose status codes, error codes, validation mappings, and response envelopes. Generated output is fully validated and serialized before its declared response headers are applied.

Operations with declared route parameters receive a typed input object containing each mapped parameter property and, when present, a `body` property. Path, query, header, and cookie values are read using their declared wire names; header lookup is case-insensitive and percent-encoded cookie values are decoded once. Required values, scalar ranges, booleans, dates, times, enums, and comma-separated arrays are validated before the handler runs. Query, header, and cookie arrays use the same comma-separated encoding as the generated Swift client: an empty string is an empty array, an omitted optional value is `undefined`, and commas inside string elements are therefore not distinguishable from separators. Swift client initializer defaults are not applied when an HTTP parameter is omitted; only the declared requiredness controls whether omission is rejected or yields `undefined`.

Generated routes use `express.raw({ type: "application/json" })` and the generated `lossless-json` runtime so wide integer fields remain exact JSON numbers. Register the generated routes before installing a broad `app.use(express.json())` middleware; an earlier ordinary JSON parser would already have rounded wide integers. Narrow integer fields are range-checked before conversion to `number`.

Mapped scalar fields use `Date` for ISO-8601 instants, `URL` for valid URL strings, and `Uint8Array` for padded base64 JSON values. UUIDs, `YYYY-MM-DD` calendar dates, and local `HH:mm:ss` values remain strings; invalid scalar formats are rejected at the generated route boundary. Raw binary request/response transport is a separate capability.

Nested DTO references, arrays, and string-keyed dictionaries are converted recursively between Swift property names and their wire names. Shared references are emitted once and reused across the package, module, and service declarations. Optional properties preserve the distinction between a missing value and `null`; nullable dictionary entries preserve their declared keys and values. Object fields that are not declared in the DTO are stripped recursively at the boundary, while dictionary entries remain data owned by the dictionary.

Declared string and integer enums are validated at both HTTP boundaries using their wire values. String enum case identifiers may differ from those values; integer enum values remain exact `bigint` values, including wide integers. Swift enum garbage tolerance is a client-side concern and does not enable unknown-value fallbacks in the generated backend. An enum property with a Swift initializer remains required unless the API property itself is optional.

Dynamic-object DTOs use the declared discriminator and variant raw values to select a type-safe payload. The primary payload key is preferred and the configured alternate key is accepted on input; responses always use the primary key. Embedded (`__self__`) payloads are decoded from the envelope and emitted alongside the discriminator. Unknown variants and malformed payloads fail validation, even when the Swift schema enables garbage tolerance; declared extra properties and dictionary contents remain available while undeclared fields are stripped.

Patch DTO properties use the built-in three-state shape: an omitted property is unchanged, `{ state: "unmodified" }` is also unchanged when supplied explicitly, and `{ state: "modified", value: ... }` assigns a value or deletes it when `value` is `null`. Generated patch routes omit unchanged properties in responses, preserve nested wire-name mappings, and keep ordinary optional fields and nullable dictionary entries separate from patch state.

Application-owned refinements and transformations are supplied as a third argument to `registerGeneratedRoutes`. Each operation may provide an `input` Zod schema, which receives the generated mapped DTO after structural decoding and may transform it into the handler's application type, and an `output` Zod schema, which receives the handler's application value and must transform it into the generated DTO before wire encoding:

```ts
const bindings = {
    adminUsersCreate: {
        input: userDtoSchema.refine((value) => value.displayName.length > 0).transform(toDomainUser),
        output: domainUserSchema.transform(toUserDto)
    }
};

const handlers: GeneratedHandlers<typeof bindings> = {
    adminUsersCreate: async (user) => saveUser(user)
};

registerGeneratedRoutes(app, handlers, bindings);
```

`GeneratedHandlers<typeof bindings>` infers the transformed handler input and return types from the schemas. Generated DTO projection still strips undeclared fields, preserves mapped names, and validates the final response. External references and generic references are emitted as `unknown` placeholders and require the relevant operation binding; missing input or output bindings fail at route registration with an actionable error. Application code can compose generic factories such as `pagedResultsSchema(itemSchema)` inside those bindings, keeping custom schemas and transformations outside generated file ownership.

When an external or generic operation has a known application value shape, use the optional type parameters on `GeneratedOperationBinding<HandlerInput, HandlerOutput, WireOutput>` to make the binding contract compile-time checked. The input schema's transformed output must match `HandlerInput`, and the output schema's input and transformed output must match `HandlerOutput` and `WireOutput`; this also preserves nested generic arguments such as `PagedResults<string>`. The unparameterized form remains available for operations whose application shape is intentionally open, while runtime parsing is still required for every external or generic payload.

Generate and validate the package with:

```sh
npm install --prefix generated/backend
npm run --prefix generated/backend build
ROUNDTRIP_BACKEND_RUNTIME_TEST=1 swift test --filter TypeScriptBackendGeneratedPackageTests/generatedPackageCompilesAndServesItsRoute
ROUNDTRIP_BACKEND_RUNTIME_TEST=1 swift test --filter TypeScriptBackendGeneratedPackageTests/generatedPackagePreservesRawAndBodylessTransport
ROUNDTRIP_BACKEND_RUNTIME_TEST=1 swift test --filter TypeScriptBackendGeneratedPackageTests/generatedPackageIntegratesAuthenticationContextAndApplicationErrors
ROUNDTRIP_BACKEND_RUNTIME_TEST=1 swift test --filter TypeScriptBackendGeneratedPackageTests/generatedPackageServesStructuredAndRawMultipartRequests
```

The generated-package HTTP test is opt-in because it installs the reference Express/Zod dependency environment; the command above runs the strict TypeScript build and HTTP assertions explicitly.

The repository's executable backend sample is generated with:

```sh
(cd samples && swift run --package-path cli cli --backend-only)
npm install --prefix samples/typescript-backend --ignore-scripts --package-lock=false
npm run --prefix samples/typescript-backend build
node samples/typescript-backend/test.mjs
```

The sample's generated files live under `src/generated`; its handwritten `src/server.ts` owns server startup and handlers, while generated `src/app.ts` supplies the minimal Express application and route-registration bootstrap. Regeneration does not replace the server or HTTP test. Use `TypeScriptBackendGeneratorOptions.existingProject(sourceDirectory: "src/generated")` when the host already owns its package and bootstrap; in that mode only generated runtime, models, routes, and index files are written. Standalone mode owns the package manifest, TypeScript configuration, root export, and `createApp` bootstrap in addition to the generated sources. Hosts may pass `GeneratedRouteOptions.jsonBodyParser` (or install their own application middleware before registration) when parser behavior or ordering needs to differ; the default remains the lossless raw-body parser.

Raw and file-body operations use `Uint8Array` at the handler boundary. Binary request bodies use `express.raw` with the declared MIME type; file requests use a wildcard raw parser. A binary operation declaring `application/json` still remains raw and is not decoded as JSON. Existing applications may replace these parsers with `GeneratedRouteOptions.rawBodyParser`, while `jsonBodyParser` remains available for JSON routes. The route-local hooks make parser placement configurable, but an application-wide parser installed earlier has already consumed the bytes and cannot be undone; install broad parsers only after generated registration when their ordering would otherwise consume a declared raw body.

Binary responses preserve their exact bytes and declared MIME type. Return the bytes directly for the default status, or use `generatedResponse(value, { status, headers })` from `src/generated/runtime.ts` to select one of the operation's acceptable statuses and add response headers such as pagination metadata. An unexpected status reaches the application's error boundary. `.none` operations and no-body statuses (`1xx`, `204`, `205`, and `304`) end without a response body while retaining headers. Absolute and runtime-supplied backend paths remain explicitly rejected.

Multipart operations use an application-owned adapter because upload middleware, limits, storage, and per-part validation differ between Express applications. The generated factory receives the operation identifier and all declared required part names. Its middleware parses or stages the upload, and `read` returns every uploaded value as a map of part name to an array so additional names and repeated values are retained:

```ts
import type {
    GeneratedHandlers,
    GeneratedMultipartAdapterFactory
} from "./generated/routes.js";

type UploadedPart = {
    filename?: string;
    contentType?: string;
    bytes: Uint8Array;
};

type Multipart = {
    adminUploadsUploadMultipart: GeneratedMultipartAdapterFactory<UploadedPart>;
};

const multipart: Multipart = {
    adminUploadsUploadMultipart: ({ id, requiredParts }) => ({
        middleware: [existingUploadMiddleware],
        read: (request) => request.uploadedParts
    })
};

const handlers: GeneratedHandlers<{}, {}, Multipart> = {
    adminUploadsUploadMultipart: async (input) => {
        const file = input.body.required.file[0];
        const metadata = input.body.required.metadata[0];
        const repeatedCaptions = input.body.parts.get("caption") ?? [];
        return saveUpload(file, metadata, repeatedCaptions);
    }
};

registerGeneratedRoutes(app, handlers, undefined, { multipart });
```

Registration fails when a declared multipart operation has no adapter. On each request, generated policy middleware and context resolution run before adapter middleware; adapter `read` then runs before generated parameter and required-part validation. Missing declared parts become `GeneratedValidationError` input failures. Exceptions from application upload middleware or `read` remain application errors for the host error boundary to classify. Content-type rules, file-size limits, storage decisions, and richer part schemas belong in the adapter rather than the Swift API model.

Use a binary operation with MIME type `multipart/form-data` when the handler must receive the original multipart bytes instead. That route uses `Uint8Array` and preserves the exact boundary, content, and repeated-part representation; generated code does not reinterpret it as a named-part map. Choose structured multipart for typed uploaded values and raw multipart for byte-exact forwarding, verification, or legacy protocols.

## TypeScript Client Integration

Use `TypeScriptApiPackageGenerator` for a generated TypeScript package.

```swift
import TypeScriptApiGenerator

try TypeScriptApiPackageGenerator(
    package: typeScriptPackage,
    options: TypeScriptGeneratorOptions(
        packageName: "@example/api",
        packageVersion: "1.0.0",
        sourceDirectory: "src/generated",
        flavor: .tanStackQuery
    )
).write()
```

The plain flavor generates runtime, models, request builders, API interfaces, services, and package entry points. The TanStack Query flavor also generates query helpers and adds TanStack Query package metadata.

Common integration flow:

```sh
npm install --prefix generated/typescript
npm run --prefix generated/typescript build
```

Then consume the generated package by workspace link, package manager workspace, or published package.

## Vapor Server Integration

Use `SwiftVaporApiPackageGenerator` when the generated output owns a Vapor project or generated Vapor files inside one.

```swift
import SwiftVaporGenerator

try SwiftVaporApiPackageGenerator(
    package: vaporPackage,
    options: SwiftVaporGeneratorOptions(
        appName: "ExampleApi",
        moduleName: "App",
        generatePackage: true,
        generateRunTarget: true,
        generateDockerfile: true
    )
).write()
```

Defaults generate a Swift package with a Vapor dependency, `App` target, `Run` executable, generated controllers, request models, service protocols, runtime support, route registration, and Dockerfile.

For an existing Vapor project, start with `SwiftVaporGeneratorOptions.existingProject(moduleName: "App")`. It omits all application scaffolding, including `configure.swift`. The older individual flags remain available for partial standalone scaffolding:

- Set `targetDirUrl` to the Vapor project root only if generated project files are acceptable there.
- Use `generatePackage: false`, `generateRunTarget: false`, or `generateDockerfile: false` when those files are hand-owned.
- Keep hand-written service implementations separate from generated service protocols and controllers.
- Register generated routes from the generated route configuration file in your app setup.

## Kotlin Spring Boot Server Integration

Use `KotlinSpringBootApiPackageGenerator` to generate Spring Boot server skeletons.

```swift
import KotlinSpringBootGenerator

try KotlinSpringBootApiPackageGenerator(
    package: springPackage,
    options: KotlinSpringBootGeneratorOptions(
        basePackage: "com.example.api",
        applicationName: "ExampleApiApplication",
        gradle: KotlinSpringBootGradleOptions(
            projectName: "example-api",
            group: "com.example",
            version: "1.0.0"
        ),
        generateApplication: true,
        generateRuntime: true
    )
).write()
```

Generated output includes Gradle files, controllers, request DTOs, model DTOs, service interfaces, runtime support, and optionally the application entry point.

For an existing Spring Boot service, start with `KotlinSpringBootGeneratorOptions.existingProject(basePackage: "com.example.api")`:

- Generate into a module or source root that is clearly owned by the generator.
- Set `generateApplication: false` when your app already has its own `@SpringBootApplication`.
- Implement generated service interfaces in hand-written code outside generated paths.
- Keep package names stable; generated imports are derived from `basePackage`.

## OpenAPI Documentation Integration

Use `OpenApiYamlPackageGenerator` for contract documentation and external tooling.

```swift
import OpenApiYamlGenerator

try OpenApiYamlPackageGenerator(
    package: openApiPackage,
    options: OpenApiYamlGeneratorOptions(
        title: "Example API",
        version: "1.0.0",
        servers: [
            "https://api.example.com"
        ],
        fileName: "openapi.yaml"
    )
).write()
```

The sample validates and renders OpenAPI docs with Redocly:

```sh
redocly lint --extends minimal generated/openapi/openapi.yaml
redocly build-docs generated/openapi/openapi.yaml --output generated/openapi/index.html
```

## Regeneration Workflow

Recommended CI order:

```sh
swift run --package-path api-generator ApiGenerator
swift test --package-path GeneratedApi
npm run --prefix generated/typescript build
./gradlew -p generated/kotlin build
./gradlew -p generated/spring build
swift build --package-path generated/swift-vapor
redocly lint --extends minimal generated/openapi/openapi.yaml
```

Use commands that match targets you generate. Keep them close to your normal app build so stale generated output is caught quickly.

## Repository Sample

Run included sample generator:

```sh
./samples/generate.sh
```

This builds `samples/cli`, runs it, and writes generated source files under:

- `samples/swift-client/src/generated`: Swift client.
- `samples/kotlin`: Kotlin Multiplatform client project.
- `samples/android`: native Android client library and HTTP/content-URI integration tests.
- `samples/spring`: Kotlin Spring Boot server project.
- `samples/typescript`: TypeScript client package.
- `samples/openapi`: OpenAPI YAML and generated HTML docs.
- `samples/swift-vapor`: Vapor server project.

The sample includes conventional REST resources plus `Showcase` and `Tenant` modules that exercise manual operations, nested resources, sub-operations, custom parameters, binary/file transports, dynamic objects, enums, dictionaries, external references, and generated API module aggregation.

## Migration Notes

URL properties now follow the same requiredness rules as other property helpers. `ApiModelProperty.url("website")` is required; use `.optional` or `required: false` to retain the earlier optional behavior. `.mandatory` always makes the property required, including URLs. This can change generated model initializers and decoding behavior, so declare nullable fields explicitly.

Field-selection support has been removed: `fieldsQueryParam`, `fieldsQueryParamValues`, and the dynamic-object `published` and `publishDataPropertyNameFirst` parameters are no longer available. Remove those arguments and helper calls from schema declarations. The generator no longer supplies or rewrites `fields`/`optional_fields` queries. Dynamic Kotlin constructors use the former default order: extra properties before the payload. Independent `.unpublished` model-property visibility remains available.

Existing array initializers, resource identifier arguments, REST default security and pagination, and Swift whole-directory writes remain available. Adopt builders and named configuration incrementally.
