import Foundation
import GeneratorModels
import Testing
@testable import TypeScriptBackendGenerator

struct TypeScriptBackendGeneratedPackageTests {
    @Test(.enabled(if: ProcessInfo.processInfo.environment["ROUNDTRIP_BACKEND_RUNTIME_TEST"] != nil))
    func generatedModelsDistinguishOmissionFromExplicitNull() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let update = ApiTypeSchema.object(typeName: "UpdateFields", properties: [
            .string("name").omittable,
            .string("nullable_note", propertyName: "nullableNote").optional
        ])
        let operation = ApiOperation.post(
            name: "update",
            path: .relative("/fields"),
            security: .unsecured,
            request: update.asRef,
            response: update.asRef,
        )
        let package = ApiPackage(
            name: "FieldPresence",
            targetDirUrl: root,
            modules: [ApiModule(name: "Fields", definitions: [ApiService(name: "Updates", operations: [operation], references: [update])])],
        )

        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let files = try TypeScriptBackendApiPackageGenerator(package: package).generatedFiles()
        let models = try #require(files.first { $0.relativePath == "src/generated/models.ts" }?.contents)
        #expect(models.contains("name?: string;"))
        #expect(models.contains("nullableNote?: string | null;"))
        for file in files {
            try file.write(to: root)
        }
        try """
        import assert from "node:assert/strict";
        import { decodeUpdateFields, encodeUpdateFields } from "./dist/generated/models.js";

        assert.equal(decodeUpdateFields({}).name, undefined);
        assert.equal(decodeUpdateFields({ name: "Ada" }).name, "Ada");
        assert.throws(() => decodeUpdateFields({ name: null }));
        assert.equal(decodeUpdateFields({ nullable_note: null }).nullableNote, null);
        assert.equal(JSON.stringify(encodeUpdateFields({})), "{}");
        assert.equal(JSON.stringify(encodeUpdateFields({ name: "Ada", nullableNote: null })), '{"name":"Ada","nullable_note":null}');
        assert.throws(() => encodeUpdateFields({ name: null }));
        """.write(to: root.appendingPathComponent("test.mjs"), atomically: true, encoding: .utf8)

