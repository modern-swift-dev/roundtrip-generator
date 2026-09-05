import Foundation
import GeneratorBuilder
import GeneratorModels

extension ApiOperation {
    /// The Type name as will be written on disk
    var typeName: String {
        "\(name.capitalCased)Operation".swiftTypeName
    }

    var allDataTypes: [ApiTypeSchema] {
        var types = [ApiTypeSchema]()
        if let requestType = request.dataType {
            types.append(requestType)
        }

        if let responseType = response.dataType {
            types.append(responseType)
        }
        return types
    }

    var allReferences: [ApiTypeSchema] {
        let requestReferences: [ApiTypeSchema] = request.dataType?.referenceDataTypes ?? []
        let responseReferences: [ApiTypeSchema] = response.dataType?.referenceDataTypes ?? []
        var paramReferences: [ApiTypeSchema] = []
        for param in parameters {
            switch param.dataType {
                case let .intEnumValue(type, _),
                     let .intEnumArray(type, _),
                     let .stringEnumValue(type, _),
                     let .stringEnumArray(type, _):
                    if !type.isReference {
                        paramReferences.append(type)
                    }
                    paramReferences.append(contentsOf: type.referenceDataTypes)
                default:
                    break
            }
        }

        return requestReferences + responseReferences + paramReferences
    }

    var allImports: [ApiImport] {
        let bodyImports = allDataTypes.flatMap(\.allImports)
        let parameterImports = parameters.flatMap { param -> [ApiImport] in
            switch param.dataType {
                case let .intEnumValue(type, _),
                     let .intEnumArray(type, _),
                     let .stringEnumValue(type, _),
                     let .stringEnumArray(type, _):
                    type.allImports
                default:
                    []
            }
        }
        return bodyImports + parameterImports
    }
}
