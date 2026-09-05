import Foundation
import GeneratorModels

struct KotlinTypeEmitter {
    let dataType: ApiTypeSchema
    let options: KotlinGeneratorOptions

    init(dataType: ApiTypeSchema, options: KotlinGeneratorOptions = .init()) {
        self.dataType = dataType
        self.options = options
    }

    var typeDeclaration: String {
        typeName.declaration
    }

    var typeName: KotlinTypeName {
        switch dataType {
            case .uuid:
                return KotlinTypeName("String")
            case .string:
                return KotlinTypeName("String")
            case .int:
                return KotlinTypeName("Int")
            case .int64:
                return KotlinTypeName("Long")
            case .int32:
                return KotlinTypeName("Int")
            case .int16:
                return KotlinTypeName("Short")
            case .int8:
                return KotlinTypeName("Byte")
            case .uint:
                return KotlinTypeName("UInt")
            case .uint64:
                return KotlinTypeName("ULong")
            case .uint32:
                return KotlinTypeName("UInt")
            case .uint16:
                return KotlinTypeName("UShort")
            case .uint8:
                return KotlinTypeName("UByte")
            case .double:
                return KotlinTypeName("Double")
            case .date:
                return KotlinTypeName("Instant", imports: ["kotlin.time.Instant"])
            case .timelessDate:
                return KotlinTypeName("LocalDate", imports: ["kotlinx.datetime.LocalDate"])
            case .time:
                return KotlinTypeName("LocalTime", imports: ["kotlinx.datetime.LocalTime"])
            case .url:
                return KotlinTypeName("String")
            case .bool:
                return KotlinTypeName("Boolean")
            case .binary:
                return KotlinTypeName("ByteArray")
            case let .keyedByString(type, isOptional):
                let valueTypeName = Self(dataType: type, options: options).typeName
                let valueDeclaration = isOptional ? valueTypeName.nullable.declaration : valueTypeName.declaration
                return KotlinTypeName("Map<String, \(valueDeclaration)>", imports: valueTypeName.imports)
            case let .stringEnum(typeName, _, _, _, _),
                 let .intEnum(typeName, _, _, _),
                 let .object(typeName, _, _, _, _, _),
                 let .dynamicObject(typeName, _, _, _, _, _, _, _, _):
                if let mapping = options.mapping(for: typeName) {
                    return KotlinTypeName(mapping.kotlinType, imports: Set(mapping.imports))
                }
                return KotlinTypeName(typeName.kotlinTypeReferenceName)
            case let .reference(typeName, strict, imports, _, dataType):
                if let dataType {
                    return Self(dataType: dataType, options: options).typeName
                }
                if let mapping = options.mapping(for: typeName) {
                    return KotlinTypeName(mapping.kotlinType, imports: Set(mapping.imports))
                }
                return KotlinTypeName(typeName.kotlinTypeReferenceName, imports: strict ? [] : Set(imports.map(\.name)))
            case let .array(type):
                let itemTypeName = Self(dataType: type, options: options).typeName
                return KotlinTypeName("List<\(itemTypeName.declaration)>", imports: itemTypeName.imports)
            case let .genericReference(typeName, types):
                let typeNames = types.map { Self(dataType: $0, options: options).typeName }
                let genericDeclaration = typeNames.map(\.declaration).joined(separator: ", ")
                let imports = typeNames.reduce(Set<String>()) { $0.union($1.imports) }
                if let mapping = options.mapping(for: typeName) {
                    return KotlinTypeName("\(mapping.kotlinType)<\(genericDeclaration)>", imports: imports.union(mapping.imports))
                }
                return KotlinTypeName("\(typeName.kotlinTypeReferenceName)<\(genericDeclaration)>", imports: imports)
        }
    }

    // swiftlint:disable:next cyclomatic_complexity
    func defaultValue(required: Bool) -> String? {
        if dataType.isKotlinPatchableValue {
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