        try run(["install", "--ignore-scripts", "--package-lock=false"], in: root)
        try run(["run", "build"], in: root)
        try run(["exec", "--", "node", "test.mjs"], in: root)
    }

    @Test(.enabled(if: ProcessInfo.processInfo.environment["ROUNDTRIP_BACKEND_RUNTIME_TEST"] != nil))
    func generatedPackageCompilesAndServesItsRoute() throws {
        let dumpPath = ProcessInfo.processInfo.environment["ROUNDTRIP_BACKEND_DUMP_PATH"]
        let root = dumpPath.map(URL.init(fileURLWithPath:)) ?? FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer {
            if dumpPath == nil {
                try? FileManager.default.removeItem(at: root)
            }
        }

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
        let state = ApiTypeSchema.stringEnum(
            typeName: "State",
            values: [(name: "inProgress", rawName: "in-progress")],
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
        let messagePayload = ApiTypeSchema.object(
            typeName: "MessagePayload",
            properties: [.string("message_text", propertyName: "messageText")],
        )
        let imagePayload = ApiTypeSchema.object(
            typeName: "ImagePayload",
            properties: [.string("image_url", propertyName: "imageUrl")],
        )
        let eventEnvelope = ApiTypeSchema.dynamicObject(
            typeName: "EventEnvelope",
            objectTypePropertyName: "kind",
            objectDataPropertyName: "payload",
            alternateObjectDataPropertyName: "data",
            objectTypes: [
                (objectTypeName: "Message", objectTypeRawName: "message", objectType: messagePayload.asRef),
                (objectTypeName: "Image", objectTypeRawName: "image", objectType: imagePayload.asRef)
            ],
            supportGarbage: true,
            extraProperties: [
                .bool("visible", required: false),
                .keyedByString("metadata", valueType: .string(), required: false, valueOptional: true)
            ],
        )
        let embeddedEnvelope = ApiTypeSchema.dynamicObject(
            typeName: "EmbeddedEventEnvelope",
            objectTypePropertyName: "kind",
            objectDataPropertyName: "__self__",
            objectTypes: [
                (objectTypeName: "Message", objectTypeRawName: "message", objectType: messagePayload.asRef)
            ],
            extraProperties: [.bool("visible", required: false)],
        )
        let patchedUser = ApiTypeSchema.object(
            typeName: "PatchedUser",
            properties: [
                ApiModelProperty(rawName: "display_name", propertyName: "displayName", dataType: .string().asPatchable),
                ApiModelProperty(rawName: "profile_data", propertyName: "profile", dataType: profile.asPatchable),
                .string("nickname", required: false),
                .keyedByString("labels", valueType: .string(), required: false, valueOptional: true)
            ],
        )
        let transformedUser = ApiTypeSchema.object(
            typeName: "TransformedUser",
            properties: [
                .string("display_name", propertyName: "displayName"),
                .bool("active")
            ],
        )
        let externalEnvelope = ApiTypeSchema.object(
            typeName: "ExternalEnvelope",
            properties: [
                ApiModelProperty(
                    rawName: "external_user",
                    propertyName: "externalUser",
                    dataType: .reference(typeName: "ExternalUser", strict: false),
                ),
                ApiModelProperty(
                    rawName: "paged_results",
                    propertyName: "pagedResults",
                    dataType: .genericReference(typeName: "PagedResults", genericTypes: [.string()]),
                )
            ],
        )
        let user = ApiTypeSchema.object(
            typeName: "User",
            properties: [
                .string("display_name", propertyName: "displayName"),
                .bool("active"),
                .double("score"),
                .ref("profile", of: profile),
                .ref("state", of: state),
                .ref("magnitude", of: magnitude),
                .date("created_at", propertyName: "createdAt"),
                .url("website"),
                .binary("payload"),
                .uuid("identifier"),
                .timelessDate("business_date", propertyName: "businessDate"),
                .time("business_time", propertyName: "businessTime"),
                .int64("id"),
                .uint64("count"),
                .int32("attempts")
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
        let eventOperation = ApiOperation.post(
            name: "createEvent",
            path: .relative("/events"),
            security: .unsecured,
            request: eventEnvelope.asRef,
            response: eventEnvelope.asRef,
            acceptableStatuses: [200],
        )
        let embeddedOperation = ApiOperation.post(
            name: "createEmbedded",
            path: .relative("/embedded-events"),
            security: .unsecured,
            request: embeddedEnvelope.asRef,
            response: embeddedEnvelope.asRef,
            acceptableStatuses: [200],
        )
        let patchOperation = ApiOperation.patch(
            name: "update",
            path: .relative("/users/patch"),
            security: .unsecured,
            request: patchedUser.asRef,
            response: patchedUser.asRef,
            acceptableStatuses: [200],
        )
        let transformOperation = ApiOperation.post(
            name: "transform",
            path: .relative("/transformed-users"),
            security: .unsecured,
            request: transformedUser.asRef,
            response: transformedUser.asRef,
            acceptableStatuses: [200],
        )
        let externalOperation = ApiOperation.post(
            name: "external",
            path: .relative("/external"),
            security: .unsecured,
            request: externalEnvelope.asRef,
            response: externalEnvelope.asRef,
            acceptableStatuses: [200],
        )
        let package = ApiPackage(
            name: "Example",
            targetDirUrl: root,
            modules: [
                ApiModule(name: "Admin", definitions: [
                    ApiService(
                        name: "Users",
                        operations: [operation, eventOperation, embeddedOperation, patchOperation, transformOperation, externalOperation],
                        references: [user, profile, address, state, magnitude, eventEnvelope, embeddedEnvelope, patchedUser, transformedUser, externalEnvelope, messagePayload, imagePayload],
                    )
                ])
            ],
            referencedModules: [],
            references: [],
            commonReferences: [],
            imports: [],
        )

        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        for file in try TypeScriptBackendApiPackageGenerator(package: package).generatedFiles() {
            try file.write(to: root)
        }
        if dumpPath != nil {
            return
        }
        try typeFixture().write(
            to: root.appendingPathComponent("src/handler-fixture.ts"),
            atomically: true,
            encoding: .utf8,
        )
        try runtimeTest().write(to: root.appendingPathComponent("test.mjs"), atomically: true, encoding: .utf8)

        try run(["install", "--ignore-scripts", "--package-lock=false"], in: root)
        try run(["run", "build"], in: root)
        try run(["exec", "--", "node", "test.mjs"], in: root)
    }

    @Test(.enabled(if: ProcessInfo.processInfo.environment["ROUNDTRIP_BACKEND_RUNTIME_TEST"] != nil))
    func generatedPackageServesDeclaredPublicErrors() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let success = ApiTypeSchema.object(typeName: "Success", properties: [.string("value")])
        let failure = ApiTypeSchema.object(typeName: "Failure", properties: [.string("code")])
        let operation = ApiOperation.get(
            name: "read",
            path: .relative("/records"),
            security: .unsecured,
            response: success.asRef,
            publicErrors: [.init(status: 409, response: .json(failure.asRef))],
        )
        let package = ApiPackage(
            name: "Errors",
            targetDirUrl: root,
            modules: [ApiModule(name: "Records", definitions: [ApiService(name: "Records", operations: [operation], references: [success, failure])])],
        )

        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        for file in try TypeScriptBackendApiPackageGenerator(package: package).generatedFiles() {
            try file.write(to: root)
        }
        try publicErrorRuntimeTest().write(to: root.appendingPathComponent("test.mjs"), atomically: true, encoding: .utf8)

        try run(["install", "--ignore-scripts", "--package-lock=false"], in: root)
        try run(["run", "build"], in: root)
        try run(["exec", "--", "node", "test.mjs"], in: root)
    }

    @Test(.enabled(if: ProcessInfo.processInfo.environment["ROUNDTRIP_BACKEND_RUNTIME_TEST"] != nil))
    func generatedPackagePreservesRawAndBodylessTransport() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let upload = ApiOperation.post(
            name: "upload",
            path: .relative("/upload"),
            security: .unsecured,
            requestType: .binary(mimeType: "application/json"),
            responseType: .binary(mimeType: "image/png"),
            acceptableStatuses: [201, 204],
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
            responseType: .binary(mimeType: "application/octet-stream"),
            acceptableStatuses: [200],
        )
        let package = ApiPackage(
            name: "RawExample",
            targetDirUrl: root,
            modules: [ApiModule(name: "Files", definitions: [ApiService(name: "Transport", operations: [upload, fileUpload, health])])],
        )

        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        for file in try TypeScriptBackendApiPackageGenerator(package: package).generatedFiles() {
            try file.write(to: root)
        }
        try rawRuntimeTest().write(to: root.appendingPathComponent("test.mjs"), atomically: true, encoding: .utf8)

        try run(["install", "--ignore-scripts", "--package-lock=false"], in: root)
        try run(["run", "build"], in: root)
        try run(["exec", "--", "node", "test.mjs"], in: root)
    }

    @Test(.enabled(if: ProcessInfo.processInfo.environment["ROUNDTRIP_BACKEND_RUNTIME_TEST"] != nil))
    func generatedPackageIntegratesAuthenticationContextAndApplicationErrors() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let payload = ApiTypeSchema.object(typeName: "Payload", properties: [.string("value")])
        let result = ApiTypeSchema.object(
            typeName: "PolicyResult",
            properties: [
                .string("policy"),
                .string("identity", required: false),
                .string("value")
            ],
        )
        let secured = ApiOperation.get(
            name: "secured",
            path: .relative("/secured/{id}"),
            security: .secured,
            parameters: [.path("id", .string())],
            response: result.asRef,
        )
        let optional = ApiOperation.get(
            name: "optional",
            path: .relative("/optional"),
            security: .optional,
            response: result.asRef,
        )
        let publicOperation = ApiOperation.post(
            name: "public",
            path: .relative("/public"),
            security: .unsecured,
            request: payload.asRef,
            response: result.asRef,
            acceptableStatuses: [200],
        )
        let package = ApiPackage(
            name: "PolicyExample",
            targetDirUrl: root,
            modules: [
                ApiModule(name: "Auth", definitions: [
                    ApiService(name: "Policies", operations: [secured, optional, publicOperation], references: [payload, result])
                ])
            ],
        )

        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        for file in try TypeScriptBackendApiPackageGenerator(package: package).generatedFiles() {
            try file.write(to: root)
        }
        try securityTypeFixture().write(
            to: root.appendingPathComponent("src/security-fixture.ts"),
            atomically: true,
            encoding: .utf8,
        )
        try securityRuntimeTest().write(to: root.appendingPathComponent("test.mjs"), atomically: true, encoding: .utf8)

        try run(["install", "--ignore-scripts", "--package-lock=false"], in: root)
        try run(["run", "build"], in: root)
        try run(["exec", "--", "node", "test.mjs"], in: root)
    }

    @Test(.enabled(if: ProcessInfo.processInfo.environment["ROUNDTRIP_BACKEND_RUNTIME_TEST"] != nil))
    func generatedPackageServesStructuredAndRawMultipartRequests() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let result = ApiTypeSchema.object(
            typeName: "UploadResult",
            properties: [
                .string("filename"),
                .int32("size"),
                .string("metadata"),
                .string("additional"),
                .int32("repeat_count", propertyName: "repeatCount")
            ],
        )
        let profile = ApiOperation.postMultipart(
            name: "profile",
            path: .relative("/profile"),
            security: .secured,
            parameters: [.query("compress", .bool()).optional],
            multiParts: ["file", "metadata"],
            response: result.asRef,
            acceptableStatuses: [200],
        )
        let rawReceipt = ApiOperation.post(
            name: "rawReceipt",
            path: .relative("/raw-receipts"),
            security: .unsecured,
            requestType: .binary(mimeType: "multipart/form-data"),
            responseType: .binary(mimeType: "multipart/form-data"),
            acceptableStatuses: [200],
        )
        let package = ApiPackage(
            name: "MultipartExample",
            targetDirUrl: root,
            modules: [
                ApiModule(name: "Files", definitions: [
                    ApiService(name: "Uploads", operations: [profile, rawReceipt], references: [result])
                ])
            ],
        )

        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        for file in try TypeScriptBackendApiPackageGenerator(package: package).generatedFiles() {
            try file.write(to: root)
        }
        try multipartTypeFixture().write(
            to: root.appendingPathComponent("src/multipart-fixture.ts"),
            atomically: true,
            encoding: .utf8,
        )
        try multipartRuntimeTest().write(to: root.appendingPathComponent("test.mjs"), atomically: true, encoding: .utf8)

        try run(["install", "--ignore-scripts", "--package-lock=false"], in: root)
        try run(["run", "build"], in: root)
        try run(["exec", "--", "node", "test.mjs"], in: root)
    }

    @Test(.enabled(if: ProcessInfo.processInfo.environment["ROUNDTRIP_BACKEND_RUNTIME_TEST"] != nil))
    func generatedPackageServesCompleteNumericAndRootBodyMatrix() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let matrix = ApiTypeSchema.object(
            typeName: "NumericMatrix",
            properties: [
                .int("platform_signed", propertyName: "platformSigned"),
                .uint("platform_unsigned", propertyName: "platformUnsigned"),
                .int8("tiny_signed", propertyName: "tinySigned"),
                .int16("small_signed", propertyName: "smallSigned"),
                .int32("medium_signed", propertyName: "mediumSigned"),
                .uint8("tiny_unsigned", propertyName: "tinyUnsigned"),
                .uint16("small_unsigned", propertyName: "smallUnsigned"),
                .uint32("medium_unsigned", propertyName: "mediumUnsigned"),
                .array("wide_values", propertyName: "wideValues", of: .int64()),
                .array("unsigned_values", propertyName: "unsignedValues", of: .uint64()),
                .keyedByString("wide_map", propertyName: "wideMap", valueType: .int64()),
                .string("internal_note", propertyName: "internalNote").unpublished
            ],
        )
        let operations = [
            ApiOperation.post(
                name: "echoMatrix",
                path: .relative("/matrix"),
                security: .unsecured,
                request: matrix.asRef,
                response: matrix.asRef,
            ),
            ApiOperation(
                name: "putWide",
                method: .put,
                path: .relative("/root/wide"),
                security: .unsecured,
                parameters: [],
                request: .json(.int64()),
                response: .json(.int64()),
                acceptableStatuses: [200],
                extraImports: [],
            ),
            ApiOperation(
                name: "deleteArray",
                method: .delete,
                path: .relative("/root/array"),
                security: .unsecured,
                parameters: [],
                request: .json(.array(.uint32())),
                response: .json(.array(.uint32())),
                acceptableStatuses: [200],
                extraImports: [],
            ),
            ApiOperation.post(
                name: "echoDictionary",
                path: .relative("/root/dictionary"),
                security: .unsecured,
                request: .keyedByString(.int16()),
                response: .keyedByString(.int16()),
            )
        ]
        let package = ApiPackage(
            name: "MatrixExample",
            targetDirUrl: root,
            modules: [
                ApiModule(name: "Matrix", definitions: [
                    ApiService(name: "Scalars", operations: operations, references: [matrix])
                ])
            ],
        )

        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        for file in try TypeScriptBackendApiPackageGenerator(package: package).generatedFiles() {
            try file.write(to: root)
        }
        try numericMatrixTypeFixture().write(
            to: root.appendingPathComponent("src/matrix-fixture.ts"),
            atomically: true,
            encoding: .utf8,
        )
        try numericMatrixRuntimeTest().write(to: root.appendingPathComponent("test.mjs"), atomically: true, encoding: .utf8)

        try run(["install", "--ignore-scripts", "--package-lock=false"], in: root)
        try run(["run", "build"], in: root)
        try run(["exec", "--", "node", "test.mjs"], in: root)
    }

    @Test(.enabled(if: ProcessInfo.processInfo.environment["ROUNDTRIP_BACKEND_RUNTIME_TEST"] != nil))
    func generatedPackageBindsRouteParametersOverHTTP() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let observed = ApiTypeSchema.object(
            typeName: "Observed",
            properties: [
                .string("user_id", propertyName: "userId"),
                .array("tags", of: .string()),
                .string("state"),
                .string("magnitude"),
                .array("flags", of: .bool()),
                .array("integers", of: .string()),
                .array("states", of: .string()),
                .array("magnitudes", of: .string()),
                .string("trace"),
                .string("session"),
                .string("when"),
                .string("date"),
                .string("time"),
                .int32("limit"),
                .int32("small"),
                .bool("enabled")
            ],
        )
        let state = ApiTypeSchema.stringEnum(
            typeName: "State",
            values: [(name: "ready", rawName: "ready")],
        )
        let magnitude = ApiTypeSchema.intEnum(
            typeName: "Magnitude",
            values: [
                (name: "small", rawValue: 1),
                (name: "maximum", rawValue: 9_223_372_036_854_775_807)
            ],
        )
        let operation = ApiOperation(
            name: "inspect",
            method: .get,
            path: .relative("/users/{user_id}"),
            security: .unsecured,
            parameters: [
                .path("user_id", .int64(), propertyName: "userId"),
                .query("include_tags", .stringArray(), propertyName: "includeTags", required: false),
                .query("state", .stringEnumValue(type: state.asRef), propertyName: "state"),
                .query("magnitude", .intEnumValue(type: magnitude.asRef), propertyName: "magnitude"),
                .query("flags", .boolArray(), propertyName: "flags"),
                .query("integers", .int64Array(), propertyName: "integers"),
                .query("states", .stringEnumArray(type: state.asRef), propertyName: "states"),
                .query("magnitudes", .intEnumArray(type: magnitude.asRef), propertyName: "magnitudes"),
                .query("when", .dateTime, propertyName: "when"),
                .query("date", .date, propertyName: "date"),
                .query("time", .time, propertyName: "time"),
                .query("limit", .int32(), propertyName: "limit"),
                .query("small", .uint16(), propertyName: "small"),
                .header("X-Trace", .string(), propertyName: "trace"),
                .header("X-Enabled", .bool(), propertyName: "enabled"),
                .cookie("session_id", .string(), propertyName: "sessionId")
            ],
            request: .none,
            response: .json(observed.asRef),
            acceptableStatuses: [200],
            extraImports: [],
        )
        let escapedPathOperation = ApiOperation(
            name: "inspectFile",
            method: .get,
            path: .relative("/files/{file_name}"),
            security: .unsecured,
            parameters: [.path("file_name", .string(), propertyName: "fileName")],
            request: .none,
            response: .json(.string()),
            acceptableStatuses: [200],
            extraImports: [],
        )
        let numericParameterOperation = ApiOperation.get(
            name: "inspectNumericParameters",
            path: .relative("/numeric-parameters"),
            security: .unsecured,
            parameters: [
                .query("signed", .int()),
                .query("signed_array", .intArray(), propertyName: "signedArray"),
                .query("small_signed", .int16(), propertyName: "smallSigned"),
                .query("small_signed_array", .int16Array(), propertyName: "smallSignedArray"),
                .query("medium_signed_array", .int32Array(), propertyName: "mediumSignedArray"),
                .query("unsigned", .uint()),
                .query("unsigned_array", .uintArray(), propertyName: "unsignedArray"),
                .query("small_unsigned_array", .uint16Array(), propertyName: "smallUnsignedArray"),
                .query("medium_unsigned", .uint32(), propertyName: "mediumUnsigned"),
                .query("medium_unsigned_array", .uint32Array(), propertyName: "mediumUnsignedArray"),
                .query("large_unsigned", .uint64(), propertyName: "largeUnsigned"),
                .query("large_unsigned_array", .uint64Array(), propertyName: "largeUnsignedArray")
            ],
            response: .string(),
        )
        let package = ApiPackage(
            name: "ParameterExample",
            targetDirUrl: root,
            modules: [ApiModule(
                name: "Admin",
                definitions: [ApiService(name: "Users", operations: [operation, escapedPathOperation, numericParameterOperation], references: [observed, state, magnitude])]
            )],
        )

        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        for file in try TypeScriptBackendApiPackageGenerator(package: package).generatedFiles() {
            try file.write(to: root)
        }
        try parameterRuntimeTest().write(to: root.appendingPathComponent("test.mjs"), atomically: true, encoding: .utf8)

        try run(["install", "--ignore-scripts", "--package-lock=false"], in: root)
        try run(["run", "build"], in: root)
        try run(["exec", "--", "node", "test.mjs"], in: root)
    }

    private func run(_ arguments: [String], in directory: URL) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["npm"] + arguments
        process.currentDirectoryURL = directory
        let output = Pipe()
        process.standardOutput = output
        process.standardError = output
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            let text = String(data: output.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            throw NSError(domain: "TypeScriptBackendGeneratedPackageTests", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: text])
        }
    }

    private func rawRuntimeTest() -> String {
        """
        import assert from "node:assert/strict";
        import express from "express";
        import { registerGeneratedRoutes } from "./dist/generated/routes.js";
        import { GeneratedValidationError } from "./dist/generated/runtime.js";
        import { generatedResponse } from "./dist/generated/runtime.js";

        const app = express();
        const handlers = {
            filesTransportUpload: async (input) => generatedResponse(input, {
                status: 201,
                headers: { "x-page": "1" }
            }),
            filesTransportFileUpload: async (input) => generatedResponse(input),
            filesTransportHealth: async () => generatedResponse(undefined, {
                status: 204,
                headers: { "x-health": "ok" }
            })
        };
        registerGeneratedRoutes(app, handlers);
        app.use((error, _request, response, _next) => {
            const status = error instanceof GeneratedValidationError && error.phase === "input" ? 400 : 500;
            response.status(status).json({ error: "Request failed" });
        });
        const server = app.listen(0);
        await new Promise((resolve) => server.once("listening", resolve));
        try {
            const address = server.address();
            const requestBytes = new Uint8Array([0, 255, 1, 10]);
            const upload = await fetch(`http://127.0.0.1:${address.port}/upload`, {
                method: "POST",
                headers: { "content-type": "application/json" },
                body: requestBytes
            });
            assert.equal(upload.status, 201);
            assert.equal(upload.headers.get("content-type"), "image/png");
            assert.equal(upload.headers.get("x-page"), "1");
            assert.deepEqual(new Uint8Array(await upload.arrayBuffer()), requestBytes);

            const fileBytes = new Uint8Array([9, 8, 7, 6]);
            const fileUpload = await fetch(`http://127.0.0.1:${address.port}/file-upload`, {
                method: "POST",
                headers: { "content-type": "application/octet-stream" },
                body: fileBytes
            });
            assert.equal(fileUpload.status, 200);
            assert.equal(fileUpload.headers.get("content-type"), "application/octet-stream");
            assert.deepEqual(new Uint8Array(await fileUpload.arrayBuffer()), fileBytes);

            const health = await fetch(`http://127.0.0.1:${address.port}/health`);
            assert.equal(health.status, 204);
            assert.equal(health.headers.get("x-health"), "ok");
            assert.equal(await health.text(), "");
        } finally {
            await new Promise((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
        }
        """
    }

    private func publicErrorRuntimeTest() -> String {
        """
        import assert from "node:assert/strict";
        import express from "express";
        import { registerGeneratedRoutes } from "./dist/generated/routes.js";
        import { generatedResponse } from "./dist/generated/runtime.js";

        const app = express();
        registerGeneratedRoutes(app, {
            recordsRecordsRead: async () => generatedResponse({ code: "CONFLICT", internal: "must-not-escape" }, { status: 409 })
        });
        const server = app.listen(0);
        await new Promise((resolve) => server.once("listening", resolve));
        try {
            const address = server.address();
            const response = await fetch(`http://127.0.0.1:${address.port}/records`);
            assert.equal(response.status, 409);
            assert.deepEqual(await response.json(), { code: "CONFLICT" });
        } finally {
            await new Promise((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
        }
        """
    }

    private func securityTypeFixture() -> String {
        """
        import type {
            GeneratedHandlers,
            GeneratedRequestPolicy
        } from "./generated/routes.js";

        type Integration = {
            secured: GeneratedRequestPolicy<{ identity: string; requestId: string }>;
            optional: GeneratedRequestPolicy<{ identity: string | null; requestId: string }>;
            unsecured: GeneratedRequestPolicy<{ requestId: string; parserWasPending: boolean }>;
        };

        const handlers: GeneratedHandlers<{}, Integration> = {
            authPoliciesSecured: async (input, context) => ({ policy: "secured", identity: context.identity, value: input.id }),
            authPoliciesOptional: async (_input, context) => ({ policy: "optional", identity: context.identity ?? undefined, value: context.requestId }),
            authPoliciesPublic: async (input, context) => ({ policy: "public", value: context.parserWasPending ? input.value : "late-parser" })
        };

        const securedHandler: GeneratedHandlers<{}, Integration>["authPoliciesSecured"] = async (_input, context) => {
            // @ts-expect-error secured identity remains a string
            const identity: number = context.identity;
            return { policy: "secured", identity: context.identity, value: identity.toString() };
        };

        const optionalHandler: GeneratedHandlers<{}, Integration>["authPoliciesOptional"] = async (_input, context) => {
            // @ts-expect-error optional identity can be null
            const identity: string = context.identity;
            return { policy: "optional", identity, value: context.requestId };
        };

        const publicHandlerWithoutIntegration: GeneratedHandlers<{}, {}>["authPoliciesPublic"] = async (input, context) => {
            // @ts-expect-error omitted unsecured policy produces undefined context
            const requestId = context.requestId;
            return { policy: "public", value: requestId ?? input.value };
        };

        void handlers;
        void securedHandler;
        void optionalHandler;
        void publicHandlerWithoutIntegration;
        """
    }

    private func securityRuntimeTest() -> String {
        """
        import assert from "node:assert/strict";
        import express from "express";
        import { z } from "zod";
        import { registerGeneratedRoutes } from "./dist/generated/routes.js";
        import { GeneratedValidationError, generatedResponse } from "./dist/generated/runtime.js";

        class HandlerFailure extends Error {}
        class BindingFailure extends Error {}
        const order = [];
        let handlerCalls = 0;

        const integration = {
            secured: {
                middleware: [
                    (request, response, next) => {
                        order.push("secured:middleware");
                        if (request.get("Authorization") === "Bearer accepted") {
                            response.locals.identity = "user-1";
                            next();
                            return;
                        }
                        response.status(401).json({ code: "AUTH_REQUIRED" });
                    }
                ],
                context: (_request, response) => {
                    order.push("secured:context");
                    return { identity: response.locals.identity, requestId: "secured-request" };
                }
            },
            optional: {
                middleware: [
                    (request, response, next) => {
                        order.push("optional:middleware");
                        response.locals.identity = request.get("Authorization") === "Bearer accepted" ? "user-1" : null;
                        next();
                    }
                ],
                context: (_request, response) => {
                    order.push("optional:context");
                    return { identity: response.locals.identity, requestId: "optional-request" };
                }
            },
            unsecured: {
                middleware: [(request, _response, next) => { order.push("public:middleware"); next(); }],
                context: (request) => {
                    order.push("public:context");
                    return { requestId: "public-request", parserWasPending: request.body === undefined };
                }
            }
        };

        const handlers = {
            authPoliciesSecured: async (input, context) => {
                handlerCalls += 1;
                order.push("secured:handler");
                if (input.id === "throw") {
                    throw new HandlerFailure("handler failed");
                }
                if (input.id === "invalid-output") {
                    return generatedResponse(42, { headers: { "x-success": "must-not-escape" } });
                }
                return { policy: "secured", identity: context.identity, value: input.id };
            },
            authPoliciesOptional: async (_input, context) => {
                handlerCalls += 1;
                order.push("optional:handler");
                return { policy: "optional", identity: context.identity ?? undefined, value: context.requestId };
            },
            authPoliciesPublic: async (input, context) => {
                handlerCalls += 1;
                order.push("public:handler");
                return { policy: "public", value: context.parserWasPending ? input.value : "late-parser" };
            }
        };
        const bindings = {
            authPoliciesSecured: {
                output: z.object({
                    policy: z.string(),
                    identity: z.string().optional(),
                    value: z.string()
                }).transform((value) => {
                    if (value.value === "binding-output-error") {
                        throw new BindingFailure("output binding failed");
                    }
                    return value;
                })
            },
            authPoliciesPublic: {
                input: z.object({ value: z.string().min(1) }).transform((value) => {
                    if (value.value === "binding-input-error") {
                        throw new BindingFailure("input binding failed");
                    }
                    return value;
                })
            }
        };

        assert.throws(
            () => registerGeneratedRoutes(express(), handlers),
            /Missing secured request policy/
        );

        const app = express();
        registerGeneratedRoutes(app, handlers, bindings, { integration });
        app.use((error, _request, response, _next) => {
            if (error instanceof GeneratedValidationError) {
                response.status(error.phase === "input" ? 400 : 500).json({ code: `GENERATED_${error.phase.toUpperCase()}`, operation: error.operationId });
                return;
            }
            if (error instanceof HandlerFailure) {
                response.status(409).json({ code: "HANDLER_FAILURE" });
                return;
            }
            if (error instanceof BindingFailure) {
                response.status(422).json({ code: "BINDING_FAILURE" });
                return;
            }
            response.status(500).json({ code: "UNEXPECTED" });
        });

        const server = app.listen(0);
        await new Promise((resolve) => server.once("listening", resolve));
        try {
            const address = server.address();
            const base = `http://127.0.0.1:${address.port}`;

            const rejected = await fetch(`${base}/secured/rejected`);
            assert.equal(rejected.status, 401);
            assert.deepEqual(await rejected.json(), { code: "AUTH_REQUIRED" });
            assert.equal(handlerCalls, 0);

            order.length = 0;
            const accepted = await fetch(`${base}/secured/accepted`, { headers: { authorization: "Bearer accepted" } });
            assert.equal(accepted.status, 200);
            assert.deepEqual(await accepted.json(), { policy: "secured", identity: "user-1", value: "accepted" });
            assert.deepEqual(order, ["secured:middleware", "secured:context", "secured:handler"]);

            const anonymous = await fetch(`${base}/optional`);
            assert.equal(anonymous.status, 200);
            assert.deepEqual(await anonymous.json(), { policy: "optional", value: "optional-request" });

            const identified = await fetch(`${base}/optional`, { headers: { authorization: "Bearer accepted" } });
            assert.equal(identified.status, 200);
            assert.deepEqual(await identified.json(), { policy: "optional", identity: "user-1", value: "optional-request" });

            order.length = 0;
            const publicResponse = await fetch(`${base}/public`, {
                method: "POST",
                headers: { "content-type": "application/json" },
                body: '{"value":"parsed"}'
            });
            assert.equal(publicResponse.status, 200);
            assert.deepEqual(await publicResponse.json(), { policy: "public", value: "parsed" });
            assert.deepEqual(order, ["public:middleware", "public:context", "public:handler"]);

            const handlerFailure = await fetch(`${base}/secured/throw`, { headers: { authorization: "Bearer accepted" } });
            assert.equal(handlerFailure.status, 409);
            assert.deepEqual(await handlerFailure.json(), { code: "HANDLER_FAILURE" });

            const malformed = await fetch(`${base}/public`, {
                method: "POST",
                headers: { "content-type": "application/json" },
                body: "{"
            });
            assert.equal(malformed.status, 400);
            assert.deepEqual(await malformed.json(), { code: "GENERATED_INPUT", operation: "Auth.Policies.Public" });

            const invalidBindingInput = await fetch(`${base}/public`, {
                method: "POST",
                headers: { "content-type": "application/json" },
                body: '{"value":""}'
            });
            assert.equal(invalidBindingInput.status, 400);
            assert.deepEqual(await invalidBindingInput.json(), { code: "GENERATED_INPUT", operation: "Auth.Policies.Public" });

            const bindingInputFailure = await fetch(`${base}/public`, {
                method: "POST",
                headers: { "content-type": "application/json" },
                body: '{"value":"binding-input-error"}'
            });
            assert.equal(bindingInputFailure.status, 422);
            assert.deepEqual(await bindingInputFailure.json(), { code: "BINDING_FAILURE" });

            const bindingOutputFailure = await fetch(`${base}/secured/binding-output-error`, { headers: { authorization: "Bearer accepted" } });
            assert.equal(bindingOutputFailure.status, 422);
            assert.deepEqual(await bindingOutputFailure.json(), { code: "BINDING_FAILURE" });

            const invalidOutput = await fetch(`${base}/secured/invalid-output`, { headers: { authorization: "Bearer accepted" } });
            assert.equal(invalidOutput.status, 500);
            assert.equal(invalidOutput.headers.get("x-success"), null);
            assert.deepEqual(await invalidOutput.json(), { code: "GENERATED_OUTPUT", operation: "Auth.Policies.Secured" });
        } finally {
            await new Promise((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
        }
        """
    }

    private func multipartTypeFixture() -> String {
        """
        import type {
            GeneratedHandlers,
            GeneratedMultipartAdapterFactory,
            GeneratedRequestPolicy
        } from "./generated/routes.js";

        type UploadPart = {
            filename?: string;
            contentType?: string;
            bytes: Uint8Array;
        };
        type Integration = {
            secured: GeneratedRequestPolicy<{ identity: string }>;
        };
        type Multipart = {
            filesUploadsProfile: GeneratedMultipartAdapterFactory<UploadPart>;
        };

        const handlers: GeneratedHandlers<{}, Integration, Multipart> = {
            filesUploadsProfile: async (input, context) => {
                const file = input.body.required.file[0];
                const metadata = input.body.required.metadata[0];
                const additional = input.body.parts.get("caption") ?? [];
                return {
                    filename: `${context.identity}:${file.filename ?? "unknown"}`,
                    size: file.bytes.length,
                    metadata: new TextDecoder().decode(metadata.bytes),
                    additional: additional.map((part) => new TextDecoder().decode(part.bytes)).join(","),
                    repeatCount: additional.length
                };
            },
            filesUploadsRawReceipt: async (input) => input
        };

        const profileHandler: GeneratedHandlers<{}, Integration, Multipart>["filesUploadsProfile"] = async (input) => {
            // @ts-expect-error adapter part bytes remain Uint8Array
            const bytes: string = input.body.required.file[0].bytes;
            return { filename: "invalid", size: bytes.length, metadata: "", additional: "", repeatCount: 0 };
        };

        void handlers;
        void profileHandler;
        """
    }

    private func multipartRuntimeTest() -> String {
        """
        import assert from "node:assert/strict";
        import express from "express";
        import { registerGeneratedRoutes } from "./dist/generated/routes.js";
        import { GeneratedValidationError } from "./dist/generated/runtime.js";

        class UploadFailure extends Error {}

        function parseMultipart(request) {
            const contentType = request.get("content-type") ?? "";
            const match = /boundary=(?:"([^"]+)"|([^;]+))/.exec(contentType);
            if (!match || !(request.body instanceof Uint8Array)) {
                throw new UploadFailure("Missing multipart body or boundary");
            }
            const boundary = match[1] ?? match[2];
            const source = Buffer.from(request.body).toString("latin1");
            const result = new Map();
            for (let section of source.split(`--${boundary}`).slice(1)) {
                if (section.startsWith("--")) break;
                if (section.startsWith("\\r\\n")) section = section.slice(2);
                if (section.endsWith("\\r\\n")) section = section.slice(0, -2);
                const separator = section.indexOf("\\r\\n\\r\\n");
                if (separator < 0) continue;
                const headers = section.slice(0, separator);
                const disposition = /content-disposition:\\s*form-data;([^\\r\\n]*)/i.exec(headers);
                const name = /(?:^\\s*|;\\s*)name="([^"]+)"/i.exec(disposition?.[1] ?? "")?.[1];
                const filename = /(?:^\\s*|;\\s*)filename="([^"]*)"/i.exec(disposition?.[1] ?? "")?.[1];
                if (!name) continue;
                const content = section.slice(separator + 4);
                const contentTypeMatch = /content-type:\\s*([^\\r\\n]+)/i.exec(headers);
                const part = {
                    filename: filename || undefined,
                    contentType: contentTypeMatch?.[1],
                    bytes: Uint8Array.from(Buffer.from(content, "latin1"))
                };
                result.set(name, [...(result.get(name) ?? []), part]);
            }
            return result;
        }

        const order = [];
        let factoryCalls = 0;
        let handlerCalls = 0;
        const integration = {
            secured: {
                middleware: [(request, response, next) => {
                    order.push("auth");
                    if (request.get("authorization") !== "Bearer accepted") {
                        response.status(401).json({ code: "AUTH_REQUIRED" });
                        return;
                    }
                    next();
                }],
                context: () => {
                    order.push("context");
                    return { identity: "user-1" };
                }
            }
        };
        const multipart = {
            filesUploadsProfile: (operation) => {
                factoryCalls += 1;
                assert.deepEqual(operation, {
                    id: "Files.Uploads.Profile",
                    requiredParts: ["file", "metadata"]
                });
                return {
                    middleware: [
                        express.raw({ type: "multipart/form-data", limit: "1mb" }),
                        (_request, _response, next) => { order.push("upload"); next(); }
                    ],
                    read: (request) => {
                        const parts = parseMultipart(request);
                        const file = parts.get("file")?.[0];
                        if (file?.contentType !== "image/png") {
                            throw new UploadFailure("Only PNG files are accepted");
                        }
                        return parts;
                    }
                };
            }
        };
        const handlers = {
            filesUploadsProfile: async (input, context) => {
                handlerCalls += 1;
                order.push("handler");
                const file = input.body.required.file[0];
                const metadata = input.body.required.metadata[0];
                const captions = input.body.parts.get("caption") ?? [];
                return {
                    filename: `${context.identity}:${file.filename}`,
                    size: file.bytes.length,
                    metadata: new TextDecoder().decode(metadata.bytes),
                    additional: captions.map((part) => new TextDecoder().decode(part.bytes)).join(","),
                    repeatCount: captions.length
                };
            },
            filesUploadsRawReceipt: async (input) => input
        };

        assert.throws(
            () => registerGeneratedRoutes(express(), handlers, undefined, { integration }),
            /Missing multipart adapter for filesUploadsProfile/
        );

        const app = express();
        registerGeneratedRoutes(app, handlers, undefined, { integration, multipart });
        assert.equal(factoryCalls, 1);
        app.use((error, _request, response, _next) => {
            if (error instanceof GeneratedValidationError) {
                response.status(400).json({ code: "INVALID_MULTIPART", operation: error.operationId });
                return;
            }
            if (error instanceof UploadFailure) {
                response.status(415).json({ code: "UPLOAD_REJECTED" });
                return;
            }
            response.status(500).json({ code: "UNEXPECTED" });
        });

        const server = app.listen(0);
        await new Promise((resolve) => server.once("listening", resolve));
        try {
            const address = server.address();
            const base = `http://127.0.0.1:${address.port}`;

            const rejectedAuth = await fetch(`${base}/profile`, { method: "POST" });
            assert.equal(rejectedAuth.status, 401);
            assert.equal(handlerCalls, 0);

            order.length = 0;
            const form = new FormData();
            form.append("file", new Blob([new Uint8Array([0, 255, 1])], { type: "image/png" }), "avatar.png");
            form.append("metadata", new Blob(["profile-metadata"], { type: "application/json" }));
            form.append("caption", "first");
            form.append("caption", "second");
            const uploaded = await fetch(`${base}/profile?compress=true`, {
                method: "POST",
                headers: { authorization: "Bearer accepted" },
                body: form
            });
            assert.equal(uploaded.status, 200);
            assert.deepEqual(await uploaded.json(), {
                filename: "user-1:avatar.png",
                size: 3,
                metadata: "profile-metadata",
                additional: "first,second",
                repeat_count: 2
            });
            assert.deepEqual(order, ["auth", "context", "upload", "handler"]);

            const missing = new FormData();
            missing.append("file", new Blob([new Uint8Array([1])], { type: "image/png" }), "avatar.png");
            const missingResponse = await fetch(`${base}/profile`, {
                method: "POST",
                headers: { authorization: "Bearer accepted" },
                body: missing
            });
            assert.equal(missingResponse.status, 400);
            assert.deepEqual(await missingResponse.json(), { code: "INVALID_MULTIPART", operation: "Files.Uploads.Profile" });

            const invalid = new FormData();
            invalid.append("file", new Blob(["not-an-image"], { type: "text/plain" }), "avatar.txt");
            invalid.append("metadata", "metadata");
            const invalidResponse = await fetch(`${base}/profile`, {
                method: "POST",
                headers: { authorization: "Bearer accepted" },
                body: invalid
            });
            assert.equal(invalidResponse.status, 415);
            assert.deepEqual(await invalidResponse.json(), { code: "UPLOAD_REJECTED" });

            const boundary = "raw-receipt-boundary";
            const rawText = `--${boundary}\\r\\nContent-Disposition: form-data; name="receipt"\\r\\n\\r\\nfirst\\r\\n--${boundary}\\r\\nContent-Disposition: form-data; name="receipt"\\r\\n\\r\\nsecond\\r\\n--${boundary}--\\r\\n`;
            const rawBytes = new TextEncoder().encode(rawText);
            const rawResponse = await fetch(`${base}/raw-receipts`, {
                method: "POST",
                headers: { "content-type": `multipart/form-data; boundary=${boundary}` },
                body: rawBytes
            });
            assert.equal(rawResponse.status, 200);
            assert.deepEqual(new Uint8Array(await rawResponse.arrayBuffer()), rawBytes);
        } finally {
            await new Promise((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
        }
        """
    }

    private func numericMatrixTypeFixture() -> String {
        """
        import type { GeneratedHandlers } from "./generated/routes.js";

        export const handlers: GeneratedHandlers = {
            matrixScalarsEchoMatrix: async (input) => ({ ...input, internalNote: "must not escape" }),
            matrixScalarsPutWide: async (input) => input,
            matrixScalarsDeleteArray: async (input) => input,
            matrixScalarsEchoDictionary: async (input) => input
        };

        const wideHandler: GeneratedHandlers["matrixScalarsPutWide"] = async (input) => {
            const exact: bigint = input;
            // @ts-expect-error wide root bodies remain bigint
            const rounded: number = input;
            void exact;
            void rounded;
            return input;
        };

        void wideHandler;
        """
    }

    private func numericMatrixRuntimeTest() -> String {
        """
        import assert from "node:assert/strict";
        import express from "express";
        import { registerGeneratedRoutes } from "./dist/generated/routes.js";
        import { GeneratedValidationError } from "./dist/generated/runtime.js";
        import { handlers } from "./dist/matrix-fixture.js";

        const app = express();
        registerGeneratedRoutes(app, handlers);
        app.use((error, _request, response, _next) => {
            response.status(error instanceof GeneratedValidationError && error.phase === "input" ? 400 : 500).end();
        });
        const server = app.listen(0);
        await new Promise((resolve) => server.once("listening", resolve));
        try {
            const address = server.address();
            const base = `http://127.0.0.1:${address.port}`;
            const matrix = '{"platform_signed":9223372036854775807,"platform_unsigned":18446744073709551615,"tiny_signed":-128,"small_signed":-32768,"medium_signed":-2147483648,"tiny_unsigned":255,"small_unsigned":65535,"medium_unsigned":4294967295,"wide_values":[-9223372036854775808,9223372036854775807],"unsigned_values":[0,18446744073709551615],"wide_map":{"minimum":-9223372036854775808,"maximum":9223372036854775807},"internal_note":"private"}';
            const matrixResponse = await fetch(`${base}/matrix`, {
                method: "POST",
                headers: { "content-type": "application/json" },
                body: matrix
            });
            assert.equal(matrixResponse.status, 200);
            assert.equal(await matrixResponse.text(), matrix.replace(',"internal_note":"private"', ""));

            const wideResponse = await fetch(`${base}/root/wide`, {
                method: "PUT",
                headers: { "content-type": "application/json" },
                body: "-9223372036854775808"
            });
            assert.equal(wideResponse.status, 200);
            assert.equal(await wideResponse.text(), "-9223372036854775808");

            const arrayResponse = await fetch(`${base}/root/array`, {
                method: "DELETE",
                headers: { "content-type": "application/json" },
                body: "[0,4294967295]"
            });
            assert.equal(arrayResponse.status, 200);
            assert.equal(await arrayResponse.text(), "[0,4294967295]");

            const dictionaryResponse = await fetch(`${base}/root/dictionary`, {
                method: "POST",
                headers: { "content-type": "application/json" },
                body: '{"minimum":-32768,"maximum":32767}'
            });
            assert.equal(dictionaryResponse.status, 200);
            assert.equal(await dictionaryResponse.text(), '{"minimum":-32768,"maximum":32767}');

            const outOfRange = await fetch(`${base}/root/dictionary`, {
                method: "POST",
                headers: { "content-type": "application/json" },
                body: '{"invalid":32768}'
            });
            assert.equal(outOfRange.status, 400);
        } finally {
            await new Promise((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
        }
        """
    }

    private func parameterRuntimeTest() -> String {
        """
        import assert from "node:assert/strict";
        import express from "express";
        import { registerGeneratedRoutes } from "./dist/generated/routes.js";
        import { GeneratedValidationError } from "./dist/generated/runtime.js";

        const app = express();
        let handlerCalls = 0;
        const handlers = {
            adminUsersInspect: async (input) => {
                handlerCalls += 1;
                return {
                    userId: input.userId.toString(),
                    tags: input.includeTags ?? [],
                    state: input.state,
                    magnitude: input.magnitude.toString(),
                    flags: input.flags,
                    integers: input.integers.map((value) => value.toString()),
                    states: input.states,
                    magnitudes: input.magnitudes.map((value) => value.toString()),
                    trace: input.trace,
                    session: input.sessionId,
                    when: input.when.toISOString(),
                    date: input.date,
                    time: input.time,
                    limit: input.limit,
                    small: input.small,
                    enabled: input.enabled
                };
            },
            adminUsersInspectFile: async (input) => input.fileName,
            adminUsersInspectNumericParameters: async (input) => {
                assert.equal(input.signed, -9223372036854775808n);
                assert.deepEqual(input.signedArray, [-1n, 9223372036854775807n]);
                assert.equal(input.smallSigned, -32768);
                assert.deepEqual(input.smallSignedArray, [-32768, 32767]);
                assert.deepEqual(input.mediumSignedArray, [-2147483648, 2147483647]);
                assert.equal(input.unsigned, 18446744073709551615n);
                assert.deepEqual(input.unsignedArray, [0n, 18446744073709551615n]);
                assert.deepEqual(input.smallUnsignedArray, [0, 65535]);
                assert.equal(input.mediumUnsigned, 4294967295);
                assert.deepEqual(input.mediumUnsignedArray, [0, 4294967295]);
                assert.equal(input.largeUnsigned, 18446744073709551615n);
                assert.deepEqual(input.largeUnsignedArray, [0n, 18446744073709551615n]);
                return "ok";
            }
        };
        registerGeneratedRoutes(app, handlers);
        app.use((error, _request, response, _next) => {
            const status = error instanceof GeneratedValidationError && error.phase === "input" ? 400 : 500;
            response.status(status).json({ error: "Request failed" });
        });
        const server = app.listen(0);
        await new Promise((resolve) => server.once("listening", resolve));
        try {
            const address = server.address();
            const response = await fetch(`http://127.0.0.1:${address.port}/users/9223372036854775807?include_tags=alpha%2Cbeta,gamma&state=ready&magnitude=9223372036854775807&flags=true,false&integers=-9223372036854775808,9223372036854775807&states=ready,ready&magnitudes=1,9223372036854775807&when=2026-09-21T12:34:56Z&date=2026-09-21&time=12:34:56.789&limit=32767&small=65535`, {
                headers: {
                    "x-trace": "trace-value",
                    "x-enabled": "true",
                    "cookie": "session_id=session%20value%2C1"
                }
            });
            assert.equal(response.status, 200);
            assert.deepEqual(await response.json(), {
                user_id: "9223372036854775807",
                tags: ["alpha", "beta", "gamma"],
                state: "ready",
                magnitude: "9223372036854775807",
                flags: [true, false],
                integers: ["-9223372036854775808", "9223372036854775807"],
                states: ["ready", "ready"],
                magnitudes: ["1", "9223372036854775807"],
                trace: "trace-value",
                session: "session value,1",
                when: "2026-09-21T12:34:56.000Z",
                date: "2026-09-21",
                time: "12:34:56.789",
                limit: 32767,
                small: 65535,
                enabled: true
            });

            const escapedPath = await fetch(`http://127.0.0.1:${address.port}/files/alpha%20beta`);
            const escapedPathBody = await escapedPath.text();
            assert.equal(escapedPath.status, 200, escapedPathBody);
            assert.equal(JSON.parse(escapedPathBody), "alpha beta");

            const numericParameters = await fetch(`http://127.0.0.1:${address.port}/numeric-parameters?signed=-9223372036854775808&signed_array=-1,9223372036854775807&small_signed=-32768&small_signed_array=-32768,32767&medium_signed_array=-2147483648,2147483647&unsigned=18446744073709551615&unsigned_array=0,18446744073709551615&small_unsigned_array=0,65535&medium_unsigned=4294967295&medium_unsigned_array=0,4294967295&large_unsigned=18446744073709551615&large_unsigned_array=0,18446744073709551615`);
            assert.equal(numericParameters.status, 200);
            assert.equal(await numericParameters.text(), '"ok"');

            const emptyArray = await fetch(`http://127.0.0.1:${address.port}/users/1?include_tags=&state=ready&magnitude=9223372036854775807&flags=true,false&integers=1&states=ready&magnitudes=1&when=2026-09-21T12:34:56Z&date=2026-09-21&time=12:34:56&limit=1&small=1`, {
                headers: { "x-trace": "trace-value", "x-enabled": "true", "cookie": "session_id=session" }
            });
            assert.equal(emptyArray.status, 200);
            assert.deepEqual((await emptyArray.json()).tags, []);

            const omittedArray = await fetch(`http://127.0.0.1:${address.port}/users/1?state=ready&magnitude=9223372036854775807&flags=true,false&integers=1&states=ready&magnitudes=1&when=2026-09-21T12:34:56Z&date=2026-09-21&time=12:34:56&limit=1&small=1`, {
                headers: { "x-trace": "trace-value", "x-enabled": "true", "cookie": "session_id=session" }
            });
            assert.equal(omittedArray.status, 200);
            assert.deepEqual((await omittedArray.json()).tags, []);

            const invalidWideInteger = await fetch(`http://127.0.0.1:${address.port}/users/9223372036854775808?state=ready&magnitude=9223372036854775807&flags=true,false&integers=1&states=ready&magnitudes=1&when=2026-09-21T12:34:56Z&date=2026-09-21&time=12:34:56&limit=1&small=1`, {
                headers: { "x-trace": "trace-value", "x-enabled": "true", "cookie": "session_id=session" }
            });
            assert.equal(invalidWideInteger.status, 400);

            const missingRequired = await fetch(`http://127.0.0.1:${address.port}/users/1?magnitude=9223372036854775807&flags=true,false&integers=1&states=ready&magnitudes=1&when=2026-09-21T12:34:56Z&date=2026-09-21&time=12:34:56&limit=1&small=1`, {
                headers: { "x-trace": "trace-value", "x-enabled": "true", "cookie": "session_id=session" }
            });
            assert.equal(missingRequired.status, 400);

            const invalidBoolean = await fetch(`http://127.0.0.1:${address.port}/users/1?state=ready&magnitude=9223372036854775807&flags=true,false&integers=1&states=ready&magnitudes=1&when=2026-09-21T12:34:56Z&date=2026-09-21&time=12:34:56&limit=1&small=1`, {
                headers: { "x-trace": "trace-value", "x-enabled": "not-a-boolean", "cookie": "session_id=session" }
            });
            assert.equal(invalidBoolean.status, 400);

            const invalidNarrowInteger = await fetch(`http://127.0.0.1:${address.port}/users/1?state=ready&magnitude=9223372036854775807&flags=true,false&integers=1&states=ready&magnitudes=1&when=2026-09-21T12:34:56Z&date=2026-09-21&time=12:34:56&limit=1&small=65536`, {
                headers: { "x-trace": "trace-value", "x-enabled": "true", "cookie": "session_id=session" }
            });
            assert.equal(invalidNarrowInteger.status, 400);

            const invalidDate = await fetch(`http://127.0.0.1:${address.port}/users/1?state=ready&magnitude=9223372036854775807&flags=true,false&integers=1&states=ready&magnitudes=1&when=2026-09-21T12:34:56Z&date=2026-02-30&time=12:34:56&limit=1&small=1`, {
                headers: { "x-trace": "trace-value", "x-enabled": "true", "cookie": "session_id=session" }
            });
            assert.equal(invalidDate.status, 400);

            const invalidTime = await fetch(`http://127.0.0.1:${address.port}/users/1?state=ready&magnitude=9223372036854775807&flags=true,false&integers=1&states=ready&magnitudes=1&when=2026-09-21T12:34:56Z&date=2026-09-21&time=25:34:56&limit=1&small=1`, {
                headers: { "x-trace": "trace-value", "x-enabled": "true", "cookie": "session_id=session" }
            });
            assert.equal(invalidTime.status, 400);

            const invalidEnum = await fetch(`http://127.0.0.1:${address.port}/users/1?state=unknown&magnitude=9223372036854775807&flags=true,false&integers=1&states=ready&magnitudes=1&when=2026-09-21T12:34:56Z&date=2026-09-21&time=12:34:56&limit=1&small=1`, {
                headers: { "x-trace": "trace-value", "x-enabled": "true", "cookie": "session_id=session" }
            });
            assert.equal(invalidEnum.status, 400);
            assert.equal(handlerCalls, 3);
        } finally {
            await new Promise((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
        }
        """
    }

    private func runtimeTest() -> String {
        """
        import assert from "node:assert/strict";
        import express from "express";
        import { z } from "zod";
        import { registerGeneratedRoutes } from "./dist/generated/routes.js";
        import { GeneratedValidationError } from "./dist/generated/runtime.js";

        const app = express();
        let handlerCalls = 0;
        const transformedInput = z.object({
            displayName: z.string(),
            active: z.boolean()
        }).refine((value) => value.displayName.length > 0, "displayName is required").transform((value) => ({
            name: value.displayName,
            active: value.active
        }));
        const transformedOutput = z.object({
            name: z.string(),
            active: z.boolean()
        }).transform((value) => ({
            displayName: value.name,
            active: value.active
        }));
        const pagedResultsSchema = (item) => z.object({
            results: z.array(item),
            next: z.string().nullable().optional(),
            count: z.union([z.number(), z.bigint()]).transform(Number).refine((value) => Number.isSafeInteger(value) && value >= 0).nullable().optional()
        });
        const externalInput = z.object({
            externalUser: z.object({ id: z.string(), role: z.string() }),
            pagedResults: pagedResultsSchema(z.string())
        }).transform((value) => ({
            id: value.externalUser.id,
            labels: value.pagedResults.results
        }));
        const externalOutput = z.object({
            id: z.string(),
            labels: z.array(z.string())
        }).transform((value) => ({
            externalUser: { id: value.id, role: "reader" },
            pagedResults: { results: value.labels, count: value.labels.length }
        }));
        const bindings = {
            adminUsersTransform: { input: transformedInput, output: transformedOutput },
            adminUsersExternal: { input: externalInput, output: externalOutput }
        };
        const handlers = {
            adminUsersCreate(input) {
                handlerCalls += 1;
                if (input.score === 1.5) {
                    assert.equal(input.profile.address.streetName, "Main Street");
                    assert.equal(input.profile.address.verified, true);
                    assert.equal(input.profile.previousAddresses[0].streetName, "Old Street");
                    assert.equal(input.profile.previousAddresses[1].verified, true);
                    assert.deepEqual(input.profile.labels, { primary: "home", secondary: null, extra: "removed" });
                    assert.equal(input.profile.nickname, null);
                    assert.equal(input.state, "in-progress");
                    assert.equal(input.magnitude, 9223372036854775807n);
                    assert.equal(input.createdAt.toISOString(), "2026-09-21T12:34:56.789Z");
                    assert.equal(input.website.toString(), "https://example.com/path");
                    assert.deepEqual(Array.from(input.payload), [1, 2, 3]);
                    assert.equal(input.identifier, "550e8400-e29b-41d4-a716-446655440000");
                    assert.equal(input.businessDate, "2026-09-21");
                    assert.equal(input.businessTime, "12:34:56.789");
                    assert.equal(input.id, 9223372036854775807n);
                    assert.equal(input.count, 18446744073709551615n);
                    assert.equal(input.attempts, 12);
                }
                if (input.score === 1.6) {
                    assert.equal(input.createdAt.toISOString(), "2026-09-21T12:34:56.789Z");
                    assert.equal(input.website.toString(), "https://example.com/path");
                    assert.deepEqual(Array.from(input.payload), [1, 2, 3]);
                    assert.equal(input.id, -9223372036854775808n);
                    assert.equal(input.count, 0n);
                    assert.equal(input.attempts, -2147483648);
                }
                if (input.score === 1.8) {
                    assert.ok(input.magnitude === 1 || input.magnitude === 1n);
                }
                if (input.score === 1.7) {
                    assert.equal(input.profile.nickname, undefined);
                }
                if (input.score === 2) {
                    return { ...input, score: "invalid" };
                }
                if (input.score === 3) {
                    return { ...input, id: 9223372036854775808n };
                }
                if (input.score === 4) {
                    return { ...input, createdAt: new Date("invalid") };
                }
                if (input.score === 5) {
                    return { ...input, website: {} };
                }
                if (input.score === 6) {
                    return { ...input, identifier: "not-a-UUID" };
                }
                if (input.score === 7) {
                    return { ...input, payload: [] };
                }
                if (input.score === 8) {
                    return { ...input, state: "unknown" };
                }
                return { ...input, privateValue: "removed" };
            },
            adminUsersCreateEvent(input) {
                if (input.objectType === "message") {
                    if (input.payload.messageText === "bad") {
                        return { ...input, payload: { messageText: 42 } };
                    }
                    assert.equal(input.payload.messageText, "hello");
                    assert.equal(input.visible, true);
                    assert.deepEqual(input.metadata, { source: "test", extra: "kept" });
                }
                if (input.objectType === "image") {
                    assert.equal(input.payload.imageUrl, "https://example.com/image.png");
                    assert.equal(input.visible, undefined);
                }
                return input;
            },
            adminUsersCreateEmbedded(input) {
                assert.equal(input.objectType, "message");
                assert.equal(input.payload.messageText, "embedded");
                assert.equal(input.visible, true);
                return input;
            },
            adminUsersUpdate(input) {
                if (input.profile !== undefined) {
                    assert.equal(input.profile.state, "modified");
                    assert.equal(input.profile.value?.address.streetName, "Main Street");
                }
                if (input.displayName !== undefined) {
                    assert.equal(input.displayName.state, "modified");
                    assert.equal(input.displayName.value, null);
                }
                if (input.nickname === "return-unmodified") {
                    return { ...input, displayName: { state: "unmodified" } };
                }
                return input;
            },
            adminUsersTransform(input) {
                assert.equal(input.name, "Ada");
                assert.equal(input.active, true);
                return input;
            },
            adminUsersExternal(input) {
                if (input.id === "invalid-output") {
                    return { id: input.id, labels: [42] };
                }
                assert.equal(input.id, "external-1");
                assert.deepEqual(input.labels, ["first", "second"]);
                return input;
            }
        };
        assert.throws(
            () => registerGeneratedRoutes(express(), handlers),
            /Missing schema binding for adminUsersExternal input/
        );
        registerGeneratedRoutes(app, handlers, bindings);
        app.use((error, _request, response, _next) => {
            const status = error instanceof GeneratedValidationError && error.phase === "input" ? 400 : 500;
            response.status(status).json({ error: "Request failed" });
        });
        const server = await new Promise((resolve) => {
            const value = app.listen(0, () => resolve(value));
        });
        const port = server.address().port;
        const url = "http://127.0.0.1:" + port + "/users";
        const eventUrl = "http://127.0.0.1:" + port + "/events";
        const embeddedUrl = "http://127.0.0.1:" + port + "/embedded-events";
        const patchUrl = "http://127.0.0.1:" + port + "/users/patch";
        const transformedUrl = "http://127.0.0.1:" + port + "/transformed-users";
        const externalUrl = "http://127.0.0.1:" + port + "/external";
        const body = (score, id, count, attempts, magnitude = "9223372036854775807") =>
            `{"display_name":"Ada","active":true,"score":${score},"profile":{"address":{"street_name":"Main Street","verified":true,"extra":"removed"},"previous_addresses":[{"street_name":"Old Street","verified":false},{"street_name":"New Street","verified":true}],"labels":{"primary":"home","secondary":null,"extra":"removed"},"nickname":null,"extra":"removed"},"state":"in-progress","magnitude":${magnitude},"created_at":"2026-09-21T12:34:56.789Z","website":"https://example.com/path","payload":"AQID","identifier":"550e8400-e29b-41d4-a716-446655440000","business_date":"2026-09-21","business_time":"12:34:56.789","id":${id},"count":${count},"attempts":${attempts}}`;

        const valid = await fetch(url, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: body("1.5", "9223372036854775807", "18446744073709551615", "12").replace("}", ',"undeclared":"removed"}')
        });
        assert.equal(valid.status, 200);
        assert.equal(await valid.text(), '{"display_name":"Ada","active":true,"score":1.5,"profile":{"address":{"street_name":"Main Street","verified":true},"previous_addresses":[{"street_name":"Old Street","verified":false},{"street_name":"New Street","verified":true}],"labels":{"primary":"home","secondary":null,"extra":"removed"},"nickname":null},"state":"in-progress","magnitude":9223372036854775807,"created_at":"2026-09-21T12:34:56.789Z","website":"https://example.com/path","payload":"AQID","identifier":"550e8400-e29b-41d4-a716-446655440000","business_date":"2026-09-21","business_time":"12:34:56.789","id":9223372036854775807,"count":18446744073709551615,"attempts":12}');

        const messageEvent = await fetch(eventUrl, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: '{"kind":"message","payload":{"message_text":"hello","extra":"removed"},"visible":true,"metadata":{"source":"test","extra":"kept"},"undeclared":"removed"}'
        });
        assert.equal(messageEvent.status, 200);
        assert.equal(await messageEvent.text(), '{"kind":"message","payload":{"message_text":"hello"},"visible":true,"metadata":{"source":"test","extra":"kept"}}');

        const alternateImageEvent = await fetch(eventUrl, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: '{"kind":"image","data":{"image_url":"https://example.com/image.png","extra":"removed"}}'
        });
        assert.equal(alternateImageEvent.status, 200);
        assert.equal(await alternateImageEvent.text(), '{"kind":"image","payload":{"image_url":"https://example.com/image.png"}}');

        const invalidDynamicDiscriminator = await fetch(eventUrl, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: '{"kind":"unknown","payload":{}}'
        });
        assert.equal(invalidDynamicDiscriminator.status, 400);

        const malformedDynamicPayload = await fetch(eventUrl, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: '{"kind":"message","payload":{}}'
        });
        assert.equal(malformedDynamicPayload.status, 400);

        const invalidDynamicOutput = await fetch(eventUrl, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: '{"kind":"message","payload":{"message_text":"bad"},"visible":true}'
        });
        assert.equal(invalidDynamicOutput.status, 500);

        const embeddedEvent = await fetch(embeddedUrl, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: '{"kind":"message","message_text":"embedded","visible":true,"extra":"removed"}'
        });
        assert.equal(embeddedEvent.status, 200);
        assert.equal(await embeddedEvent.text(), '{"kind":"message","visible":true,"message_text":"embedded"}');

        const assignedPatch = await fetch(patchUrl, {
            method: "PATCH",
            headers: { "content-type": "application/json" },
            body: '{"profile_data":{"address":{"street_name":"Main Street","verified":true},"previous_addresses":[],"labels":null,"nickname":null},"labels":{"source":"test","removed":null}}'
        });
        assert.equal(assignedPatch.status, 200);
        assert.equal(await assignedPatch.text(), '{"profile_data":{"address":{"street_name":"Main Street","verified":true},"previous_addresses":[],"labels":null,"nickname":null},"labels":{"source":"test","removed":null}}');

        const deletedPatch = await fetch(patchUrl, {
            method: "PATCH",
            headers: { "content-type": "application/json" },
            body: '{"display_name":null,"nickname":null,"labels":null}'
        });
        assert.equal(deletedPatch.status, 200);
        assert.equal(await deletedPatch.text(), '{"display_name":null,"nickname":null,"labels":null}');

        const unmodifiedPatch = await fetch(patchUrl, {
            method: "PATCH",
            headers: { "content-type": "application/json" },
            body: '{"nickname":"return-unmodified"}'
        });
        assert.equal(unmodifiedPatch.status, 200);
        assert.equal(await unmodifiedPatch.text(), '{"nickname":"return-unmodified"}');

        const transformed = await fetch(transformedUrl, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: '{"display_name":"Ada","active":true,"private":"removed"}'
        });
        assert.equal(transformed.status, 200);
        assert.equal(await transformed.text(), '{"display_name":"Ada","active":true}');

        const invalidTransformed = await fetch(transformedUrl, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: '{"display_name":"","active":true}'
        });
        assert.equal(invalidTransformed.status, 400);

        const external = await fetch(externalUrl, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: '{"external_user":{"id":"external-1","role":"admin","private":"removed"},"paged_results":{"results":["first","second"],"count":2,"private":"removed"},"private":"removed"}'
        });
        assert.equal(external.status, 200);
        assert.equal(await external.text(), '{"external_user":{"id":"external-1","role":"reader"},"paged_results":{"results":["first","second"],"count":2}}');

        const invalidExternalOutput = await fetch(externalUrl, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: '{"external_user":{"id":"invalid-output","role":"admin"},"paged_results":{"results":["first"],"count":1}}'
        });
        assert.equal(invalidExternalOutput.status, 500);

        const malformedPatch = await fetch(patchUrl, {
            method: "PATCH",
            headers: { "content-type": "application/json" },
            body: '{"display_name":{"state":"modified","value":42}}'
        });
        assert.equal(malformedPatch.status, 400);

        const applicationStateOnWire = await fetch(patchUrl, {
            method: "PATCH",
            headers: { "content-type": "application/json" },
            body: '{"display_name":{"state":"modified","value":"Ada"}}'
        });
        assert.equal(applicationStateOnWire.status, 400);

        const omittedOptional = await fetch(url, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: body("1.7", "1", "1", "12").replace(',"nickname":null', "")
        });
        assert.equal(omittedOptional.status, 200);
        assert.equal(await omittedOptional.text(), '{"display_name":"Ada","active":true,"score":1.7,"profile":{"address":{"street_name":"Main Street","verified":true},"previous_addresses":[{"street_name":"Old Street","verified":false},{"street_name":"New Street","verified":true}],"labels":{"primary":"home","secondary":null,"extra":"removed"}},"state":"in-progress","magnitude":9223372036854775807,"created_at":"2026-09-21T12:34:56.789Z","website":"https://example.com/path","payload":"AQID","identifier":"550e8400-e29b-41d4-a716-446655440000","business_date":"2026-09-21","business_time":"12:34:56.789","id":1,"count":1,"attempts":12}');

        const safeIntegerEnum = await fetch(url, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: body("1.8", "1", "1", "12", 1)
        });
        assert.equal(safeIntegerEnum.status, 200);
        assert.equal(await safeIntegerEnum.text(), '{"display_name":"Ada","active":true,"score":1.8,"profile":{"address":{"street_name":"Main Street","verified":true},"previous_addresses":[{"street_name":"Old Street","verified":false},{"street_name":"New Street","verified":true}],"labels":{"primary":"home","secondary":null,"extra":"removed"},"nickname":null},"state":"in-progress","magnitude":1,"created_at":"2026-09-21T12:34:56.789Z","website":"https://example.com/path","payload":"AQID","identifier":"550e8400-e29b-41d4-a716-446655440000","business_date":"2026-09-21","business_time":"12:34:56.789","id":1,"count":1,"attempts":12}');

        const signedBoundary = await fetch(url, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: body("1.6", "-9223372036854775808", "0", "-2147483648")
        });
        assert.equal(signedBoundary.status, 200);
        assert.equal(await signedBoundary.text(), '{"display_name":"Ada","active":true,"score":1.6,"profile":{"address":{"street_name":"Main Street","verified":true},"previous_addresses":[{"street_name":"Old Street","verified":false},{"street_name":"New Street","verified":true}],"labels":{"primary":"home","secondary":null,"extra":"removed"},"nickname":null},"state":"in-progress","magnitude":9223372036854775807,"created_at":"2026-09-21T12:34:56.789Z","website":"https://example.com/path","payload":"AQID","identifier":"550e8400-e29b-41d4-a716-446655440000","business_date":"2026-09-21","business_time":"12:34:56.789","id":-9223372036854775808,"count":0,"attempts":-2147483648}');

        const invalidOutput = await fetch(url, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: body("2", "1", "1", "12")
        });
        assert.equal(invalidOutput.status, 500);

        const invalidWideOutput = await fetch(url, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: body("3", "1", "1", "12")
        });
        assert.equal(invalidWideOutput.status, 500);

        const invalidDateOutput = await fetch(url, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: body("4", "1", "1", "12")
        });
        assert.equal(invalidDateOutput.status, 500);

        const invalidUrlOutput = await fetch(url, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: body("5", "1", "1", "12")
        });
        assert.equal(invalidUrlOutput.status, 500);

        const invalidUUIDOutput = await fetch(url, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: body("6", "1", "1", "12")
        });
        assert.equal(invalidUUIDOutput.status, 500);

        const invalidBinaryOutput = await fetch(url, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: body("7", "1", "1", "12")
        });
        assert.equal(invalidBinaryOutput.status, 500);

        const invalidEnumOutput = await fetch(url, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: body("8", "1", "1", "12")
        });
        assert.equal(invalidEnumOutput.status, 500);

        const invalid = await fetch(url, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: body("1.5", "9223372036854775807", "18446744073709551615", "12").replace(',"attempts":12}', "}")
        });
        assert.equal(invalid.status, 400);
        assert.equal(handlerCalls, 11);

        const invalidDate = await fetch(url, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: body("1.5", "1", "1", "12").replace("2026-09-21T12:34:56.789Z", "not-a-date")
        });
        assert.equal(invalidDate.status, 400);

        const invalidCalendarDate = await fetch(url, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: body("1.5", "1", "1", "12").replace("2026-09-21", "2026-02-31")
        });
        assert.equal(invalidCalendarDate.status, 400);

        const invalidUrl = await fetch(url, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: body("1.5", "1", "1", "12").replace("https://example.com/path", "not a url")
        });
        assert.equal(invalidUrl.status, 400);

        const invalidUUID = await fetch(url, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: body("1.5", "1", "1", "12").replace("550e8400-e29b-41d4-a716-446655440000", "not-a-uuid")
        });
        assert.equal(invalidUUID.status, 400);

        const invalidBase64 = await fetch(url, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: body("1.5", "1", "1", "12").replace("AQID", "not-base64")
        });
        assert.equal(invalidBase64.status, 400);

        const invalidEnumInput = await fetch(url, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: body("1.5", "1", "1", "12").replace("in-progress", "unknown")
        });
        assert.equal(invalidEnumInput.status, 400);

        const missingRequiredEnum = await fetch(url, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: body("1.5", "1", "1", "12").replace(',"state":"in-progress"', "")
        });
        assert.equal(missingRequiredEnum.status, 400);

        const wrongEnumType = await fetch(url, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: body("1.5", "1", "1", "12").replace('"magnitude":9223372036854775807', '"magnitude":"9223372036854775807"')
        });
        assert.equal(wrongEnumType.status, 400);

        const negativeUnsigned = await fetch(url, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: body("1.5", "1", "-1", "12")
        });
        assert.equal(negativeUnsigned.status, 400);

        const tooLargeSigned = await fetch(url, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: body("1.5", "9223372036854775808", "1", "12")
        });
        assert.equal(tooLargeSigned.status, 400);

        const narrowOutOfRange = await fetch(url, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: body("1.5", "1", "1", "2147483648")
        });
        assert.equal(narrowOutOfRange.status, 400);

        const fractionalWide = await fetch(url, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: body("1.5", "1.5", "1", "12")
        });
        assert.equal(fractionalWide.status, 400);

        const malformed = await fetch(url, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: "{"
        });
        assert.equal(malformed.status, 400);
        assert.equal(handlerCalls, 11);

        await new Promise((resolve) => server.close(resolve));
        """
    }

    private func typeFixture() -> String {
        """
        import { z } from "zod";
        import type { GeneratedHandlers, GeneratedOperationBinding, GeneratedSchemaBindings } from "./generated/routes.js";

        type PagedResults<T> = { results: T[]; next?: string | null; count?: number | null };

        const pagedResultsSchema = <T extends z.ZodTypeAny>(item: T): z.ZodType<PagedResults<z.output<T>>> => z.object({
            results: z.array(item),
            next: z.string().nullable().optional(),
            count: z.number().nullable().optional()
        });

        type ExternalHandlerInput = { id: string; labels: string[] };
        type ExternalHandlerOutput = { id: string; labels: string[] };
        type ExternalWireOutput = { externalUser: { id: string }; pagedResults: PagedResults<string> };

        type BindingContract = GeneratedSchemaBindings & {
            adminUsersExternal: GeneratedOperationBinding<ExternalHandlerInput, ExternalHandlerOutput, ExternalWireOutput>;
        };

        const customBindings = {
            adminUsersTransform: {
                input: z.object({ displayName: z.string(), active: z.boolean() }).transform((value) => ({ name: value.displayName, active: value.active })),
                output: z.object({ name: z.string(), active: z.boolean() }).transform((value) => ({ displayName: value.name, active: value.active }))
            },
            adminUsersExternal: {
                input: z.object({ externalUser: z.object({ id: z.string() }), pagedResults: pagedResultsSchema(z.string()) }).transform((value) => ({ id: value.externalUser.id, labels: value.pagedResults.results })),
                output: z.object({ id: z.string(), labels: z.array(z.string()) }).transform((value) => ({ externalUser: { id: value.id }, pagedResults: { results: value.labels, count: value.labels.length } }))
            }
        };
        const typedBindings: BindingContract = customBindings;

        const incompatibleExternalBinding: BindingContract = {
            adminUsersExternal: {
                // @ts-expect-error external binding contracts reject incompatible transformed values
                input: z.object({ externalUser: z.object({ id: z.number() }), pagedResults: pagedResultsSchema(z.string()) }).transform((value) => ({ id: value.externalUser.id, labels: value.pagedResults.results }))
            }
        };

        const incompatibleGenericBinding: BindingContract = {
            adminUsersExternal: {
                // @ts-expect-error nested generic arguments remain part of the application binding contract
                input: z.object({ externalUser: z.object({ id: z.string() }), pagedResults: pagedResultsSchema(z.number()) }).transform((value) => ({ id: value.externalUser.id, labels: value.pagedResults.results }))
            }
        };

        const incompatibleOutputBinding: BindingContract = {
            adminUsersExternal: {
                // @ts-expect-error output bindings reject incompatible generated wire values
                output: z.object({ id: z.string(), labels: z.array(z.string()) }).transform((value) => ({ externalUser: { id: value.id }, pagedResults: { results: [42], count: 1 } }))
            }
        };

        const validHandlers: GeneratedHandlers<typeof customBindings> = {
            adminUsersCreate: async (input) => input,
            adminUsersCreateEvent: async (input) => input,
            adminUsersCreateEmbedded: async (input) => input,
            adminUsersUpdate: async (input) => input,
            adminUsersTransform: async (input) => ({ name: input.name, active: input.active }),
            adminUsersExternal: async (input) => ({ id: input.id, labels: input.labels }),
        };

        const incompatibleHandlers: Pick<GeneratedHandlers, "adminUsersCreate"> = {
            // @ts-expect-error generated handlers reject incompatible output types
            adminUsersCreate: async () => {
                return { displayName: "Ada", active: true, score: "not-a-number" };
            }
        };

        const incompatibleDynamicHandlers: Pick<GeneratedHandlers, "adminUsersCreateEvent"> = {
            // @ts-expect-error generated handlers reject incompatible dynamic payload types
            adminUsersCreateEvent: async () => {
                return { objectType: "message", payload: { messageText: 42 } };
            }
        };

        // @ts-expect-error application handlers must return the binding input type
        const incompatibleTransformHandler: GeneratedHandlers<typeof customBindings>["adminUsersTransform"] = async () => {
            return { name: 42, active: true };
        };

        void validHandlers;
        void incompatibleHandlers;
        void incompatibleDynamicHandlers;
        void incompatibleTransformHandler;
        void typedBindings;
        void incompatibleExternalBinding;
        void incompatibleGenericBinding;
        void incompatibleOutputBinding;
        """
    }
}
