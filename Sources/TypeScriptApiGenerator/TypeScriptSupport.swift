import Foundation
import GeneratorBuilder
import GeneratorModels

// swiftlint:disable cyclomatic_complexity

enum TypeScriptGeneratorError: Error, LocalizedError, Equatable {
    case invalidPackageName(String)
    case invalidSourceDirectory(String)
    case invalidPackage(reason: String)
    case unresolvedExternalType(String)
    case emptyAcceptableStatuses(operationName: String)
    case invalidAcceptableStatus(operationName: String, statusCode: Int)
    case typedResponseWithBodylessStatus(operationName: String, statusCode: Int)

    var errorDescription: String? {
        switch self {
            case let .invalidPackageName(value):
                "Invalid TypeScript package name: \(value)"
            case let .invalidSourceDirectory(value):
                "Invalid TypeScript source directory: \(value)"
            case let .invalidPackage(reason):
                "Invalid TypeScript package: \(reason)"
            case let .unresolvedExternalType(value):
                "Missing TypeScript type mapping for external type: \(value)"
            case let .emptyAcceptableStatuses(operationName):
                "TypeScript operation \(operationName) must accept at least one HTTP status"
            case let .invalidAcceptableStatus(operationName, statusCode):
                "TypeScript operation \(operationName) has invalid HTTP status \(statusCode)"
            case let .typedResponseWithBodylessStatus(operationName, statusCode):
                "TypeScript operation \(operationName) has a typed response but accepts bodyless HTTP status \(statusCode)"
        }
    }
}

struct TypeScriptTypeEmitter {
    let dataType: ApiTypeSchema
    let options: TypeScriptGeneratorOptions
    let declaredTypePrefix: String

    init(
        dataType: ApiTypeSchema,
        options: TypeScriptGeneratorOptions = .init(),
        declaredTypePrefix: String = "",
    ) {
        self.dataType = dataType
        self.options = options
        self.declaredTypePrefix = declaredTypePrefix
    }

    var declaration: String {
        switch dataType {
            case .uuid,
                 .string,
                 .timelessDate,
                 .time:
                return "string"
            case .int,
                 .int64,
                 .int32,
                 .int16,
                 .int8,
                 .uint,
                 .uint64,
                 .uint32,
                 .uint16,
                 .uint8,
                 .double:
                return "number"
            case .date:
                return "Date"
            case .url:
                return "URL"
            case .bool:
                return "boolean"
            case .binary:
                return "ArrayBuffer"
            case let .keyedByString(type, isOptional):
                let valueType = Self(dataType: type, options: options, declaredTypePrefix: declaredTypePrefix).declaration
                return isOptional ? "Record<string, \(valueType) | null>" : "Record<string, \(valueType)>"
            case let .array(type):
                return "\(Self(dataType: type, options: options, declaredTypePrefix: declaredTypePrefix).declaration)[]"
            case let .stringEnum(typeName, _, _, _, _),
                 let .intEnum(typeName, _, _, _),
                 let .object(typeName, _, _, _, _, _),
                 let .dynamicObject(typeName, _, _, _, _, _, _, _, _):
                if let mapping = options.mapping(for: typeName) {
                    return mapping.typeScriptType
                }
                return "\(declaredTypePrefix)\(typeName.tsTypeName)"
            case let .reference(typeName, strict, _, _, referencedDataType):
                if let referencedDataType {
                    return Self(dataType: referencedDataType, options: options, declaredTypePrefix: declaredTypePrefix).declaration
                }
                if let mapping = options.mapping(for: typeName) {
                    return mapping.typeScriptType
                }
                return strict ? "\(declaredTypePrefix)\(typeName.tsTypeName)" : typeName
            case let .genericReference(typeName, types):
                let genericTypes = types
                    .map { Self(dataType: $0, options: options, declaredTypePrefix: declaredTypePrefix).declaration }
                    .joined(separator: ", ")
                let baseType = options.mapping(for: typeName)?.typeScriptType ?? typeName.tsTypeName
                return "\(baseType)<\(genericTypes)>"
        }
    }

