# ``GeneratorModels``

Describe REST API packages, modules, operations, parameters, and shared payload types.

## Overview

`GeneratorModels` is the public schema consumed by the Swift, Vapor, Kotlin Multiplatform, Android, Spring Boot, TypeScript, and OpenAPI generators. Start with an ``ApiPackage``. A package contains ``ApiModule`` values, modules contain ``ApiService`` values, and definitions contain ``ApiOperation`` values.

Reusable payload models are represented by ``ApiTypeSchema``. Request and response shapes are attached to operations with ``ApiRequestBody`` and ``ApiResponseBody``. Parameters use ``ApiParameter`` and can live in the path, query string, header, or cookie.

```swift
let user = ApiTypeSchema.object(
    typeName: "User",
    properties: [
        .string("name"),
        .string("email").optional
    ]
)

let definition = ApiService(
    name: "User",
    operations: [
        .get(
            name: "get",
            path: .relative("/users/{user_id}"),
            parameters: [.path("user_id", .int64())],
            response: user.asRef
        )
    ],
    references: [user]
)
```

Collection closures use ``ApiCollectionBuilder`` and support reusable arrays, conditionals, and loops. Existing array initializers remain available. Package reference and import collections default to empty; `output(to:)` creates a copy for another destination while preserving model identities.

Register generated types in a definition, module, or package's `references`. Use `commonReferences` for types supplied by another package. `.asRef` points to the same model value; it does not register the declaration. Construct shared models once and reuse them.

URL properties are required by default like other property helpers. Use `.optional` for nullable URLs. The generator has no field-selection query helpers; `.unpublished` independently controls whether a model property is emitted.

## Topics

### Collection Builders

- ``ApiCollectionBuilder``

### Package Structure

- ``ApiPackage``
- ``ApiModule``
- ``ApiService``
- ``ApiImport``

### Operations

- ``ApiOperation``
- ``HttpMethod``
- ``ApiOperationPath``
- ``ApiAuthorizationHeaderPolicy``
- ``ApiParameter``
- ``ApiRequestBody``
- ``ApiResponseBody``

### Data Types

- ``ApiTypeSchema``
- ``ApiModelProperty``
- ``ApiEnumCase``
- ``ApiEnumAssociatedValue``
- ``ApiTypeNameResolver``

### REST Resource Shorthand

- ``ApiRestResourceGroup``
- ``ApiRestResource``

### Validation

- ``ApiValidationError``
