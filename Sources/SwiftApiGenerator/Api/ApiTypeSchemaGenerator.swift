import Foundation
import GeneratorBuilder
import GeneratorModels
import SwiftSyntax
import SwiftSyntaxBuilder

struct ApiTypeSchemasGenerator {
    let dataTypes: [ApiTypeSchema]

    func write(
        toDirectory url: URL,
        extensionName: String,
        fileNamePrefix: String,
        imports: [ApiImport]
    ) throws {
        guard url.isFileURL else {
            throw ApiValidationError.failed("Output directory must be a file URL: \(url)")
        }

        if !FileManager.default.dirExist(at: url) {
            try FileManager.default.createDirectory(atPath: url.path, withIntermediateDirectories: true, attributes: nil)
        }

        for dataType in dataTypes {
            try ApiTypeSchemaGenerator(dataType: dataType)
                .write(
                    toDirectory: url,
                    extensionName: extensionName,
                    fileNamePrefix: fileNamePrefix,
                    imports: dataType.allImports + imports
                )
        }
    }
}

// swiftlint:disable cyclomatic_complexity
// swiftlint:disable function_body_length
struct ApiTypeSchemaGenerator {
    let dataType: ApiTypeSchema

    /// Writes generated code to the specified directory.
    ///
    /// - parameter url: The URL of the directory to write the code
    /// - parameter extensionName: The name of the extension for the code
    /// - parameter fileNamePrefix: The filename prefix for the file
    /// - parameter imports: The list of imports to add to the generated code
    func write(
        toDirectory url: URL,
        extensionName: String,
        fileNamePrefix: String,
        imports: [ApiImport]
    ) throws {
        guard url.isFileURL else {
            throw ApiValidationError.failed("Output directory must be a file URL: \(url)")
        }

        var imports = dataType.allImports + imports
        var outputTypeName = ""
        switch dataType {
            case let .object(typeName, _, _, _, _, _):
                outputTypeName = typeName
            case let .stringEnum(typeName, _, _, _, _):
                outputTypeName = typeName
            case let .intEnum(typeName, _, _, _):
                outputTypeName = typeName
            case let .dynamicObject(typeName, _, _, _, _, supportGarbage, _, _, _):
                if supportGarbage {
                    imports.append(ApiImport(stringLiteral: "os"))
                }
                outputTypeName = typeName
            default:
                break
        }

        if outputTypeName.isEmpty {
            return
        }

        let safeFileName = try "\(fileNamePrefix)\(outputTypeName).generated.swift".safeFilePathComponent()
        let fileUrl = url.appendingPathComponent(safeFileName)
        guard let code = getSwiftDeclaration(parentClassName: extensionName, outputWithExtension: !extensionName.isEmpty) else {
            return
        }

        let source = SourceFileSyntax {
            for value in imports.swiftUniqueImports {
                SwiftImport(name: value.name, annotation: value.annotation).declaration
            }
            code
        }

        try SwiftSyntaxNode(source).write(to: fileUrl)
    }

    /// Method that generats the swift `class` or `struct` representation
    /// of the current data-type
    ///
    /// - parameter parentClassName: The parent class name if any.
    /// - parameter outputWithExtension: Output as an extension to the parent
    /// - returns The `NodeConvertible` representation
    func getSwiftClass(parentClassName: String?, outputWithExtension: Bool) -> (any NodeConvertible)? {
        getSwiftDeclaration(parentClassName: parentClassName, outputWithExtension: outputWithExtension)
            .map { SwiftSyntaxNode($0) }
    }

