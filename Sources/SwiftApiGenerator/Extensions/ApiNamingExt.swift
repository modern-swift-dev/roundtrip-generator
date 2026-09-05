import Foundation
import GeneratorBuilder
import GeneratorModels

extension ApiModule {
    var swiftApiTypeName: String {
        "\(name.capitalCased)Api".swiftTypeName
    }

    var swiftApiModuleTypeName: String {
        "\(name.capitalCased)ApiModule".swiftTypeName
    }

    var swiftModulePropertyName: String {
        "\(name)Module".swiftPropertyName
    }
}

extension ApiService {
    func swiftApiTypeName(moduleName: String) -> String {
        "\(moduleName.capitalCased)\(name.capitalCased)Api".swiftTypeName
    }

    var swiftAsyncApiPropertyName: String {
        "\(name)AsyncApi".swiftPropertyName
    }

    var swiftImplementationPropertyName: String {
        "\(name)Impl".swiftPropertyName
    }
}
