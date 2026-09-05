import Foundation
import GeneratorModels
@testable import SwiftVaporGenerator
import Testing

struct SwiftVaporTypeRegistryTests {
    @Test func sharedTypeGraphsAreRegisteredOnceWithoutChangingNamePrecedence() {
        let depth = 20
        let leaf = ApiTypeSchema.object(typeName: "Leaf", properties: [])
        var root = leaf
        for level in 0..<depth {
            root = .object(typeName: "Level\(level)", properties: [
                ApiModelProperty(rawName: "left", propertyName: "left", dataType: root),
                ApiModelProperty(rawName: "right", propertyName: "right", dataType: root)
            ])
        }
        var generated = SwiftVaporTypeRegistry()
        generated.register(root, prefix: "First")
        let originalIDs = generated.types.map(\.id)
        let originalNames = generated.types.map(\.name)
        let originalLeafName = generated.swiftType(for: leaf)
        generated.register(root, prefix: "Second")
        #expect(generated.types.count == depth + 1)
        #expect(generated.types.map(\.id) == originalIDs)
        #expect(generated.types.map(\.name) == originalNames)
        #expect(generated.swiftType(for: leaf) == originalLeafName)
        #expect(originalLeafName.hasPrefix("First"))

        let package = ApiPackage(
            name: "Test",
            targetDirUrl: URL(fileURLWithPath: "/unused"),
            modules: [], referencedModules: [], references: [root],
            commonReferences: [root], imports: []
        )
        var supplied = SwiftVaporTypeRegistry()
        supplied.registerPackage(package)
        #expect(supplied.types.isEmpty)
        #expect(supplied.swiftType(for: root) == "Level19")
        #expect(supplied.swiftType(for: leaf).hasPrefix("Level19"))
        #expect(supplied.swiftType(for: leaf).hasSuffix("Leaf"))
    }
}
