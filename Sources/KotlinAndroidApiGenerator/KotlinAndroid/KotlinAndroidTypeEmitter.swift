import Foundation
import GeneratorModels

struct KotlinAndroidTypeEmitter {
    let dataType: ApiTypeSchema
    let options: KotlinAndroidGeneratorOptions

    init(dataType: ApiTypeSchema, options: KotlinAndroidGeneratorOptions = .init()) {
        self.dataType = dataType
        self.options = options
    }

    var typeDeclaration: String {
        typeName.declaration
    }

    var typeName: KotlinAndroidTypeName {
        switch dataType {
            case .uuid:
                return KotlinAndroidTypeName("String")
            case .string:
                return KotlinAndroidTypeName("String")
            case .int:
                return KotlinAndroidTypeName("Int")
            case .int64:
                return KotlinAndroidTypeName("Long")
            case .int32:
                return KotlinAndroidTypeName("Int")
            case .int16:
                return KotlinAndroidTypeName("Short")
            case .int8:
                return KotlinAndroidTypeName("Byte")
            case .uint:
                return KotlinAndroidTypeName("UInt")
            case .uint64:
                return KotlinAndroidTypeName("ULong")
            case .uint32:
                return KotlinAndroidTypeName("UInt")
            case .uint16:
                return KotlinAndroidTypeName("UShort")
            case .uint8:
                return KotlinAndroidTypeName("UByte")
            case .double:
                return KotlinAndroidTypeName("Double")
            case .date:
                return KotlinAndroidTypeName("Instant", imports: ["kotlin.time.Instant"])
            case .timelessDate:
                return KotlinAndroidTypeName("LocalDate", imports: ["kotlinx.datetime.LocalDate"])
            case .time:
                return KotlinAndroidTypeName("LocalTime", imports: ["kotlinx.datetime.LocalTime"])
            case .url:
                return KotlinAndroidTypeName("String")
            case .bool:
                return KotlinAndroidTypeName("Boolean")
            case .binary:
                return KotlinAndroidTypeName("ByteArray")
            case let .keyedByString(type, isOptional):
                let valueTypeName = Self(dataType: type, options: options).typeName
                let valueDeclaration = isOptional ? valueTypeName.nullable.declaration : valueTypeName.declaration
                return KotlinAndroidTypeName("Map<String, \(valueDeclaration)>", imports: valueTypeName.imports)
            case let .stringEnum(typeName, _, _, _, _),
                 let .intEnum(typeName, _, _, _),
                 let .object(typeName, _, _, _, _, _),
                 let .dynamicObject(typeName, _, _, _, _, _, _, _, _):
                if let mapping = options.mapping(for: typeName) {
                    return KotlinAndroidTypeName(mapping.kotlinType, imports: Set(mapping.imports))
                }
                return KotlinAndroidTypeName(typeName.kotlinTypeReferenceName)
            case let .reference(typeName, strict, imports, _, dataType):
                if let dataType {
                    return Self(dataType: dataType, options: options).typeName
                }
                if let mapping = options.mapping(for: typeName) {
                    return KotlinAndroidTypeName(mapping.kotlinType, imports: Set(mapping.imports))
                }
                return KotlinAndroidTypeName(typeName.kotlinTypeReferenceName, imports: strict ? [] : Set(imports.map(\.name)))
            case let .array(type):
                let itemTypeName = Self(dataType: type, options: options).typeName
                return KotlinAndroidTypeName("List<\(itemTypeName.declaration)>", imports: itemTypeName.imports)
            case let .genericReference(typeName, types):
                let typeNames = types.map { Self(dataType: $0, options: options).typeName }
                let genericDeclaration = typeNames.map(\.declaration).joined(separator: ", ")
                let imports = typeNames.reduce(Set<String>()) { $0.union($1.imports) }
                if let mapping = options.mapping(for: typeName) {
                    return KotlinAndroidTypeName("\(mapping.kotlinType)<\(genericDeclaration)>", imports: imports.union(mapping.imports))
                }
                return KotlinAndroidTypeName("\(typeName.kotlinTypeReferenceName)<\(genericDeclaration)>", imports: imports)
        }
    }

    // swiftlint:disable:next cyclomatic_complexity
    func defaultValue(required: Bool) -> String? {
        if dataType.isKotlinAndroidPatchableValue {
            let patchableTypeName =
                dataType.typeName.flatMap { options.mapping(for: $0)?.kotlinType }
                    ?? "PatchableValue"
            return "\(patchableTypeName).Unmodified"
        }

        if !required {
            return "null"
        }

        switch dataType {
            case let .string(initialValue):
                return initialValue?.kotlinStringLiteral
            case let .int(initialValue):
                return initialValue.map { "\($0)" }
            case let .int64(initialValue):
                return initialValue.map { "\($0)L" }
            case let .int32(initialValue):
                return initialValue.map { "\($0)" }
            case let .int16(initialValue):
                return initialValue.map { "\($0)" }
            case let .int8(initialValue):
                return initialValue.map { "\($0)" }
            case let .uint(initialValue):
                return initialValue.map { "\($0)u" }
            case let .uint64(initialValue):
                return initialValue.map { "\($0)uL" }
            case let .uint32(initialValue):
                return initialValue.map { "\($0)u" }
            case let .uint16(initialValue):
                return initialValue.map { "\($0)u" }
            case let .uint8(initialValue):
                return initialValue.map { "\($0)u" }
            case let .double(initialValue):
                return initialValue.map { "\($0)" }
            case let .date(initialValue):
                return initialValue.map { value in
                    let milliseconds = Int64((value.timeIntervalSince1970 * 1000).rounded())
                    return "Instant.fromEpochMilliseconds(\(milliseconds)L)"
                }
            case let .url(initialValue):
                return initialValue.map(\.absoluteString.kotlinStringLiteral)
            case let .bool(initialValue):
                return String(describing: initialValue)
            case let .stringEnum(typeName, values, initialValue, _, _):
                guard options.mapping(for: typeName) == nil else {
                    return nil
                }
                guard let initialValue,
                      let selectedCase = values.first(where: { $0.name == initialValue }) else {
                    return nil
                }
                return "\(typeName.kotlinTypeReferenceName).\(selectedCase.name.kotlinEnumCaseName)"
            case let .intEnum(typeName, values, initialValue, _):
                guard options.mapping(for: typeName) == nil else {
                    return nil
                }
                guard let initialValue,
                      let selectedCase = values.first(where: { $0.rawValue == initialValue }) else {
                    return nil
                }
                let caseName = selectedCase.name?.isEmpty == false
                    ? selectedCase.name?.kotlinEnumCaseName
                    : selectedCase.rawValue.description.kotlinEnumCaseName
                return caseName.map { "\(typeName.kotlinTypeReferenceName).\($0)" }
            case let .reference(typeName, _, _, _, dataType):
                guard options.mapping(for: typeName) == nil else {
                    return nil
                }
                return dataType.flatMap { Self(dataType: $0, options: options).defaultValue(required: required) }
            default:
                return nil
        }
    }
}
