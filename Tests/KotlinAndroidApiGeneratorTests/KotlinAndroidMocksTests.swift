import Foundation
import GeneratorModels
@testable import KotlinAndroidApiGenerator
import Testing

struct KotlinAndroidMocksTests {
    @Test func mocksQualifyModelsWithSameShortNameByDefinitionIdentity() throws {
        let firstUser = ApiTypeSchema.object(typeName: "User", properties: [.string("name")])
        let secondUser = ApiTypeSchema.object(typeName: "User", properties: [.int64("id")])
        let first = ApiService(
            name: "First",
            operations: [.get(name: "get", path: .relative("/first"), security: .unsecured, response: firstUser.asRef)],
            references: [firstUser]
        )
        let second = ApiService(
            name: "Second",
            operations: [.get(name: "get", path: .relative("/second"), security: .unsecured, response: secondUser.asRef)],
            references: [secondUser]
        )
        let package = ApiPackage(
            name: "Test",
            targetDirUrl: URL(fileURLWithPath: "/unused-mocks-regression"),
            modules: [ApiModule(name: "Example", definitions: [first, second])],
            referencedModules: [], references: [], commonReferences: [], imports: []
        )
        let files = try KotlinAndroidApiPackageGenerator(package: package, options: .init(generateMocks: true)).generatedFiles()
        let mocks = try #require(files.first { $0.relativePath.hasSuffix("/ApiModulesMocks.kt") }).contents
        #expect(mocks.contains("ApiOperationResult<com.example.api.example.first.models.User>"))
        #expect(mocks.contains("ApiOperationResult<com.example.api.example.second.models.User>"))
        #expect(!mocks.contains("import com.example.api.example.first.models.User"))
        #expect(!mocks.contains("import com.example.api.example.second.models.User"))
        #expect(mocks.contains("val getCalls"))
        #expect(!mocks.contains("`get`Calls"))
    }
}