    func defaultValue(required: Bool) -> String? {
        if dataType.isTypeScriptPatchableValue {
            return "{ state: \"unmodified\" }"
        }

        var defaultValue: String?
        switch dataType {
            case let .string(initialValue):
                defaultValue = initialValue?.tsStringLiteral
            case let .int(initialValue):
                defaultValue = initialValue.map { String($0) }
            case let .int64(initialValue):
                defaultValue = initialValue.map { String($0) }
            case let .int32(initialValue):
                defaultValue = initialValue.map { String($0) }
            case let .int16(initialValue):
                defaultValue = initialValue.map { String($0) }
            case let .int8(initialValue):
                defaultValue = initialValue.map { String($0) }
            case let .uint(initialValue):
                defaultValue = initialValue.map { String($0) }
            case let .uint64(initialValue):
                defaultValue = initialValue.map { String($0) }
            case let .uint32(initialValue):
                defaultValue = initialValue.map { String($0) }
            case let .uint16(initialValue):
                defaultValue = initialValue.map { String($0) }
            case let .uint8(initialValue):
                defaultValue = initialValue.map { String($0) }
            case let .double(initialValue):
                defaultValue = initialValue.map { String($0) }
            case let .date(initialValue):
                defaultValue = initialValue.map { "new Date(\($0.timeIntervalSince1970 * 1000))" }
            case let .url(initialValue):
                defaultValue = initialValue.map { "new URL(\($0.absoluteString.tsStringLiteral))" }
            case let .bool(initialValue):
                defaultValue = String(describing: initialValue)
            case let .stringEnum(typeName, values, initialValue, _, _):
                if options.mapping(for: typeName) == nil,
                   let initialValue,
                   let selectedCase = values.first(where: { $0.name == initialValue }) {
                    defaultValue = selectedCase.rawName.tsStringLiteral
                }
            case let .intEnum(typeName, values, initialValue, _):
                if options.mapping(for: typeName) == nil,
                   let initialValue,
                   values.contains(where: { $0.rawValue == initialValue }) {
                    defaultValue = String(initialValue)
                }
            case let .reference(typeName, _, _, _, referencedDataType):
                if options.mapping(for: typeName) == nil {
                    defaultValue = referencedDataType.flatMap {
                        Self(dataType: $0, options: options, declaredTypePrefix: declaredTypePrefix).defaultValue(required: required)
                    }
                }
            default:
                break
        }

        if !required, defaultValue == nil {
            return "null"
        }
        return defaultValue
    }
}

struct TypeScriptParameterEmitter {
    let dataType: ApiParameter.DataType
    let options: TypeScriptGeneratorOptions
    let declaredTypePrefix: String

    var declaration: String {
        switch dataType {
            case .bool:
                "boolean"
            case .boolArray:
                "boolean[]"
            case .string,
                 .date,
                 .time:
                "string"
            case .stringArray:
                "string[]"
            case .dateTime:
                "Date"
            case .int,
                 .int16,
                 .int32,
                 .int64,
                 .uint,
                 .uint16,
                 .uint32,
                 .uint64:
                "number"
            case .intArray,
                 .int16Array,
                 .int32Array,
                 .int64Array,
                 .uintArray,
                 .uint16Array,
                 .uint32Array,
                 .uint64Array:
                "number[]"
            case let .stringEnumValue(type, _),
                 let .intEnumValue(type, _):
                TypeScriptTypeEmitter(dataType: type, options: options, declaredTypePrefix: declaredTypePrefix).declaration
            case let .stringEnumArray(type, _),
                 let .intEnumArray(type, _):
                "\(TypeScriptTypeEmitter(dataType: type, options: options, declaredTypePrefix: declaredTypePrefix).declaration)[]"
        }
    }

