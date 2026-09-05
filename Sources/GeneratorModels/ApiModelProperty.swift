import Foundation
import GeneratorBuilder

/// A property for a ``ApiTypeSchema/object(typeName:properties:protocols:isValueType:uuid:)``
public struct ApiModelProperty: Sendable {

    /// The raw name, for the coding key
    public var rawName: String

    /// The property name, camelized for the code
    public var propertyName: String

    /// The data type
    public var dataType: ApiTypeSchema

    /// Is the property required
    public var required: Bool = true

    /// Is the property part of the equatable protocol
    public var equatable: Bool = false

    /// Is the property part of the hashable protocol
    public var hashable: Bool = false

    /// Published as Field
    public var publishedAsField: Bool = true

    public init(
        rawName: String,
        propertyName: String,
        dataType: ApiTypeSchema,
        required: Bool = true,
        equatable: Bool = false,
        hashable: Bool = false,
        publishedAsField: Bool = true
    ) {
        self.rawName = rawName
        self.propertyName = propertyName
        self.dataType = dataType
        self.required = required
        self.equatable = equatable
        self.hashable = hashable
        self.publishedAsField = publishedAsField
    }
}

// MARK: - Comparable
extension ApiModelProperty: Comparable {

    public static func < (lhs: ApiModelProperty, rhs: ApiModelProperty) -> Bool {
        lhs.rawName < rhs.rawName
    }

    public static func == (lhs: ApiModelProperty, rhs: ApiModelProperty) -> Bool {
        lhs.rawName == rhs.rawName
    }
}

// MARK: - Utilities for Fields
public extension ApiModelProperty {

    /// Return an unpublished version of this property.
    var unpublished: ApiModelProperty {
        .init(
            rawName: rawName,
            propertyName: propertyName,
            dataType: dataType,
            required: required,
            equatable: equatable,
            hashable: hashable,
            publishedAsField: false
        )
    }

}

// MARK: - Utilities for optionals
public extension ApiModelProperty {

    /// Return an optional version of this property
    var optional: ApiModelProperty {
        .init(
            rawName: rawName,
            propertyName: propertyName,
            dataType: dataType,
            required: false,
            equatable: equatable,
            hashable: hashable,
            publishedAsField: publishedAsField
        )
    }

    /// Return a mandatory version of this property
    var mandatory: ApiModelProperty {
        .init(
            rawName: rawName,
            propertyName: propertyName,
            dataType: dataType,
            required: true,
            equatable: equatable,
            hashable: hashable,
            publishedAsField: publishedAsField
        )
    }
}

// MARK: - Sugar Syntax
public extension ApiModelProperty {

    private static func make(
        _ named: String,
        propertyName: String?,
        dataType: ApiTypeSchema,
        required: Bool = true,
        equatable: Bool = false,
        hashable: Bool = false
    ) -> ApiModelProperty {
        .init(
            rawName: named,
            propertyName: (propertyName ?? named).swiftPropertyName,
            dataType: dataType,
            required: required,
            equatable: equatable,
            hashable: hashable
        )
    }

    /// Create a `Foundation.UUID` property
    /// - parameter named: The `raw` name of the property
    /// - parameter propertyName: A swift-friendly name for property
    /// - parameter required: Boolean that dictates if this property is required or optional
    /// - parameter equatable: Boolean that dictates if this property is part of the `Equatable` protocol
    /// - parameter hashable: Boolean that dictates if this property is part of the `Hashable` protocol
    static func uuid(_ named: String, propertyName: String? = nil, required: Bool = true, equatable: Bool = false, hashable: Bool = false) -> ApiModelProperty {
        make(named, propertyName: propertyName, dataType: .uuid, required: required, equatable: equatable, hashable: hashable)
    }

    /// Create a `Swift.String` property
    /// - parameter named: The `raw` name of the property
    /// - parameter propertyName: A swift-friendly name for property
    /// - parameter initialValue: The initial value of the property
    /// - parameter required: Boolean that dictates if this property is required or optional
    /// - parameter equatable: Boolean that dictates if this property is part of the `Equatable` protocol
    /// - parameter hashable: Boolean that dictates if this property is part of the `Hashable` protocol
    static func string(_ named: String, propertyName: String? = nil, initialValue: String? = nil, required: Bool = true, equatable: Bool = false, hashable: Bool = false) -> ApiModelProperty {
        make(named, propertyName: propertyName, dataType: .string(initialValue), required: required, equatable: equatable, hashable: hashable)
    }

