import Foundation
import GeneratorModels
@testable import OpenApiYamlGenerator
import Testing

@Suite(.serialized) struct OpenApiYamlGeneratorTests {
    @Test func `shared reference graphs register each schema once`() throws {
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
        let yaml = try OpenApiYamlPackageGenerator(package: package).generatedFile().contents
        #expect(yaml.split(separator: "\n").filter { $0 == "      type: \"object\"" }.count == depth + 1)
        #expect(yaml.components(separatedBy: "#/components/schemas/Leaf").count - 1 == 2)
        #expect(yaml.contains("    Leaf:"))
    }

    @Test func `deeply nested models register each schema`() throws {
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
        let yaml = try OpenApiYamlPackageGenerator(package: package).generatedFile().contents
        #expect(yaml.split(separator: "\n").filter { $0 == "      type: \"object\"" }.count == depth + 1)
        #expect(yaml.contains("    Leaf:"))
        for level in 0 ..< depth {
            #expect(yaml.contains("    Level\(level):"))
        }
    }

    @Test func `generated yaml contains paths schemas bodies and security`() throws {
        let files = try OpenApiYamlPackageGenerator(package: testPackage()).generatedFiles()
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

    @Test func `generated yaml excludes runtime paths and includes multipart binary cookie and external references`() throws {
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

        let yaml = try OpenApiYamlPackageGenerator(package: package).generatedFile().contents

        #expect(!yaml.contains(#""/_runtime/{runtimeUrl}":"#))
        #expect(!yaml.contains("x-runtime-url: true"))
        #expect(yaml.contains("multipart/form-data:"))
        #expect(yaml.contains("file:\n                  type: \"string\"\n                  format: \"binary\""))
        #expect(yaml.contains("\"application/zip\":"))
        #expect(yaml.contains("in: \"cookie\""))
        #expect(yaml.contains("- {}"))
    }

    @Test func `generated yaml documents declared public errors and excludes client only paths`() throws {
        let success = ApiTypeSchema.object(typeName: "Success", properties: [.string("value")])
        let failure = ApiTypeSchema.object(typeName: "Failure", properties: [.string("code")])
        let operation = ApiOperation.get(
            name: "read",
            path: .relative("/records"),
            security: .unsecured,
            response: success.asRef,
            publicErrors: [.init(status: 409, response: .json(failure.asRef))],
        )
        let clientOnly = ApiOperation.get(
            name: "receipt",
            path: .absolute("https://example.com/receipt"),
            security: .unsecured,
            response: success.asRef,
        )
        let package = ApiPackage(
            name: "Errors",
            targetDirUrl: URL(fileURLWithPath: "/tmp/openapi"),
            modules: [ApiModule(name: "Records", definitions: [ApiService(name: "Records", operations: [operation, clientOnly], references: [success, failure])])],
        )

        let yaml = try OpenApiYamlPackageGenerator(package: package).generatedFile().contents

        #expect(yaml.contains(#""409":"#))
        #expect(yaml.contains("#/components/schemas/Failure"))
        #expect(!yaml.contains("example.com/receipt"))
        #expect(!yaml.contains("/_runtime/"))
    }

    @Test func `generated yaml preserves boolean literal constraints`() throws {
        let failure = ApiTypeSchema.object(typeName: "Failure", properties: [.boolLiteral("success", value: false)])
        let operation = ApiOperation.get(
            name: "read",
            path: .relative("/records"),
            security: .unsecured,
            response: nil,
            publicErrors: [.init(status: 409, response: .json(failure.asRef))],
        )
        let package = ApiPackage(
            name: "Errors",
            targetDirUrl: URL(fileURLWithPath: "/tmp/openapi"),
            modules: [ApiModule(name: "Records", definitions: [ApiService(name: "Records", operations: [operation], references: [failure])])],
        )

        let yaml = try OpenApiYamlPackageGenerator(package: package).generatedFile().contents

        #expect(yaml.contains("enum:\n            - false"))
    }

    @Test func `duplicate method and path is rejected`() {
        let first = ApiOperation.get(
            name: "first",
            path: .relative("/records"),
            security: .unsecured,
            response: nil,
        )
        let second = ApiOperation.get(
            name: "second",
            path: .relative("/records"),
            security: .secured,
            response: nil,
        )
        let package = ApiPackage(
            name: "Duplicate",
            targetDirUrl: URL(fileURLWithPath: "/tmp/openapi"),
            modules: [ApiModule(name: "Records", definitions: [ApiService(name: "Records", operations: [first, second])])],
        )

        #expect(throws: OpenApiYamlPackageGeneratorError.duplicateMethodAndPath("GET /records")) {
            try OpenApiYamlPackageGenerator(package: package).generatedFile()
        }
    }

    @Test func `write refuses to overwrite user owned file`() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let fileURL = root.appendingPathComponent("openapi.yaml")
        try "user file\n".write(to: fileURL, atomically: true, encoding: .utf8)

        let file = try OpenApiYamlPackageGenerator(package: testPackage(targetDirUrl: root)).generatedFile()

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
