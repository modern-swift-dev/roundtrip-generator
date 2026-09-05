import GeneratorBuilder
import GeneratorModels

extension ApiModule {
    var kotlinApiModuleTypeName: String {
        "\(name.capitalCased)ApiModule".kotlinTypeName
    }

    var kotlinModulePropertyName: String {
        "\(name)Module".kotlinPropertyName
    }
}

extension ApiService {
    func kotlinApiTypeName(moduleName: String) -> String {
        "\(moduleName.capitalCased)\(name.capitalCased)Api".kotlinTypeName
    }

    func kotlinApiServiceTypeName(moduleName: String) -> String {
        "\(kotlinApiTypeName(moduleName: moduleName))Service".kotlinTypeName
    }

    var kotlinApiPropertyName: String {
        "\(name)Api".kotlinPropertyName
    }
}

extension ApiOperation {
    var kotlinOperationTypeName: String {
        "\(name.capitalCased)Operation".kotlinTypeName
    }

    var kotlinMethodName: String {
        name.kotlinPropertyName
    }
}
