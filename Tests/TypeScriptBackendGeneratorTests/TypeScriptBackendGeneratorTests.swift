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
