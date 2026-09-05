import Foundation
import GeneratorBuilder

/// Primitive and composite data types used to describe generated Swift models.
public indirect enum ApiTypeSchema: Sendable {

    /// `Foundation.UUID` datatype, may not have a default value.
    /// - Example 1: `ApiTypeSchema.uuid`
    case uuid

    /// `Swift.String` primitive datatype, may have a default value.
    /// - Example 1: `ApiTypeSchema.string()`
    /// - Example 2: `ApiTypeSchema.string("")`
    /// - Example 3: `ApiTypeSchema.string("value")`
    case string(String? = nil)

    /// `Swift.Int` primitive datatype, may have a default value.
    /// - Example 1: `ApiTypeSchema.int()`
    /// - Example 2: `ApiTypeSchema.int(0)`
    /// - Example 3: `ApiTypeSchema.int(.max)`
    case int(Int? = nil)

    /// `Swift.Int64` primitive datatype, may have a default value.
    /// - Example 1: `ApiTypeSchema.int64()`
    /// - Example 2: `ApiTypeSchema.int64(0)`
    /// - Example 3: `ApiTypeSchema.int64(.max)`
    case int64(Int64? = nil)

    /// `Swift.Int32` primitive datatype, may have a default value.
    /// - Example 1: `ApiTypeSchema.int32()`
    /// - Example 2: `ApiTypeSchema.int32(0)`
    /// - Example 3: `ApiTypeSchema.int32(.max)`
    case int32(Int32? = nil)

    /// `Swift.Int16` primitive datatype, may have a default value.
    /// - Example 1: `ApiTypeSchema.int16()`
    /// - Example 2: `ApiTypeSchema.int16(0)`
    /// - Example 3: `ApiTypeSchema.int16(.max)`
    case int16(Int16? = nil)

    /// `Swift.Int8` primitive datatype, may have a default value.
    /// - Example 1: `ApiTypeSchema.int8()`
    /// - Example 2: `ApiTypeSchema.int8(0)`
    /// - Example 3: `ApiTypeSchema.int8(.max)`
    case int8(Int8? = nil)

    /// `Swift.UInt` primitive datatype, may have a default value.
    /// - Example 1: `ApiTypeSchema.uint()`
    /// - Example 2: `ApiTypeSchema.uint(0)`
    /// - Example 3: `ApiTypeSchema.uint(.max)`
    case uint(UInt? = nil)

    /// `Swift.UInt64` primitive datatype, may have a default value.
    /// - Example 1: `ApiTypeSchema.uint64()`
    /// - Example 2: `ApiTypeSchema.uint64(0)`
    /// - Example 3: `ApiTypeSchema.uint64(.max)`
    case uint64(UInt64? = nil)

    /// `Swift.UInt32` primitive datatype, may have a default value.
    /// - Example 1: `ApiTypeSchema.uint32()`
    /// - Example 2: `ApiTypeSchema.uint32(0)`
    /// - Example 3: `ApiTypeSchema.uint32(.max)`
    case uint32(UInt32? = nil)

    /// `Swift.UInt16` primitive datatype, may have a default value.
    /// - Example 1: `ApiTypeSchema.uint16()`
    /// - Example 2: `ApiTypeSchema.uint16(0)`
    /// - Example 3: `ApiTypeSchema.uint16(.max)`
    case uint16(UInt16? = nil)

    /// `Swift.UInt8` primitive datatype, may have a default value.
    /// - Example 1: `ApiTypeSchema.uint8()`
    /// - Example 2: `ApiTypeSchema.uint8(0)`
    /// - Example 3: `ApiTypeSchema.uint8(.max)`
    case uint8(UInt8? = nil)

    /// `Swift.Double` primitive datatype, may have a default value.
    /// - Example 1: `ApiTypeSchema.double()`
    /// - Example 2: `ApiTypeSchema.double(5.95)`
    /// - Example 3: `ApiTypeSchema.double(.pi)`
    case double(Double? = nil)

    /// `Swift.Date` primitive datatype, may have a default value.
    /// - Example 1: `ApiTypeSchema.date()`
    /// - Example 2: `ApiTypeSchema.date(.distantPast)`
    case date(Date? = nil)

    /// `TimelessDate` primitive datatype, may not have a default value.
    /// - Example 1: `ApiTypeSchema.timelessDate()`
    case timelessDate

    /// `Time` primitive datatype, may not have a default value.
    /// - Example 1: `ApiTypeSchema.time()`
    case time

    /// `Swift.URL` primitive datatype, may have a default value.
    /// - Example 1: `ApiTypeSchema.url()`
    /// - Example 2: `ApiTypeSchema.url(URL(string:"http://www.google.ca"))`
    case url(URL? = nil)

    /// `Swift.Bool` primitive datatype, has a default value of `false`
    /// - Example 1: `ApiTypeSchema.bool()`
    /// - Example 2: `ApiTypeSchema.bool(true)`
    case bool(Bool = false)

    /// `Swift.Data` binary datatype. Does not have a default value.
    /// Example: `ApiTypeSchema.binary`
    case binary

    /// A composite data-type representing a dictionary of object, keyed by a String.
    ///
    /// Example: `[String: String]` as defined as `ApiTypeSchema.keyedByString(.string())`
    ///
    /// > Any default specified (if applicable to the data-type) will be ignored.
    case keyedByString(ApiTypeSchema = .string(), isOptional: Bool = false)

    /// A `enum` with a base-type of `Swift.String`
    ///
    /// - parameters:
    ///   - typeName: The name of the type defined. `TestEnum` would create a enum type `enum TestEnum: String {}`
    ///   - values: An array of 2-value tuple for the enum values.
    ///   - initialValue: In the context of a `ApiModelProperty`, the initial value of the enum field is set. Must match a `name` in the array of values
    ///
    /// Example:
    ///
    ///
    /// ```swift
    /// ApiTypeSchema.stringEnum(
    ///     typeName: "Mode",
    ///     values: [(name: "foo", rawName: "bar")]
    /// )
    /// ```
    ///
    /// would generate the following:
    ///
    /// ```swift
    /// enum Mode: String, Codable {
    ///   case foo = "bar"
    /// }
    /// ```
    ///
    /// > The `initialValue` must match the `name` of one of the values.
    case stringEnum(typeName: String, values: [(name: String, rawName: String)], initialValue: String? = nil, uuid: UUID = .init(), supportGarbage: Bool = false)

    /// A `enum` with a base-type of `Swift.Int`
    ///
    /// - parameters:
    ///   - typeName: The name of the type defined. `TestEnum` would create a enum type `enum TestEnum: Int {}`
    ///   - values: An array of possible values
    ///   - initialValue: In the context of a `ApiModelProperty`, the initial value of the enum field is set. Must match a `name` in the array of values
    ///
    /// Example:
    ///
    /// ```swift
    /// ApiTypeSchema.intEnum(
    ///     typeName: "Mode",
    ///     values: [
    ///         (name: nil, rawValue: 0),
    ///         (name: nil, rawValue: 1),
    ///         (name: nil, rawValue: 100)
    ///     ]
    /// )
    /// ```
    ///
    /// would generate the following:
    ///
    /// ```swift
    /// enum Mode: Int, Codable {
    ///   case zero = 0
    ///   case one = 1
    ///   case oneHundred = 100
    /// }
    /// ```
    ///
    /// > The `initialValue` must match one of the values.
    case intEnum(typeName: String, values: [(name: String?, rawValue: Int)], initialValue: Int? = nil, uuid: UUID = .init())

    /// A simple array type.
    ///
    /// - parameter DataType: The element data type.
    ///
    /// Example:
    ///
    /// - `ApiTypeSchema.array(.int())` would result in `[Int]` to be declared
    case array(ApiTypeSchema = .string())

    /// A complex data-type, that can be used to express more complex concept within
    /// the api.
    ///
    /// - parameter typeName: The name of the type
    /// - parameter properties: The list of properties for the data-type
    /// - parameter protocols: The list of extra protocols
    /// - parameter isValueType: Boolean parameter that controls whether the generated code is a `class` or a `struct`. Defaults to `true` or `struct`
    ///
    /// Example:
    ///
    /// The following declaration:
    ///
    /// ```swift
    /// ApiTypeSchema.object(
    ///   typeName: "Image",
    ///   properties: [
    ///     .url("thumbnail", propertyName: "small"),
    ///     .url("medium"),
    ///     .url("large")
    ///   ],
    ///   protocols: ["SomeProtocol"]
    /// )
    /// ```
    ///
    /// Will generate the following code:
    ///
    /// ```swift
    /// public struct Image: Codable, Sendable, SomeProtocol {
    ///    public var small: URL
    ///    public var medium: URL
    ///    public var large: URL
    ///
    ///    public init(
    ///        small: URL,
    ///        medium: URL,
    ///        large: URL
    ///    ) {
    ///        self.small = small
    ///        self.medium = medium
    ///        self.large = large
    ///    }
    ///
    ///    public enum CodingKeys: String, CodingKey {
    ///        case small = "thumbnail"
    ///        case medium
    ///        case large
    ///    }
    /// }
    /// ```
    ///
    /// > The list of protocols is added, but you are responsible
    /// for ensuring that the protocol is accessible by the generated code in the
    /// target package.
    ///
    case object(
        typeName: String,
        properties: [ApiModelProperty],
        protocols: [String] = [],
        imports: [ApiImport] = [],
        isValueType: Bool = true,
        uuid: UUID = .init()
    )

    /// A data-type that is dynamic based on a property, like `content_type`, and its underlying
    /// data is `extras`.
    case dynamicObject(
        typeName: String,
        objectTypePropertyName: String = "content_type",
        objectDataPropertyName: String = "extras",
        alternateObjectDataPropertyName: String = "extra",
        objectTypes: [
            (objectTypeName: String, objectTypeRawName: String, objectType: ApiTypeSchema)
        ],
        supportGarbage: Bool = false,
        imports: [ApiImport] = [],
        uuid: UUID = .init(),
        extraProperties: [ApiModelProperty] = []
    )

    /// A reference to another data type that
    /// may or may not be generated by the code generator. See the `strict` parameter
    ///
    /// - parameter typeName: The typeName of the referred data-type
    /// - parameter strict: A flag that disable the validation, making it an external reference that you are responsible for ensuring that the referred data-type is accessible by the generated code in the target package
    ///
    /// Example:
    ///
    /// ```swift
    /// let someDataType: ApiTypeSchema = .object(typeName: "SomeData", properties: [])
    ///
    /// someDataType.asRef
    /// ```
    ///
    /// An external reference (where `strict` is false) is simple, you simply write it
    ///
    /// ```swift
    /// ApiTypeSchema.reference(typeName: "LDValue", strict: false)
    /// ```
    ///
    case reference(typeName: String, strict: Bool = true, imports: [ApiImport] = [], uuid: UUID = .init(), dataType: ApiTypeSchema? = nil)

    /// A generic reference is another type of reference, but referring to a Swift generic
    /// type. Since the code generator does not generate Swift Generics, this reference
    /// is implicitly an external reference, that you are responsible for ensuring that
    /// it is accessible to the generated code in the target package.
    ///
    /// Example:
    ///
    /// ```swift
    /// ApiTypeSchema.genericReference(typeName: "PagedResults", genericTypes: [.string()])
    /// ```
    case genericReference(typeName: String, genericTypes: [ApiTypeSchema])

}

