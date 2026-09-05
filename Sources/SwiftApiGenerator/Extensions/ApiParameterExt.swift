import Foundation
import GeneratorBuilder
import GeneratorModels

extension ApiParameter {
    var swiftProperty: SwiftProperty {
        .init(
            visibility: .public,
            mutable: isMutable,
            name: propertyName,
            dataType: dataType.swiftTypeDeclaration,
            nullable: !isRequired,
            defaultValue: dataType.getDefaultValue(isRequired: isRequired),
            rawName: rawName,
        )
    }

    func validate() throws {
        switch dataType {
            case let .stringEnumArray(type, _):
                if location == .path {
                    throw ApiValidationError.failed("Enum Type are not allow in path parameters")
                }

                if try validateStringEnum(type: type) {
                    try validateEnumDefaults()
                    return
                }

                throw ApiValidationError.failed("Invalid Enum Type for \(location.rawValue) parameters")

            case let .stringEnumValue(type, _):
                if try validateStringEnum(type: type) {
                    try validateEnumDefaults()
                    return
                }

                throw ApiValidationError.failed("Invalid Enum Type for \(location.rawValue) parameters")

            case let .intEnumArray(type, _):
                if location == .path {
                    throw ApiValidationError.failed("Enum Type are not allow in path parameters")
                }

                if try validateIntEnum(type: type) {
                    try validateEnumDefaults()
                    return
                }

                throw ApiValidationError.failed("Invalid Enum Type for \(location.rawValue) parameters")

            case let .intEnumValue(type, _):
                if try validateIntEnum(type: type) {
                    try validateEnumDefaults()
                    return
                }

                throw ApiValidationError.failed("Invalid Enum Type for \(location.rawValue) parameters")

            default:
                break
        }

        try validateEnumDefaults()
    }

    private func validateStringEnum(type: ApiTypeSchema) throws -> Bool {
        switch type {
            case .stringEnum:
                try ApiTypeSchemaValidator(dataType: type).validate()
                return true
            case let .reference(_, _, _, _, dataType):
                guard let dataType else {
                    return true
                }
                return try validateStringEnum(type: dataType)
            default:
                return false
        }
    }

    private func validateIntEnum(type: ApiTypeSchema) throws -> Bool {
        switch type {
            case .intEnum:
                try ApiTypeSchemaValidator(dataType: type).validate()
                return true
            case let .reference(_, _, _, _, dataType):
                guard let dataType else {
                    return true
                }
                return try validateIntEnum(type: dataType)
            default:
                return false
        }
    }

    private func validateEnumDefaults() throws {
        switch dataType {
            case let .stringEnumValue(type, defaultValue):
                guard let defaultValue else {
                    return
                }
                guard let rawNames = stringEnumRawNames(type: type),
                      rawNames.contains(defaultValue) else {
                    throw ApiValidationError.failed("Invalid Enum default value for \(location.rawValue) parameters")
                }
            case let .stringEnumArray(type, defaultValues):
                guard let defaultValues else {
                    return
                }
                guard let rawNames = stringEnumRawNames(type: type) else {
                    throw ApiValidationError.failed("Invalid Enum default value for \(location.rawValue) parameters")
                }
                if defaultValues.contains(where: { !rawNames.contains($0) }) {
                    throw ApiValidationError.failed("Invalid Enum default value for \(location.rawValue) parameters")
                }
            case let .intEnumValue(type, defaultValue):
                guard let defaultValue else {
                    return
                }
                guard let rawValues = intEnumRawValues(type: type),
                      rawValues.contains(defaultValue) else {
                    throw ApiValidationError.failed("Invalid Enum default value for \(location.rawValue) parameters")
                }
            case let .intEnumArray(type, defaultValues):
                guard let defaultValues else {
                    return
                }
                guard let rawValues = intEnumRawValues(type: type) else {
                    throw ApiValidationError.failed("Invalid Enum default value for \(location.rawValue) parameters")
                }
                if defaultValues.contains(where: { !rawValues.contains($0) }) {
                    throw ApiValidationError.failed("Invalid Enum default value for \(location.rawValue) parameters")
                }
            default:
                break
        }
    }