    func getSwiftDeclaration(parentClassName: String?, outputWithExtension: Bool) -> DeclSyntax? {
        switch dataType {
            case .uuid: return nil
            case .string: return nil
            case .int: return nil
            case .int64: return nil
            case .int32: return nil
            case .int16: return nil
            case .int8: return nil
            case .uint: return nil
            case .uint64: return nil
            case .uint32: return nil
            case .uint16: return nil
            case .uint8: return nil
            case .double: return nil
            case .date: return nil
            case .time: return nil
            case .timelessDate: return nil
            case .url: return nil
            case .bool: return nil
            case .binary: return nil
            case let .keyedByString(type, _):
                return Self(dataType: type).getSwiftDeclaration(parentClassName: parentClassName, outputWithExtension: outputWithExtension)
            case let .stringEnum(typeName, values, _, _, supportGarbage):
                let enumValues = values.map { (name: $0.name.swiftEnumValueDeclaration, raw: "\($0.rawName)") }
                return SwiftStringEnum(
                    extensionName: outputWithExtension ? parentClassName : nil,
                    visibility: .public,
                    name: typeName.swiftTypeName,
                    values: enumValues,
                    supportGarbage: supportGarbage
                ).declaration
            case let .intEnum(typeName, values, _, _):
                let enumValues = values.map { value -> (name: String, raw: String) in
                    let valueName = if let name = value.name, !name.isEmpty {
                        name.swiftEnumValueDeclaration
                    } else {
                        value.rawValue.swiftEnumValueDeclaration
                    }
                    let rawValue = "\(value.rawValue)"
                    return (name: valueName, raw: rawValue)
                }
                return SwiftIntEnum(
                    extensionName: outputWithExtension ? parentClassName : nil,
                    visibility: .public,
                    name: typeName.swiftTypeName,
                    values: enumValues
                ).declaration
            case let .array(type):
                return Self(dataType: type).getSwiftDeclaration(parentClassName: parentClassName, outputWithExtension: outputWithExtension)
            case let .object(typeName, properties, protocols, _, isValueType, _):
                let publishedProperties = properties.filter(\.publishedAsField)
                let swiftProperties: [SwiftProperty] = publishedProperties.map(\.swiftProperty)
                let swiftTypeName = typeName.swiftTypeName

                let innerTypes = publishedProperties.compactMap {
                    Self(dataType: $0.dataType).getSwiftDeclaration(parentClassName: swiftTypeName, outputWithExtension: false)
                }

                return SwiftClass(
                    extensionName: outputWithExtension ? parentClassName : nil,
                    name: swiftTypeName,
                    classAnnotations: [],
                    protocols: protocols,
                    properties: swiftProperties,
                    innerTypes: innerTypes,
                    isValueType: isValueType,
                    includeSendable: dataType.isSwiftSendable
                ).declaration
            case let .dynamicObject(typeName, objectTypePropertyName, objectDataPropertyName, alternateObjectDataPropertyName, objectTypes, garbage, _, _, extraProperties):
                let swiftTypeName = typeName.swiftTypeName
                var stringEnumValues = objectTypes.map { (name: "\($0.objectTypeName.swiftEnumValueDeclaration)", raw: "\($0.objectTypeRawName)") }
                if garbage {
                    stringEnumValues.insert((name: "garbage", raw: "__garbage__"), at: 0)
                }

                let stringEnum = SwiftStringEnum(name: "ObjectType", values: stringEnumValues, supportGarbage: false)

                let subTypes = objectTypes.map(\.objectType).compactMap { Self(dataType: $0).getSwiftDeclaration(parentClassName: parentClassName, outputWithExtension: false) }

                let allIdentifiable = objectTypes.map(\.objectType).allSatisfy(Self.supportsDynamicObjectIdentifiable)

                let visibilityPrefix = outputWithExtension ? "" : "public "
                var conformances = ["Codable"]
                if dataType.isSwiftSendable {
                    conformances.append("Sendable")
                }
                if allIdentifiable {
                    conformances.append("Identifiable")
                }
                let enumDeclaration = SwiftGeneratedSyntax.parse("data type \(swiftTypeName)") {
                    try EnumDeclSyntax("\(raw: visibilityPrefix)enum \(raw: swiftTypeName): \(raw: conformances.joined(separator: ", "))") {
                        if garbage {
                            try EnumCaseDeclSyntax("case garbage")
                        }

                        for objectType in objectTypes {
                            Self.dynamicObjectCaseDeclaration(
                                typeName: swiftTypeName,
                                objectTypeName: objectType.objectTypeName,
                                objectDataType: objectType.objectType,
                                extraProperties: extraProperties
                            )
                        }

                        Self.dynamicObjectInitDeclaration(
                            context: swiftTypeName,
                            objectTypes: objectTypes,
                            garbage: garbage,
                            objectDataPropertyName: objectDataPropertyName,
                            extraProperties: extraProperties
                        )

                        Self.dynamicObjectEncodeDeclaration(
                            context: swiftTypeName,
                            objectTypes: objectTypes,
                            garbage: garbage,
                            objectDataPropertyName: objectDataPropertyName,
                            extraProperties: extraProperties
                        )

                        if objectDataPropertyName != "__self__" {
                            Self.dynamicObjectDecodeCustomTypeDeclaration(context: swiftTypeName)
                            Self.dynamicObjectCodingKeysDeclaration(
                                context: swiftTypeName,
                                objectTypePropertyName: objectTypePropertyName,
                                objectDataPropertyName: objectDataPropertyName,
                                alternateObjectDataPropertyName: alternateObjectDataPropertyName,
                                extraProperties: extraProperties
                            )
                        } else {
                            Self.dynamicObjectCodingKeysDeclaration(
                                context: swiftTypeName,
                                objectTypePropertyName: objectTypePropertyName,
                                objectDataPropertyName: nil,
                                alternateObjectDataPropertyName: nil,
                                extraProperties: extraProperties
                            )
                        }

                        stringEnum.enumDeclaration(includeVisibility: true, includeGeneratedComment: false)
                            .with(\.leadingTrivia, .docLineComment("/// The list of supported object types\n"))
                        Self.dynamicObjectTypeDeclaration(
                            context: swiftTypeName,
                            objectTypes: objectTypes,
                            garbage: garbage
                        )

                        if allIdentifiable {
                            for declaration in Self.dynamicObjectIdentifiableDeclarations(
                                context: swiftTypeName,
                                objectTypes: objectTypes,
                                garbage: garbage,
                                extraProperties: extraProperties
                            ) {
                                declaration
                            }
                        }

                        for subType in subTypes {
                            subType
                        }
                    }
                }

                if outputWithExtension, let extensionName = parentClassName, !extensionName.isEmpty {
                    let extensionDeclaration = SwiftGeneratedSyntax.parse("data type \(extensionName).\(swiftTypeName) extension") {
                        try ExtensionDeclSyntax("public extension \(raw: extensionName)") {
                            enumDeclaration
                        }
                    }

                    return DeclSyntax(extensionDeclaration)
                }

                return DeclSyntax(enumDeclaration)
            case .reference:
                return nil
            case .genericReference:
                return nil
        }

    }