// swiftlint:disable cyclomatic_complexity
extension ApiTypeSchema: Hashable, Equatable {
    public static func == (lhs: ApiTypeSchema, rhs: ApiTypeSchema) -> Bool {
        switch (lhs, rhs) {
            case (.uuid, .uuid),
                 (.timelessDate, .timelessDate),
                 (.time, .time),
                 (.binary, .binary):
                true
            case let (.string(lhs), .string(rhs)):
                lhs == rhs
            case let (.int(lhs), .int(rhs)):
                lhs == rhs
            case let (.int64(lhs), .int64(rhs)):
                lhs == rhs
            case let (.int32(lhs), .int32(rhs)):
                lhs == rhs
            case let (.int16(lhs), .int16(rhs)):
                lhs == rhs
            case let (.int8(lhs), .int8(rhs)):
                lhs == rhs
            case let (.uint(lhs), .uint(rhs)):
                lhs == rhs
            case let (.uint64(lhs), .uint64(rhs)):
                lhs == rhs
            case let (.uint32(lhs), .uint32(rhs)):
                lhs == rhs
            case let (.uint16(lhs), .uint16(rhs)):
                lhs == rhs
            case let (.uint8(lhs), .uint8(rhs)):
                lhs == rhs
            case let (.double(lhs), .double(rhs)):
                lhs == rhs
            case let (.date(lhs), .date(rhs)):
                lhs == rhs
            case let (.url(lhs), .url(rhs)):
                lhs == rhs
            case let (.bool(lhs), .bool(rhs)):
                lhs == rhs
            case let (.keyedByString(lhsType, lhsOptional), .keyedByString(rhsType, rhsOptional)):
                lhsType == rhsType && lhsOptional == rhsOptional
            case let (.stringEnum(lhsName, lhsValues, lhsInitial, lhsUUID, lhsGarbage), .stringEnum(rhsName, rhsValues, rhsInitial, rhsUUID, rhsGarbage)):
                lhsName == rhsName &&
                    lhsValues.elementsEqual(rhsValues) { lhs, rhs in lhs.name == rhs.name && lhs.rawName == rhs.rawName } &&
                    lhsInitial == rhsInitial &&
                    lhsUUID == rhsUUID &&
                    lhsGarbage == rhsGarbage
            case let (.intEnum(lhsName, lhsValues, lhsInitial, lhsUUID), .intEnum(rhsName, rhsValues, rhsInitial, rhsUUID)):
                lhsName == rhsName &&
                    lhsValues.elementsEqual(rhsValues) { lhs, rhs in lhs.name == rhs.name && lhs.rawValue == rhs.rawValue } &&
                    lhsInitial == rhsInitial &&
                    lhsUUID == rhsUUID
            case let (.array(lhs), .array(rhs)):
                lhs == rhs
            case let (.object(lhsName, lhsProperties, lhsProtocols, lhsImports, lhsValueType, lhsUUID), .object(rhsName, rhsProperties, rhsProtocols, rhsImports, rhsValueType, rhsUUID)):
                lhsName == rhsName &&
                    lhsProperties.elementsEqual(rhsProperties, by: Self.propertiesEqual) &&
                    lhsProtocols == rhsProtocols &&
                    lhsImports == rhsImports &&
                    lhsValueType == rhsValueType &&
                    lhsUUID == rhsUUID
            case let (
            .dynamicObject(lhsName, lhsTypeProperty, lhsDataProperty, lhsAlternateDataProperty, lhsTypes, lhsGarbage, lhsImports, lhsUUID, lhsExtra),
            .dynamicObject(rhsName, rhsTypeProperty, rhsDataProperty, rhsAlternateDataProperty, rhsTypes, rhsGarbage, rhsImports, rhsUUID, rhsExtra)
        ):
                lhsName == rhsName &&
                    lhsTypeProperty == rhsTypeProperty &&
                    lhsDataProperty == rhsDataProperty &&
                    lhsAlternateDataProperty == rhsAlternateDataProperty &&
                    lhsTypes.elementsEqual(rhsTypes) { lhs, rhs in
                        lhs.objectTypeName == rhs.objectTypeName &&
                            lhs.objectTypeRawName == rhs.objectTypeRawName &&
                            lhs.objectType == rhs.objectType
                    } &&
                    lhsGarbage == rhsGarbage &&
                    lhsImports == rhsImports &&
                    lhsUUID == rhsUUID &&
                    lhsExtra.elementsEqual(rhsExtra, by: Self.propertiesEqual)
            case let (.reference(lhsName, lhsStrict, lhsImports, lhsUUID, lhsDataType), .reference(rhsName, rhsStrict, rhsImports, rhsUUID, rhsDataType)):
                lhsName == rhsName && lhsStrict == rhsStrict && lhsImports == rhsImports && lhsUUID == rhsUUID && lhsDataType == rhsDataType
            case let (.genericReference(lhsName, lhsTypes), .genericReference(rhsName, rhsTypes)):
                lhsName == rhsName && lhsTypes == rhsTypes
            default:
                false
        }
    }