    private func stringEnumRawNames(type: ApiTypeSchema) -> Set<String>? {
        switch type {
            case let .stringEnum(_, values, _, _, _):
                Set(values.map(\.rawName))
            case let .reference(_, _, _, _, dataType):
                dataType.flatMap { stringEnumRawNames(type: $0) }
            default:
                nil
        }
    }

    private func intEnumRawValues(type: ApiTypeSchema) -> Set<Int>? {
        switch type {
            case let .intEnum(_, values, _, _):
                Set(values.map(\.rawValue))
            case let .reference(_, _, _, _, dataType):
                dataType.flatMap { intEnumRawValues(type: $0) }
            default:
                nil
        }
    }
}

extension ApiParameter.DataType {
    var swiftTypeDeclaration: String {
        switch self {
            case .bool: String(describing: Bool.self)
            case .boolArray: "[\(String(describing: Bool.self))]"
            case .string: String(describing: String.self)
            case .stringArray: "[\(String(describing: String.self))]"
            case .int: String(describing: Int.self)
            case .int16: String(describing: Int16.self)
            case .int32: String(describing: Int32.self)
            case .int64: String(describing: Int64.self)
            case .intArray: "[\(String(describing: Int.self))]"
            case .int16Array: "[\(String(describing: Int16.self))]"
            case .int32Array: "[\(String(describing: Int32.self))]"
            case .int64Array: "[\(String(describing: Int64.self))]"
            case .uint: String(describing: UInt.self)
            case .uint16: String(describing: UInt16.self)
            case .uint32: String(describing: UInt32.self)
            case .uint64: String(describing: UInt64.self)
            case .uintArray: "[\(String(describing: UInt.self))]"
            case .uint16Array: "[\(String(describing: UInt16.self))]"
            case .uint32Array: "[\(String(describing: UInt32.self))]"
            case .uint64Array: "[\(String(describing: UInt64.self))]"
            case let .stringEnumValue(type, _): ApiTypeSchemaGenerator(dataType: type).swiftTypeDeclaration
            case let .stringEnumArray(type, _): "[\(ApiTypeSchemaGenerator(dataType: type).swiftTypeDeclaration)]"
            case let .intEnumValue(type, _): ApiTypeSchemaGenerator(dataType: type).swiftTypeDeclaration
            case let .intEnumArray(type, _): "[\(ApiTypeSchemaGenerator(dataType: type).swiftTypeDeclaration)]"
            case .date: String(describing: Date.self)
            case .dateTime: String(describing: Date.self)
            case .time: "Time"
        }
    }