    /// Return the default value for the current type name.
    func getDefaultValue(required: Bool) -> String? {

        if case let .genericReference(typeName, _) = dataType,
           typeName == "PatchableValue" {
            return ".unmodified"
        }

        var defaultValue: String?
        switch dataType {
            case let .string(initialValue):
                if let value = initialValue {
                    defaultValue = value.swiftStringLiteral
                }
            case let .int(initialValue):
                if let value = initialValue {
                    defaultValue = "\(value)"
                }
            case let .int8(initialValue):
                if let value = initialValue {
                    defaultValue = "\(value)"
                }
            case let .int16(initialValue):
                if let value = initialValue {
                    defaultValue = "\(value)"
                }
            case let .int32(initialValue):
                if let value = initialValue {
                    defaultValue = "\(value)"
                }
            case let .int64(initialValue):
                if let value = initialValue {
                    defaultValue = "\(value)"
                }
            case let .uint(initialValue):
                if let value = initialValue {
                    defaultValue = "\(value)"
                }
            case let .uint8(initialValue):
                if let value = initialValue {
                    defaultValue = "\(value)"
                }
            case let .uint16(initialValue):
                if let value = initialValue {
                    defaultValue = "\(value)"
                }
            case let .uint32(initialValue):
                if let value = initialValue {
                    defaultValue = "\(value)"
                }
            case let .uint64(initialValue):
                if let value = initialValue {
                    defaultValue = "\(value)"
                }
            case let .double(initialValue):
                if let value = initialValue {
                    defaultValue = "\(value)"
                }
            case let .url(initialValue):
                if let value = initialValue {
                    defaultValue = "URL(string: \(value.absoluteString.swiftStringLiteral))! // This is ok, because we've already validated this is a valid url at generation-time"
                }
            case let .date(initialValue):
                if let value = initialValue {
                    defaultValue = "Date(timeIntervalSince1970: \(value.timeIntervalSince1970))"
                }
            case let .bool(initialValue):
                defaultValue = String(describing: initialValue)
            case let .stringEnum(_, values, initialValue, _, _):
                if let value = initialValue,
                   let selectedCase = values.first(where: { $0.name == value }) {
                    defaultValue = ".\(selectedCase.name.swiftEnumValueDeclaration)"
                }
            case let .intEnum(_, values, initialValue, _):
                if let value = initialValue,
                   let selectedCase = values.first(where: { $0.rawValue == value }) {
                    defaultValue = ".\(SwiftIntEnum.intEnumCaseName(selectedCase))"
                }
            default:
                break
        }

        if !required, defaultValue == nil {
            return "nil"
        }

        return defaultValue
    }

