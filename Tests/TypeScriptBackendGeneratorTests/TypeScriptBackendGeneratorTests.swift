import Foundation
import GeneratorModels
import Testing
@testable import TypeScriptBackendGenerator

struct TypeScriptBackendGeneratorTests {
    @Test func generatedBackendExposesStrictStandalonePackage() throws {
        let user = ApiTypeSchema.object(
            typeName: "User",
            properties: [
                .string("display_name", propertyName: "displayName"),
                .bool("active"),
                .double("score")
            ],
        )
        let operation = ApiOperation.post(
            name: "create",
            path: .relative("/users"),
            security: .unsecured,
            request: user.asRef,
            response: user.asRef,
            acceptableStatuses: [200],
        )
        let package = testPackage(operation: operation, references: [user])

        let files = try TypeScriptBackendApiPackageGenerator(package: package).generatedFiles()
        let paths = Set(files.map(\.relativePath))

        #expect(paths.contains("package.json"))
        #expect(paths.contains("tsconfig.json"))
        #expect(paths.contains("src/index.ts"))
        #expect(paths.contains("src/app.ts"))
        #expect(paths.contains("src/generated/models.ts"))
        #expect(paths.contains("src/generated/routes.ts"))

        let routes = try #require(files.first { $0.relativePath == "src/generated/routes.ts" }?.contents)
        #expect(routes.contains("export function registerGeneratedRoutes"))
        #expect(routes.contains("type Application"))
        #expect(routes.contains("app: Application"))
        #expect(routes.contains("app.post(\"/users\""))

        let models = try #require(files.first { $0.relativePath == "src/generated/models.ts" }?.contents)
        #expect(models.contains("display_name"))
        #expect(models.contains("displayName"))

        let packageJSON = try #require(files.first { $0.relativePath == "package.json" }?.contents)
        #expect(packageJSON.contains(#""express": "^5.2.1""#))
        #expect(packageJSON.contains(#""zod": "^4.4.3""#))
        #expect(packageJSON.contains(#""typescript": "^6.0.0""#))
        let app = try #require(files.first { $0.relativePath == "src/app.ts" }?.contents)
        #expect(app.contains("export function createApp"))
        let routesWithOptions = try #require(files.first { $0.relativePath == "src/generated/routes.ts" }?.contents)
        #expect(routesWithOptions.contains("jsonBodyParser?: RequestHandler"))
        #expect(routesWithOptions.contains("options?.jsonBodyParser ?? express.raw"))
        #expect(files == (try TypeScriptBackendApiPackageGenerator(package: package).generatedFiles()))
    }

    @Test func `generated backend validates and serializes each declared public error`() throws {
        let success = ApiTypeSchema.object(typeName: "Success", properties: [.string("value")])
        let failure = ApiTypeSchema.object(typeName: "Failure", properties: [.string("code")])
        let operation = ApiOperation.get(
            name: "read",
            path: .relative("/records"),
            security: .unsecured,
            response: success.asRef,
            publicErrors: [.init(status: 409, response: .json(failure.asRef))],
        )

        let files = try TypeScriptBackendApiPackageGenerator(
            package: testPackage(operation: operation, references: [success, failure]),
        ).generatedFiles()
        let routes = try #require(files.first { $0.relativePath == "src/generated/routes.ts" }?.contents)

        #expect(routes.contains("validateGeneratedResponseStatus(output.status, [200, 409])"))
        #expect(routes.contains("if (output.status === 409)"))
        #expect(routes.contains("response.status(output.status).type(\"application/json\").send(responseBody);"))
        #expect(routes.contains("Success | Failure"))
    }

    @Test func `generated backend registers only supplied handlers`() throws {
        let user = ApiTypeSchema.object(typeName: "User", properties: [.string("name")])
        let operation = ApiOperation.get(
            name: "read",
            path: .relative("/users"),
            security: .secured,
            response: user.asRef,
        )

        let files = try TypeScriptBackendApiPackageGenerator(
            package: testPackage(operation: operation, references: [user]),
        ).generatedFiles()
        let routes = try #require(files.first { $0.relativePath == "src/generated/routes.ts" }?.contents)

        #expect(routes.contains("adminUsersRead?: AdminUsersReadHandler"))
        #expect(routes.contains("const handler_adminUsersRead = handlers.adminUsersRead;"))
        #expect(routes.contains("if (handler_adminUsersRead) {"))
        #expect(routes.contains("await handler_adminUsersRead(input"))
    }

    @Test func `generated backend preserves boolean literal constraints`() throws {
        let failure = ApiTypeSchema.object(typeName: "Failure", properties: [.boolLiteral("success", value: false)])
        let operation = ApiOperation.get(
            name: "read",
            path: .relative("/records"),
            security: .unsecured,
            response: nil,
            publicErrors: [.init(status: 409, response: .json(failure.asRef))],
        )

        let files = try TypeScriptBackendApiPackageGenerator(
            package: testPackage(operation: operation, references: [failure]),
        ).generatedFiles()
        let models = try #require(files.first { $0.relativePath == "src/generated/models.ts" }?.contents)

        #expect(models.contains("\"success\": z.literal(false)"))
    }

