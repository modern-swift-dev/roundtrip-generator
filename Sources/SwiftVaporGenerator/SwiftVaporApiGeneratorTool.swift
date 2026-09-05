import Foundation
import GeneratorModels

public struct SwiftVaporApiGeneratorTool {
    public let package: ApiPackage
    public let options: SwiftVaporGeneratorOptions

    public init(package: ApiPackage, options: SwiftVaporGeneratorOptions = .init()) {
        self.package = package
        self.options = options
    }

    public func execute(_: [String]) {
        do {
            try SwiftVaporApiPackageGenerator(package: package, options: options).write()
            print("Success!")
            exit(0)
        } catch {
            print(error.localizedDescription)
            exit(1)
        }
    }

    public var description: String {
        "Swift Vapor API Code Generator"
    }
}