    /// Type declaration, for property declaration
    var swiftTypeDeclaration: String {
        switch dataType {
            case .uuid: return String(describing: UUID.self)
            case .string: return String(describing: String.self)
            case .int: return String(describing: Int.self)
            case .int64: return String(describing: Int64.self)
            case .int32: return String(describing: Int32.self)
            case .int16: return String(describing: Int16.self)
            case .int8: return String(describing: Int8.self)
            case .uint: return String(describing: UInt.self)
            case .uint64: return String(describing: UInt64.self)
            case .uint32: return String(describing: UInt32.self)
            case .uint16: return String(describing: UInt16.self)
            case .uint8: return String(describing: UInt8.self)
            case .double: return String(describing: Double.self)
            case .date: return String(describing: Date.self)
            case .time: return "Time"
            case .timelessDate: return "TimelessDate"
            case .url: return String(describing: URL.self)
            case .bool: return String(describing: Bool.self)
            case .binary: return String(describing: Data.self)
            case let .keyedByString(type, isOptional):
                if isOptional {
                    return "[\(String(describing: String.self)): \(Self(dataType: type).swiftTypeDeclaration)?]"
                }
                return "[\(String(describing: String.self)): \(Self(dataType: type).swiftTypeDeclaration)]"
            case let .stringEnum(typeName, _, _, _, _):
                return ApiTypeNameResolver.shared.scopedName(for: dataType) ?? typeName.swiftTypeName
            case let .intEnum(typeName, _, _, _):
                return ApiTypeNameResolver.shared.scopedName(for: dataType) ?? typeName.swiftTypeName
            case let .array(type):
                return "[\(Self(dataType: type).swiftTypeDeclaration)]"
            case let .object(typeName, _, _, _, _, _):
                return ApiTypeNameResolver.shared.scopedName(for: dataType) ?? typeName.swiftTypeName
            case let .dynamicObject(typeName, _, _, _, _, _, _, _, _):
                return ApiTypeNameResolver.shared.scopedName(for: dataType) ?? typeName.swiftTypeName
            case let .reference(typeName, strict, _, _, referencedDataType):
                if let scopedName = ApiTypeNameResolver.shared.scopedName(for: dataType) {
                    return scopedName
                }
                if let referencedDataType {
                    return Self(dataType: referencedDataType).swiftTypeDeclaration
                }
                return strict ? typeName.swiftTypeName : typeName
            case let .genericReference(typeName, types):
                let type = types.map { Self(dataType: $0).swiftTypeDeclaration }.joined(separator: ", ")
                return "\(typeName)<\(type)>"
        }
    }

