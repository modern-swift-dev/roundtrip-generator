import Foundation
import GeneratorBuilder

public struct ApiParameter: Sendable {
    /// The location of a parameter
    public enum Location: String, Sendable {
        /// A `query` parameters is on the URL, after the `?`. Ex: `?offset=0&limit=100`
        case query

        /// A `header` parameter is simply a parameter that is in the http headers, and sent to the back-end.
        case header

        /// A `cookie` parameter is simply a parameter that is in the http headers, and sent to the back-end.
        case cookie

        /// A `path` parameter is simply a portion of the `path` that gets replaced at runtime.
        ///
        /// If your path is `/users/{id}/`, then your parameter should be named `id`, and the
        /// generated operation will automatically replace the `{id}` portion with the `percentEncoded` value
        /// of the parameter
        case path
    }

    /// The `ApiParameter` data-types are simpler than `ApiTypeSchema`, because they are used within
    /// the `query`, `header` or `path`
    public enum DataType: Sendable {
        /// `Swift.Bool` datatype
        /// - Example 1: `ApiParameter.DataType.bool()`
        /// - Example 2: `ApiParameter.DataType.bool(true)`
        case bool(Bool? = nil)

        /// Array of `Swift.Bool` datatype.
        /// - Example 1: `ApiParameter.DataType.boolArray()`
        /// - Example 2: `ApiParameter.DataType.boolArray([true, false])`
        ///
        /// > Note that the values are separated by a comma in the `query`, `header`. Like this: `?offset=0&limit=100&value=true,false`
        case boolArray([Bool]? = nil)

        /// `Swift.String` datatype
        /// - Example 1: `ApiParameter.DataType.string()`
        /// - Example 2: `ApiParameter.DataType.string("test")`
        case string(String? = nil)

        /// Array of `Swift.String` datatype.
        /// - Example 1: `ApiParameter.DataType.stringArray()`
        /// - Example 2: `ApiParameter.DataType.stringArray(["a", "b"])`
        ///
        /// > Note that the values are separated by a comma in the `query`, `header`. Like this: `?offset=0&limit=100&value=a,b`
        case stringArray([String]? = nil)

        /// `Swift.Int` datatype
        /// - Example 1: `ApiParameter.DataType.int()`
        /// - Example 2: `ApiParameter.DataType.int(1)`
        case int(Int? = nil)

        /// Array of `Swift.Int` datatype.
        /// - Example 1: `ApiParameter.DataType.intArray()`
        /// - Example 2: `ApiParameter.DataType.intArray([0, 1])`
        ///
        /// > Note that the values are separated by a comma in the `query`, `header`. Like this: `?offset=0&limit=100&value=0,1`
        case intArray([Int]? = nil)

        /// `Swift.Int16` datatype
        /// - Example 1: `ApiParameter.DataType.int16()`
        /// - Example 2: `ApiParameter.DataType.int16(1)`
        case int16(Int16? = nil)

        /// Array of `Swift.Int16` datatype.
        /// - Example 1: `ApiParameter.DataType.int16Array()`
        /// - Example 2: `ApiParameter.DataType.int16Array([0, 1])`
        ///
        /// > Note that the values are separated by a comma in the `query`, `header`. Like this: `?offset=0&limit=100&value=0,1`
        case int16Array([Int16]? = nil)

        /// `Swift.Int32` datatype
        /// - Example 1: `ApiParameter.DataType.int32()`
        /// - Example 2: `ApiParameter.DataType.int32(1)`
        case int32(Int32? = nil)

        /// Array of `Swift.Int32` datatype.
        /// - Example 1: `ApiParameter.DataType.int32Array()`
        /// - Example 2: `ApiParameter.DataType.int32Array([0, 1])`
        ///
        /// > Note that the values are separated by a comma in the `query`, `header`. Like this: `?offset=0&limit=100&value=0,1`
        case int32Array([Int32]? = nil)

        /// `Swift.Int64` datatype
        /// - Example 1: `ApiParameter.DataType.int64()`
        /// - Example 2: `ApiParameter.DataType.int64(1)`
        case int64(Int64? = nil)

        /// Array of `Swift.Int64` datatype.
        /// - Example 1: `ApiParameter.DataType.int64Array()`
        /// - Example 2: `ApiParameter.DataType.int64Array([0, 1])`
        ///
        /// > Note that the values are separated by a comma in the `query`, `header`. Like this: `?offset=0&limit=100&value=0,1`
        case int64Array([Int64]? = nil)

        /// `Swift.UInt` datatype
        /// - Example 1: `ApiParameter.DataType.uint()`
        /// - Example 2: `ApiParameter.DataType.uint(1)`
        case uint(UInt? = nil)

        /// Array of `Swift.UInt` datatype.
        /// - Example 1: `ApiParameter.DataType.uintArray()`
        /// - Example 2: `ApiParameter.DataType.uintArray([0, 1])`
        ///
        /// > Note that the values are separated by a comma in the `query`, `header`. Like this: `?offset=0&limit=100&value=0,1`
        case uintArray([UInt]? = nil)

