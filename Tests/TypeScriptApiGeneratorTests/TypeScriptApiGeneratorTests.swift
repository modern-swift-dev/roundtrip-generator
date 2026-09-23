import Foundation
import GeneratorModels
import Testing
@testable import TypeScriptApiGenerator

@Suite(.serialized) struct TypeScriptApiGeneratorTests {
    @Test func `options expose package defaults`() {
        let options = TypeScriptGeneratorOptions()

        #expect(options.packageName == "generated-api")
        #expect(options.packageVersion == "1.0.0")
        #expect(options.sourceDirectory == "src/generated")
        #expect(options.generateRuntime)
        #expect(options.flavor == .plain)
        #expect(options.mapping(for: "PagedResults")?.typeScriptType == "PagedResults")
        #expect(options.overwritePolicy == .replaceManagedFiles)
    }

    @Test func `generated project includes package tsconfig runtime models and operations`() throws {
        let files = try TypeScriptApiPackageGenerator(package: testPackage()).generatedFiles()
        let paths = Set(files.map(\.relativePath))

        #expect(paths.contains("package.json"))
        #expect(paths.contains("tsconfig.json"))
        #expect(paths.contains("src/index.ts"))
        #expect(paths.contains("src/generated/index.ts"))
        #expect(paths.contains("src/generated/runtime.ts"))
        #expect(paths.contains("src/generated/models.ts"))
        #expect(paths.contains("src/generated/operations.ts"))
        #expect(!paths.contains("src/generated/tanstack-query.ts"))

        let packageJSON = try #require(files.first { $0.relativePath == "package.json" }?.contents)
        #expect(packageJSON.contains(#""x-generated": "Generated code. Do not edit.""#))
        #expect(packageJSON.contains(#""build": "tsc -p tsconfig.json""#))
        #expect(!packageJSON.contains(#""@tanstack/react-query""#))

        let tsconfig = try #require(files.first { $0.relativePath == "tsconfig.json" }?.contents)
        #expect(tsconfig.hasPrefix("// Generated code. Do not edit."))
        #expect(tsconfig.contains(#""strict": true"#))
    }

    @Test func `tan stack query flavor generates options factories and dependencies`() throws {
        let createOperation = ApiOperation.post(
            name: "create",
            path: .relative("/users"),
            security: .unsecured,
            requestType: .none,
            responseType: .none,
        )
        let files = try TypeScriptApiPackageGenerator(
            package: testPackage(operations: nil).addingOperation(createOperation),
            options: TypeScriptGeneratorOptions(flavor: .tanStackQuery),
        )
        .generatedFiles()
        let paths = Set(files.map(\.relativePath))

        #expect(paths.contains("src/generated/tanstack-query.ts"))

        let packageJSON = try #require(files.first { $0.relativePath == "package.json" }?.contents)
        #expect(packageJSON.contains(#""peerDependencies": {"#))
        #expect(packageJSON.contains(#""@tanstack/react-query": "^5.0.0""#))

        let index = try #require(files.first { $0.relativePath == "src/generated/index.ts" }?.contents)
        #expect(index.contains(#"export * from "./tanstack-query.js";"#))

        let tanStack = try #require(files.first { $0.relativePath == "src/generated/tanstack-query.ts" }?.contents)
        #expect(tanStack.contains(#"import { mutationOptions, queryOptions } from "@tanstack/react-query";"#))
        #expect(tanStack.contains(#"AdminUsersGetRequest"#))
        #expect(tanStack.contains(#"export function adminUsersGetKey(request: AdminUsersGetRequest)"#))
        #expect(tanStack.contains(#"return ["AdminUsersApi", "get_", request] as const;"#))
        #expect(tanStack.contains(#"export function adminUsersGetQueryOptions(api: AdminUsersApi, request: AdminUsersGetRequest)"#))
        #expect(tanStack.contains(#"queryFn: () => api.get_(request)"#))
        #expect(tanStack.contains(#"export function adminUsersCreateMutationOptions(api: AdminUsersApi)"#))
        #expect(tanStack.contains(#"mutationFn: (request: AdminUsersCreateRequest) => api.create(request)"#))
    }

    @Test func `generated type script contains models operations services and runtime`() throws {
        let files = try TypeScriptApiPackageGenerator(package: testPackage()).generatedFiles()
        let output = files.map(\.contents).joined(separator: "\n")

        #expect(output.contains("export interface User"))
        #expect(output.contains("displayName: string;"))
        #expect(output.contains("export function decodeUser"))
        #expect(output.contains("export interface AdminUsersGetRequest"))
        #expect(output.contains("id: number;"))
        #expect(output.contains("fields?: string[] | null;"))
        #expect(output.contains("export function buildAdminUsersGetRequest"))
        #expect(output.contains("export interface AdminUsersApi"))
        #expect(output.contains("export class AdminUsersApiService"))
        #expect(output.contains("export class AdminApiModule"))
        #expect(output.contains("export class ApiModules"))
        #expect(output.contains("export class ApiClient"))
        #expect(output.contains("this.client.execute(buildAdminUsersGetRequest(adaptedRequest), [200], ModelCodecs.decodeUser)"))
    }