    public func hash(into hasher: inout Hasher) {
        switch self {
            case .uuid:
                hasher.combine(0)
            case let .string(value):
                hasher.combine(1)
                hasher.combine(value)
            case let .int(value):
                hasher.combine(2)
                hasher.combine(value)
            case let .int64(value):
                hasher.combine(3)
                hasher.combine(value)
            case let .int32(value):
                hasher.combine(4)
                hasher.combine(value)
            case let .int16(value):
                hasher.combine(5)
                hasher.combine(value)
            case let .int8(value):
                hasher.combine(6)
                hasher.combine(value)
            case let .uint(value):
                hasher.combine(7)
                hasher.combine(value)
            case let .uint64(value):
                hasher.combine(8)
                hasher.combine(value)
            case let .uint32(value):
                hasher.combine(9)
                hasher.combine(value)
            case let .uint16(value):
                hasher.combine(10)
                hasher.combine(value)
            case let .uint8(value):
                hasher.combine(11)
                hasher.combine(value)
            case let .double(value):
                hasher.combine(12)
                hasher.combine(value)
            case let .date(value):
                hasher.combine(13)
                hasher.combine(value)
            case .timelessDate:
                hasher.combine(14)
            case .time:
                hasher.combine(15)
            case let .url(value):
                hasher.combine(16)
                hasher.combine(value)
            case let .bool(value):
                hasher.combine(17)
                hasher.combine(value)
            case .binary:
                hasher.combine(18)
            case let .keyedByString(type, isOptional):
                hasher.combine(19)
                hasher.combine(type)
                hasher.combine(isOptional)
            case let .stringEnum(typeName, values, initialValue, uuid, supportGarbage):
                hasher.combine(20)
                hasher.combine(typeName)
                for value in values {
                    hasher.combine(value.name)
                    hasher.combine(value.rawName)
                }
                hasher.combine(initialValue)
                hasher.combine(uuid)
                hasher.combine(supportGarbage)
            case let .intEnum(typeName, values, initialValue, uuid):
                hasher.combine(21)
                hasher.combine(typeName)
                for value in values {
                    hasher.combine(value.name)
                    hasher.combine(value.rawValue)
                }
                hasher.combine(initialValue)
                hasher.combine(uuid)
            case let .array(type):
                hasher.combine(22)
                hasher.combine(type)
            case let .object(typeName, properties, protocols, imports, isValueType, uuid):
                hasher.combine(23)
                hasher.combine(typeName)
                properties.forEach { Self.hash($0, into: &hasher) }
                hasher.combine(protocols)
                hasher.combine(imports)
                hasher.combine(isValueType)
                hasher.combine(uuid)
            case let .dynamicObject(
            typeName,
            objectTypePropertyName,
            objectDataPropertyName,
            alternateObjectDataPropertyName,
            objectTypes,
            supportGarbage,
            imports,
            uuid,
            extraProperties
        ):
                hasher.combine(24)
                hasher.combine(typeName)
                hasher.combine(objectTypePropertyName)
                hasher.combine(objectDataPropertyName)
                hasher.combine(alternateObjectDataPropertyName)
                for item in objectTypes {
                    hasher.combine(item.objectTypeName)
                    hasher.combine(item.objectTypeRawName)
                    hasher.combine(item.objectType)
                }
                hasher.combine(supportGarbage)
                hasher.combine(imports)
                hasher.combine(uuid)
                extraProperties.forEach { Self.hash($0, into: &hasher) }
            case let .reference(typeName, strict, imports, uuid, dataType):
                hasher.combine(25)
                hasher.combine(typeName)
                hasher.combine(strict)
                hasher.combine(imports)
                hasher.combine(uuid)
                hasher.combine(dataType)
            case let .genericReference(typeName, genericTypes):
                hasher.combine(26)
                hasher.combine(typeName)
                hasher.combine(genericTypes)
        }
    }