    private static func dynamicObjectCaseDeclaration(
        typeName: String,
        objectTypeName: String,
        objectDataType: ApiTypeSchema,
        extraProperties: [ApiModelProperty]
    ) -> EnumCaseDeclSyntax {
        let caseName = objectTypeName.swiftEnumValueDeclaration
        let associatedTypes = extraProperties.map(Self.swiftTypeDeclaration(for:))
            + [Self(dataType: objectDataType).swiftTypeDeclaration]
        let associatedValues = associatedTypes.isEmpty ? "" : "(\(associatedTypes.joined(separator: ", ")))"

        return SwiftGeneratedSyntax.parse("data type \(typeName) \(caseName) case") {
            try EnumCaseDeclSyntax("case \(raw: caseName)\(raw: associatedValues)")
        }
    }

    private static func swiftTypeDeclaration(for property: ApiModelProperty) -> String {
        let declaration = ApiTypeSchemaGenerator(dataType: property.dataType).swiftTypeDeclaration
        return property.required ? declaration : "\(declaration)?"
    }

    private static func supportsDynamicObjectIdentifiable(_ dataType: ApiTypeSchema) -> Bool {
        switch dataType {
            case let .object(_, _, protocols, _, _, _):
                protocols.contains("Identifiable")
            case let .reference(_, _, _, _, dataType):
                dataType.map(supportsDynamicObjectIdentifiable) ?? false
            case .stringEnum,
                 .intEnum:
                true
            default:
                false
        }
    }

    private static func dynamicObjectDecodeCustomTypeDeclaration(context: String) -> FunctionDeclSyntax {
        SwiftGeneratedSyntax.parse("data type \(context) decode custom type") {
            try FunctionDeclSyntax(
                """
                /// Utility method that allows to decode from `extras`
                private static func decodeCustomType<T: Decodable>(_ container: KeyedDecodingContainer<CodingKeys>) throws -> T {
                    if let value = try container.decodeIfPresent(T.self, forKey: .extras) {
                        return value
                    }

                    if let value = try container.decodeIfPresent(T.self, forKey: .extra) {
                        return value
                    }

                    throw CocoaError(.coderInvalidValue)
                }
                """
            )
        }
    }

    private static func dynamicObjectCodingKeysDeclaration(
        context: String,
        objectTypePropertyName: String,
        objectDataPropertyName: String?,
        alternateObjectDataPropertyName: String?,
        extraProperties: [ApiModelProperty]
    ) -> EnumDeclSyntax {
        SwiftGeneratedSyntax.parse("data type \(context) coding keys") {
            try EnumDeclSyntax(
                """
                /// The coding keys
                public enum CodingKeys: String, CodingKey
                """
            ) {
                try EnumCaseDeclSyntax("case contentType = \(raw: objectTypePropertyName.debugDescription)")
                if let objectDataPropertyName {
                    try EnumCaseDeclSyntax("case extras = \(raw: objectDataPropertyName.debugDescription)")
                }
                if let alternateObjectDataPropertyName {
                    try EnumCaseDeclSyntax("case extra = \(raw: alternateObjectDataPropertyName.debugDescription)")
                }
                for prop in extraProperties {
                    try EnumCaseDeclSyntax("case \(raw: prop.propertyName) = \(raw: prop.rawName.debugDescription)")
                }
            }
        }
    }

    private static func dynamicObjectTypeDeclaration(
        context: String,
        objectTypes: [(objectTypeName: String, objectTypeRawName: String, objectType: ApiTypeSchema)],
        garbage: Bool
    ) -> VariableDeclSyntax {
        let garbageCase = garbage ? "case .garbage: return .garbage\n" : ""
        let objectTypeCases = objectTypes.map {
            let caseName = $0.objectTypeName.swiftEnumValueDeclaration
            return "case .\(caseName): return .\(caseName)"
        }.joined(separator: "\n")

        return SwiftGeneratedSyntax.parse("data type \(context) object type") {
            try VariableDeclSyntax(
                """
                public var objectType: ObjectType {
                    switch self {
                    \(raw: garbageCase)\(raw: objectTypeCases)
                    }
                }
                """
            )
        }
    }

