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
        #expect(paths.contains("src/generated/models.ts"))
        #expect(paths.contains("src/generated/routes.ts"))

        let routes = try #require(files.first { $0.relativePath == "src/generated/routes.ts" }?.contents)
        #expect(routes.contains("export function registerGeneratedRoutes"))
        #expect(routes.contains("app.post(\"/users\""))

        let models = try #require(files.first { $0.relativePath == "src/generated/models.ts" }?.contents)
        #expect(models.contains("display_name"))
        #expect(models.contains("displayName"))

        let packageJSON = try #require(files.first { $0.relativePath == "package.json" }?.contents)
        #expect(packageJSON.contains(#""express": "^5.2.1""#))
        #expect(packageJSON.contains(#""zod": "^4.4.3""#))
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

    @Test func securedOperationsAreRejectedUntilAuthenticationIntegrationExists() {
        let operation = ApiOperation.get(
            name: "read",
            path: .relative("/users"),
            security: .secured,
            response: .object(typeName: "User", properties: []).asRef,
        )

        #expect(throws: TypeScriptBackendGeneratorError.unsupportedSecurity(operationName: "Read")) {
            try TypeScriptBackendApiPackageGenerator(package: testPackage(operation: operation)).generatedFiles()
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
