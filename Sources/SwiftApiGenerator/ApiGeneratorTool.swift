import Foundation
import GeneratorModels

public struct ApiGeneratorTool {

    public let package: ApiPackage

    public init(package: ApiPackage) {
        self.package = package
    }

    public func execute(_: [String]) {
        do {
            try ApiPackageValidator(package: package).validate()

            let generator = ApiPackageGenerator(package: package)
            try generator.write()

            print("Success! ✅")
            exit(0)
        } catch {
            print(error.localizedDescription)
            exit(1)
        }
    }

    /// Description displayed in Help
    public var description: String {
        "API Code Generator"
    }
}