    private static func propertiesEqual(_ lhs: ApiModelProperty, _ rhs: ApiModelProperty) -> Bool {
        lhs.rawName == rhs.rawName &&
            lhs.propertyName == rhs.propertyName &&
            lhs.dataType == rhs.dataType &&
            lhs.required == rhs.required &&
            lhs.equatable == rhs.equatable &&
            lhs.hashable == rhs.hashable &&
            lhs.publishedAsField == rhs.publishedAsField
    }

    private static func hash(_ property: ApiModelProperty, into hasher: inout Hasher) {
        hasher.combine(property.rawName)
        hasher.combine(property.propertyName)
        hasher.combine(property.dataType)
        hasher.combine(property.required)
        hasher.combine(property.equatable)
        hasher.combine(property.hashable)
        hasher.combine(property.publishedAsField)
    }
}

// swiftlint:enable cyclomatic_complexity

// MARK: Validation
public extension ApiTypeSchema {

    var uuid: UUID? {
        switch self {
            case let .object(_, _, _, _, _, uuid):
                uuid
            case let .stringEnum(_, _, _, uuid, _):
                uuid
            case let .dynamicObject(_, _, _, _, _, _, _, uuid, _):
                uuid
            case let .intEnum(_, _, _, uuid):
                uuid
            default:
                nil
        }
    }

