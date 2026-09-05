import Foundation
import GeneratorModels
import Testing

struct ApiPackageDXTests {
    @Test func `output copy preserves contract and reference identity`() {
        let model = ApiTypeSchema.object(typeName: "User", properties: [.string("name")])
        let module = ApiModule(name: "Admin", definitions: [
            ApiService(name: "Users", operations: [
                .get(name: "get", path: .relative("/users"), response: model.asRef)
            ], references: [model])
        ])
        let original = ApiPackage(
            name: "Example",
            targetDirUrl: URL(fileURLWithPath: "/original"),
            modules: [module],
            referencedModules: [module],
            references: [model],
            commonReferences: [model],
            imports: ["CustomModels"],
            generateApiModules: false,
        )
        let copy = original.output(to: URL(fileURLWithPath: "/other"))

        #expect(original.targetDirUrl.path == "/original")
        #expect(copy.targetDirUrl.path == "/other")
        #expect(copy.name == original.name)
        #expect(copy.modules.first?.definitions.first?.referencedTypes == [model])
        #expect(copy.referencedModules.first?.name == "Admin")
        #expect(copy.references == original.references)
        #expect(copy.commonReferences == original.commonReferences)
        #expect(copy.imports == original.imports)
        #expect(!copy.generateApiModules)
    }
}
