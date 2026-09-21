import Foundation
import GeneratorModels

public struct TypeScriptBackendGeneratorTool {
    public let package: ApiPackage
    public let options: TypeScriptBackendGeneratorOptions

    public init(package: ApiPackage, options: TypeScriptBackendGeneratorOptions = .init()) {
        self.package = package
        self.options = options
    }

    public func run() throws {
        try TypeScriptBackendApiPackageGenerator(package: package, options: options).write()
    }
}