    // swiftlint:disable cyclomatic_complexity function_body_length
    func getDefaultValue(isRequired: Bool) -> String? {
        var defaultValue: String?

        switch self {
            case let .bool(initialValue):
                if let value = initialValue {
                    defaultValue = String(describing: value)
                }
            case let .boolArray(initialValue):
                if let value = initialValue?.map({ String(describing: $0) }).joined(separator: ", ") {
                    defaultValue = "[\(value)]"
                }
            case let .string(initialValue):
                if let value = initialValue {
                    defaultValue = value.swiftStringLiteral
                }
            case let .int(initialValue):
                if let value = initialValue {
                    defaultValue = "\(value)"
                }
            case let .int16(initialValue):
                if let value = initialValue {
                    defaultValue = "\(value)"
                }
            case let .int32(initialValue):
                if let value = initialValue {
                    defaultValue = "\(value)"
                }
            case let .int64(initialValue):
                if let value = initialValue {
                    defaultValue = "\(value)"
                }
            case let .uint(initialValue):
                if let value = initialValue {
                    defaultValue = "\(value)"
                }
            case let .uint16(initialValue):
                if let value = initialValue {
                    defaultValue = "\(value)"
                }
            case let .uint32(initialValue):
                if let value = initialValue {
                    defaultValue = "\(value)"
                }
            case let .uint64(initialValue):
                if let value = initialValue {
                    defaultValue = "\(value)"
                }
            case let .stringArray(initialValue):
                if let value = initialValue {
                    defaultValue = "[\(value.map(\.debugDescription).joined(separator: ", "))]"
                }
            case let .intArray(initialValue):
                if let value = initialValue?.map({ "\($0)" }).joined(separator: ", ") {
                    defaultValue = "[\(value)]"
                }
            case let .int16Array(initialValue):
                if let value = initialValue?.map({ "\($0)" }).joined(separator: ", ") {
                    defaultValue = "[\(value)]"
                }
            case let .int32Array(initialValue):
                if let value = initialValue?.map({ "\($0)" }).joined(separator: ", ") {
                    defaultValue = "[\(value)]"
                }
            case let .int64Array(initialValue):
                if let value = initialValue?.map({ "\($0)" }).joined(separator: ", ") {
                    defaultValue = "[\(value)]"
                }
            case let .uintArray(initialValue):
                if let value = initialValue?.map({ "\($0)" }).joined(separator: ", ") {
                    defaultValue = "[\(value)]"
                }
            case let .uint16Array(initialValue):
                if let value = initialValue?.map({ "\($0)" }).joined(separator: ", ") {
                    defaultValue = "[\(value)]"
                }
            case let .uint32Array(initialValue):
                if let value = initialValue?.map({ "\($0)" }).joined(separator: ", ") {
                    defaultValue = "[\(value)]"
                }
            case let .uint64Array(initialValue):
                if let value = initialValue?.map({ "\($0)" }).joined(separator: ", ") {
                    defaultValue = "[\(value)]"
                }
            case let .intEnumValue(type, initialValue):
                if let value = initialValue,
                   let selectedCase = intEnumCase(type: type, rawValue: value) {
                    let caseName = intEnumCaseName(selectedCase)
                    defaultValue = ".\(caseName)"
                }
            case let .intEnumArray(type, initialValues):
                if let values = initialValues {
                    let selectedCases = values.compactMap { intEnumCase(type: type, rawValue: $0) }
                    guard selectedCases.count == values.count else {
                        break
                    }
                    let computedValues = selectedCases
                        .map {
                            ".\(intEnumCaseName($0))"
                        }
                        .joined(separator: ", ")

                    defaultValue = "[\(computedValues)]"
                }
            case let .stringEnumValue(type, initialValue):
                if let value = initialValue,
                   let selectedCase = stringEnumCase(type: type, rawName: value) {
                    defaultValue = ".\(selectedCase.name.swiftEnumValueDeclaration)"
                }
            case let .stringEnumArray(type, initialValues):
                if let values = initialValues {
                    let selectedCases = values.compactMap { stringEnumCase(type: type, rawName: $0) }
                    guard selectedCases.count == values.count else {
                        break
                    }
                    let computedValues = selectedCases
                        .map {
                            ".\($0.name.swiftEnumValueDeclaration)"
                        }
                        .joined(separator: ", ")

                    defaultValue = "[\(computedValues)]"
                }
            case .date,
                 .time,
                 .dateTime:
                defaultValue = nil
        }

        if !isRequired, defaultValue == nil {
            defaultValue = "nil"
        }

        return defaultValue
    }

    private func intEnumCase(type: ApiTypeSchema, rawValue: Int) -> (name: String?, rawValue: Int)? {
        switch type {
            case let .intEnum(_, values, _, _):
                values.first { $0.rawValue == rawValue }
            case let .reference(_, _, _, _, dataType):
                dataType.flatMap { intEnumCase(type: $0, rawValue: rawValue) }
            default:
                nil
        }
    }

    private func intEnumCaseName(_ selectedCase: (name: String?, rawValue: Int)) -> String {
        if let name = selectedCase.name, !name.isEmpty {
            name.swiftEnumValueDeclaration
        } else {
            selectedCase.rawValue.swiftEnumValueDeclaration
        }
    }

    private func stringEnumCase(type: ApiTypeSchema, rawName: String) -> (name: String, rawName: String)? {
        switch type {
            case let .stringEnum(_, values, _, _, _):
                values.first { $0.rawName == rawName }
            case let .reference(_, _, _, _, dataType):
                dataType.flatMap { stringEnumCase(type: $0, rawName: rawName) }
            default:
                nil
        }
    }
}
