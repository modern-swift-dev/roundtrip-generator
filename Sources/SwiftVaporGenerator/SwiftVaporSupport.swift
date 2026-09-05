import Foundation
import GeneratorBuilder
import GeneratorModels

struct SwiftVaporRegisteredType: Equatable {
    let id: UUID
    let name: String
    let dataType: ApiTypeSchema
}

struct SwiftVaporTypeRegistry {
    private(set) var types: [SwiftVaporRegisteredType] = []
    private var namesByID: [UUID: String] = [:]
    private var suppliedCommonTypeIDs: Set<UUID> = []
    private var visitedGeneratedTypeIDs: Set<UUID> = []
    private var visitedSuppliedTypeIDs: Set<UUID> = []

    mutating func registerPackage(_ package: ApiPackage) {
        suppliedCommonTypeIDs = Set(package.commonReferences.compactMap(\.declaredSwiftVaporTypeID))
        for type in package.commonReferences {
            registerSupplied(type)
        }
        for type in package.references {
            register(type, prefix: "")
        }
        for module in package.referencedModules {
            registerSupplied(module: module)
        }
        for module in package.modules {
            for type in module.references {
                register(type, prefix: module.name.capitalCased)
            }
            for definition in module.definitions {
                let prefix = "\(module.name.capitalCased)\(definition.name.capitalCased)"
                for type in definition.referencedTypes {
                    register(type, prefix: prefix)
                }
                for operation in definition.operations where operation.isSwiftVaporRoutable {
                    for type in operation.swiftVaporDeclaredDataTypes {
                        register(type, prefix: prefix)
                    }
                    for parameter in operation.parameters {
                        if let type = parameter.swiftVaporDeclaredDataType {
                            register(type, prefix: prefix)
                        }
                    }
                }
            }
        }
    }

    private mutating func registerSupplied(module: ApiModule) {
        for type in module.references {
            registerSupplied(type, prefix: module.name.capitalCased)
        }
        for definition in module.definitions {
            let prefix = "\(module.name.capitalCased)\(definition.name.capitalCased)"
            for type in definition.referencedTypes {
                registerSupplied(type, prefix: prefix)
            }
            for operation in definition.operations where operation.isSwiftVaporRoutable {
                for type in operation.swiftVaporDeclaredDataTypes {
                    registerSupplied(type, prefix: prefix)
                }
                for parameter in operation.parameters {
                    if let type = parameter.swiftVaporDeclaredDataType {
                        registerSupplied(type, prefix: prefix)
                    }
                }
            }
        }
    }

    mutating func register(_ dataType: ApiTypeSchema, prefix: String) {
        if let uuid = dataType.declaredSwiftVaporTypeID,
           suppliedCommonTypeIDs.contains(uuid) {
            registerSupplied(dataType)
            return
        }
        switch dataType {
            case let .reference(_, strict, _, _, dataType):
                if strict, let dataType {
                    register(dataType, prefix: prefix)
                }
            case let .array(type),
                 let .keyedByString(type, _):
                register(type, prefix: prefix)
            case let .genericReference(_, types):
                for type in types {
                    register(type, prefix: prefix)
                }
            case let .object(typeName, properties, _, _, _, uuid):
                guard visitedGeneratedTypeIDs.insert(uuid).inserted else {
                    return
                }
                registerReferenceable(dataType, uuid: uuid, rawName: typeName, prefix: prefix)
                let nestedPrefix = generatedName(rawName: typeName, prefix: prefix)
                for property in properties {
                    register(property.dataType, prefix: nestedPrefix)
                }
            case let .stringEnum(typeName, _, _, uuid, _):
                registerReferenceable(dataType, uuid: uuid, rawName: typeName, prefix: prefix)
            case let .intEnum(typeName, _, _, uuid):
                registerReferenceable(dataType, uuid: uuid, rawName: typeName, prefix: prefix)
            case let .dynamicObject(typeName, _, _, _, objectTypes, _, _, uuid, extraProperties):
                guard visitedGeneratedTypeIDs.insert(uuid).inserted else {
                    return
                }
                registerReferenceable(dataType, uuid: uuid, rawName: typeName, prefix: prefix)
                let nestedPrefix = generatedName(rawName: typeName, prefix: prefix)
                for objectType in objectTypes {
                    register(objectType.objectType, prefix: nestedPrefix)
                }
                for property in extraProperties {
                    register(property.dataType, prefix: nestedPrefix)
                }
            default:
                break
        }
    }

