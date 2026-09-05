import Foundation
import GeneratorModels

public struct KotlinAndroidApiGeneratorTool {
    public let package: ApiPackage
    public let options: KotlinAndroidGeneratorOptions

    public init(package: ApiPackage, options: KotlinAndroidGeneratorOptions = .init()) {
        self.package = package
        self.options = options
    }

    public func execute(_: [String]) {
        do {
            try KotlinAndroidApiPackageGenerator(package: package, options: options).write()
            print("Success!")
            exit(0)
        } catch {
            print(error.localizedDescription)
            exit(1)
        }
    }

    public var description: String {
        "KotlinAndroid API Code Generator"
    }
}