    @Test func `omittable model fields exclude null and preserve omission`() throws {
        let update = ApiTypeSchema.object(typeName: "UpdateFields", properties: [
            .string("name").omittable,
            .string("nullable_note", propertyName: "nullableNote").optional
        ])
        let files = try TypeScriptApiPackageGenerator(
            package: testPackage(response: update.asRef, references: [update]),
        ).generatedFiles()
        let models = try #require(files.first { $0.relativePath == "src/generated/models.ts" }?.contents)

        #expect(models.contains("name?: string;"))
        #expect(models.contains("nullableNote?: string | null;"))
        #expect(models.contains("name: object[\"name\"] === undefined ? undefined"))
        #expect(models.contains("if (value.name !== undefined)"))
        #expect(models.contains("if (value.name === null) throw"))
    }

    @Test(.enabled(if: ProcessInfo.processInfo.environment["ROUNDTRIP_TYPESCRIPT_RUNTIME_TEST"] != nil))
    func `generated type script client enforces omittable fields at wire boundary`() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let update = ApiTypeSchema.object(typeName: "UpdateFields", properties: [
            .string("name").omittable,
            .string("nullable_note", propertyName: "nullableNote").optional
        ])
        let files = try TypeScriptApiPackageGenerator(
            package: testPackage(response: update.asRef, references: [update]),
        ).generatedFiles()
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
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