    var imports: [ApiImport] {
        switch self {
            case let .object(_, _, _, imports, _, _):
                imports
            case let .dynamicObject(_, _, _, _, _, _, imports, _, _):
                imports
            case let .reference(_, _, imports, _, _):
                imports
            default:
                []
        }
    }

    var referenceUUID: UUID? {
        switch self {
            case let .reference(_, _, _, uuid, _):
                uuid
            default:
                nil
        }
    }

    /// Returns a list of references data-types by the current type-definition.
    var referenceDataTypes: [ApiTypeSchema] {
        var seenReferenceUUIDs: Set<UUID> = []
        return referenceDataTypes(
            seenReferenceUUIDs: &seenReferenceUUIDs,
            includeDynamicObjectPayloadReferences: true
        )
    }

    private func referenceDataTypes(
        seenReferenceUUIDs: inout Set<UUID>,
        includeDynamicObjectPayloadReferences: Bool
    ) -> [ApiTypeSchema] {
        switch self {
            case let .reference(_, strict, _, uuid, dataType):
                guard strict else {
                    return []
                }
                guard seenReferenceUUIDs.insert(uuid).inserted else {
                    return []
                }
                return [self] + (dataType?.referenceDataTypes(
                    seenReferenceUUIDs: &seenReferenceUUIDs,
                    includeDynamicObjectPayloadReferences: includeDynamicObjectPayloadReferences
                ) ?? [])
            case let .object(_, properties, _, _, _, _):
                return properties.map(\.dataType).flatMap {
                    $0.referenceDataTypes(
                        seenReferenceUUIDs: &seenReferenceUUIDs,
                        includeDynamicObjectPayloadReferences: includeDynamicObjectPayloadReferences
                    )
                }
            case let .keyedByString(type, _),
                 let .array(type):
                return type.referenceDataTypes(
                    seenReferenceUUIDs: &seenReferenceUUIDs,
                    includeDynamicObjectPayloadReferences: includeDynamicObjectPayloadReferences
                )
            case let .genericReference(_, types):
                return types.flatMap {
                    $0.referenceDataTypes(
                        seenReferenceUUIDs: &seenReferenceUUIDs,
                        includeDynamicObjectPayloadReferences: includeDynamicObjectPayloadReferences
                    )
                }
            case let .dynamicObject(_, _, _, _, types, _, _, _, extraProperties):
                let payloadReferences = includeDynamicObjectPayloadReferences
                    ? types
                    .map(\.objectType)
                    .flatMap {
                        $0.referenceDataTypes(
                            seenReferenceUUIDs: &seenReferenceUUIDs,
                            includeDynamicObjectPayloadReferences: includeDynamicObjectPayloadReferences
                        )
                    }
                    : []
                return payloadReferences +
                    extraProperties
                    .map(\.dataType)
                    .flatMap {
                        $0.referenceDataTypes(
                            seenReferenceUUIDs: &seenReferenceUUIDs,
                            includeDynamicObjectPayloadReferences: includeDynamicObjectPayloadReferences
                        )
                    }
            default:
                return []
        }
    }

