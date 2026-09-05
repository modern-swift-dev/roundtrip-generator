import Foundation
import GeneratorModels

public struct KotlinApiGeneratorTool {
    public let package: ApiPackage
    public let options: KotlinGeneratorOptions

    public init(package: ApiPackage, options: KotlinGeneratorOptions = .init()) {
        self.package = package
        self.options = options
    }

    public func execute(_: [String]) {
        do {
            try KotlinApiPackageGenerator(package: package, options: options).write()
            print("Success!")
            exit(0)
        } catch {
            print(error.localizedDescription)
            exit(1)
        }
    }

    public var description: String {
        "Kotlin API Code Generator"
    }
}