        try runNpm(["install", "--ignore-scripts", "--package-lock=false"], in: root)
        try runNpm(["run", "build"], in: root)
        try runNpm(["exec", "--", "node", "test.mjs"], in: root)
    }

    @Test func `generated type script uses swift defaults for optional bool and dynamic garbage`() throws {
        let payload = ApiTypeSchema.object(typeName: "Payload", properties: [.string("value")])
        let dynamic = ApiTypeSchema.dynamicObject(
            typeName: "EventEnvelope",
            objectTypePropertyName: "kind",
            objectDataPropertyName: "payload",
            alternateObjectDataPropertyName: "data",
            objectTypes: [
                (objectTypeName: "Message", objectTypeRawName: "message", objectType: payload.asRef)
            ],
            supportGarbage: true,
            extraProperties: [.bool("visible", required: false)],
        )
        let operation = ApiOperation.get(
            name: "read",
            path: .relative("/events"),
            security: .unsecured,
            parameters: [.query("enabled", .bool(false)).optional],
            response: dynamic.asRef,
        )
        let files = try TypeScriptApiPackageGenerator(
            package: testPackage(operations: [operation], references: [dynamic, payload]),
        )
        .generatedFiles()
        let output = files.map(\.contents).joined(separator: "\n")

        #expect(output.contains("enabled?: boolean | null;"))
        #expect(output.contains("appendQueryParameter(queryParameters, \"enabled\", (request.enabled ?? false));"))
        #expect(output.contains("export type EventEnvelope"))
        #expect(output.contains("{ objectType: \"__garbage__\"; rawValue: unknown }"))
        #expect(output.contains("const objectType = object[\"kind\"];"))
        #expect(output.contains("payload: decodePayload((object[\"payload\"] ?? object[\"data\"])),"))
    }

    @Test func `generated type script decodes array and dictionary responses`() throws {
        let payload = ApiTypeSchema.object(typeName: "Payload", properties: [.date("created_at", propertyName: "createdAt")])
        let listOperation = ApiOperation.get(
            name: "list",
            path: .relative("/payloads"),
            security: .unsecured,
            response: .array(payload.asRef),
        )
        let dictionaryOperation = ApiOperation.get(
            name: "dictionary",
            path: .relative("/payloads/by-key"),
            security: .unsecured,
            response: .keyedByString(payload.asRef, isOptional: true),
        )
        let files = try TypeScriptApiPackageGenerator(
            package: testPackage(operations: [listOperation, dictionaryOperation], references: [payload]),
        )
        .generatedFiles()
        let operations = try #require(files.first { $0.relativePath == "src/generated/operations.ts" }?.contents)

        #expect(operations.contains("((value ?? []) as unknown[]).map(ModelCodecs.decodePayload)"))
        #expect(operations.contains("(item == null ? null : ModelCodecs.decodePayload(item))"))
    }

    @Test func `mapped type imports are emitted`() throws {
        let external = ApiTypeSchema.reference(typeName: "ExternalThing", strict: false)
        let files = try TypeScriptApiPackageGenerator(
            package: testPackage(response: external),
            options: TypeScriptGeneratorOptions(
                typeMappings: TypeScriptTypeMapping.defaultMappings + [
                    .init(apiTypeName: "ExternalThing", typeScriptType: "ExternalThing", imports: ["import type { ExternalThing } from \"external-lib\";"])
                ],
            ),
        )
        .generatedFiles()
        let models = try #require(files.first { $0.relativePath == "src/generated/models.ts" }?.contents)

        #expect(models.contains("import type { ExternalThing } from \"external-lib\";"))
    }

    @Test func `shared schema graph generates each declaration once`() throws {
        var type = ApiTypeSchema.object(typeName: "SharedLeaf", properties: [.string("value")])
        for depth in 0 ..< 24 {
            type = .object(typeName: "SharedNode\(depth)", properties: [
                .init(rawName: "left", propertyName: "left", dataType: type.asRef),
                .init(rawName: "right", propertyName: "right", dataType: type.asRef)
            ])
        }
        let files = try TypeScriptApiPackageGenerator(
            package: testPackage(response: type.asRef, references: []),
        ).generatedFiles()
        let models = try #require(files.first { $0.relativePath == "src/generated/models.ts" }?.contents)
        #expect(models.components(separatedBy: "export interface ").count - 1 == 25)
        #expect(models.contains("export interface SharedLeaf"))
        #expect(models.contains("export interface SharedNode23"))
    }

    @Test func `nested reference declarations are collected`() throws {
        let child = ApiTypeSchema.object(typeName: "Child", properties: [.string("value")])
        let parent = ApiTypeSchema.object(typeName: "Parent", properties: [
            .init(rawName: "child", propertyName: "child", dataType: child.asRef)
        ])
        let files = try TypeScriptApiPackageGenerator(
            package: testPackage(operations: [], references: [parent]),
        ).generatedFiles()
        let models = try #require(files.first { $0.relativePath == "src/generated/models.ts" }?.contents)
        #expect(models.contains("export interface Parent"))
        #expect(models.contains("export interface Child"))
    }

    @Test func `duplicate generated type script operation names fail validation`() {
        let operations = [
            ApiOperation.get(name: "read-user", path: .relative("/one"), security: .unsecured),
            ApiOperation.get(name: "read_user", path: .relative("/two"), security: .unsecured)
        ]

        #expect(throws: TypeScriptGeneratorError.invalidPackage(reason: "definition Users has duplicate request type names")) {
            try TypeScriptApiPackageGenerator(package: testPackage(operations: operations, references: [])).generatedFiles()
        }
    }

    @Test(arguments: ["", "/models.ts", "../models.ts", "src/../models.ts"])
    func `generated text file rejects invalid paths without writing`(path: String) {
        #expect(throws: TypeScriptGeneratedTextFileError.invalidRelativePath(path)) {
            try TypeScriptGeneratedTextFile(relativePath: path, contents: "")
                .validatedPathComponents()
        }
    }

    @Test func `generated text file validates nested path without writing`() throws {
        let file = TypeScriptGeneratedTextFile(relativePath: "src/generated/models.ts", contents: "")
        #expect(try file.validatedPathComponents() == ["src", "generated", "models.ts"])
    }

    @Test func `generated text file refuses to overwrite user owned files`() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try "user".write(to: root.appendingPathComponent("package.json"), atomically: true, encoding: .utf8)

        #expect(throws: TypeScriptGeneratedTextFileError.refusingToOverwriteUserFile("package.json")) {
            try TypeScriptGeneratedTextFile(relativePath: "package.json", contents: "{}")
                .write(to: root, overwritePolicy: .replaceManagedFiles)
        }
    }

    @Test func `unresolved external type requires mapping`() {
        let external = ApiTypeSchema.reference(typeName: "ExternalThing", strict: false)

        #expect(throws: TypeScriptGeneratorError.unresolvedExternalType("ExternalThing")) {
            try TypeScriptApiPackageGenerator(package: testPackage(response: external)).generatedFiles()
        }
    }

    private func testPackage(
        response: ApiTypeSchema? = nil,
        operations: [ApiOperation]? = nil,
        references: [ApiTypeSchema]? = nil,
    ) -> ApiPackage {
        let user = ApiTypeSchema.object(
            typeName: "User",
            properties: [
                .string("display_name", propertyName: "displayName"),
                .int64("id")
            ],
            protocols: ["Identifiable"],
        )
        let operation = ApiOperation.get(
            name: "get",
            path: .relative("/users/{id}"),
            security: .optional,
            parameters: [
                .path("id", .int64()),
                .query("fields", .stringArray()).optional
            ],
            response: response ?? user.asRef,
        )
        return ApiPackage(
            name: "Test",
            targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true),
            modules: [
                ApiModule(name: "Admin", definitions: [
                    ApiService(name: "Users", operations: operations ?? [operation], references: references ?? [user])
                ])
            ],
            referencedModules: [],
            references: [],
            commonReferences: [],
            imports: [],
        )
    }

    private func runNpm(_ arguments: [String], in directory: URL) throws {
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
            let message = String(data: output.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            throw NSError(domain: "TypeScriptApiGeneratorTests", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: message])
        }
    }
}

private extension ApiPackage {
    func addingOperation(_ operation: ApiOperation) -> ApiPackage {
        ApiPackage(
            name: name,
            targetDirUrl: targetDirUrl,
            modules: modules.map { module in
                ApiModule(
                    name: module.name,
                    definitions: module.definitions.map { definition in
                        ApiService(
                            name: definition.name,
                            operations: definition.operations + [operation],
                            references: definition.referencedTypes,
                        )
                    },
                    references: module.references,
                )
            },
            referencedModules: referencedModules,
            references: references,
            commonReferences: commonReferences,
            imports: imports,
            generateApiModules: generateApiModules,
        )
    }
}