    /// Create a `URL` property
    /// - parameter named: The `raw` name of the property
    /// - parameter propertyName: A swift-friendly name for property
    /// - parameter initialValue: The initial value of the property
    /// - parameter required: Boolean that dictates if this property is required or optional
    /// - parameter equatable: Boolean that dictates if this property is part of the `Equatable` protocol
    /// - parameter hashable: Boolean that dictates if this property is part of the `Hashable` protocol
    static func url(_ named: String, propertyName: String? = nil, initialValue: URL? = nil, required: Bool = true, equatable: Bool = false, hashable: Bool = false) -> ApiModelProperty {
        make(named, propertyName: propertyName, dataType: .url(initialValue), required: required, equatable: equatable, hashable: hashable)
    }

    /// Create a `Swift.Int` property
    /// - parameter named: The `raw` name of the property
    /// - parameter propertyName: A swift-friendly name for property
    /// - parameter initialValue: The initial value of the property
    /// - parameter required: Boolean that dictates if this property is required or optional
    /// - parameter equatable: Boolean that dictates if this property is part of the `Equatable` protocol
    /// - parameter hashable: Boolean that dictates if this property is part of the `Hashable` protocol
    static func int(_ named: String, propertyName: String? = nil, initialValue: Int? = nil, required: Bool = true, equatable: Bool = false, hashable: Bool = false) -> ApiModelProperty {
        make(named, propertyName: propertyName, dataType: .int(initialValue), required: required, equatable: equatable, hashable: hashable)
    }

    /// Create a `Swift.Int32` property
    /// - parameter named: The `raw` name of the property
    /// - parameter propertyName: A swift-friendly name for property
    /// - parameter initialValue: The initial value of the property
    /// - parameter required: Boolean that dictates if this property is required or optional
    /// - parameter equatable: Boolean that dictates if this property is part of the `Equatable` protocol
    /// - parameter hashable: Boolean that dictates if this property is part of the `Hashable` protocol
    static func int32(_ named: String, propertyName: String? = nil, initialValue: Int32? = nil, required: Bool = true, equatable: Bool = false, hashable: Bool = false) -> ApiModelProperty {
        make(named, propertyName: propertyName, dataType: .int32(initialValue), required: required, equatable: equatable, hashable: hashable)
    }

    /// Create a `Swift.Int64` property
    /// - parameter named: The `raw` name of the property
    /// - parameter propertyName: A swift-friendly name for property
    /// - parameter initialValue: The initial value of the property
    /// - parameter required: Boolean that dictates if this property is required or optional
    /// - parameter equatable: Boolean that dictates if this property is part of the `Equatable` protocol
    /// - parameter hashable: Boolean that dictates if this property is part of the `Hashable` protocol
    static func int64(_ named: String, propertyName: String? = nil, initialValue: Int64? = nil, required: Bool = true, equatable: Bool = false, hashable: Bool = false) -> ApiModelProperty {
        make(named, propertyName: propertyName, dataType: .int64(initialValue), required: required, equatable: equatable, hashable: hashable)
    }

    /// Create a `Swift.Int16` property
    /// - parameter named: The `raw` name of the property
    /// - parameter propertyName: A swift-friendly name for property
    /// - parameter initialValue: The initial value of the property
    /// - parameter required: Boolean that dictates if this property is required or optional
    /// - parameter equatable: Boolean that dictates if this property is part of the `Equatable` protocol
    /// - parameter hashable: Boolean that dictates if this property is part of the `Hashable` protocol
    static func int16(_ named: String, propertyName: String? = nil, initialValue: Int16? = nil, required: Bool = true, equatable: Bool = false, hashable: Bool = false) -> ApiModelProperty {
        make(named, propertyName: propertyName, dataType: .int16(initialValue), required: required, equatable: equatable, hashable: hashable)
    }

    /// Create a `Swift.Int8` property
    /// - parameter named: The `raw` name of the property
    /// - parameter propertyName: A swift-friendly name for property
    /// - parameter initialValue: The initial value of the property
    /// - parameter required: Boolean that dictates if this property is required or optional
    /// - parameter equatable: Boolean that dictates if this property is part of the `Equatable` protocol
    /// - parameter hashable: Boolean that dictates if this property is part of the `Hashable` protocol
    static func int8(_ named: String, propertyName: String? = nil, initialValue: Int8? = nil, required: Bool = true, equatable: Bool = false, hashable: Bool = false) -> ApiModelProperty {
        make(named, propertyName: propertyName, dataType: .int8(initialValue), required: required, equatable: equatable, hashable: hashable)
    }