    private static func dynamicObjectEncodeDeclaration(
        context: String,
        objectTypes: [(objectTypeName: String, objectTypeRawName: String, objectType: ApiTypeSchema)],
        garbage: Bool,
        objectDataPropertyName: String,
        extraProperties: [ApiModelProperty]
    ) -> FunctionDeclSyntax {
        let payloadVariableName = dynamicObjectPayloadVariableName(extraProperties: extraProperties)
        let containerVariableName = dynamicObjectLocalVariableName(
            baseName: "container",
            usedNames: Set(extraProperties.map(\.propertyName) + [payloadVariableName])
        )
        let extraBindings = dynamicObjectExtraBindings(
            extraProperties: extraProperties,
            reservedNames: Set([payloadVariableName, containerVariableName])
        )
        let garbageCase = garbage ? "case .garbage: break\n" : ""
        let objectTypeCases = objectTypes.map { objectType in
            let caseName = objectType.objectTypeName.swiftEnumValueDeclaration
            let associatedValues = extraBindings.map(\.localName).joined(separator: ", ")
            let patternValues = associatedValues.isEmpty ? payloadVariableName : "\(associatedValues), \(payloadVariableName)"
            let extraEncodes = extraBindings.map { binding in
                if binding.property.required {
                    return "try \(containerVariableName).encode(\(binding.localName), forKey: .\(binding.property.propertyName))"
                }
                return "try \(containerVariableName).encodeIfPresent(\(binding.localName), forKey: .\(binding.property.propertyName))"
            }.joined(separator: "\n")
            let valueEncode = if objectDataPropertyName == "__self__" {
                "try \(payloadVariableName).encode(to: encoder)"
            } else {
                "try \(containerVariableName).encode(\(payloadVariableName), forKey: .extras)"
            }

            return """
            case let .\(caseName)(\(patternValues)):
            \(extraEncodes)
                \(valueEncode)
            """
        }.joined(separator: "\n")

        return SwiftGeneratedSyntax.parse("data type \(context) encode") {
            try FunctionDeclSyntax(
                """
                /// Encoder to JSON
                public func encode(to encoder: Encoder) throws {
                    var \(raw: containerVariableName) = encoder.container(keyedBy: CodingKeys.self)
                    try \(raw: containerVariableName).encode(objectType, forKey: .contentType)
                    switch self {
                    \(raw: garbageCase)\(raw: objectTypeCases)
                    }
                }
                """
            )
        }
    }

    private static func dynamicObjectExtraBindings(
        extraProperties: [ApiModelProperty],
        reservedNames: Set<String>
    ) -> [(property: ApiModelProperty, localName: String)] {
        var usedNames = reservedNames
        return extraProperties.map { property in
            let localName = dynamicObjectLocalVariableName(
                baseName: property.propertyName,
                usedNames: usedNames
            )
            usedNames.insert(localName)
            return (property: property, localName: localName)
        }
    }

    private static func dynamicObjectPayloadVariableName(extraProperties: [ApiModelProperty]) -> String {
        let usedNames = Set(extraProperties.map(\.propertyName))
        guard usedNames.contains("value") else {
            return "value"
        }

        var index = 0
        var candidate = "payload"
        while usedNames.contains(candidate) {
            index += 1
            candidate = "payload\(index)"
        }
        return candidate
    }

    private static func dynamicObjectLocalVariableName(baseName: String, usedNames: Set<String>) -> String {
        guard usedNames.contains(baseName) else {
            return baseName
        }

        var index = 1
        var candidate = "\(baseName)\(index)"
        while usedNames.contains(candidate) {
            index += 1
            candidate = "\(baseName)\(index)"
        }
        return candidate
    }

