import Foundation
import GeneratorBuilder
import GeneratorModels

struct ApiTypeSchemaValidator {
    let dataType: ApiTypeSchema

    /// Valide the data-type, ensuring property uniqueness, and validate it's sub-type
    /// when applicable
    func validate() throws {
        var seen = Set<UUID>()
        try validate(seen: &seen)
    }

    // swiftlint:disable:next cyclomatic_complexity
    private func validate(seen: inout Set<UUID>) throws {
        if case let .reference(_, _, _, _, dataType) = dataType {
            if let dataType {
                try Self(dataType: dataType).validate(seen: &seen)
            }
            return
        }

        if let uuid = dataType.uuid ?? dataType.referenceUUID {
            guard seen.insert(uuid).inserted else {
                return
            }
        }

        switch dataType {
            case let .object(typeName, properties, _, _, _, _):
                let propertyNames = properties.map(\.propertyName)
                if Set(propertyNames).count != propertyNames.count {
                    throw ApiValidationError.failed("Object Type named \(typeName) has property duplication: \(propertyNames)")
                }

                let rawNames = properties.map(\.rawName)
                if Set(rawNames).count != rawNames.count {
                    throw ApiValidationError.failed("Object Type named \(typeName) has property duplication: \(rawNames)")
                }

                let customTypes = properties.map(\.dataType).filter(Self.declaresSwiftType)
                if customTypes.hasDuplicates {
                    throw ApiValidationError.failed("Object Type named \(typeName) has type duplication: \(customTypes.map { ApiTypeSchemaGenerator(dataType: $0).swiftTypeDeclaration })")
                }

                if customTypes.hasDuplicateDeclarations {
                    throw ApiValidationError.failed("Object Type named \(typeName) has type duplication: \(customTypes.map { ApiTypeSchemaGenerator(dataType: $0).swiftTypeDeclaration })")
                }

                for property in properties {
                    try Self(dataType: property.dataType).validate(seen: &seen)
                }
            case let .keyedByString(type, _),
                 let .array(type):
                try Self(dataType: type).validate(seen: &seen)
            case let .genericReference(_, types):
                for type in types {
                    try Self(dataType: type).validate(seen: &seen)
                }
            case let .stringEnum(typeName, values, initialValue, _, supportGarbage):
                guard !values.isEmpty else {
                    throw ApiValidationError.failed("Enum Type named \(typeName) has no values")
                }

                if Set(values.map(\.name.swiftEnumValueDeclaration)).count != values.count {
                    throw ApiValidationError.failed("Enum Type named \(typeName) has value duplication")
                }

                if Set(values.map(\.rawName)).count != values.count {
                    throw ApiValidationError.failed("Enum Type named \(typeName) has value duplication")
                }

                if supportGarbage,
                   values.map(\.name.swiftEnumValueDeclaration).contains("garbage") || values.map(\.rawName).contains("__garbage__") {
                    throw ApiValidationError.failed("Enum Type named \(typeName) has value duplication")
                }

                if let initialValue, !values.map(\.name).contains(initialValue) {
                    throw ApiValidationError.failed("Enum Type named \(typeName) initial value is not valid")
                }
            case let .intEnum(typeName, values, initialValue, _):
                guard !values.isEmpty else {
                    throw ApiValidationError.failed("Enum Type named \(typeName) has no values")
                }

                if Set(values.map { SwiftIntEnum.intEnumCaseName($0) }).count != values.count {
                    throw ApiValidationError.failed("Enum Type named \(typeName) has value duplication")
                }

                if Set(values.map(\.1)).count != values.count {
                    throw ApiValidationError.failed("Enum Type named \(typeName) has value duplication")
                }

                if let initialValue, !values.map(\.1).contains(initialValue) {
                    throw ApiValidationError.failed("Enum Type named \(typeName) initial value is not valid")
                }
            case let .double(value):
                if let value, !value.isFinite {
                    throw ApiValidationError.failed("Double initial value must be finite")
                }
            case let .dynamicObject(typeName, objectTypePropertyName, objectDataPropertyName, alternateObjectDataPropertyName, objectTypes, supportGarbage, _, _, extraProperties):
                guard !objectTypes.isEmpty else {
                    throw ApiValidationError.failed("Dynamic Object Type named \(typeName) has no object types")
                }

                let objectTypeNames = objectTypes.map(\.objectTypeName.swiftEnumValueDeclaration)
                if Set(objectTypeNames).count != objectTypeNames.count {
                    throw ApiValidationError.failed("Dynamic Object Type named \(typeName) has object type duplication")
                }

                let objectTypeRawNames = objectTypes.map(\.objectTypeRawName)
                if Set(objectTypeRawNames).count != objectTypeRawNames.count {
                    throw ApiValidationError.failed("Dynamic Object Type named \(typeName) has object type duplication")
                }

                if supportGarbage,
                   objectTypeNames.contains("garbage") || objectTypeRawNames.contains("__garbage__") {
                    throw ApiValidationError.failed("Dynamic Object Type named \(typeName) has object type duplication")
                }

                let customTypes = objectTypes.map(\.objectType).filter(Self.declaresSwiftType)
                if customTypes.hasDuplicates {
                    throw ApiValidationError.failed("Dynamic Object Type named \(typeName) has type duplication: \(customTypes.map { ApiTypeSchemaGenerator(dataType: $0).swiftTypeDeclaration })")
                }

                if customTypes.hasDuplicateDeclarations {
                    throw ApiValidationError.failed("Dynamic Object Type named \(typeName) has type duplication: \(customTypes.map { ApiTypeSchemaGenerator(dataType: $0).swiftTypeDeclaration })")
                }

                let extraPropertyNames = extraProperties.map(\.propertyName)
                if Set(extraPropertyNames).count != extraPropertyNames.count {
                    throw ApiValidationError.failed("Dynamic Object Type named \(typeName) has extra property duplication: \(extraPropertyNames)")
                }

                let reservedRawNames = objectDataPropertyName == "__self__"
                    ? [objectTypePropertyName]
                    : [objectTypePropertyName, objectDataPropertyName, alternateObjectDataPropertyName]
                if Set(reservedRawNames).count != reservedRawNames.count {
                    throw ApiValidationError.failed("Dynamic Object Type named \(typeName) has reserved property duplication: \(reservedRawNames)")
                }

                let extraRawNames = extraProperties.map(\.rawName)
                if Set(extraRawNames).count != extraRawNames.count || extraRawNames.contains(where: { reservedRawNames.contains($0) }) {
                    throw ApiValidationError.failed("Dynamic Object Type named \(typeName) has extra property duplication: \(extraRawNames)")
                }

                let reservedPropertyNames = reservedRawNames.map(\.swiftPropertyName)
                if extraPropertyNames.contains(where: { reservedPropertyNames.contains($0) }) {
                    throw ApiValidationError.failed("Dynamic Object Type named \(typeName) has extra property duplication: \(extraPropertyNames)")
                }

                if objectDataPropertyName == "__self__" {
                    let reservedNames = Set([objectTypePropertyName] + extraRawNames)
                    for objectType in objectTypes {
                        let rawNames = Self.objectRawNames(in: objectType.objectType)
                        if rawNames.contains(where: { reservedNames.contains($0) }) {
                            throw ApiValidationError.failed("Dynamic Object Type named \(typeName) has self-encoded property duplication: \(rawNames)")
                        }
                    }
                }

                for objectType in objectTypes {
                    try Self(dataType: objectType.objectType).validate(seen: &seen)
                }

                for property in extraProperties {
                    try Self(dataType: property.dataType).validate(seen: &seen)
                }
            default:
                break
        }
    }

    private static func objectRawNames(in dataType: ApiTypeSchema) -> [String] {
        switch dataType {
            case let .object(_, properties, _, _, _, _):
                properties.map(\.rawName)
            case let .reference(_, _, _, _, dataType):
                dataType.map(objectRawNames(in:)) ?? []
            default:
                []
        }
    }

    private static func declaresSwiftType(_ dataType: ApiTypeSchema) -> Bool {
        switch dataType {
            case .object,
                 .stringEnum,
                 .intEnum,
                 .dynamicObject:
                true
            case let .keyedByString(type, _),
                 let .array(type):
                declaresSwiftType(type)
            default:
                false
        }
    }
}