    /// Create a `Swift.UInt` property
    /// - parameter named: The `raw` name of the property
    /// - parameter propertyName: A swift-friendly name for property
    /// - parameter initialValue: The initial value of the property
    /// - parameter required: Boolean that dictates if this property is required or optional
    /// - parameter equatable: Boolean that dictates if this property is part of the `Equatable` protocol
    /// - parameter hashable: Boolean that dictates if this property is part of the `Hashable` protocol
    static func uint(_ named: String, propertyName: String? = nil, initialValue: UInt? = nil, required: Bool = true, equatable: Bool = false, hashable: Bool = false) -> ApiModelProperty {
        make(named, propertyName: propertyName, dataType: .uint(initialValue), required: required, equatable: equatable, hashable: hashable)
    }

    /// Create a `Swift.UInt32` property
    /// - parameter named: The `raw` name of the property
    /// - parameter propertyName: A swift-friendly name for property
    /// - parameter initialValue: The initial value of the property
    /// - parameter required: Boolean that dictates if this property is required or optional
    /// - parameter equatable: Boolean that dictates if this property is part of the `Equatable` protocol
    /// - parameter hashable: Boolean that dictates if this property is part of the `Hashable` protocol
    static func uint32(_ named: String, propertyName: String? = nil, initialValue: UInt32? = nil, required: Bool = true, equatable: Bool = false, hashable: Bool = false) -> ApiModelProperty {
        make(named, propertyName: propertyName, dataType: .uint32(initialValue), required: required, equatable: equatable, hashable: hashable)
    }

    /// Create a `Swift.UInt64` property
    /// - parameter named: The `raw` name of the property
    /// - parameter propertyName: A swift-friendly name for property
    /// - parameter initialValue: The initial value of the property
    /// - parameter required: Boolean that dictates if this property is required or optional
    /// - parameter equatable: Boolean that dictates if this property is part of the `Equatable` protocol
    /// - parameter hashable: Boolean that dictates if this property is part of the `Hashable` protocol
    static func uint64(_ named: String, propertyName: String? = nil, initialValue: UInt64? = nil, required: Bool = true, equatable: Bool = false, hashable: Bool = false) -> ApiModelProperty {
        make(named, propertyName: propertyName, dataType: .uint64(initialValue), required: required, equatable: equatable, hashable: hashable)
    }

    /// Create a `Swift.UInt16` property
    /// - parameter named: The `raw` name of the property
    /// - parameter propertyName: A swift-friendly name for property
    /// - parameter initialValue: The initial value of the property
    /// - parameter required: Boolean that dictates if this property is required or optional
    /// - parameter equatable: Boolean that dictates if this property is part of the `Equatable` protocol
    /// - parameter hashable: Boolean that dictates if this property is part of the `Hashable` protocol
    static func uint16(_ named: String, propertyName: String? = nil, initialValue: UInt16? = nil, required: Bool = true, equatable: Bool = false, hashable: Bool = false) -> ApiModelProperty {
        make(named, propertyName: propertyName, dataType: .uint16(initialValue), required: required, equatable: equatable, hashable: hashable)
    }

    /// Create a `Swift.UInt8` property
    /// - parameter named: The `raw` name of the property
    /// - parameter propertyName: A swift-friendly name for property
    /// - parameter initialValue: The initial value of the property
    /// - parameter required: Boolean that dictates if this property is required or optional
    /// - parameter equatable: Boolean that dictates if this property is part of the `Equatable` protocol
    /// - parameter hashable: Boolean that dictates if this property is part of the `Hashable` protocol
    static func uint8(_ named: String, propertyName: String? = nil, initialValue: UInt8? = nil, required: Bool = true, equatable: Bool = false, hashable: Bool = false) -> ApiModelProperty {
        make(named, propertyName: propertyName, dataType: .uint8(initialValue), required: required, equatable: equatable, hashable: hashable)
    }

    /// Create a ``ApiTypeSchema`` property
    /// - parameter named: The `raw` name of the property
    /// - parameter propertyName: A swift-friendly name for property
    /// - parameter dataType: The ``ApiTypeSchema``
    /// - parameter required: Boolean that dictates if this property is required or optional
    /// - parameter equatable: Boolean that dictates if this property is part of the `Equatable` protocol
    /// - parameter hashable: Boolean that dictates if this property is part of the `Hashable` protocol
    static func object(_ named: String, propertyName: String? = nil, of dataType: ApiTypeSchema, required: Bool = true, equatable: Bool = false, hashable: Bool = false) -> ApiModelProperty {
        make(named, propertyName: propertyName, dataType: dataType, required: required, equatable: equatable, hashable: hashable)
    }