    @Test func existingProjectGenerationLeavesHostBootstrapAndPackageFilesAlone() throws {
        let user = ApiTypeSchema.object(typeName: "User", properties: [.string("name")])
        let operation = ApiOperation.post(
            name: "create",
            path: .relative("/users"),
            security: .unsecured,
            request: user.asRef,
            response: user.asRef,
            acceptableStatuses: [200],
        )
        let files = try TypeScriptBackendApiPackageGenerator(
            package: testPackage(operation: operation, references: [user]),
            options: .existingProject(),
        ).generatedFiles()
        let paths = Set(files.map(\.relativePath))

        #expect(paths == [
            "src/generated/runtime.ts",
            "src/generated/models.ts",
            "src/generated/routes.ts",
            "src/generated/index.ts"
        ])
    }

    @Test func generatedBackendSupportsRawAndBodylessOperations() throws {
        let upload = ApiOperation.post(
            name: "upload",
            path: .relative("/upload"),
            security: .unsecured,
            requestType: .binary(mimeType: "application/json"),
            responseType: .binary(mimeType: "image/png"),
            acceptableStatuses: [200, 204],
        )
        let health = ApiOperation(
            name: "health",
            method: .get,
            path: .relative("/health"),
            security: .unsecured,
            parameters: [],
            request: .none,
            response: .none,
            acceptableStatuses: [204],
            extraImports: [],
        )
        let fileUpload = ApiOperation.post(
            name: "fileUpload",
            path: .relative("/file-upload"),
            security: .unsecured,
            requestType: .file,
            responseType: .none,
            acceptableStatuses: [204],
        )
        let package = ApiPackage(
            name: "Example",
            targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString),
            modules: [ApiModule(name: "Admin", definitions: [ApiService(name: "Files", operations: [upload, health, fileUpload])])],
        )

        let files = try TypeScriptBackendApiPackageGenerator(package: package).generatedFiles()
        let routes = try #require(files.first { $0.relativePath == "src/generated/routes.ts" }?.contents)
        #expect(routes.contains("adminFilesUpload?: AdminFilesUploadHandler"))
        #expect(routes.contains("adminFilesHealth?: AdminFilesHealthHandler"))
        #expect(routes.contains("options?.rawBodyParser ?? express.raw({ type: \"application/json\" })"))
        #expect(routes.contains("options?.rawBodyParser ?? express.raw({ type: \"*/*\" })"))
        #expect(routes.contains("output.value instanceof Uint8Array"))
        #expect(routes.contains("output.headers[\"Content-Type\"] ?? output.headers[\"content-type\"]"))
        #expect(routes.contains("app.get(\"/health\", ...(options?.integration?.unsecured?.middleware ?? [])"))
        #expect(routes.contains("response.status(output.status).end()"))
    }

    @Test func `generated backend distinguishes binary success from bodyless redirect`() throws {
        let operation = ApiOperation(
            name: "receipt",
            method: .get,
            path: .relative("/receipts/{id}"),
            security: .unsecured,
            parameters: [.path("id", .string())],
            request: .none,
            response: .binary(mimeType: "image/png"),
            acceptableStatuses: [200, 302],
            extraImports: [],
        )
        .withSuccessResponse(status: 302, response: .none, requiredHeaders: ["Location"])
        let files = try TypeScriptBackendApiPackageGenerator(package: testPackage(operation: operation, references: [])).generatedFiles()
        let routes = try #require(files.first { $0.relativePath == "src/generated/routes.ts" }?.contents)

        #expect(routes.contains("if (output.status === 302)"))
        #expect(routes.contains("Bodyless response cannot include a response value"))
        #expect(routes.contains("Missing required response header: Location"))
        #expect(routes.contains("response.status(output.status).end();"))
        #expect(routes.contains("response.status(output.status).type(contentType).send(output.value);"))
        #expect(routes.contains("Uint8Array | void"))
    }

    @Test func `generated backend rejects success overrides outside declared statuses`() {
        let operation = ApiOperation(
            name: "receipt",
            method: .get,
            path: .relative("/receipt"),
            security: .unsecured,
            parameters: [],
            request: .none,
            response: .binary(mimeType: "image/png"),
            acceptableStatuses: [200],
            extraImports: [],
        ).withSuccessResponse(status: 302, response: .none, requiredHeaders: ["Location"])

        #expect(throws: TypeScriptBackendGeneratorError.invalidPackage(reason: "operation receipt has invalid success response override")) {
            try TypeScriptBackendApiPackageGenerator(package: testPackage(operation: operation, references: [])).generatedFiles()
        }
    }

    @Test func generatedBackendExposesApplicationOwnedMultipartAdapters() throws {
        let receipt = ApiTypeSchema.object(typeName: "Receipt", properties: [.string("id")])
        let operation = ApiOperation.postMultipart(
            name: "upload",
            path: .relative("/uploads"),
            security: .secured,
            parameters: [.query("compress", .bool()).optional],
            multiParts: ["file", "metadata"],
            response: receipt.asRef,
        )

        let files = try TypeScriptBackendApiPackageGenerator(
            package: testPackage(operation: operation, references: [receipt]),
        ).generatedFiles()
        let routes = try #require(files.first { $0.relativePath == "src/generated/routes.ts" }?.contents)

        #expect(routes.contains("export interface GeneratedMultipartOperation"))
        #expect(routes.contains("export interface GeneratedMultipartAdapter<Part = unknown>"))
        #expect(routes.contains("export type GeneratedMultipartBody<Part, RequiredPart extends string>"))
        #expect(routes.contains("adminUsersUpload?: GeneratedMultipartAdapterFactory"))
        #expect(routes.contains("Missing multipart adapter for adminUsersUpload"))
        #expect(routes.contains("requiredParts: [\"file\", \"metadata\"]"))
        #expect(routes.contains("generatedRequiredMultipartPart(multipartParts, \"file\")"))
        #expect(routes.contains("generatedRequiredMultipartPart(multipartParts, \"metadata\")"))
        #expect(routes.contains("...multipartAdapter_adminUsersUpload.middleware"))
        #expect(routes.contains("readonly required: { readonly [Name in RequiredPart]: readonly [Part, ...Part[]] }"))
        #expect(routes.contains("readonly parts: ReadonlyMap<string, readonly Part[]>"))
    }

    @Test func generatedBackendRejectsInvalidMultipartPartNames() {
        for parts in [[], [""], ["file", "file"]] {
            let operation = ApiOperation.postMultipart(
                name: "upload",
                path: .relative("/uploads"),
                security: .unsecured,
                multiParts: parts,
                response: nil,
            )

            #expect(throws: TypeScriptBackendGeneratorError.invalidPackage(reason: "operation Upload has invalid multipart part names")) {
                try TypeScriptBackendApiPackageGenerator(package: testPackage(operation: operation)).generatedFiles()
            }
        }
    }

    @Test func generatedBackendExcludesAbsoluteAndRuntimeOperationPaths() throws {
        let operations = [
            ApiOperation.get(name: "absoluteReceiptImage", path: .absolute("https://example.com/receipt.png"), security: .unsecured),
            ApiOperation.get(name: "runtimeReceiptImage", path: .runtime, security: .unsecured)
        ]

        for operation in operations {
            let files = try TypeScriptBackendApiPackageGenerator(package: testPackage(operation: operation)).generatedFiles()
            let routes = try #require(files.first { $0.relativePath == "src/generated/routes.ts" }?.contents)
            #expect(!routes.contains(operation.name))
        }
    }

    @Test func generatedBackendBindsTypedRouteParameters() throws {
        let payload = ApiTypeSchema.object(typeName: "Payload", properties: [.string("message")])
        let state = ApiTypeSchema.stringEnum(
            typeName: "State",
            values: [(name: "ready", rawName: "ready")],
        )
        let operation = ApiOperation(
            name: "inspect",
            method: .post,
            path: .relative("/users/{user_id}"),
            security: .unsecured,
            parameters: [
                .path("user_id", .int64(), propertyName: "userId"),
                .query("include_tags", .stringArray(), propertyName: "includeTags", required: false),
                .query("page_size", .int16(50), propertyName: "pageSize").optional,
                .query("state", .stringEnumValue(type: state.asRef), propertyName: "state"),
                .header("X-Trace", .string(), propertyName: "trace"),
                .cookie("session_id", .string(), propertyName: "sessionId")
            ],
            request: .json(payload.asRef),
            response: .json(payload.asRef),
            acceptableStatuses: [200],
            extraImports: [],
        )
        let files = try TypeScriptBackendApiPackageGenerator(
            package: testPackage(operation: operation, references: [payload, state]),
        ).generatedFiles()
        let routes = try #require(files.first { $0.relativePath == "src/generated/routes.ts" }?.contents)

        #expect(routes.contains("app.post(\"/users/:user_id\""))
        #expect(routes.contains("export interface AdminUsersInspectInput"))
        #expect(routes.contains("userId: bigint;"))
        #expect(routes.contains("includeTags?: string[];"))
        #expect(routes.contains("pageSize?: number;"))
        #expect(!routes.contains("raw_pageSize === undefined ? 50"))
        #expect(routes.contains("body: Payload;"))
        #expect(routes.contains("readRequestParameter(request, \"header\", \"X-Trace\")"))
        #expect(routes.contains("parseParameterBigInt"))
        #expect(routes.contains("decodeState"))
    }

    @Test func generatedBackendRejectsInvalidParameterEnumDefaults() {
        let state = ApiTypeSchema.stringEnum(
            typeName: "State",
            values: [(name: "ready", rawName: "ready")],
        )
        let operation = ApiOperation.get(
            name: "inspect",
            path: .relative("/users"),
            security: .unsecured,
            parameters: [.query("state", .stringEnumValue(type: state.asRef, defaultValue: "unknown"))],
        )

        #expect(throws: TypeScriptBackendGeneratorError.invalidPackage(reason: "operation Inspect has an invalid enum parameter default")) {
            try TypeScriptBackendApiPackageGenerator(
                package: testPackage(operation: operation, references: [state]),
            ).generatedFiles()
        }
    }

    @Test func generatedBackendExposesApplicationSchemaBindings() throws {
        let external = ApiTypeSchema.reference(typeName: "ExternalUser", strict: false)
        let envelope = ApiTypeSchema.object(
            typeName: "Envelope",
            properties: [
                ApiModelProperty(rawName: "external_user", propertyName: "externalUser", dataType: external),
                ApiModelProperty(
                    rawName: "paged_results",
                    propertyName: "pagedResults",
                    dataType: .genericReference(typeName: "PagedResults", genericTypes: [.string()]),
                )
            ],
        )
        let operation = ApiOperation.post(
            name: "custom",
            path: .relative("/custom"),
            security: .unsecured,
            request: envelope.asRef,
            response: envelope.asRef,
            acceptableStatuses: [200],
        )

        let files = try TypeScriptBackendApiPackageGenerator(package: testPackage(operation: operation, references: [envelope])).generatedFiles()
        let models = try #require(files.first { $0.relativePath == "src/generated/models.ts" }?.contents)
        let routes = try #require(files.first { $0.relativePath == "src/generated/routes.ts" }?.contents)

        #expect(models.contains("externalUser: unknown;"))
        #expect(models.contains("pagedResults: PagedResults<string>;"))
        #expect(models.contains("export interface PagedResults<T>"))
        #expect(models.contains("PagedResultsWireSchema"))
        #expect(routes.contains("export interface GeneratedOperationBinding"))
        #expect(routes.contains("GeneratedSchemaBinding<Output = unknown, Input = unknown>"))
        #expect(routes.contains("GeneratedOperationBinding<HandlerInput = unknown, HandlerOutput = unknown, WireOutput = unknown>"))
        #expect(routes.contains("export type GeneratedHandlerInput"))
        #expect(routes.contains("input"))
        #expect(routes.contains("output"))
        #expect(routes.contains("Missing schema binding for adminUsersCustom input"))
        #expect(routes.contains("Missing schema binding for adminUsersCustom output"))
        #expect(routes.contains("bindings?: Bindings"))
    }

    @Test func generatedBackendUsesLosslessNumbersForIntegerBoundaries() throws {
        let record = ApiTypeSchema.object(
            typeName: "Record",
            properties: [
                .int64("signed"),
                .uint64("unsigned"),
                .int("platformSigned"),
                .uint("platformUnsigned"),
                .int8("tinySigned"),
                .int16("smallSigned"),
                .int32("narrowSigned"),
                .uint8("tinyUnsigned"),
                .uint16("smallUnsigned"),
                .uint32("narrowUnsigned"),
                .double("ratio")
            ],
        )
        let operation = ApiOperation.post(
            name: "create",
            path: .relative("/records"),
            security: .unsecured,
            request: record.asRef,
            response: record.asRef,
            acceptableStatuses: [200],
        )
        let package = testPackage(operation: operation, references: [record])

        let files = try TypeScriptBackendApiPackageGenerator(package: package).generatedFiles()
        let models = try #require(files.first { $0.relativePath == "src/generated/models.ts" }?.contents)
        let runtime = try #require(files.first { $0.relativePath == "src/generated/runtime.ts" }?.contents)
        let routes = try #require(files.first { $0.relativePath == "src/generated/routes.ts" }?.contents)
        let packageJSON = try #require(files.first { $0.relativePath == "package.json" }?.contents)

        #expect(models.contains("signed: bigint;"))
        #expect(models.contains("unsigned: bigint;"))
        #expect(models.contains("platformSigned: bigint;"))
        #expect(models.contains("platformUnsigned: bigint;"))
        #expect(models.contains("tinySigned: number;"))
        #expect(models.contains("smallSigned: number;"))
        #expect(models.contains("tinyUnsigned: number;"))
        #expect(models.contains("smallUnsigned: number;"))
        #expect(models.contains("z.bigint().refine"))
        #expect(models.contains("parseNarrowInteger"))
        #expect(models.contains("parseDouble"))
        #expect(runtime.contains(#"from "lossless-json""#))
        #expect(runtime.contains("parseNumberAndBigInt"))
        #expect(runtime.contains("typeof value !== \"string\" && !(value instanceof Uint8Array)"))
        #expect(runtime.contains("stringifyJsonResponse"))
        #expect(routes.contains("express.raw"))
        #expect(routes.contains("parseJsonBody"))
        #expect(routes.contains("stringifyJsonResponse"))
        #expect(packageJSON.contains(#""lossless-json": "^4.3.0""#))
    }

    @Test func generatedBackendValidatesRootNumericBodies() throws {
        let operation = ApiOperation.post(
            name: "echo",
            path: .relative("/numbers"),
            security: .unsecured,
            request: .int64(),
            response: .int64(),
            acceptableStatuses: [200],
        )
        let package = testPackage(operation: operation)

        let files = try TypeScriptBackendApiPackageGenerator(package: package).generatedFiles()
        let routes = try #require(files.first { $0.relativePath == "src/generated/routes.ts" }?.contents)

        #expect(routes.contains("import { z } from \"zod\";"))
        #expect(routes.contains("z.bigint().refine"))
        #expect(routes.contains(".parse(parseJsonBody(request.body)) as bigint"))
    }

    @Test func generatedBackendUsesMappedScalarCodecs() throws {
        let record = ApiTypeSchema.object(
            typeName: "MappedRecord",
            properties: [
                .date("created_at", propertyName: "createdAt"),
                .url("website"),
                .binary("payload"),
                .uuid("identifier"),
                .timelessDate("business_date", propertyName: "businessDate"),
                .time("business_time", propertyName: "businessTime")
            ],
        )
        let operation = ApiOperation.post(
            name: "create",
            path: .relative("/mapped"),
            security: .unsecured,
            request: record.asRef,
            response: record.asRef,
            acceptableStatuses: [200],
        )
        let package = testPackage(operation: operation, references: [record])

        let files = try TypeScriptBackendApiPackageGenerator(package: package).generatedFiles()
        let models = try #require(files.first { $0.relativePath == "src/generated/models.ts" }?.contents)
        let runtime = try #require(files.first { $0.relativePath == "src/generated/runtime.ts" }?.contents)

        #expect(models.contains("createdAt: Date;"))
        #expect(models.contains("website: URL;"))
        #expect(models.contains("payload: Uint8Array;"))
        #expect(models.contains("isValidISODate"))
        #expect(models.contains("isValidURL"))
        #expect(models.contains("isValidBase64"))
        #expect(models.contains("isValidUUID"))
        #expect(models.contains("isValidCalendarDate"))
        #expect(models.contains("isValidLocalTime"))
        #expect(models.contains("serializeDate"))
        #expect(models.contains("serializeURL"))
        #expect(models.contains("uint8ArrayToBase64"))
        #expect(runtime.contains("parseDate"))
        #expect(runtime.contains("parseURL"))
        #expect(runtime.contains("base64ToUint8Array"))
        #expect(runtime.contains("uint8ArrayToBase64"))
    }

    @Test func generatedBackendSupportsNestedCollectionsAndSharedReferences() throws {
        let address = ApiTypeSchema.object(
            typeName: "Address",
            properties: [
                .string("street_name", propertyName: "streetName"),
                .bool("verified")
            ],
        )
        let profile = ApiTypeSchema.object(
            typeName: "Profile",
            properties: [
                .ref("address", of: address),
                .arrayOfRef("previous_addresses", propertyName: "previousAddresses", of: address),
                .keyedByString("labels", valueType: .string(), required: false, valueOptional: true),
                .string("nickname", required: false)
            ],
        )
        let operation = ApiOperation.post(
            name: "create",
            path: .relative("/profiles"),
            security: .unsecured,
            request: profile.asRef,
            response: profile.asRef,
            acceptableStatuses: [200],
        )
        let package = testPackage(operation: operation, references: [address, profile])

        let files = try TypeScriptBackendApiPackageGenerator(package: package).generatedFiles()
        let models = try #require(files.first { $0.relativePath == "src/generated/models.ts" }?.contents)

        #expect(models.contains("export interface Address"))
        #expect(models.contains("export interface Profile"))
        #expect(models.contains("previousAddresses: Address[];"))
        #expect(models.contains("labels?: Record<string, string | null> | null;"))
        #expect(models.contains("AddressWireSchema()"))
        #expect(models.contains("z.array(AddressWireSchema())"))
        #expect(models.contains("Object.entries(object[\"labels\"]"))
        #expect(models.components(separatedBy: "export interface Address").count == 2)
    }

    @Test func generatedBackendImportsCodecsForRootCollections() throws {
        let address = ApiTypeSchema.object(
            typeName: "Address",
            properties: [.string("street_name", propertyName: "streetName")],
        )
        let operation = ApiOperation.post(
            name: "create",
            path: .relative("/addresses"),
            security: .unsecured,
            request: .array(address.asRef),
            response: .keyedByString(address.asRef),
            acceptableStatuses: [200],
        )
        let package = testPackage(operation: operation, references: [address])

        let files = try TypeScriptBackendApiPackageGenerator(package: package).generatedFiles()
        let routes = try #require(files.first { $0.relativePath == "src/generated/routes.ts" }?.contents)

        #expect(routes.contains("decodeAddress"))
        #expect(routes.contains("encodeAddress"))
        #expect(routes.contains("type Address"))
    }

    @Test func generatedBackendRejectsNormalizedTypeNameCollisions() {
        let upper = ApiTypeSchema.object(typeName: "Foo", properties: [])
        let lower = ApiTypeSchema.object(typeName: "foo", properties: [])
        let operation = ApiOperation.post(
            name: "create",
            path: .relative("/foos"),
            security: .unsecured,
            request: upper.asRef,
            response: upper.asRef,
            acceptableStatuses: [200],
        )

        #expect(throws: TypeScriptBackendGeneratorError.typeNameCollision(generatedName: "Foo", firstType: "Foo", secondType: "foo")) {
            try TypeScriptBackendApiPackageGenerator(package: testPackage(operation: operation, references: [upper, lower])).generatedFiles()
        }
    }

    @Test func generatedBackendReusesReferencesAcrossOwnershipScopes() throws {
        let address = ApiTypeSchema.object(typeName: "Address", properties: [.string("street")])
        let profile = ApiTypeSchema.object(
            typeName: "Profile",
            properties: [.ref("address", of: address)],
        )
        let user = ApiTypeSchema.object(
            typeName: "User",
            properties: [.ref("profile", of: profile)],
        )
        let operation = ApiOperation.post(
            name: "create",
            path: .relative("/users"),
            security: .unsecured,
            request: user.asRef,
            response: user.asRef,
            acceptableStatuses: [200],
        )
        let package = ApiPackage(
            name: "Example",
            targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString),
            modules: [
                ApiModule(name: "Admin", definitions: [
                    ApiService(name: "Users", operations: [operation], references: [user, address])
                ], references: [profile])
            ],
            referencedModules: [],
            references: [address],
            commonReferences: [],
            imports: [],
        )

        let files = try TypeScriptBackendApiPackageGenerator(package: package).generatedFiles()
        let models = try #require(files.first { $0.relativePath == "src/generated/models.ts" }?.contents)

        #expect(models.components(separatedBy: "export interface Address").count == 2)
        #expect(models.components(separatedBy: "export interface Profile").count == 2)
        #expect(models.components(separatedBy: "export interface User").count == 2)
    }

    @Test func generatedBackendIgnoresUnpublishedExternalFields() throws {
        let record = ApiTypeSchema.object(
            typeName: "Record",
            properties: [
                .string("name"),
                ApiModelProperty(
                    rawName: "private_value",
                    propertyName: "privateValue",
                    dataType: .genericReference(typeName: "PrivateValue", genericTypes: []),
                ).unpublished
            ],
        )
        let operation = ApiOperation.post(
            name: "create",
            path: .relative("/records"),
            security: .unsecured,
            request: record.asRef,
            response: record.asRef,
            acceptableStatuses: [200],
        )

        let files = try TypeScriptBackendApiPackageGenerator(package: testPackage(operation: operation, references: [record])).generatedFiles()
        let models = try #require(files.first { $0.relativePath == "src/generated/models.ts" }?.contents)

        #expect(models.contains("name: string;"))
        #expect(!models.contains("privateValue"))
    }

    @Test func generatedBackendPreservesEnumWireValuesAndPrecision() throws {
        let state = ApiTypeSchema.stringEnum(
            typeName: "State",
            values: [
                (name: "inProgress", rawName: "in-progress")
            ],
            initialValue: "inProgress",
            supportGarbage: true,
        )
        let magnitude = ApiTypeSchema.intEnum(
            typeName: "Magnitude",
            values: [
                (name: "small", rawValue: 1),
                (name: "maximum", rawValue: 9_223_372_036_854_775_807)
            ],
        )
        let record = ApiTypeSchema.object(
            typeName: "Record",
            properties: [
                .ref("state", of: state),
                .ref("magnitude", of: magnitude)
            ],
        )
        let operation = ApiOperation.post(
            name: "create",
            path: .relative("/records"),
            security: .unsecured,
            request: record.asRef,
            response: record.asRef,
            acceptableStatuses: [200],
        )
        let package = testPackage(operation: operation, references: [record, state, magnitude])

        let files = try TypeScriptBackendApiPackageGenerator(package: package).generatedFiles()
        let models = try #require(files.first { $0.relativePath == "src/generated/models.ts" }?.contents)

        #expect(models.contains(#"export type State = "in-progress";"#))
        #expect(models.contains(#"z.enum(["in-progress"])"#))
        #expect(models.contains("export type Magnitude = 1 | 1n | 9223372036854775807n;"))
        #expect(models.contains("z.literal(1)"))
        #expect(models.contains("z.literal(9223372036854775807n)"))
        #expect(!models.contains("supportGarbage"))
    }

    @Test func generatedBackendSupportsDynamicObjectVariants() throws {
        let message = ApiTypeSchema.object(
            typeName: "MessagePayload",
            properties: [.string("message_text", propertyName: "messageText")],
        )
        let image = ApiTypeSchema.object(
            typeName: "ImagePayload",
            properties: [.string("image_url", propertyName: "imageUrl")],
        )
        let envelope = ApiTypeSchema.dynamicObject(
            typeName: "EventEnvelope",
            objectTypePropertyName: "kind",
            objectDataPropertyName: "payload",
            alternateObjectDataPropertyName: "data",
            objectTypes: [
                (objectTypeName: "Message", objectTypeRawName: "message", objectType: message.asRef),
                (objectTypeName: "Image", objectTypeRawName: "image", objectType: image.asRef)
            ],
            supportGarbage: true,
            extraProperties: [.bool("visible", required: false)],
        )
        let operation = ApiOperation.post(
            name: "create",
            path: .relative("/events"),
            security: .unsecured,
            request: envelope.asRef,
            response: envelope.asRef,
            acceptableStatuses: [200],
        )
        let package = testPackage(operation: operation, references: [envelope, message, image])

        let files = try TypeScriptBackendApiPackageGenerator(package: package).generatedFiles()
        let models = try #require(files.first { $0.relativePath == "src/generated/models.ts" }?.contents)

        #expect(models.contains("objectType: \"message\"; payload: MessagePayload;"))
        #expect(models.contains("objectType: \"image\"; payload: ImagePayload;"))
        #expect(models.contains("z.discriminatedUnion(\"kind\""))
        #expect(models.contains("z.literal(\"message\")"))
        #expect(models.contains("object[\"payload\"] ?? object[\"data\"]"))
        #expect(models.contains("\"visible\""))
        #expect(!models.contains("__garbage__"))
    }

    @Test func generatedBackendPreservesPatchStates() throws {
        let profile = ApiTypeSchema.object(
            typeName: "Profile",
            properties: [.string("display_name", propertyName: "displayName")],
        )
        let patch = ApiTypeSchema.object(
            typeName: "PatchedUser",
            properties: [
                ApiModelProperty(rawName: "display_name", propertyName: "displayName", dataType: .string().asPatchable),
                ApiModelProperty(rawName: "profile", propertyName: "profile", dataType: profile.asPatchable),
                .string("nickname", required: false),
                .keyedByString("labels", valueType: .string(), required: false, valueOptional: true)
            ],
        )
        let operation = ApiOperation.patch(
            name: "update",
            path: .relative("/users"),
            security: .unsecured,
            request: patch.asRef,
            response: patch.asRef,
            acceptableStatuses: [200],
        )
        let package = testPackage(operation: operation, references: [patch, profile])

        let files = try TypeScriptBackendApiPackageGenerator(package: package).generatedFiles()
        let models = try #require(files.first { $0.relativePath == "src/generated/models.ts" }?.contents)

        #expect(models.contains("displayName?: { state: \"unmodified\" } | { state: \"modified\"; value: string | null };"))
        #expect(models.contains("profile?: { state: \"unmodified\" } | { state: \"modified\"; value: Profile | null };"))
        #expect(models.contains(#""display_name": z.string().nullable().optional()"#))
        #expect(models.contains(#""profile": ProfileWireSchema().nullable().optional()"#))
        #expect(models.contains(#"return { state: "modified", value:"#))
        #expect(!models.contains("z.literal(\"unmodified\")"))
        #expect(models.contains("display_name"))
        #expect(models.contains("nickname?: string | null;"))
    }

    @Test func generatedBackendExposesSecurityPoliciesTypedContextAndApplicationErrors() throws {
        let user = ApiTypeSchema.object(typeName: "User", properties: [.string("name")])
        let operations = [
            ApiOperation.get(name: "secured", path: .relative("/secured"), security: .secured, response: user.asRef),
            ApiOperation.get(name: "optional", path: .relative("/optional"), security: .optional, response: user.asRef),
            ApiOperation.get(name: "public", path: .relative("/public"), security: .unsecured, response: user.asRef)
        ]
        let package = ApiPackage(
            name: "Example",
            targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString),
            modules: [
                ApiModule(name: "Admin", definitions: [
                    ApiService(name: "Users", operations: operations, references: [user])
                ])
            ],
        )

        let files = try TypeScriptBackendApiPackageGenerator(package: package).generatedFiles()
        let routes = try #require(files.first { $0.relativePath == "src/generated/routes.ts" }?.contents)
        let runtime = try #require(files.first { $0.relativePath == "src/generated/runtime.ts" }?.contents)

        #expect(routes.contains("export interface GeneratedRequestPolicy<Context = unknown>"))
        #expect(routes.contains("export interface GeneratedRequestIntegration"))
        #expect(routes.contains("secured?: GeneratedRequestPolicy"))
        #expect(routes.contains("optional?: GeneratedRequestPolicy"))
        #expect(routes.contains("unsecured?: GeneratedRequestPolicy"))
        #expect(routes
            .contains("GeneratedHandlers<Bindings extends GeneratedSchemaBindings = {}, Integration extends GeneratedRequestIntegration = {}, Multipart extends GeneratedMultipartAdapters = {}>"))
        #expect(routes.contains("GeneratedHandlerContext<Integration, \"secured\">"))
        #expect(routes.contains("GeneratedHandlerContext<Integration, \"optional\">"))
        #expect(routes.contains("GeneratedHandlerContext<Integration, \"unsecured\">"))
        #expect(routes.contains("Missing secured request policy"))
        #expect(routes.contains("Missing optional request policy"))
        #expect(routes.contains("generatedRequestContextMiddleware"))
        #expect(routes.contains("new GeneratedValidationError(\"Admin.Users.Secured\", \"input\""))
        #expect(routes.contains("new GeneratedValidationError(\"Admin.Users.Secured\", \"output\""))
        #expect(runtime.contains("export class GeneratedValidationError extends Error"))
        #expect(runtime.contains("readonly phase: \"input\" | \"output\""))
    }

    @Test func backendRegenerationRemovesOnlyStaleManagedSources() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let user = ApiTypeSchema.object(typeName: "User", properties: [.string("name")])
        let operation = ApiOperation.post(
            name: "create",
            path: .relative("/users"),
            security: .unsecured,
            request: user.asRef,
            response: user.asRef,
            acceptableStatuses: [200],
        )
        let package = ApiPackage(
            name: "Example",
            targetDirUrl: root,
            modules: [ApiModule(name: "Admin", definitions: [ApiService(name: "Users", operations: [operation], references: [user])])],
        )
        let generator = TypeScriptBackendApiPackageGenerator(package: package)

        try generator.write()
        let generatedRoot = root.appendingPathComponent("src/generated")
        try TypeScriptBackendGeneratedTextFile(
            relativePath: "src/generated/stale.ts",
            contents: TypeScriptBackendGeneratedTextFile.managedHeader,
        ).write(to: root)
        try "handwritten".write(
            to: generatedRoot.appendingPathComponent("handwritten.ts"),
            atomically: true,
            encoding: .utf8,
        )

        try generator.write()

        #expect(!FileManager.default.fileExists(atPath: generatedRoot.appendingPathComponent("stale.ts").path))
        #expect(try String(contentsOf: generatedRoot.appendingPathComponent("handwritten.ts"), encoding: .utf8) == "handwritten")
    }

    @Test func backendWriteRefusesUserOwnedGeneratedFiles() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let user = ApiTypeSchema.object(typeName: "User", properties: [.string("name")])
        let operation = ApiOperation.post(
            name: "create",
            path: .relative("/users"),
            security: .unsecured,
            request: user.asRef,
            response: user.asRef,
            acceptableStatuses: [200],
        )
        let package = ApiPackage(
            name: "Example",
            targetDirUrl: root,
            modules: [ApiModule(name: "Admin", definitions: [ApiService(name: "Users", operations: [operation], references: [user])])],
        )
        let generatedRoot = root.appendingPathComponent("src/generated")
        try FileManager.default.createDirectory(at: generatedRoot, withIntermediateDirectories: true)
        try "handwritten".write(
            to: generatedRoot.appendingPathComponent("models.ts"),
            atomically: true,
            encoding: .utf8,
        )

        #expect(throws: TypeScriptBackendGeneratedTextFileError.refusingToOverwriteUserFile("src/generated/models.ts")) {
            try TypeScriptBackendApiPackageGenerator(package: package).write()
        }
    }

    @Test func backendWriteRejectsGeneratedLeafSymlinkEscape() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let outside = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer {
            try? FileManager.default.removeItem(at: root)
            try? FileManager.default.removeItem(at: outside)
        }
        let user = ApiTypeSchema.object(typeName: "User", properties: [.string("name")])
        let operation = ApiOperation.post(
            name: "create",
            path: .relative("/users"),
            security: .unsecured,
            request: user.asRef,
            response: user.asRef,
            acceptableStatuses: [200],
        )
        let package = ApiPackage(
            name: "Example",
            targetDirUrl: root,
            modules: [ApiModule(name: "Admin", definitions: [ApiService(name: "Users", operations: [operation], references: [user])])],
        )
        let outsideFile = outside.appendingPathComponent("models.ts")
        try FileManager.default.createDirectory(at: outside, withIntermediateDirectories: true)
        try "outside".write(to: outsideFile, atomically: true, encoding: .utf8)
        let generatedRoot = root.appendingPathComponent("src/generated")
        try FileManager.default.createDirectory(at: generatedRoot, withIntermediateDirectories: true)
        try FileManager.default.createSymbolicLink(
            at: generatedRoot.appendingPathComponent("models.ts"),
            withDestinationURL: outsideFile,
        )

        #expect(throws: TypeScriptBackendGeneratedTextFileError.invalidRelativePath("src/generated/models.ts")) {
            try TypeScriptBackendApiPackageGenerator(package: package).write()
        }
        #expect(try String(contentsOf: outsideFile, encoding: .utf8) == "outside")
    }

    @Test func backendNeverOverwritePolicyRefusesExistingManagedFiles() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let user = ApiTypeSchema.object(typeName: "User", properties: [.string("name")])
        let operation = ApiOperation.post(
            name: "create",
            path: .relative("/users"),
            security: .unsecured,
            request: user.asRef,
            response: user.asRef,
            acceptableStatuses: [200],
        )
        let package = ApiPackage(
            name: "Example",
            targetDirUrl: root,
            modules: [ApiModule(name: "Admin", definitions: [ApiService(name: "Users", operations: [operation], references: [user])])],
        )
        try TypeScriptBackendApiPackageGenerator(package: package).write()

        let neverOverwrite = TypeScriptBackendApiPackageGenerator(
            package: package,
            options: TypeScriptBackendGeneratorOptions(overwritePolicy: .neverOverwriteExisting),
        )
        #expect(throws: TypeScriptBackendGeneratedTextFileError.refusingToOverwriteUserFile("package.json")) {
            try neverOverwrite.write()
        }
    }

    @Test func backendRejectsDestinationPathCollisions() {
        let user = ApiTypeSchema.object(typeName: "User", properties: [])
        let operation = ApiOperation.post(
            name: "create",
            path: .relative("/users"),
            security: .unsecured,
            request: user.asRef,
            response: user.asRef,
            acceptableStatuses: [200],
        )
        let options = TypeScriptBackendGeneratorOptions(sourceDirectory: "package.json")

        #expect(throws: TypeScriptBackendGeneratorError.invalidSourceDirectory("package.json")) {
            try TypeScriptBackendApiPackageGenerator(
                package: testPackage(operation: operation),
                options: options,
            ).generatedFiles()
        }
    }

    private func testPackage(operation: ApiOperation, references: [ApiTypeSchema] = []) -> ApiPackage {
        ApiPackage(
            name: "Example",
            targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString),
            modules: [
                ApiModule(name: "Admin", definitions: [
                    ApiService(name: "Users", operations: [operation], references: references)
                ])
            ],
            referencedModules: [],
            references: [],
            commonReferences: [],
            imports: [],
        )
    }
}