        /// `Swift.UInt16` datatype
        /// - Example 1: `ApiParameter.DataType.uint16()`
        /// - Example 2: `ApiParameter.DataType.uint16(1)`
        case uint16(UInt16? = nil)

        /// Array of `Swift.UInt16` datatype.
        /// - Example 1: `ApiParameter.DataType.uint16Array()`
        /// - Example 2: `ApiParameter.DataType.uint16Array([0, 1])`
        ///
        /// > Note that the values are separated by a comma in the `query`, `header`. Like this: `?offset=0&limit=100&value=0,1`
        case uint16Array([UInt16]? = nil)

        /// `Swift.UInt32` datatype
        /// - Example 1: `ApiParameter.DataType.uint32()`
        /// - Example 2: `ApiParameter.DataType.uint32(1)`
        case uint32(UInt32? = nil)

        /// Array of `Swift.UInt32` datatype.
        /// - Example 1: `ApiParameter.DataType.uint32Array()`
        /// - Example 2: `ApiParameter.DataType.uint32Array([0, 1])`
        ///
        /// > Note that the values are separated by a comma in the `query`, `header`. Like this: `?offset=0&limit=100&value=0,1`
        case uint32Array([UInt32]? = nil)

        /// `Swift.UInt64` datatype
        /// - Example 1: `ApiParameter.DataType.uint64()`
        /// - Example 2: `ApiParameter.DataType.uint64(1)`
        case uint64(UInt64? = nil)

        /// Array of `Swift.UInt64` datatype.
        /// - Example 1: `ApiParameter.DataType.uint64Array()`
        /// - Example 2: `ApiParameter.DataType.uint64Array([0, 1])`
        ///
        /// > Note that the values are separated by a comma in the `query`, `header`. Like this: `?offset=0&limit=100&value=0,1`
        case uint64Array([UInt64]? = nil)

        /// String Enum of ``ApiTypeSchema`` datatype.
        /// - Example 1: `ApiParameter.DataType.stringEnumValue(type: .predefined.myEnumType.asRef)`
        /// - Example 2: `ApiParameter.DataType.stringEnumValue(type: .predefined.myEnumType.asRef, defaultValue: "caseRawValue")`
        ///
        /// > Note that the values are separated by a comma in the `query`, `header`. Like this: `?offset=0&limit=100&value=0,1`
        case stringEnumValue(type: ApiTypeSchema, defaultValue: String? = nil)

        /// String Enum Array of ``ApiTypeSchema`` datatype.
        /// - Example 1: `ApiParameter.DataType.stringEnumArray(type: .predefined.myEnumType.asRef)`
        /// - Example 2: `ApiParameter.DataType.stringEnumArray(type: .predefined.myEnumType.asRef, defaultValues: ["caseRawValue"])`
        ///
        /// > Note that the values are separated by a comma in the `query`, `header`. Like this: `?offset=0&limit=100&value=0,1`
        case stringEnumArray(type: ApiTypeSchema, defaultValues: [String]? = nil)

        /// Int Enum ``ApiTypeSchema`` datatype.
        /// - Example 1: `ApiParameter.DataType.intEnumValue(type: .predefined.myEnumType.asRef)`
        /// - Example 2: `ApiParameter.DataType.intEnumValue(type: .predefined.myEnumType.asRef, defaultValue: 0)`
        ///
        /// > Note that the values are separated by a comma in the `query`, `header`. Like this: `?offset=0&limit=100&value=1`
        case intEnumValue(type: ApiTypeSchema, defaultValue: Int? = nil)

        /// Int Enum Array of ``ApiTypeSchema`` datatype.
        /// - Example 1: `ApiParameter.DataType.intEnumArray(type: .predefined.myEnumType.asRef)`
        /// - Example 2: `ApiParameter.DataType.intEnumArray(type: .predefined.myEnumType.asRef, defaultValues: [0])`
        ///
        /// > Note that the values are separated by a comma in the `query`, `header`. Like this: `?offset=0&limit=100&value=0,1`
        case intEnumArray(type: ApiTypeSchema, defaultValues: [Int]? = nil)

        /// A date data-type, that output time in the iso 8601 format. i.e.: `yyyy/MM/ddTHH:mm:ssZ`, or `2022/11/30T21:38:59Z`
        case dateTime

        /// A date data-type, that output time in the iso date format. i.e.: `yyyy/MM/dd`, or `2022/11/30`
        case date

        /// A time data-type, that output time in the iso time format. i.e.: `HH:mm:ss`, or `21:38:59`
        case time
    }

    /// The raw name, for the coding key
    public var rawName: String

    /// The property name, camelized for the code
    public var propertyName: String

    /// The location of the parameter
    public var location: Location

    /// The data type
    public var dataType: DataType

    /// Is the property required
    public var isRequired: Bool = true

    /// Mutable
    public var isMutable: Bool = true
}

