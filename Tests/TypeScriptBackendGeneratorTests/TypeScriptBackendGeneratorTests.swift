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
