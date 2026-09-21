---
status: accepted
---

# Keep application behavior outside the reusable TypeScript backend target

Add a reusable TypeScript backend generation target, using FutureNXL as the first compatibility reference. Generate routes, input/output schemas, and integration wiring; keep business logic, persistence, and custom schema refinements and transformations in the consuming TypeScript application rather than expanding the Swift DSL to express application behavior. Compatibility means API capabilities and payload mappings, and permits changes to imports and route registration.

Generate route registration and an optional minimal Express bootstrap. Existing applications retain ownership of application-specific middleware and operational setup, including database migrations, Redis, realtime services, and shutdown.

Generated DTOs use the contract's mapped property names, with generated conversion to and from the wire names. Application-specific database and domain mapping remains handwritten.

DTO instant dates use `Date`, URL values use `URL`, and binary properties use `Uint8Array`. Wire conversion uses ISO-8601 strings for instant dates, strings for URLs, and base64 for binary properties inside JSON. UUIDs, calendar dates, and local times remain strings. Raw binary HTTP bodies remain bytes, distinct from binary properties inside JSON. TypeScript-owned transformations handle application-specific formats.

Generated routes call typed application-owned endpoint functions and handle input parsing plus output validation and serialization. The application supplies business logic and authentication/context integration; existing Express controllers may need adapters or changes.

Application-owned schema bindings may perform typed transformations, with handler types inferred from those bindings and the final serialized response checked against the declared wire contract. External and generic types require application-provided schemas. Server validation rejects invalid enum values and dynamic variants rather than copying the Swift client's garbage fallbacks. Undeclared object fields are stripped on both input and output; declared dictionaries and dynamic payload content remain governed by their declared schemas.

Absolute and runtime operation URLs are unsupported in the first version. This is an explicit exception to Swift mapping coverage; it does not authorize inventing server routes for these operations.

The first delivery provides the generator and validation against representative FutureNXL routes, rather than migrating the entire backend. It must also cover the features of the existing Swift mappings, subject to the URL exception above. The user confirmed this design and approved testing primarily through generated packages compiled and exercised over HTTP, with additional generator-level checks for output ownership and unsupported definitions.

The implementation specification is tracked in [issue #2](https://github.com/modern-swift-dev/roundtrip-generator/issues/2).

## Implementation

Implemented and verified in the reusable `TypeScriptBackendApiPackageGenerator`, the executable `samples/typescript-backend` package, and the generator and HTTP compatibility fixtures. Issue #2 is closed; the focused generator suite passes with 32 tests.