    /// Create a ``ApiTypeSchema`` reference
    /// - parameter named: The `raw` name of the property
    /// - parameter propertyName: A swift-friendly name for property
    /// - parameter dataType: The ``ApiTypeSchema``
    /// - parameter required: Boolean that dictates if this property is required or optional
    /// - parameter equatable: Boolean that dictates if this property is part of the `Equatable` protocol
    /// - parameter hashable: Boolean that dictates if this property is part of the `Hashable` protocol
    static func ref(_ named: String, propertyName: String? = nil, of dataType: ApiTypeSchema, required: Bool = true, equatable: Bool = false, hashable: Bool = false) -> ApiModelProperty {
        make(named, propertyName: propertyName, dataType: dataType.asRef, required: required, equatable: equatable, hashable: hashable)
    }

    /// Create a `Swift.Bool` property
    /// - parameter named: The `raw` name of the property
    /// - parameter propertyName: A swift-friendly name for property
    /// - parameter initialValue: The initial value of the property
    /// - parameter required: Boolean that dictates if this property is required or optional
    /// - parameter equatable: Boolean that dictates if this property is part of the `Equatable` protocol
    /// - parameter hashable: Boolean that dictates if this property is part of the `Hashable` protocol
    static func bool(_ named: String, propertyName: String? = nil, initialValue: Bool = false, required: Bool = true, equatable: Bool = false, hashable: Bool = false) -> ApiModelProperty {
        make(named, propertyName: propertyName, dataType: .bool(initialValue), required: required, equatable: equatable, hashable: hashable)
    }

    /// Create a `Swift.Double` property
    /// - parameter named: The `raw` name of the property
    /// - parameter propertyName: A swift-friendly name for property
    /// - parameter initialValue: The initial value of the property
    /// - parameter required: Boolean that dictates if this property is required or optional
    /// - parameter equatable: Boolean that dictates if this property is part of the `Equatable` protocol
    /// - parameter hashable: Boolean that dictates if this property is part of the `Hashable` protocol
    static func double(_ named: String, propertyName: String? = nil, initialValue: Double? = nil, required: Bool = true, equatable: Bool = false, hashable: Bool = false) -> ApiModelProperty {
        make(named, propertyName: propertyName, dataType: .double(initialValue), required: required, equatable: equatable, hashable: hashable)
    }

    /// Create a `Swift.Date` property
    /// - parameter named: The `raw` name of the property
    /// - parameter propertyName: A swift-friendly name for property
    /// - parameter initialValue: The initial value of the property
    /// - parameter required: Boolean that dictates if this property is required or optional
    /// - parameter equatable: Boolean that dictates if this property is part of the `Equatable` protocol
    /// - parameter hashable: Boolean that dictates if this property is part of the `Hashable` protocol
    static func date(_ named: String, propertyName: String? = nil, initialValue: Date? = nil, required: Bool = true, equatable: Bool = false, hashable: Bool = false) -> ApiModelProperty {
        make(named, propertyName: propertyName, dataType: .date(initialValue), required: required, equatable: equatable, hashable: hashable)
    }

    /// Create a `TimelessDate` property
    /// - parameter named: The `raw` name of the property
    /// - parameter propertyName: A swift-friendly name for property
    /// - parameter required: Boolean that dictates if this property is required or optional
    /// - parameter equatable: Boolean that dictates if this property is part of the `Equatable` protocol
    /// - parameter hashable: Boolean that dictates if this property is part of the `Hashable` protocol
    static func timelessDate(_ named: String, propertyName: String? = nil, required: Bool = true, equatable: Bool = false, hashable: Bool = false) -> ApiModelProperty {
        make(named, propertyName: propertyName, dataType: .timelessDate, required: required, equatable: equatable, hashable: hashable)
    }

    /// Create a `Time` property
    /// - parameter named: The `raw` name of the property
    /// - parameter propertyName: A swift-friendly name for property
    /// - parameter required: Boolean that dictates if this property is required or optional
    /// - parameter equatable: Boolean that dictates if this property is part of the `Equatable` protocol
    /// - parameter hashable: Boolean that dictates if this property is part of the `Hashable` protocol
    static func time(_ named: String, propertyName: String? = nil, required: Bool = true, equatable: Bool = false, hashable: Bool = false) -> ApiModelProperty {
        make(named, propertyName: propertyName, dataType: .time, required: required, equatable: equatable, hashable: hashable)
    }