    func defaultValue() -> String? {
        switch dataType {
            case let .bool(value):
                value.map { String(describing: $0) }
            case let .boolArray(value):
                value.map { "[\($0.map { String(describing: $0) }.joined(separator: ", "))]" }
            case let .string(value):
                value?.tsStringLiteral
            case let .stringArray(value):
                value.map { "[\($0.map(\.tsStringLiteral).joined(separator: ", "))]" }
            case let .int(value):
                value.map { String($0) }
            case let .int16(value):
                value.map { String($0) }
            case let .int32(value):
                value.map { String($0) }
            case let .int64(value):
                value.map { String($0) }
            case let .intArray(value):
                value.map { "[\($0.map { String($0) }.joined(separator: ", "))]" }
            case let .int16Array(value):
                value.map { "[\($0.map { String($0) }.joined(separator: ", "))]" }
            case let .int32Array(value):
                value.map { "[\($0.map { String($0) }.joined(separator: ", "))]" }
            case let .int64Array(value):
                value.map { "[\($0.map { String($0) }.joined(separator: ", "))]" }
            case let .uint(value):
                value.map { String($0) }
            case let .uint16(value):
                value.map { String($0) }
            case let .uint32(value):
                value.map { String($0) }
            case let .uint64(value):
                value.map { String($0) }
            case let .uintArray(value):
                value.map { "[\($0.map { String($0) }.joined(separator: ", "))]" }
            case let .uint16Array(value):
                value.map { "[\($0.map { String($0) }.joined(separator: ", "))]" }
            case let .uint32Array(value):
                value.map { "[\($0.map { String($0) }.joined(separator: ", "))]" }
            case let .uint64Array(value):
                value.map { "[\($0.map { String($0) }.joined(separator: ", "))]" }
            case let .stringEnumValue(_, value):
                value?.tsStringLiteral
            case let .stringEnumArray(_, values):
                values.map { "[\($0.map(\.tsStringLiteral).joined(separator: ", "))]" }
            case let .intEnumValue(_, value):
                value.map { String($0) }
            case let .intEnumArray(_, values):
                values.map { "[\($0.map { String($0) }.joined(separator: ", "))]" }
            case .date,
                 .dateTime,
                 .time:
                nil
        }
    }
}

extension String {
    private static let typeScriptKeywords: Set<String> = [
        "abstract", "any", "as", "async", "await", "boolean", "break", "case", "catch",
        "class", "const", "constructor", "continue", "debugger", "declare", "default",
        "delete", "do", "else", "enum", "export", "extends", "false", "finally", "for",
        "from", "function", "get", "if", "implements", "import", "in", "infer", "instanceof",
        "interface", "is", "keyof", "let", "module", "namespace", "never", "new", "null",
        "number", "object", "of", "package", "private", "protected", "public", "readonly",
        "require", "return", "set", "static", "string", "super", "switch", "symbol", "this",
        "throw", "true", "try", "type", "typeof", "undefined", "unique", "unknown", "var",
        "void", "while", "with", "yield"
    ]

    var tsStringLiteral: String {
        debugDescription
    }

    var tsPropertyName: String {
        camelized.tsIdentifierWithValidLeadingCharacter.tsIdentifier
    }

    var tsTypeName: String {
        capitalCased.tsIdentifierWithValidLeadingCharacter.tsIdentifier
    }

    var tsEnumCaseName: String {
        camelized.tsIdentifierWithValidLeadingCharacter.tsIdentifier
    }

    var tsFileName: String {
        let value = camelized
        return value.isEmpty ? "value" : value
    }

    var isValidTypeScriptPackageName: Bool {
        let pattern = #"^(@[a-z0-9][a-z0-9._~-]*/)?[a-z0-9][a-z0-9._~-]*$"#
        return range(of: pattern, options: .regularExpression) != nil
    }

    private var tsIdentifier: String {
        if isEmpty {
            return "_value"
        }
        if Self.typeScriptKeywords.contains(self) {
            return "\(self)_"
        }
        return self
    }

    private var tsIdentifierWithValidLeadingCharacter: String {
        if first?.isNumber == true {
            return "_\(self)"
        }
        return self
    }
}