    private mutating func registerSupplied(_ dataType: ApiTypeSchema, prefix: String = "") {
        switch dataType {
            case let .reference(typeName, strict, _, uuid, dataType):
                let suppliedName = strict ? generatedName(rawName: typeName, prefix: prefix) : typeName.swiftTypeReferenceName
                namesByID[uuid] = namesByID[uuid] ?? suppliedName
                if let dataType {
                    registerSupplied(dataType, prefix: prefix)
                }
            case let .array(type),
                 let .keyedByString(type, _):
                registerSupplied(type, prefix: prefix)
            case let .genericReference(_, types):
                for type in types {
                    registerSupplied(type, prefix: prefix)
                }
            case let .object(typeName, properties, _, _, _, uuid):
                guard visitedSuppliedTypeIDs.insert(uuid).inserted else {
                    return
                }
                namesByID[uuid] = namesByID[uuid] ?? generatedName(rawName: typeName, prefix: prefix)
                let nestedPrefix = generatedName(rawName: typeName, prefix: prefix)
                for property in properties {
                    registerSupplied(property.dataType, prefix: nestedPrefix)
                }
            case let .stringEnum(typeName, _, _, uuid, _):
                namesByID[uuid] = namesByID[uuid] ?? generatedName(rawName: typeName, prefix: prefix)
            case let .intEnum(typeName, _, _, uuid):
                namesByID[uuid] = namesByID[uuid] ?? generatedName(rawName: typeName, prefix: prefix)
            case let .dynamicObject(typeName, _, _, _, objectTypes, _, _, uuid, extraProperties):
                guard visitedSuppliedTypeIDs.insert(uuid).inserted else {
                    return
                }
                namesByID[uuid] = namesByID[uuid] ?? generatedName(rawName: typeName, prefix: prefix)
                let nestedPrefix = generatedName(rawName: typeName, prefix: prefix)
                for objectType in objectTypes {
                    registerSupplied(objectType.objectType, prefix: nestedPrefix)
                }
                for property in extraProperties {
                    registerSupplied(property.dataType, prefix: nestedPrefix)
                }
            default:
                break
        }
    }

    // swiftlint:disable:next cyclomatic_complexity
    func swiftType(for dataType: ApiTypeSchema) -> String {
        switch dataType {
            case .uuid:
                "UUID"
            case .string:
                "String"
            case .int:
                "Int"
            case .int64:
                "Int64"
            case .int32:
                "Int32"
            case .int16:
                "Int16"
            case .int8:
                "Int8"
            case .uint:
                "UInt"
            case .uint64:
                "UInt64"
            case .uint32:
                "UInt32"
            case .uint16:
                "UInt16"
            case .uint8:
                "UInt8"
            case .double:
                "Double"
            case .date:
                "Date"
            case .timelessDate:
                "TimelessDate"
            case .time:
                "Time"
            case .url:
                "URL"
            case .bool:
                "Bool"
            case .binary:
                "Data"
            case let .keyedByString(type, isOptional):
                "[String: \(swiftType(for: type))\(isOptional ? "?" : "")]"
            case let .array(type):
                "[\(swiftType(for: type))]"
            case let .stringEnum(typeName, _, _, uuid, _),
                 let .intEnum(typeName, _, _, uuid):
                namesByID[uuid] ?? typeName.swiftTypeName
            case let .object(typeName, _, _, _, _, uuid),
                 let .dynamicObject(typeName, _, _, _, _, _, _, uuid, _):
                namesByID[uuid] ?? typeName.swiftTypeName
            case let .reference(typeName, strict, _, uuid, dataType):
                namesByID[uuid] ?? dataType.map { swiftType(for: $0) } ?? (strict ? typeName.swiftTypeName : typeName.swiftTypeReferenceName)
            case let .genericReference(typeName, types):
                "\(typeName.swiftTypeReferenceName)<\(types.map { swiftType(for: $0) }.joined(separator: ", "))>"
        }
    }