    /// Return the fully qualified name `Swift` type name for the data-type
    var fullyQualifiedName: String? {
        ApiTypeNameResolver.shared.name(for: self) ?? typeName
    }

    /// Return the `Swift` type name for the data-type
    var typeName: String? {
        switch self {
            case let .object(typeName, _, _, _, _, _),
                 let .stringEnum(typeName, _, _, _, _),
                 let .intEnum(typeName, _, _, _),
                 let .reference(typeName, _, _, _, _):
                return typeName
            case .keyedByString:
                return nil
            case let .genericReference(typeName, types):
                let type = types.map { $0.fullyQualifiedName ?? "Any" }.joined(separator: ", ")
                return "\(typeName)<\(type)>"
            case let .dynamicObject(typeName, _, _, _, _, _, _, _, _):
                return typeName
            case .string:
                return "String"
            case .bool:
                return "Bool"
            case .uuid:
                return "UUID"
            case .int:
                return "Int"
            case .int64:
                return "Int64"
            case .int32:
                return "Int32"
            case .int16:
                return "Int16"
            case .int8:
                return "Int8"
            case .uint:
                return "UInt"
            case .uint64:
                return "UInt64"
            case .uint32:
                return "UInt32"
            case .uint16:
                return "UInt16"
            case .uint8:
                return "UInt8"
            case .double:
                return "Double"
            case .date:
                return "Date"
            case .timelessDate:
                return "TimelessDate"
            case .time:
                return "Time"
            case .url:
                return "URL"
            case .binary:
                return "Data"
            case let .array(dataType):
                return "[\(dataType.typeName ?? "Any")]"
        }
    }

    /// True if the current data-type can be referenced in code by
    /// name.
    var isReferenceable: Bool {
        switch self {
            case .object,
                 .stringEnum,
                 .intEnum,
                 .dynamicObject:
                true

            default:
                false
        }
    }

    /// True if the current data-type is an URL
    var isURL: Bool {
        switch self {
            case .url:
                true
            default:
                false
        }
    }

    /// True if the current data-type can be referenced in code by
    /// name.
    var isIdentifiable: Bool {
        switch self {
            case let .object(_, _, protocols, _, _, _):
                protocols.contains("Identifiable")
            case let .reference(_, _, _, _, dataType):
                dataType?.isIdentifiable ?? false
            case let .genericReference(_, genericTypes):
                genericTypes.allSatisfy(\.isIdentifiable)
            case let .array(type):
                type.isIdentifiable
            case .stringEnum,
                 .intEnum:
                true
            case let .keyedByString(type, _):
                type.isIdentifiable
            default:
                false
        }
    }

    /// True if the current type is a reference
    var isReference: Bool {
        switch self {
            case .reference:
                true
            default:
                false
        }
    }

    /// True if the current type support `Swift.Optional`
    var supportsOptionals: Bool {
        switch self {
            case .bool:
                false
            default:
                true
        }
    }

}

// MARK: Sugar Syntax
public extension ApiTypeSchema {

    /// A sugar-syntax way to _extend_ an existing `ApiTypeSchema` with more properties. Prepending new properties before the existing type properties.
    ///
    /// - parameter properties: The new properties
    /// - returns: A new type instance with the prepended properties
    ///
    /// Please beware, the name of the data-type is not changed, you need to change it using the `renaming(to:)` method for that.
    ///
    /// Example:
    ///
    /// ```swift
    /// let preexistingType: ApiTypeSchema = ...
    ///
    /// let newType = preexistingType
    ///   .prepending(properties: [
    ///      .int64("id")
    ///   ])
    ///   .renaming(to: "NewName")
    /// ```
    func prepending(properties newProperties: [ApiModelProperty], newImports: [ApiImport] = []) throws -> ApiTypeSchema {
        switch self {
            case let .object(typeName, properties, protocols, imports, isValueType, _):
                .object(
                    typeName: typeName,
                    properties: newProperties + properties,
                    protocols: protocols,
                    imports: imports + newImports,
                    isValueType: isValueType
                )
            case let .keyedByString(type, isOptional):
                .keyedByString(try type.prepending(properties: newProperties), isOptional: isOptional)
            case let .array(type):
                .array(try type.prepending(properties: newProperties))
            default:
                throw ApiValidationError.failed("Impossible to add properties to a non-object data type")
        }
    }

