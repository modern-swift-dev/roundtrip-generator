import Foundation
import GeneratorModels

extension [ApiTypeSchema] {
    var hasDuplicates: Bool {
        let uuids = compactMap(\.uuid)
        let uuidSet = Set(uuids)
        if uuidSet.count != uuids.count {
            return true
        }
        return false
    }

    var hasDuplicateDeclarations: Bool {
        let declarationName = compactMap(\.declaredSwiftTypeDeclaration)
        let declarationNameSet = Set(declarationName)
        if declarationNameSet.count != declarationName.count {
            return true
        }
        return false
    }
}

extension ApiTypeSchema {
    var allImports: [ApiImport] {
        var seen = Set<UUID>()
        return allImports(seen: &seen)
    }

    private func allImports(seen: inout Set<UUID>) -> [ApiImport] {
        if let uuid = uuid ?? referenceUUID,
           !seen.insert(uuid).inserted {
            return imports
        }

        return switch self {
            case let .object(_, properties, _, imports, _, _):
                imports + properties.flatMap { $0.dataType.allImports(seen: &seen) }
            case let .dynamicObject(_, _, _, _, objectTypes, _, imports, _, extraProperties):
                imports
                    + objectTypes.flatMap { $0.objectType.allImports(seen: &seen) }
                    + extraProperties.flatMap { $0.dataType.allImports(seen: &seen) }
            case let .reference(_, _, imports, _, dataType):
                imports + (dataType?.allImports(seen: &seen) ?? [])
            case let .keyedByString(type, _),
                 let .array(type):
                type.allImports(seen: &seen)
            case let .genericReference(_, types):
                types.flatMap { $0.allImports(seen: &seen) }
            default:
                []
        }
    }

    var declaredSwiftTypeDeclaration: String? {
        switch self {
            case .object,
                 .stringEnum,
                 .intEnum,
                 .dynamicObject:
                ApiTypeSchemaGenerator(dataType: self).swiftTypeDeclaration
            case let .array(type),
                 let .keyedByString(type, _):
                type.declaredSwiftTypeDeclaration
            case let .reference(_, _, _, _, dataType):
                dataType?.declaredSwiftTypeDeclaration ?? ApiTypeSchemaGenerator(dataType: self).swiftTypeDeclaration
            default:
                nil
        }
    }

    var isSwiftSendable: Bool {
        var seen = Set<UUID>()
        return isSwiftSendable(seen: &seen)
    }

    private func isSwiftSendable(seen: inout Set<UUID>) -> Bool {
        if case let .reference(_, _, _, _, dataType) = self {
            return dataType?.isSwiftSendable(seen: &seen) ?? true
        }

        if let uuid = uuid ?? referenceUUID,
           !seen.insert(uuid).inserted {
            return true
        }

        return switch self {
            case .uuid,
                 .string,
                 .int,
                 .int64,
                 .int32,
                 .int16,
                 .int8,
                 .uint,
                 .uint64,
                 .uint32,
                 .uint16,
                 .uint8,
                 .double,
                 .date,
                 .timelessDate,
                 .time,
                 .url,
                 .bool,
                 .binary,
                 .stringEnum,
                 .intEnum:
                true
            case let .keyedByString(type, _),
                 let .array(type):
                type.isSwiftSendable(seen: &seen)
            case let .object(_, properties, protocols, _, isValueType, _):
                isValueType || protocols.contains("Sendable") || protocols.contains("@unchecked Sendable")
                    ? properties.allSatisfy { $0.dataType.isSwiftSendable(seen: &seen) }
                    : false
            case let .dynamicObject(_, _, _, _, objectTypes, _, _, _, extraProperties):
                objectTypes.allSatisfy { $0.objectType.isSwiftSendable(seen: &seen) }
                    && extraProperties.allSatisfy { $0.dataType.isSwiftSendable(seen: &seen) }
            case .reference:
                true
            case let .genericReference(_, types):
                types.allSatisfy { $0.isSwiftSendable(seen: &seen) }
        }
    }
}
