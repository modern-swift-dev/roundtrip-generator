import Foundation
import GeneratorBuilder
import GeneratorModels

extension ApiRequestBody {
    func validate() throws {
        switch self {
            case let .json(type):
                if let type {
                    try ApiTypeSchemaValidator(dataType: type).validate()
                }
            case let .multiPart(parts):
                guard !parts.isEmpty else {
                    throw ApiValidationError.failed("List of multi-part cannot be empty")
                }

                guard parts.allSatisfy({ !$0.isEmpty }) else {
                    throw ApiValidationError.failed("List of multi-part cannot contain empty names")
                }

                guard Set(parts).count == parts.count else {
                    throw ApiValidationError.failed("List of of multi-part cannot contain duplicates")
                }

                let setterNames = parts.map(\.capitalCased)
                guard Set(setterNames).count == setterNames.count else {
                    throw ApiValidationError.failed("List of of multi-part cannot contain duplicate generated setters")
                }
            default:
                break
        }
    }

    var isBinary: Bool {
        switch self {
            case .binary,
                 .file:
                true
            default:
                false
        }
    }

    var isJson: Bool {
        switch self {
            case let .json(type):
                type != nil
            default:
                false
        }
    }

    var isMultipart: Bool {
        switch self {
            case .multiPart:
                true
            default:
                false
        }
    }

    var isEquatable: Bool {
        switch self {
            case let .json(value):
                value?.isEquatable ?? false
            case .multiPart:
                false
            default:
                true
        }
    }

    var isSwiftSendable: Bool {
        switch self {
            case let .json(type):
                type?.isSwiftSendable ?? true
            default:
                true
        }
    }

    var hasBody: Bool {
        switch self {
            case .none:
                false
            default:
                true
        }
    }

    var isFile: Bool {
        switch self {
            case .file:
                true
            default:
                false
        }
    }

    var multiPartNames: [String] {
        switch self {
            case let .multiPart(parts):
                parts
            default:
                []
        }
    }
}
