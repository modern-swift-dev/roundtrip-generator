import Foundation
import GeneratorModels
@testable import OpenApiYamlGenerator
import Testing

@Suite(.serialized) struct OpenApiYamlGeneratorTests {
    @Test func `shared reference graphs register each schema once`() {
        let depth = 24
        var model = ApiTypeSchema.object(typeName: "Leaf", properties: [.string("value")])
        for level in 0 ..< depth {
            model = .object(typeName: "Level\(level)", properties: [
                ApiModelProperty(rawName: "left", propertyName: "left", dataType: model.asRef),
                ApiModelProperty(rawName: "right", propertyName: "right", dataType: model.asRef)
            ])
        }
        let package = ApiPackage(
            name: "Shared", targetDirUrl: URL(fileURLWithPath: "/unused"),
            modules: [], referencedModules: [], references: [model],
            commonReferences: [], imports: [],
        )
        let yaml = OpenApiYamlPackageGenerator(package: package).generatedFile().contents
        #expect(yaml.split(separator: "\n").filter { $0 == "      type: \"object\"" }.count == depth + 1)
        #expect(yaml.components(separatedBy: "#/components/schemas/Leaf").count - 1 == 2)
        #expect(yaml.contains("    Leaf:"))
    }

    @Test func `deeply nested models register each schema`() {
        // A single chain previously traversed each subtree twice at every level.
        let depth = 18
        var model = ApiTypeSchema.object(typeName: "Leaf", properties: [.string("value")])
        for level in 0 ..< depth {
            model = .object(typeName: "Level\(level)", properties: [
                ApiModelProperty(rawName: "child", propertyName: "child", dataType: model)
            ])
        }
        let package = ApiPackage(
            name: "Nested", targetDirUrl: URL(fileURLWithPath: "/unused"),
            modules: [], referencedModules: [], references: [model],
            commonReferences: [], imports: [],
        )
        let yaml = OpenApiYamlPackageGenerator(package: package).generatedFile().contents
        #expect(yaml.split(separator: "\n").filter { $0 == "      type: \"object\"" }.count == depth + 1)
        #expect(yaml.contains("    Leaf:"))
        for level in 0 ..< depth {
            #expect(yaml.contains("    Level\(level):"))
        }
    }

    @Test func `generated yaml contains paths schemas bodies and security`() throws {
        let files = OpenApiYamlPackageGenerator(package: testPackage()).generatedFiles()
        let file = try #require(files.first)
        let yaml = file.contents

        #expect(file.relativePath == "openapi.yaml")
        #expect(yaml.hasPrefix("# Generated code. Do not edit."))
        #expect(yaml.contains("openapi: 3.1.2"))
        #expect(yaml.contains("""
        info:
          title: "Test"
          version: "1.0.0"
        """))
        #expect(yaml.contains(#""/users/{id}":"#))
        #expect(yaml.contains("operationId: \"AdminUsersGetUser\""))
        #expect(yaml.contains("name: \"Authorization\""))
        #expect(yaml.contains("apiKey: []"))
        #expect(yaml.contains(#""200":"#))
        #expect(yaml.contains("$ref: \"#/components/schemas/User\""))
        #expect(yaml
            .contains(
                "User:\n      type: \"object\"\n      properties:\n        id:\n          type: \"integer\"\n          format: \"int64\"\n        display_name:\n          type: \"string\"\n      required:\n        - \"id\"\n        - \"display_name\"",
            ))
    }

    @Test func `generated yaml includes runtime multipart binary cookie and external references`() {
        let receipt = ApiTypeSchema.object(typeName: "Receipt", properties: [
            .string("state")
        ])
        let operation = ApiOperation.post(
            name: "upload",
            path: .relative("/uploads"),
            security: .optional,
            parameters: [
                .cookie("session_id", .string(), propertyName: "sessionId").optional
            ],
            requestType: .multiPart(["file", "metadata"]),
            responseType: .binary(mimeType: "application/zip"),
            acceptableStatuses: [200, 202],
            extraImports: [],
        )
        let runtime = ApiOperation.get(
            name: "follow",
            path: .runtime,
            security: .unsecured,
            response: .genericReference(typeName: "PagedResults", genericTypes: [receipt.asRef]),
        )
        let package = ApiPackage(
            name: "Runtime",
            targetDirUrl: URL(fileURLWithPath: "/tmp/openapi"),
            modules: [
                ApiModule(name: "Files", definitions: [
                    ApiService(name: "Uploads", operations: [operation, runtime], references: [receipt])
                ])
            ],
            referencedModules: [],
            references: [],
            commonReferences: [],
            imports: [],
        )

        let yaml = OpenApiYamlPackageGenerator(package: package).generatedFile().contents

        #expect(yaml.contains(#""/_runtime/{runtimeUrl}":"#))
        #expect(yaml.contains("x-runtime-url: true"))
        #expect(yaml.contains("format: \"uri\""))
        #expect(yaml.contains("multipart/form-data:"))
        #expect(yaml.contains("file:\n                  type: \"string\"\n                  format: \"binary\""))
        #expect(yaml.contains("\"application/zip\":"))
        #expect(yaml.contains("in: \"cookie\""))
        #expect(yaml.contains("PagedResultsReceipt:"))
        #expect(yaml.contains("$ref: \"#/components/schemas/PagedResultsReceipt\""))
        #expect(yaml.contains("- {}"))
    }

    @Test func `write refuses to overwrite user owned file`() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let fileURL = root.appendingPathComponent("openapi.yaml")
        try "user file\n".write(to: fileURL, atomically: true, encoding: .utf8)

        let file = OpenApiYamlPackageGenerator(package: testPackage(targetDirUrl: root)).generatedFile()

        #expect(throws: OpenApiYamlGeneratedTextFileError.refusingToOverwriteUserFile("openapi.yaml")) {
            try file.write(to: root)
        }
    }

    private func testPackage(targetDirUrl: URL = URL(fileURLWithPath: "/tmp/openapi")) -> ApiPackage {
        let user = ApiTypeSchema.object(typeName: "User", properties: [
            .int64("id"),
            .string("display_name", propertyName: "displayName"),
            .string("internal_note").unpublished
        ])
        let get = ApiOperation.get(
            name: "getUser",
            path: .relative("/users/{id}"),
            security: .secured,
            parameters: [
                .path("id", .int64())
            ],
            response: user.asRef,
        )
        let create = ApiOperation.post(
            name: "createUser",
            path: .relative("/users"),
            security: .unsecured,
            request: user.asRef,
            response: user.asRef,
            acceptableStatuses: [201],
        )
        return ApiPackage(
            name: "Test",
            targetDirUrl: targetDirUrl,
            modules: [
                ApiModule(name: "Admin", definitions: [
                    ApiService(name: "Users", operations: [get, create], references: [user])
                ])
            ],
            referencedModules: [],
            references: [],
            commonReferences: [],
            imports: [],
        )
    }
}
