import Foundation
import GeneratorModels

extension ApiResponseBody {
    var swiftDecodableDataType: ApiTypeSchema? {
        switch self {
            case let .json(type):
                type
            default:
                nil
        }
    }

    func validate() throws {
        switch self {
            case let .json(type):
                guard let type else {
                    throw ApiValidationError.failed("Typed JSON response must have a data type")
                }
                try ApiTypeSchemaValidator(dataType: type).validate()
            default:
                break
        }
    }
}