// MARK: - Sugar Syntax

public extension ApiParameter {
    /// Utility method that makes a API Parameter immutable
    ///
    /// > Defined as a `let` property instead of `var`
    var immutable: ApiParameter {
        .init(
            rawName: rawName,
            propertyName: propertyName,
            location: location,
            dataType: dataType,
            isRequired: isRequired,
            isMutable: false,
        )
    }

    /// Utility method that makes a API Parameter immutable
    ///
    /// > Defined as a `var` property instead of `let`
    var mutable: ApiParameter {
        .init(
            rawName: rawName,
            propertyName: propertyName,
            location: location,
            dataType: dataType,
            isRequired: isRequired,
            isMutable: true,
        )
    }

    /// Utility method that makes a API Parameter optional.
    ///
    /// > Example: defined as a `String?` property instead of `String`
    var optional: ApiParameter {
        .init(
            rawName: rawName,
            propertyName: propertyName,
            location: location,
            dataType: dataType,
            isRequired: false,
            isMutable: isMutable,
        )
    }

    /// Utility method that makes a API Parameter required.
    ///
    /// > Example: defined as a `String` property instead of `String?`
    var required: ApiParameter {
        .init(
            rawName: rawName,
            propertyName: propertyName,
            location: location,
            dataType: dataType,
            isRequired: true,
            isMutable: isMutable,
        )
    }

    /// Utility method that creates a `header` parameter.
    ///
    /// - parameter name: The name of the `header`. This is what is actually sent on the wire
    /// - parameter type: The data type of the parameter.
    /// - parameter propertyName: A custom name for the generated Swift property.
    /// - parameter required: Defines the parameter as required
    /// - parameter mutable: Defines the parameter as mutable
    ///
    /// > Example:
    /// > ```swift
    /// > ApiParameter.header("Last-Modified", .string())
    /// > ```
    static func header(_ name: String, _ type: DataType, propertyName: String? = nil, required: Bool = true, mutable: Bool = true) -> ApiParameter {
        .init(
            rawName: name,
            propertyName: (propertyName ?? name).swiftPropertyName,
            location: .header,
            dataType: type,
            isRequired: required,
            isMutable: mutable,
        )
    }

    /// Utility method that creates a `cookie` parameter.
    ///
    /// - parameter name: The name of the cookie sent on the wire.
    /// - parameter type: The data type of the parameter.
    /// - parameter propertyName: A custom name for the generated Swift property.
    /// - parameter required: Defines the parameter as required
    /// - parameter mutable: Defines the parameter as mutable
    ///
    /// > Example:
    /// > ```swift
    /// > ApiParameter.cookie("session_id", .string())
    /// > ```
    static func cookie(_ name: String, _ type: DataType, propertyName: String? = nil, required: Bool = true, mutable: Bool = true) -> ApiParameter {
        .init(
            rawName: name,
            propertyName: (propertyName ?? name).swiftPropertyName,
            location: .cookie,
            dataType: type,
            isRequired: required,
            isMutable: mutable,
        )
    }

    /// Utility method that creates a `query` parameter.
    ///
    /// - parameter name: The name of the query parameter sent on the wire.
    /// - parameter type: The data type of the parameter.
    /// - parameter propertyName: A custom name for the generated Swift property.
    /// - parameter required: Defines the parameter as required
    /// - parameter mutable: Defines the parameter as mutable
    ///
    /// > Example:
    /// > ```swift
    /// > ApiParameter.query("limit", .uint(0))
    /// > ```
    static func query(_ name: String, _ type: DataType, propertyName: String? = nil, required: Bool = true, mutable: Bool = true) -> ApiParameter {
        .init(
            rawName: name,
            propertyName: (propertyName ?? name).swiftPropertyName,
            location: .query,
            dataType: type,
            isRequired: required,
            isMutable: mutable,
        )
    }

    /// Utility method that creates a `path` parameter.
    ///
    /// - parameter name: The name of the path parameter to replace in the URL template.
    /// - parameter type: The data type of the parameter.
    /// - parameter propertyName: A custom name for the generated Swift property.
    /// - parameter mutable: Defines the parameter as mutable
    ///
    /// > Example:
    /// > ```swift
    /// > ApiParameter.path("id", .int64())
    /// > ```
    ///
    /// > A path parameter is always required!
    static func path(_ name: String, _ type: DataType, propertyName: String? = nil, mutable: Bool = true) -> ApiParameter {
        .init(
            rawName: name,
            propertyName: (propertyName ?? name).swiftPropertyName,
            location: .path,
            dataType: type,
            isRequired: true,
            isMutable: mutable,
        )
    }
}

// MARK: - Comparable

extension ApiParameter: Comparable {
    public static func < (lhs: ApiParameter, rhs: ApiParameter) -> Bool {
        lhs.rawName < rhs.rawName
    }

    public static func == (lhs: ApiParameter, rhs: ApiParameter) -> Bool {
        lhs.rawName == rhs.rawName
    }
}