    /// A sugar-syntax way to _extend_ an existing `ApiTypeSchema` with more properties. appending new properties after the existing type properties.
    ///
    /// - parameter properties: The new properties
    /// - returns: A new type instance with the appended properties
    ///
    /// Please beware, the name of the data-type is not changed, you need to change it using the `renaming(to:)` method for that.
    ///
    /// Example:
    ///
    /// ```swift
    /// let preexistingType: ApiTypeSchema = ...
    ///
    /// let newType = preexistingType
    ///   .appending(properties: [
    ///      .int64("id")
    ///   ])
    ///   .renaming(to: "NewName")
    /// ```
    func appending(properties newProperties: [ApiModelProperty], newImports: [ApiImport] = []) throws -> ApiTypeSchema {
        switch self {
            case let .object(typeName, properties, protocols, imports, isValueType, _):
                .object(
                    typeName: typeName,
                    properties: properties + newProperties,
                    protocols: protocols,
                    imports: imports + newImports,
                    isValueType: isValueType
                )
            case let .keyedByString(type, isOptional):
                .keyedByString(try type.appending(properties: newProperties), isOptional: isOptional)
            case let .array(type):
                .array(try type.appending(properties: newProperties))
            default:
                throw ApiValidationError.failed("Impossible to add properties to a non-object data type")
        }
    }

    /// A sugar-syntax way to _combine_ 2 existing `ApiTypeSchema` values, merging their properties and protocols.
    ///
    /// - parameter other: The 2nd data-type
    /// - returns: A new type instance with the merged properties and protocols.
    ///
    /// Please beware, the name of the data-type is not changed, you need to change it using the `renaming(to:)` method for that.
    ///
    /// Example:
    ///
    /// ```swift
    /// let preexistingType1: ApiTypeSchema = ...
    /// let preexistingType2: ApiTypeSchema = ...
    ///
    /// let newType = preexistingType1
    ///   .combining(with: preexistingType2)
    ///   .renaming(to: "NewName")
    /// ```
    func combining(with other: ApiTypeSchema) throws -> ApiTypeSchema {
        if case let .object(typeName, properties, protocols, imports, isValueType, _) = self,
           case let .object(_, otherProperties, otherProtocols, otherImports, otherIsValueType, _) = other {

            let newProtocols: [String] = protocols + otherProtocols
            return .object(
                typeName: typeName,
                properties: properties + otherProperties,
                protocols: newProtocols.withoutDuplicates(),
                imports: imports + otherImports,
                isValueType: isValueType && otherIsValueType,
                uuid: .init()
            )
        }

        throw ApiValidationError.failed("Impossible to combine 2 non-object data type")
    }

    /// A sugar-syntax way to remove properties from an existing object `ApiTypeSchema`.
    ///
    /// - parameter properties: The raw or Swift property names to remove.
    /// - returns: A new type instance with matching properties removed.
    ///
    /// Please beware, the name of the data-type is not changed, you need to change it using the `renaming(to:)` method for that.
    ///
    /// Example:
    ///
    /// ```swift
    /// let preexistingType: ApiTypeSchema = ...
    ///
    /// let newType = preexistingType
    ///   .removing(properties: [
    ///      "id"
    ///   ])
    ///   .renaming(to: "NewName")
    /// ```
    func removing(properties names: [String]) throws -> ApiTypeSchema {
        switch self {
            case let .object(typeName, properties, protocols, imports, isValueType, _):
                var properties = properties
                properties.removeAll(where: { names.contains($0.rawName) || names.contains($0.propertyName) })
                return .object(
                    typeName: typeName,
                    properties: properties,
                    protocols: protocols,
                    imports: imports,
                    isValueType: isValueType
                )
            default:
                throw ApiValidationError.failed("Impossible to remove properties to a non-object data type")
        }
    }

    /// Modifying a properties closure
    func modifyingProperties(modifier: (ApiModelProperty) -> ApiModelProperty) throws -> ApiTypeSchema {
        switch self {
            case let .object(typeName, properties, protocols, imports, isValueType, _):
                .object(
                    typeName: typeName,
                    properties: properties.map(modifier),
                    protocols: protocols,
                    imports: imports,
                    isValueType: isValueType
                )
            case let .keyedByString(type, isOptional):
                .keyedByString(try type.modifyingProperties(modifier: modifier), isOptional: isOptional)
            case let .array(type):
                .array(try type.modifyingProperties(modifier: modifier))
            default:
                throw ApiValidationError.failed("Impossible to add properties to a non-object data type")
        }
    }