    /// Create a `Swift.Binary` property
    /// - parameter named: The `raw` name of the property
    /// - parameter propertyName: A swift-friendly name for property
    /// - parameter required: Boolean that dictates if this property is required or optional
    static func binary(_ named: String, propertyName: String? = nil, required: Bool = true) -> ApiModelProperty {
        make(named, propertyName: propertyName, dataType: .binary, required: required)
    }

    /// Create a `Swift.Array` property
    /// - parameter named: The `raw` name of the property
    /// - parameter propertyName: A swift-friendly name for property
    /// - parameter of: ``ApiTypeSchema`` for the array
    /// - parameter required: Boolean that dictates if this property is required or optional
    /// - parameter equatable: Boolean that dictates if this property is part of the `Equatable` protocol
    /// - parameter hashable: Boolean that dictates if this property is part of the `Hashable` protocol
    static func array(_ named: String, propertyName: String? = nil, of type: ApiTypeSchema, required: Bool = true, equatable: Bool = false, hashable: Bool = false) -> ApiModelProperty {
        make(named, propertyName: propertyName, dataType: .array(type), required: required, equatable: equatable, hashable: hashable)
    }

    /// Create a `Swift.Array` of ``ApiTypeSchema`` reference
    /// - parameter named: The `raw` name of the property
    /// - parameter propertyName: A swift-friendly name for property
    /// - parameter of: ``ApiTypeSchema`` for the array
    /// - parameter required: Boolean that dictates if this property is required or optional
    /// - parameter equatable: Boolean that dictates if this property is part of the `Equatable` protocol
    /// - parameter hashable: Boolean that dictates if this property is part of the `Hashable` protocol
    static func arrayOfRef(_ named: String, propertyName: String? = nil, of type: ApiTypeSchema, required: Bool = true, equatable: Bool = false, hashable: Bool = false) -> ApiModelProperty {
        make(named, propertyName: propertyName, dataType: .array(type.asRef), required: required, equatable: equatable, hashable: hashable)
    }

    /// Create a `Swift.Array<String>` property
    /// - parameter named: The `raw` name of the property
    /// - parameter propertyName: A swift-friendly name for property
    /// - parameter required: Boolean that dictates if this property is required or optional
    /// - parameter equatable: Boolean that dictates if this property is part of the `Equatable` protocol
    /// - parameter hashable: Boolean that dictates if this property is part of the `Hashable` protocol
    static func arrayOfString(_ named: String, propertyName: String? = nil, required: Bool = true, equatable: Bool = false, hashable: Bool = false) -> ApiModelProperty {
        make(named, propertyName: propertyName, dataType: .array(.string()), required: required, equatable: equatable, hashable: hashable)
    }

    /// Create a `Swift.Array<Int>` property
    /// - parameter named: The `raw` name of the property
    /// - parameter propertyName: A swift-friendly name for property
    /// - parameter required: Boolean that dictates if this property is required or optional
    /// - parameter equatable: Boolean that dictates if this property is part of the `Equatable` protocol
    /// - parameter hashable: Boolean that dictates if this property is part of the `Hashable` protocol
    static func arrayOfInt(_ named: String, propertyName: String? = nil, required: Bool = true, equatable: Bool = false, hashable: Bool = false) -> ApiModelProperty {
        make(named, propertyName: propertyName, dataType: .array(.int()), required: required, equatable: equatable, hashable: hashable)
    }

    /// Create a `Swift.Dictionary<String:ApiTypeSchema>` property
    /// - parameter named: The `raw` name of the property
    /// - parameter propertyName: A swift-friendly name for property
    /// - parameter valueType: ``ApiTypeSchema`` for the dictionary
    /// - parameter required: Boolean that dictates if this property is required or optional
    /// - parameter equatable: Boolean that dictates if this property is part of the `Equatable` protocol
    /// - parameter hashable: Boolean that dictates if this property is part of the `Hashable` protocol
    static func keyedByString(
        _ named: String,
        propertyName: String? = nil,
        valueType: ApiTypeSchema = .string(),
        required: Bool = true,
        valueOptional: Bool = false,
        equatable: Bool = false,
        hashable: Bool = false
    ) -> ApiModelProperty {
        make(named, propertyName: propertyName, dataType: .keyedByString(valueType, isOptional: valueOptional), required: required, equatable: equatable, hashable: hashable)
    }