extension ApiTypeSchema {
    var declaredTypeScriptTypeID: UUID? {
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

    var isTypeScriptPatchableValue: Bool {
        switch self {
            case let .genericReference(typeName, _):
                typeName == "PatchableValue"
            case let .reference(_, _, _, _, dataType):
                dataType?.isTypeScriptPatchableValue ?? false
            default:
                false
        }
    }

    func appendDeclaredTypeScriptDataTypes(to result: inout [ApiTypeSchema], seen: inout Set<UUID>) {
        // Reference wrappers share their UUID with the declaration they resolve to.
        if case let .reference(_, _, _, _, dataType) = self {
            dataType?.appendDeclaredTypeScriptDataTypes(to: &result, seen: &seen)
            return
        }
        if let uuid = declaredTypeScriptTypeID {
            guard seen.insert(uuid).inserted else {
                return
            }
            result.append(self)
        }
        switch self {
            case let .object(_, properties, _, _, _, _):
                for property in properties where property.publishedAsField {
                    property.dataType.appendDeclaredTypeScriptDataTypes(to: &result, seen: &seen)
                }
            case let .dynamicObject(_, _, _, _, objectTypes, _, _, _, extraProperties):
                for objectType in objectTypes {
                    objectType.objectType.appendDeclaredTypeScriptDataTypes(to: &result, seen: &seen)
                }
                for property in extraProperties where property.publishedAsField {
                    property.dataType.appendDeclaredTypeScriptDataTypes(to: &result, seen: &seen)
                }
            case let .array(type),
                 let .keyedByString(type, _):
                type.appendDeclaredTypeScriptDataTypes(to: &result, seen: &seen)
            case let .genericReference(_, types):
                for type in types {
                    type.appendDeclaredTypeScriptDataTypes(to: &result, seen: &seen)
                }
            default:
                break
        }
    }

    func externalTypeNames(options: TypeScriptGeneratorOptions, seen: inout Set<UUID>) -> [String] {
        switch self {
            case .object,
                 .dynamicObject:
                if let uuid = declaredTypeScriptTypeID, !seen.insert(uuid).inserted {
                    return []
                }
            default:
                break
        }
        switch self {
            case let .reference(typeName, _, _, _, dataType):
                if options.mapping(for: typeName) != nil {
                    return []
                }
                if let dataType {
                    return dataType.externalTypeNames(options: options, seen: &seen)
                }
                return [typeName]
            case let .genericReference(typeName, types):
                let current = options.mapping(for: typeName) == nil ? [typeName] : []
                return current + types.flatMap { $0.externalTypeNames(options: options, seen: &seen) }
            case let .array(type),
                 let .keyedByString(type, _):
                return type.externalTypeNames(options: options, seen: &seen)
            case let .object(typeName, properties, _, _, _, _):
                if options.mapping(for: typeName) != nil {
                    return []
                }
                return properties
                    .filter(\.publishedAsField)
                    .flatMap { $0.dataType.externalTypeNames(options: options, seen: &seen) }
            case let .dynamicObject(typeName, _, _, _, objectTypes, _, _, _, extraProperties):
                if options.mapping(for: typeName) != nil {
                    return []
                }
                return objectTypes.flatMap { $0.objectType.externalTypeNames(options: options, seen: &seen) }
                    + extraProperties.flatMap { $0.dataType.externalTypeNames(options: options, seen: &seen) }
            default:
                return []
        }
    }
}

extension ApiParameter {
    var usedTypeScriptDataTypes: [ApiTypeSchema] {
        switch dataType {
            case let .stringEnumValue(type, _),
                 let .stringEnumArray(type, _),
                 let .intEnumValue(type, _),
                 let .intEnumArray(type, _):
                [type]
            default:
                []
        }
    }
}

extension ApiOperation {
    var usedTypeScriptDataTypes: [ApiTypeSchema] {
        [request.dataType, response.dataType].compactMap(\.self)
            + parameters.flatMap(\.usedTypeScriptDataTypes)
    }
}