    private mutating func registerReferenceable(_ dataType: ApiTypeSchema, uuid: UUID, rawName: String, prefix: String) {
        guard namesByID[uuid] == nil else {
            return
        }
        let name = generatedName(rawName: rawName, prefix: prefix)
        namesByID[uuid] = name
        types.append(.init(id: uuid, name: name, dataType: dataType))
    }

    private func generatedName(rawName: String, prefix: String) -> String {
        let baseName = rawName.swiftTypeName
        guard !prefix.isEmpty else {
            return baseName
        }
        if baseName.hasPrefix(prefix) {
            return baseName
        }
        return "\(prefix)\(baseName)".swiftTypeName
    }
}

private extension ApiTypeSchema {
    var declaredSwiftVaporTypeID: UUID? {
        switch self {
            case let .object(_, _, _, _, _, uuid),
                 let .stringEnum(_, _, _, uuid, _),
                 let .intEnum(_, _, _, uuid),
                 let .dynamicObject(_, _, _, _, _, _, _, uuid, _),
                 let .reference(_, _, _, uuid, _):
                uuid
            default:
                nil
        }
    }
}

extension String {
    var swiftTypeReferenceName: String {
        let parts = split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count > 1, let last = parts.last else {
            return swiftTypeName
        }

        let prefix = parts.dropLast().map(String.init).joined(separator: ".")
        return "\(prefix).\(String(last).swiftTypeName)"
    }

    var swiftVaporStringLiteral: String {
        debugDescription
    }
}

extension ApiModule {
    var swiftVaporRoutableModule: ApiModule {
        ApiModule(
            name: name,
            definitions: definitions.map(\.swiftVaporRoutableDefinition),
            references: references,
        )
    }

    var swiftVaporRoutePropertyName: String {
        "\(name)Routes".swiftPropertyName
    }
}

extension ApiService {
    var swiftVaporRoutableDefinition: ApiService {
        ApiService(
            name: name,
            operations: operations.filter(\.isSwiftVaporRoutable),
            references: referencedTypes,
        )
    }

    func swiftVaporServiceTypeName(moduleName: String) -> String {
        "\(moduleName.capitalCased)\(name.capitalCased)Service".swiftTypeName
    }

    func swiftVaporControllerTypeName(moduleName: String) -> String {
        "\(moduleName.capitalCased)\(name.capitalCased)Controller".swiftTypeName
    }
}

extension ApiOperation {
    var isSwiftVaporRoutable: Bool {
        if case .relative = path {
            return true
        }
        return false
    }

    var swiftVaporOperationName: String {
        name.swiftPropertyName
    }

    var swiftVaporOperationTypeName: String {
        "\(name.capitalCased)Operation".swiftTypeName
    }

    func swiftVaporRequestTypeName(moduleName: String, definitionName: String) -> String {
        "\(moduleName.capitalCased)\(definitionName.capitalCased)\(swiftVaporOperationTypeName)Request".swiftTypeName
    }

    func swiftVaporMultipartTypeName(moduleName: String, definitionName: String) -> String {
        "\(moduleName.capitalCased)\(definitionName.capitalCased)\(swiftVaporOperationTypeName)MultipartBody".swiftTypeName
    }

    var swiftVaporDeclaredDataTypes: [ApiTypeSchema] {
        [request.dataType, response.dataType]
            .compactMap(\.self)
            .flatMap(\.swiftVaporDeclaredDataTypes)
    }
}

extension ApiParameter {
    var swiftVaporDeclaredDataType: ApiTypeSchema? {
        switch dataType {
            case let .stringEnumValue(type, _),
                 let .stringEnumArray(type, _),
                 let .intEnumValue(type, _),
                 let .intEnumArray(type, _):
                type
            default:
                nil
        }
    }
}