    /// Create a String `Enum` property
    /// - parameter named: The `raw` name of the property
    /// - parameter propertyName: A swift-friendly name for property
    /// - parameter typeName: The name of the enum
    /// - parameter values: The value of the enum
    /// - parameter initialValue: The initial value of the enum. Must match a value of the enum
    /// - parameter required: Boolean that dictates if this property is required or optional
    /// - parameter equatable: Boolean that dictates if this property is part of the `Equatable` protocol
    /// - parameter hashable: Boolean that dictates if this property is part of the `Hashable` protocol
    static func stringEnum(
        _ named: String,
        propertyName: String? = nil,
        typeName: String? = nil,
        values: [String],
        initialValue: String? = nil,
        required: Bool = true,
        equatable: Bool = false,
        hashable: Bool = false,
        supportGarbage: Bool = false
    ) -> ApiModelProperty {
        make(
            named,
            propertyName: propertyName,
            dataType: .stringEnum(
                typeName: (typeName ?? named).capitalCased,
                values: values.map { (name: $0, rawName: $0) },
                initialValue: initialValue,
                supportGarbage: supportGarbage
            ),
            required: required,
            equatable: equatable,
            hashable: hashable
        )
    }

    /// Create a String `Enum` property
    /// - parameter named: The `raw` name of the property
    /// - parameter propertyName: A swift-friendly name for property
    /// - parameter typeName: The name of the enum
    /// - parameter values: The values of the enum
    /// - parameter initialValue: The initial value of the enum. Must match a value of the enum
    /// - parameter required: Boolean that dictates if this property is required or optional
    /// - parameter equatable: Boolean that dictates if this property is part of the `Equatable` protocol
    /// - parameter hashable: Boolean that dictates if this property is part of the `Hashable` protocol
    static func stringEnum(
        _ named: String,
        propertyName: String? = nil,
        typeName: String? = nil,
        values: [(name: String, rawName: String)],
        initialValue: String? = nil,
        required: Bool = true,
        equatable: Bool = false,
        hashable: Bool = false
    ) -> ApiModelProperty {
        make(
            named,
            propertyName: propertyName,
            dataType: .stringEnum(typeName: (typeName ?? named).capitalCased, values: values, initialValue: initialValue),
            required: required,
            equatable: equatable,
            hashable: hashable
        )
    }

    /// Create a Int `Enum` property
    /// - parameter named: The `raw` name of the property
    /// - parameter propertyName: A swift-friendly name for property
    /// - parameter typeName: The name of the enum
    /// - parameter values: The values of the enum
    /// - parameter initialValue: The initial value of the enum. Must match a value of the enum
    /// - parameter required: Boolean that dictates if this property is required or optional
    /// - parameter equatable: Boolean that dictates if this property is part of the `Equatable` protocol
    /// - parameter hashable: Boolean that dictates if this property is part of the `Hashable` protocol
    static func intEnum(
        _ named: String,
        propertyName: String? = nil,
        typeName: String? = nil,
        values: [Int],
        initialValue: Int? = nil,
        required: Bool = true,
        equatable: Bool = false,
        hashable: Bool = false
    ) -> ApiModelProperty {
        make(
            named,
            propertyName: propertyName,
            dataType: .intEnum(typeName: (typeName ?? named).capitalCased, values: values.map { (nil, $0) }, initialValue: initialValue),
            required: required,
            equatable: equatable,
            hashable: hashable
        )
    }

    /// Create a Int `Enum` property
    /// - parameter named: The `raw` name of the property
    /// - parameter propertyName: A swift-friendly name for property
    /// - parameter typeName: The name of the enum
    /// - parameter values: The values of the enum
    /// - parameter initialValue: The initial value of the enum. Must match a value of the enum
    /// - parameter required: Boolean that dictates if this property is required or optional
    /// - parameter equatable: Boolean that dictates if this property is part of the `Equatable` protocol
    /// - parameter hashable: Boolean that dictates if this property is part of the `Hashable` protocol
    static func intEnum(
        _ named: String,
        propertyName: String? = nil,
        typeName: String? = nil,
        values: [(name: String, rawValue: Int)],
        initialValue: Int? = nil,
        required: Bool = true,
        equatable: Bool = false,
        hashable: Bool = false
    ) -> ApiModelProperty {
        make(
            named,
            propertyName: propertyName,
            dataType: .intEnum(typeName: (typeName ?? named).capitalCased, values: values, initialValue: initialValue),
            required: required,
            equatable: equatable,
            hashable: hashable
        )
    }

}
