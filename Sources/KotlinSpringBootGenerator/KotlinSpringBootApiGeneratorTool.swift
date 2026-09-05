import Foundation
import GeneratorModels

public struct KotlinSpringBootApiGeneratorTool {
    public let package: ApiPackage
    public let options: KotlinSpringBootGeneratorOptions

    public init(package: ApiPackage, options: KotlinSpringBootGeneratorOptions = .init()) {
        self.package = package
        self.options = options
    }

    public func execute(_: [String]) {
        do {
            try KotlinSpringBootApiPackageGenerator(package: package, options: options).write()
            print("Success!")
            exit(0)
        } catch {
            print(error.localizedDescription)
            exit(1)
        }
    }

    public var description: String {
        "Kotlin Spring Boot API Code Generator"
    }
}
