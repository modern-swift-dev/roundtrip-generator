import Foundation
import GeneratorBuilder
import GeneratorModels
@testable import SwiftApiGenerator
import Testing

struct SwiftImportsDXTests {
    @Test func `adds runtime imports and preserves explicit annotations`() {
        let package = ApiPackage(
            name: "Example", targetDirUrl: URL(fileURLWithPath: "/unused"), modules: [],
            referencedModules: [], references: [], commonReferences: [],
            imports: [.init(name: "RoundTrip", annotation: "@preconcurrency"), "Custom", "Custom"],
        )
        #expect(package.swiftImports.map(\.name) == ["Custom", "Foundation", "RoundTrip", "RoundTripREST"])
        #expect(package.swiftImports.first { $0.name == "RoundTrip" }?.annotation == "@preconcurrency")
    }

    @Test func `automatic imports never duplicate annotated imports`() {
        let imports: [ApiImport] = ["Foundation", .init(name: "Foundation", annotation: "@preconcurrency"), "Foundation"]
        #expect(imports.swiftUniqueImports == [.init(name: "Foundation", annotation: "@preconcurrency")])
        let operation = ApiOperation.get(name: "list", path: .relative("/users"), response: .string())
        let code = ApiOperationGenerator(operation: operation).swiftCode(parentClassName: "Users", imports: imports).toString()
        #expect(code.components(separatedBy: "import Foundation").count == 2)
        #expect(code.contains("@preconcurrency import Foundation"))
    }
}
