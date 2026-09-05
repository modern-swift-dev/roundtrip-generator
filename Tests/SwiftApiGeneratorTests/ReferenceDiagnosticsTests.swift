import GeneratorModels
@testable import SwiftApiGenerator
import Testing

struct ReferenceDiagnosticsTests {
    @Test func missingReferenceExplainsScopeAndIdentity() {
        let user = ApiTypeSchema.object(typeName: "User", properties: [.string("name")])
        let otherUser = ApiTypeSchema.object(typeName: "User", properties: [.string("email")])
        let definition = ApiService(name: "Users", operations: [
            .get(name: "getUser", path: .relative("/users"), response: otherUser.asRef)
        ], references: [user])
        do {
            try ApiServiceValidator(definition: definition).validate(moduleName: "Accounts")
            Issue.record("Expected unresolved reference")
        } catch {
            let message = String(describing: error)
            for expected in ["Accounts", "Users", "GetUser", "User", "different UUID", "ApiPackage.commonReferences", "same ApiTypeSchema"] {
                #expect(message.contains(expected))
            }
        }
    }
}