    private static func dynamicObjectInitDeclaration(
        context: String,
        objectTypes: [(objectTypeName: String, objectTypeRawName: String, objectType: ApiTypeSchema)],
        garbage: Bool,
        objectDataPropertyName: String,
        extraProperties: [ApiModelProperty]
    ) -> InitializerDeclSyntax {
        let containerVariableName = dynamicObjectLocalVariableName(
            baseName: "container",
            usedNames: Set(extraProperties.map(\.propertyName) + ["decoder"])
        )
        let extraBindings = dynamicObjectExtraBindings(
            extraProperties: extraProperties,
            reservedNames: Set([containerVariableName, "decoder"])
        )
        let extraDecodes = extraBindings.map { binding -> String in
            let typeName = ApiTypeSchemaGenerator(dataType: binding.property.dataType).swiftTypeDeclaration
            if binding.property.required {
                return "let \(binding.localName) = try \(containerVariableName).decode(\(typeName).self, forKey: .\(binding.property.propertyName))"
            }
            return "let \(binding.localName) = try \(containerVariableName).decodeIfPresent(\(typeName).self, forKey: .\(binding.property.propertyName))"
        }.joined(separator: "\n")
        let garbageCase = garbage ? "case .garbage: self = .garbage\n" : ""
        let objectTypeCases = objectTypes.map { objectType -> String in
            let caseName = objectType.objectTypeName.swiftEnumValueDeclaration
            let extraArguments = extraBindings.map(\.localName)
            let decodedObjectArgument = if objectDataPropertyName == "__self__" {
                garbage ? ".init(from: decoder)" : "try .init(from: decoder)"
            } else {
                garbage ? "\(context).decodeCustomType(\(containerVariableName))" : "try \(context).decodeCustomType(\(containerVariableName))"
            }
            let arguments = (extraArguments + [decodedObjectArgument]).joined(separator: ", ")

            if garbage {
                return """
                case .\(caseName):
                    do {
                        self = try .\(caseName)(\(arguments))
                    }
                    catch {
                        self = .garbage
                    }
                """
            }

            return """
            case .\(caseName):
                self = .\(caseName)(\(arguments))
            """
        }.joined(separator: "\n")

        let bodySource = if garbage {
            """
            do {
                let \(containerVariableName) = try decoder.container(keyedBy: CodingKeys.self)
                let contentType = try \(containerVariableName).decode(ObjectType.self, forKey: .contentType)
            \(extraDecodes)
                switch contentType {
                \(garbageCase)\(objectTypeCases)
                }
            }
            catch {
                self = .garbage
            }
            """
        } else {
            """
            let \(containerVariableName) = try decoder.container(keyedBy: CodingKeys.self)
            let contentType = try \(containerVariableName).decode(ObjectType.self, forKey: .contentType)
            \(extraDecodes)
            switch contentType {
            \(objectTypeCases)
            }
            """
        }

        return SwiftGeneratedSyntax.parse("data type \(context) init") {
            try InitializerDeclSyntax(
                """
                public init(from decoder: Decoder) throws {
                \(raw: bodySource)
                }
                """
            )
        }
    }

    private static func dynamicObjectIdentifiableDeclarations(
        context: String,
        objectTypes: [(objectTypeName: String, objectTypeRawName: String, objectType: ApiTypeSchema)],
        garbage: Bool,
        extraProperties: [ApiModelProperty]
    ) -> [DeclSyntax] {
        let garbageCase = garbage ? "case .garbage: return ObjectType.garbage.rawValue\n" : ""
        let ignoredExtraValues = extraProperties.map { _ in "_, " }.joined()
        let objectTypeCases = objectTypes.map {
            let caseName = $0.objectTypeName.swiftEnumValueDeclaration
            return "case let .\(caseName)(\(ignoredExtraValues)value): return \"\\(ObjectType.\(caseName).rawValue)_\\(value.id)\""
        }.joined(separator: "\n")

        return [
            DeclSyntax(SwiftGeneratedSyntax.parse("data type \(context) id") {
                try VariableDeclSyntax(
                    """
                    public var id: String {
                        switch self {
                        \(raw: garbageCase)\(raw: objectTypeCases)
                        }
                    }
                    """
                )
            })
        ]
    }
}
