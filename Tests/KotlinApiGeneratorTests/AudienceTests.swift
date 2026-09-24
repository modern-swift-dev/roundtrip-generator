import Foundation
import GeneratorModels
import KotlinApiGenerator
import Testing

struct AudienceTests {
    @Test func excludesBackendOperationAndExclusiveModels() throws {
        let secret = ApiTypeSchema.object(typeName: "SecretPayload", properties: [.string("secret")])
        let publicType = ApiTypeSchema.object(typeName: "VisiblePayload", properties: [.string("value")])
        let operations = [
            ApiOperation.get(name: "visible", path: .relative("/visible"), security: .unsecured, response: publicType.asRef),
            ApiOperation.get(name: "hidden", path: .relative("/hidden"), security: .unsecured, response: secret.asRef).backendOnly()
        ]
        let package = ApiPackage(name: "Audience", targetDirUrl: URL(fileURLWithPath: "/unused"), modules: [
            ApiModule(name: "Records", definitions: [ApiService(name: "Records", operations: operations, references: [secret, publicType])])
        ])
        let files = try KotlinApiPackageGenerator(package: package).generatedFiles()
        let output = files.map(\.contents).joined(separator: "\n")
        #expect(output.contains("VisiblePayload"))
        #expect(!output.contains("SecretPayload"))
        #expect(!output.contains("/hidden"))
    }
}