    /// A sugar-syntax way to _extend_ an existing `ApiTypeSchema` with new protocols.
    ///
    /// - parameter protocols: The new protocols
    /// - returns: A new type instance with the new protocols appended.
    ///
    /// Please beware, the name of the data-type is not changed, you need to change it using the `renaming(to:)` method for that.
    ///
    /// Example:
    ///
    /// ```swift
    /// let preexistingType: ApiTypeSchema = ...
    ///
    /// let newType = preexistingType
    ///   .implementing(protocols: [
    ///      "SoftDeletable"
    ///   ])
    ///   .renaming(to: "NewName")
    /// ```
    func implementing(protocols newProtocols: [String]) throws -> ApiTypeSchema {
        switch self {
            case let .object(typeName, properties, protocols, imports, isValueType, _):
                .object(typeName: typeName, properties: properties, protocols: protocols + newProtocols, imports: imports, isValueType: isValueType)
            case let .keyedByString(type, isOptional):
                .keyedByString(try type.implementing(protocols: newProtocols), isOptional: isOptional)
            case let .array(type):
                .array(try type.implementing(protocols: newProtocols))
            default:
                throw ApiValidationError.failed("Impossible to add properties to a non-object data type")
        }
    }

    /// A sugar-syntax way to rename an existing `ApiTypeSchema` with a new name, mostly
    /// useful when extending an existing `ApiTypeSchema` with new properties and/or protocols.
    ///
    /// - parameter to: The new name
    /// - returns: A new type instance with the new name.
    ///
    /// Example:
    ///
    /// ```swift
    /// let preexistingType: ApiTypeSchema = ...
    ///
    /// let newType = preexistingType
    ///   .renaming(to: "NewName")
    /// ```
    func renaming(to newName: String) throws -> ApiTypeSchema {
        switch self {
            case let .object(_, properties, protocols, imports, isValueType, _):
                .object(typeName: newName, properties: properties, protocols: protocols, imports: imports, isValueType: isValueType)
            case let .stringEnum(_, values, initialValue, _, supportGarbage):
                .stringEnum(typeName: newName, values: values, initialValue: initialValue, supportGarbage: supportGarbage)
            case let .intEnum(_, values, initialValue, _):
                .intEnum(typeName: newName, values: values, initialValue: initialValue)
            case let .genericReference(_, types):
                .genericReference(typeName: newName, genericTypes: types)
            case let .dynamicObject(
            _,
            objectTypePropertyName,
            objectDataPropertyName,
            alternateObjectDataPropertyName,
            objectTypes,
            supportGarbage,
            imports,
            _,
            extraProperties
        ):
                .dynamicObject(
                    typeName: newName,
                    objectTypePropertyName: objectTypePropertyName,
                    objectDataPropertyName: objectDataPropertyName,
                    alternateObjectDataPropertyName: alternateObjectDataPropertyName,
                    objectTypes: objectTypes,
                    supportGarbage: supportGarbage,
                    imports: imports,
                    extraProperties: extraProperties
                )
            default:
                throw ApiValidationError.failed("Impossible to add properties to a data-type that cannot have a typeName")
        }
    }

    var isEquatable: Bool {
        switch self {
            case let .object(_, properties, protocols, _, _, _):
                protocols.contains("Equatable") || properties.contains(where: \.equatable)

            default:
                false
        }
    }

    var asPatchable: ApiTypeSchema {
        .genericReference(typeName: "PatchableValue", genericTypes: [self])
    }

    /// Return the current data-type as a reference for all intent & purpose of code
    /// generating, ensuring that the data-type is generated correctly once, and not
    /// all over the place.
    var asRef: ApiTypeSchema {
        switch self {
            case .uuid: self
            case .string: self
            case .int: self
            case .int64: self
            case .int32: self
            case .int16: self
            case .int8: self
            case .uint: self
            case .uint64: self
            case .uint32: self
            case .uint16: self
            case .uint8: self
            case .double: self
            case .date: self
            case .timelessDate: self
            case .time: self
            case .url: self
            case .bool: self
            case .binary: self
            case let .keyedByString(type, isOptional):
                .keyedByString(type.asRef, isOptional: isOptional)
            case let .stringEnum(typeName, _, _, uuid, _):
                .reference(typeName: typeName, uuid: uuid, dataType: self)
            case let .intEnum(typeName, _, _, uuid):
                .reference(typeName: typeName, uuid: uuid, dataType: self)
            case let .array(type):
                .array(type.asRef)
            case let .object(typeName, _, _, _, _, uuid):
                .reference(typeName: typeName, uuid: uuid, dataType: self)
            case let .dynamicObject(typeName, _, _, _, _, _, _, uuid, _):
                .reference(typeName: typeName, uuid: uuid, dataType: self)
            case .reference:
                self
            case .genericReference:
                self
        }
    }

    /// Return an `array` of the current data-type.
    var asArray: ApiTypeSchema {
        .array(self)
    }

    /// Return a keyed by `String` dictionary of the current data-type.
    var asKeyedByString: ApiTypeSchema {
        .keyedByString(self)
    }
}