extension ApiTypeSchema {
    var swiftVaporDeclaredDataTypes: [ApiTypeSchema] {
        switch self {
            case .object,
                 .stringEnum,
                 .intEnum,
                 .dynamicObject:
                [self]
            case let .reference(_, strict, _, _, dataType):
                strict ? dataType.map(\.swiftVaporDeclaredDataTypes) ?? [] : []
            case let .array(type),
                 let .keyedByString(type, _):
                type.swiftVaporDeclaredDataTypes
            case let .genericReference(_, types):
                types.flatMap(\.swiftVaporDeclaredDataTypes)
            default:
                []
        }
    }
}

extension ApiParameter.DataType {
    var isSwiftVaporArray: Bool {
        switch self {
            case .boolArray,
                 .stringArray,
                 .intArray,
                 .int16Array,
                 .int32Array,
                 .int64Array,
                 .uintArray,
                 .uint16Array,
                 .uint32Array,
                 .uint64Array,
                 .stringEnumArray,
                 .intEnumArray:
                true
            default:
                false
        }
    }

    // swiftlint:disable:next cyclomatic_complexity
    func swiftVaporType(registry: SwiftVaporTypeRegistry) -> String {
        switch self {
            case .bool:
                "Bool"
            case .boolArray:
                "[Bool]"
            case .string:
                "String"
            case .stringArray:
                "[String]"
            case .int:
                "Int"
            case .int16:
                "Int16"
            case .int32:
                "Int32"
            case .int64:
                "Int64"
            case .intArray:
                "[Int]"
            case .int16Array:
                "[Int16]"
            case .int32Array:
                "[Int32]"
            case .int64Array:
                "[Int64]"
            case .uint:
                "UInt"
            case .uint16:
                "UInt16"
            case .uint32:
                "UInt32"
            case .uint64:
                "UInt64"
            case .uintArray:
                "[UInt]"
            case .uint16Array:
                "[UInt16]"
            case .uint32Array:
                "[UInt32]"
            case .uint64Array:
                "[UInt64]"
            case let .stringEnumValue(type, _),
                 let .intEnumValue(type, _):
                registry.swiftType(for: type)
            case let .stringEnumArray(type, _),
                 let .intEnumArray(type, _):
                "[\(registry.swiftType(for: type))]"
            case .date:
                "Date"
            case .dateTime:
                "Date"
            case .time:
                "Time"
        }
    }
}

extension ApiRequestBody {
    var isSwiftVaporSendable: Bool {
        switch self {
            case let .json(type):
                type?.isSwiftVaporSendable ?? true
            default:
                true
        }
    }
}

extension ApiTypeSchema {
    var isSwiftVaporSendable: Bool {
        var seen = Set<UUID>()
        return isSwiftVaporSendable(seen: &seen)
    }

    private func isSwiftVaporSendable(seen: inout Set<UUID>) -> Bool {
        if case let .reference(_, _, _, _, dataType) = self {
            return dataType?.isSwiftVaporSendable(seen: &seen) ?? true
        }
        if let uuid = uuid ?? referenceUUID,
           !seen.insert(uuid).inserted {
            return true
        }

        switch self {
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
                return true
            case let .keyedByString(type, _),
                 let .array(type):
                return type.isSwiftVaporSendable(seen: &seen)
            case let .object(_, properties, protocols, _, isValueType, _):
                guard isValueType || protocols.contains("Sendable") || protocols.contains("@unchecked Sendable") else {
                    return false
                }
                return properties.allSatisfy { $0.dataType.isSwiftVaporSendable(seen: &seen) }
            case let .dynamicObject(_, _, _, _, objectTypes, _, _, _, extraProperties):
                return objectTypes.allSatisfy { $0.objectType.isSwiftVaporSendable(seen: &seen) }
                    && extraProperties.allSatisfy { $0.dataType.isSwiftVaporSendable(seen: &seen) }
            case .reference:
                return true
            case let .genericReference(_, types):
                return types.allSatisfy { $0.isSwiftVaporSendable(seen: &seen) }
        }
    }
}
