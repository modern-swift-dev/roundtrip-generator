import Foundation
import GeneratorBuilder
import GeneratorModels

extension ApiParameter.DataType {
    var kotlinOperationTypeDeclaration: String {
        kotlinOperationTypeDeclaration(options: .init())
    }

    // swiftlint:disable:next cyclomatic_complexity
    func kotlinOperationTypeDeclaration(options: KotlinGeneratorOptions) -> String {
        switch self {
            case .bool:
                "Boolean"
            case .boolArray:
                "List<Boolean>"
            case .string:
                "String"
            case .stringArray:
                "List<String>"
            case .int:
                "Int"
            case .intArray:
                "List<Int>"
            case .int16:
                "Short"
            case .int16Array:
                "List<Short>"
            case .int32:
                "Int"
            case .int32Array:
                "List<Int>"
            case .int64:
                "Long"
            case .int64Array:
                "List<Long>"
            case .uint:
                "UInt"
            case .uintArray:
                "List<UInt>"
            case .uint16:
                "UShort"
            case .uint16Array:
                "List<UShort>"
            case .uint32:
                "UInt"
            case .uint32Array:
                "List<UInt>"
            case .uint64:
                "ULong"
            case .uint64Array:
                "List<ULong>"
            case let .stringEnumValue(type, _):
                type.kotlinTypeDeclaration(options: options)
            case let .stringEnumArray(type, _):
                "List<\(type.kotlinTypeDeclaration(options: options))>"
            case let .intEnumValue(type, _):
                type.kotlinTypeDeclaration(options: options)
            case let .intEnumArray(type, _):
                "List<\(type.kotlinTypeDeclaration(options: options))>"
            case .dateTime:
                "Instant"
            case .date:
                "LocalDate"
            case .time:
                "LocalTime"
        }
    }

    var kotlinOperationDefaultValue: String? {
        kotlinOperationDefaultValue(options: .init())
    }

    func kotlinOperationDefaultValue(options: KotlinGeneratorOptions) -> String? {
        switch self {
            case let .bool(value):
                value.map { $0 ? "true" : "false" }
            case let .boolArray(value):
                value.map { kotlinListLiteral($0.map { $0 ? "true" : "false" }) }
            case let .string(value):
                value?.kotlinStringLiteral
            case let .stringArray(value):
                value.map { kotlinListLiteral($0.map(\.kotlinStringLiteral)) }
            case let .stringEnumValue(type, value):
                value.map { "\(type.kotlinTypeDeclaration(options: options)).fromValue(\($0.kotlinStringLiteral))" }
            case let .stringEnumArray(type, values):
                values.map { kotlinListLiteral($0.map { "\(type.kotlinTypeDeclaration(options: options)).fromValue(\($0.kotlinStringLiteral))" }) }
            case let .intEnumValue(type, value):
                value.map { "\(type.kotlinTypeDeclaration(options: options)).fromValue(\($0))" }
            case let .intEnumArray(type, values):
                values.map { kotlinListLiteral($0.map { "\(type.kotlinTypeDeclaration(options: options)).fromValue(\($0))" }) }
            case .dateTime,
                 .date,
                 .time:
                nil
            case .int,
                 .intArray,
                 .int16,
                 .int16Array,
                 .int32,
                 .int32Array,
                 .int64,
                 .int64Array,
                 .uint,
                 .uintArray,
                 .uint16,
                 .uint16Array,
                 .uint32,
                 .uint32Array,
                 .uint64,
                 .uint64Array:
                kotlinOperationIntegerDefaultValue
        }
    }

    private var kotlinOperationIntegerDefaultValue: String? {
        switch self {
            case let .int(value):
                value.map(String.init)
            case let .intArray(value):
                value.map { kotlinListLiteral($0.map(String.init)) }
            case let .int16(value):
                value.map { "\($0)" }
            case let .int16Array(value):
                value.map { kotlinListLiteral($0.map { "\($0)" }) }
            case let .int32(value):
                value.map { "\($0)" }
            case let .int32Array(value):
                value.map { kotlinListLiteral($0.map { "\($0)" }) }
            case let .int64(value):
                value.map { "\($0)L" }
            case let .int64Array(value):
                value.map { kotlinListLiteral($0.map { "\($0)L" }) }
            case let .uint(value):
                value.map { "\($0)u" }
            case let .uintArray(value):
                value.map { kotlinListLiteral($0.map { "\($0)u" }) }
            case let .uint16(value):
                value.map { "\($0)u" }
            case let .uint16Array(value):
                value.map { kotlinListLiteral($0.map { "\($0)u" }) }
            case let .uint32(value):
                value.map { "\($0)u" }
            case let .uint32Array(value):
                value.map { kotlinListLiteral($0.map { "\($0)u" }) }
            case let .uint64(value):
                value.map { "\($0)uL" }
            case let .uint64Array(value):
                value.map { kotlinListLiteral($0.map { "\($0)uL" }) }
            default:
                nil
        }
    }

    var kotlinOperationImports: Set<String> {
        kotlinOperationImports(options: .init())
    }

    func kotlinOperationImports(options: KotlinGeneratorOptions) -> Set<String> {
        switch self {
            case let .stringEnumValue(type, _),
                 let .stringEnumArray(type, _),
                 let .intEnumValue(type, _),
                 let .intEnumArray(type, _):
                type.kotlinTypeImports(options: options)
            case .dateTime:
                ["kotlin.time.Instant"]
            case .date:
                ["kotlinx.datetime.LocalDate"]
            case .time:
                ["kotlinx.datetime.LocalTime"]
            default:
                []
        }
    }

    var isKotlinOperationCollection: Bool {
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

    func kotlinOperationFormValueExpression(_ expression: String) -> String {
        switch self {
            case .stringEnumValue,
                 .intEnumValue:
                "\(expression).rawValue.toApiFormValue()"
            case .stringEnumArray,
                 .intEnumArray:
                "\(expression).joinToString(\",\") { it.rawValue.toApiFormValue() }"
            default:
                "\(expression).toApiFormValue()"
        }
    }

    func kotlinOperationPathSegmentExpression(_ expression: String) -> String {
        switch self {
            case .stringEnumValue,
                 .intEnumValue:
                "\(expression).rawValue.toApiPathSegment()"
            default:
                "\(expression).toApiPathSegment()"
        }
    }
}

private func kotlinListLiteral(_ values: [String]) -> String {
    let singleLine = "listOf(\(values.joined(separator: ", ")))"
    guard singleLine.count > 80 else {
        return singleLine
    }

    return Block {
        "listOf("
        Indentation {
            NodeList(values.map { "\($0)," as any Node })
        }
        ")"
    }
    .toString()
}
