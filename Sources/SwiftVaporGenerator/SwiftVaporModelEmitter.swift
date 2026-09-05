import SwiftApiGenerator
import Foundation
import GeneratorBuilder
import GeneratorModels
import SwiftSyntax
import SwiftSyntaxBuilder

struct SwiftVaporModelEmitter {
    let registry: SwiftVaporTypeRegistry
    let sourceRoot: String
    let packageImports: [ApiImport]

    func file(for registeredType: SwiftVaporRegisteredType) -> SwiftVaporGeneratedTextFile {
        SwiftVaporGeneratedTextFile(
            relativePath: "\(sourceRoot)/Generated/Models/\(registeredType.name).generated.swift",
            syntax: SwiftVaporSyntax.sourceFile(
                imports: importLines(for: registeredType.dataType),
                declarations: declaration(for: registeredType).map { [$0] } ?? []
            )
        )
    }

    private func importLines(for dataType: ApiTypeSchema) -> [String] {
        let baseImports = [
            ApiImport(stringLiteral: "Foundation"),
            ApiImport(stringLiteral: "Vapor")
        ]
        let baseImportNames = Set(baseImports.map(\.name))
        let extraImports = Set(packageImports + dataType.swiftVaporImports)
            .filter { !baseImportNames.contains($0.name) }
            .sorted()
        return (baseImports + extraImports).map(\.swiftVaporImportLine)
    }

    func declaration(for registeredType: SwiftVaporRegisteredType) -> DeclSyntax? {
        switch registeredType.dataType {
            case let .object(_, properties, protocols, _, isValueType, _):
                DeclSyntax(objectDeclaration(
                    name: registeredType.name,
                    properties: properties,
                    protocols: protocols,
                    isValueType: isValueType
                ))
            case let .stringEnum(_, values, _, _, supportGarbage):
                DeclSyntax(stringEnumDeclaration(name: registeredType.name, values: values, supportGarbage: supportGarbage))
            case let .intEnum(_, values, _, _):
                DeclSyntax(intEnumDeclaration(name: registeredType.name, values: values))
            case let .dynamicObject(
            _,
            objectTypePropertyName,
            objectDataPropertyName,
            alternateObjectDataPropertyName,
            objectTypes,
            supportGarbage,
            _,
            _,
            extraProperties
        ):
                DeclSyntax(dynamicObjectDeclaration(
                    name: registeredType.name,
                    objectTypePropertyName: objectTypePropertyName,
                    objectDataPropertyName: objectDataPropertyName,
                    alternateObjectDataPropertyName: alternateObjectDataPropertyName,
                    objectTypes: objectTypes,
                    supportGarbage: supportGarbage,
                    extraProperties: extraProperties
                ))
            case let .reference(_, _, _, _, dataType):
                dataType.flatMap { declaration(for: .init(id: registeredType.id, name: registeredType.name, dataType: $0)) }
            default:
                nil
        }
    }

    private func objectDeclaration(
        name: String,
        properties: [ApiModelProperty],
        protocols: [String],
        isValueType: Bool
    ) -> DeclSyntax {
        let fields = properties.filter(\.publishedAsField)
        let hasPatchableFields = fields.contains { $0.dataType.isSwiftVaporPatchableValue }
        let equatableFields = fields.filter { $0.equatable || $0.hashable }
        let hashableFields = fields.filter(\.hashable)
        let usesIdentityHash = !isValueType && protocols.contains("Hashable") && hashableFields.isEmpty
        let usesIdentityEquality = !isValueType && (equatableFields.isEmpty || usesIdentityHash)
        let shouldEmitEquatableDeclaration =
            (!equatableFields.isEmpty && (!protocols.contains("Hashable") || !hashableFields.isEmpty))
                || (!isValueType && (protocols.contains("Equatable") || protocols.contains("Hashable")))
        let shouldEmitHashableDeclaration = !hashableFields.isEmpty || (!isValueType && protocols.contains("Hashable"))
        let equatableComparison = if usesIdentityEquality {
            "lhs === rhs"
        } else if equatableFields.isEmpty {
            "true"
        } else {
            equatableFields.map { "lhs.\($0.propertyName) == rhs.\($0.propertyName)" }.joined(separator: " &&\n")
        }
        let hashLines = if usesIdentityHash {
            "hasher.combine(ObjectIdentifier(self))"
        } else if hashableFields.isEmpty {
            "hasher.combine(0)"
        } else {
            hashableFields.map { "hasher.combine(self.\($0.propertyName))" }.joined(separator: "\n")
        }
        var conformances = isValueType ? ["Codable", "Sendable"] : ["Codable"]
        if !equatableFields.isEmpty || protocols.contains("Equatable") {
            conformances.append("Equatable")
        }
        if !hashableFields.isEmpty || protocols.contains("Hashable") {
            conformances.append("Hashable")
        }
        conformances.append(contentsOf: protocols.filter { !conformances.contains($0) })

        let initParameters = fields.map { property -> String in
            let defaultValue = property.swiftVaporDefaultValue(registry: registry).map { " = \($0)" } ?? ""
            return "\(property.propertyName): \(registry.swiftType(for: property.dataType))\(property.swiftVaporOptionalSuffix)\(defaultValue)"
        }.joined(separator: ", ")
        let assignments = fields.map { "self.\($0.propertyName) = \($0.propertyName)" }.joined(separator: "\n")

        let members = SwiftGeneratedSyntax.parse("model \(name) members") {
            try MemberBlockItemListSyntax {
                for property in fields {
                    try VariableDeclSyntax("public var \(raw: property.propertyName): \(raw: registry.swiftType(for: property.dataType))\(raw: property.swiftVaporOptionalSuffix)")
                }
                try InitializerDeclSyntax("public init(\(raw: initParameters))") {
                    CodeBlockItemListSyntax(stringLiteral: assignments)
                }
                if fields.contains(where: { $0.rawName != $0.propertyName }) || hasPatchableFields {
                    try EnumDeclSyntax("public enum CodingKeys: String, CodingKey") {
                        for property in fields {
                            try EnumCaseDeclSyntax("\(raw: codingKeyLine(property))")
                        }
                    }
                }
                if hasPatchableFields {
                    try InitializerDeclSyntax("public \(raw: isValueType ? "" : "required ")init(from decoder: any Decoder) throws") {
                        "let container = try decoder.container(keyedBy: CodingKeys.self)"
                        CodeBlockItemListSyntax(stringLiteral: fields.map { decodeLine($0) }.joined(separator: "\n"))
                    }
                    try FunctionDeclSyntax("public func encode(to encoder: any Encoder) throws") {
                        "var container = encoder.container(keyedBy: CodingKeys.self)"
                        CodeBlockItemListSyntax(stringLiteral: fields.map { encodeLine($0) }.joined(separator: "\n"))
                    }
                }
                if shouldEmitEquatableDeclaration {
                    try FunctionDeclSyntax("public static func == (lhs: \(raw: name), rhs: \(raw: name)) -> Bool") {
                        "\(raw: equatableComparison)"
                    }
                }
                if shouldEmitHashableDeclaration {
                    try FunctionDeclSyntax("public func hash(into hasher: inout Hasher)") {
                        CodeBlockItemListSyntax(stringLiteral: hashLines)
                    }
                }
            }
        }
        return SwiftGeneratedSyntax.parse("model \(name)") {
            if isValueType {
                DeclSyntax(try StructDeclSyntax("public struct \(raw: name): \(raw: conformances.joined(separator: ", "))") {
                    members
                })
            } else {
                DeclSyntax(try ClassDeclSyntax("public class \(raw: name): \(raw: conformances.joined(separator: ", "))") {
                    members
                })
            }
        }
    }

    private func stringEnumDeclaration(
        name: String,
        values: [(name: String, rawName: String)],
        supportGarbage: Bool
    ) -> EnumDeclSyntax {
        SwiftGeneratedSyntax.parse("string enum \(name)") {
            try EnumDeclSyntax("public enum \(raw: name): String, Codable, Sendable, CaseIterable, Identifiable") {
                for value in values {
                    let caseName = value.name.swiftEnumValueDeclaration
                    if caseName == value.rawName {
                        try EnumCaseDeclSyntax("case \(raw: caseName)")
                    } else {
                        try EnumCaseDeclSyntax("case \(raw: caseName) = \(raw: value.rawName.swiftVaporStringLiteral)")
                    }
                }
                if supportGarbage {
                    try EnumCaseDeclSyntax("case garbage = \"__garbage__\"")
                }
                try VariableDeclSyntax("public var id: String { rawValue }")
                if supportGarbage {
                    try InitializerDeclSyntax("public init(from decoder: Decoder) throws") {
                        """
                        do {
                            let container = try decoder.singleValueContainer()
                            let value = try container.decode(String.self)
                            self = Self(rawValue: value) ?? .garbage
                        } catch {
                            self = .garbage
                        }
                        """
                    }
                }
            }
        }
    }

    private func intEnumDeclaration(name: String, values: [(name: String?, rawValue: Int)]) -> EnumDeclSyntax {
        SwiftGeneratedSyntax.parse("integer enum \(name)") {
            try EnumDeclSyntax("public enum \(raw: name): Int, Codable, Sendable, CaseIterable, Identifiable") {
                for value in values {
                    try EnumCaseDeclSyntax("case \(raw: swiftVaporIntCaseName(value)) = \(raw: value.rawValue)")
                }
                try VariableDeclSyntax("public var id: Int { rawValue }")
            }
        }
    }

    private func dynamicObjectDeclaration(
        name: String,
        objectTypePropertyName: String,
        objectDataPropertyName: String,
        alternateObjectDataPropertyName: String,
        objectTypes: [(objectTypeName: String, objectTypeRawName: String, objectType: ApiTypeSchema)],
        supportGarbage: Bool,
        extraProperties: [ApiModelProperty]
    ) -> EnumDeclSyntax {
        let supportsIdentity = objectTypes.allSatisfy { supportsDynamicObjectIdentifiable($0.objectType) }
        let supportsSendable = objectTypes.allSatisfy(\.objectType.isSwiftVaporSendable)
            && extraProperties.allSatisfy(\.dataType.isSwiftVaporSendable)
        let supportsEquatable = dynamicObjectSupportsEquatable(objectTypes: objectTypes, extraProperties: extraProperties)
        let supportsHashable = dynamicObjectSupportsHashable(objectTypes: objectTypes, extraProperties: extraProperties)
        let conformances = [
            "Codable",
            supportsSendable ? "Sendable" : nil,
            supportsIdentity ? "Identifiable" : nil,
            supportsEquatable ? "Equatable" : nil,
            supportsHashable ? "Hashable" : nil
        ]
        .compactMap(\.self)
        .joined(separator: ", ")
        return SwiftGeneratedSyntax.parse("dynamic object \(name)") {
            try EnumDeclSyntax("public enum \(raw: name): \(raw: conformances)") {
                if supportGarbage {
                    try EnumCaseDeclSyntax("case garbage")
                }
                for objectType in objectTypes {
                    dynamicObjectCaseLine(objectType, extraProperties: extraProperties)
                }
                dynamicObjectInitDeclaration(
                    name: name,
                    objectDataPropertyName: objectDataPropertyName,
                    objectTypes: objectTypes,
                    supportGarbage: supportGarbage,
                    extraProperties: extraProperties
                )
                dynamicObjectEncodeDeclaration(
                    objectDataPropertyName: objectDataPropertyName,
                    objectTypes: objectTypes,
                    supportGarbage: supportGarbage,
                    extraProperties: extraProperties
                )
                if objectDataPropertyName != "__self__" {
                    dynamicObjectDecodeCustomTypeDeclaration()
                }
                dynamicObjectCodingKeysDeclaration(
                    objectTypePropertyName: objectTypePropertyName,
                    objectDataPropertyName: objectDataPropertyName == "__self__" ? nil : objectDataPropertyName,
                    alternateObjectDataPropertyName: objectDataPropertyName == "__self__" ? nil : alternateObjectDataPropertyName,
                    extraProperties: extraProperties
                )
                dynamicObjectTypeEnumDeclaration(objectTypes: objectTypes, supportGarbage: supportGarbage)
                dynamicObjectTypePropertyDeclaration(objectTypes: objectTypes, supportGarbage: supportGarbage)
                if supportsIdentity {
                    dynamicObjectIDDeclaration(objectTypes: objectTypes, supportGarbage: supportGarbage, extraProperties: extraProperties)
                }
                if supportsEquatable {
                    dynamicObjectEquatableDeclaration(objectTypes: objectTypes, supportGarbage: supportGarbage, extraProperties: extraProperties)
                }
                if supportsHashable {
                    dynamicObjectHashableDeclaration(objectTypes: objectTypes, supportGarbage: supportGarbage, extraProperties: extraProperties)
                }
            }
        }
    }

    private func dynamicObjectCaseLine(
        _ objectType: (objectTypeName: String, objectTypeRawName: String, objectType: ApiTypeSchema),
        extraProperties: [ApiModelProperty]
    ) -> EnumCaseDeclSyntax {
        let associatedTypes = extraProperties.map(swiftTypeDeclaration)
            + [registry.swiftType(for: objectType.objectType)]
        return SwiftGeneratedSyntax.parse("dynamic object case") {
            try EnumCaseDeclSyntax("case \(raw: objectType.objectTypeName.swiftEnumValueDeclaration)(\(raw: associatedTypes.joined(separator: ", ")))")
        }
    }

    private func swiftTypeDeclaration(for property: ApiModelProperty) -> String {
        "\(registry.swiftType(for: property.dataType))\(property.required ? "" : "?")"
    }

    private func dynamicObjectInitDeclaration(
        name: String,
        objectDataPropertyName: String,
        objectTypes: [(objectTypeName: String, objectTypeRawName: String, objectType: ApiTypeSchema)],
        supportGarbage: Bool,
        extraProperties: [ApiModelProperty]
    ) -> InitializerDeclSyntax {
        let containerName = dynamicObjectLocalVariableName(
            baseName: "container",
            usedNames: Set(extraProperties.map(\.propertyName) + ["contentType", "decoder"])
        )
        let contentTypeName = dynamicObjectLocalVariableName(
            baseName: "contentType",
            usedNames: Set(extraProperties.map(\.propertyName) + [containerName, "decoder"])
        )
        let extraBindings = dynamicObjectExtraBindings(
            extraProperties: extraProperties,
            reservedNames: Set([containerName, contentTypeName, "decoder"])
        )
        let switchLines = dynamicObjectDecodeSwitchLines(
            name: name,
            objectDataPropertyName: objectDataPropertyName,
            objectTypes: objectTypes,
            supportGarbage: supportGarbage,
            extraBindings: extraBindings,
            containerName: containerName
        )

        let body = """
                let \(containerName) = try decoder.container(keyedBy: CodingKeys.self)
                let \(contentTypeName) = try \(containerName).decode(ObjectType.self, forKey: .contentType)
                switch \(contentTypeName) {
        \(switchLines)
                }
        """
        let bodySource = if supportGarbage {
            """
                    do {
            \(body.prepad(2))
                    } catch {
                        self = .garbage
                    }
            """
        } else {
            body.prepad(1)
        }

        return SwiftGeneratedSyntax.parse("dynamicObjectInitDeclaration") {
            try InitializerDeclSyntax(
                """
                    public init(from decoder: Decoder) throws {
                \(raw: bodySource)
                    }
                """
            )
        }
    }

    private func dynamicObjectDecodeSwitchLines(
        name _: String,
        objectDataPropertyName: String,
        objectTypes: [(objectTypeName: String, objectTypeRawName: String, objectType: ApiTypeSchema)],
        supportGarbage: Bool,
        extraBindings: [(property: ApiModelProperty, localName: String)],
        containerName: String
    ) -> String {
        var lines = supportGarbage ? [
            """
                    case .garbage:
                        self = .garbage
            """
        ] : []
        lines.append(contentsOf: objectTypes.map { objectType in
            let caseName = objectType.objectTypeName.swiftEnumValueDeclaration
            let extraDecodes = extraBindings.map { binding -> String in
                let type = registry.swiftType(for: binding.property.dataType)
                if binding.property.required {
                    return "            let \(binding.localName) = try \(containerName).decode(\(type).self, forKey: .\(binding.property.propertyName))"
                }
                return "            let \(binding.localName) = try \(containerName).decodeIfPresent(\(type).self, forKey: .\(binding.property.propertyName))"
            }
            .joined(separator: "\n")
            let decodedObjectArgument = objectDataPropertyName == "__self__"
                ? "try .init(from: decoder)"
                : "try Self.decodeCustomType(\(containerName))"
            let arguments = (extraBindings.map(\.localName) + [decodedObjectArgument]).joined(separator: ", ")
            let extraDecodeBlock = extraDecodes.isEmpty ? "" : "\n\(extraDecodes)"
            if supportGarbage {
                let garbageExtraDecodeBlock = extraDecodes.isEmpty ? "" : "\n\(extraDecodes.prepad(1))"
                return """
                        case .\(caseName):
                            do {\(garbageExtraDecodeBlock)
                                self = .\(caseName)(\(arguments))
                            } catch {
                                self = .garbage
                            }
                """
            }
            return """
                    case .\(caseName):\(extraDecodeBlock)
                        self = .\(caseName)(\(arguments))
            """
        })
        return lines.joined(separator: "\n")
    }

    private func dynamicObjectEncodeDeclaration(
        objectDataPropertyName: String,
        objectTypes: [(objectTypeName: String, objectTypeRawName: String, objectType: ApiTypeSchema)],
        supportGarbage: Bool,
        extraProperties: [ApiModelProperty]
    ) -> FunctionDeclSyntax {
        let payloadName = dynamicObjectPayloadBindingName(extraProperties: extraProperties)
        let containerName = dynamicObjectLocalVariableName(
            baseName: "container",
            usedNames: Set(extraProperties.map(\.propertyName) + [payloadName])
        )
        let extraBindings = dynamicObjectExtraBindings(
            extraProperties: extraProperties,
            reservedNames: Set([containerName, payloadName])
        )
        var switchLines = supportGarbage ? [
            """
                    case .garbage:
                        break
            """
        ] : []
        switchLines.append(contentsOf: objectTypes.map { objectType in
            let caseName = objectType.objectTypeName.swiftEnumValueDeclaration
            let patternValues = (extraBindings.map(\.localName) + [payloadName]).joined(separator: ", ")
            let extraEncodes = extraBindings.map { binding in
                if binding.property.required {
                    return "                try \(containerName).encode(\(binding.localName), forKey: .\(binding.property.propertyName))"
                }
                return "                try \(containerName).encodeIfPresent(\(binding.localName), forKey: .\(binding.property.propertyName))"
            }
            .joined(separator: "\n")
            let valueEncode = objectDataPropertyName == "__self__"
                ? "                try \(payloadName).encode(to: encoder)"
                : "                try \(containerName).encode(\(payloadName), forKey: .extras)"
            let encodes = ([extraEncodes, valueEncode].filter { !$0.isEmpty }).joined(separator: "\n")
            return """
                    case let .\(caseName)(\(patternValues)):
            \(encodes)
            """
        })

        return SwiftGeneratedSyntax.parse("dynamicObjectEncodeDeclaration") {
            try FunctionDeclSyntax(
                """
                    public func encode(to encoder: Encoder) throws {
                        var \(raw: containerName) = encoder.container(keyedBy: CodingKeys.self)
                        try \(raw: containerName).encode(objectType, forKey: .contentType)
                        switch self {
                \(raw: switchLines.joined(separator: "\n"))
                        }
                    }
                """
            )
        }
    }

    private func dynamicObjectPayloadBindingName(extraProperties: [ApiModelProperty]) -> String {
        var name = "value"
        var index = 0
        let reservedNames = Set(extraProperties.map(\.propertyName))
        while reservedNames.contains(name) {
            index += 1
            name = "value\(index)"
        }
        return name
    }

    private func dynamicObjectExtraBindings(
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

    private func dynamicObjectLocalVariableName(baseName: String, usedNames: Set<String>) -> String {
        guard usedNames.contains(baseName) else {
            return baseName
        }

        var index = 1
        var candidate = "\(baseName.swiftVaporUnescapedIdentifier)\(index)".swiftPropertyName
        while usedNames.contains(candidate) {
            index += 1
            candidate = "\(baseName.swiftVaporUnescapedIdentifier)\(index)".swiftPropertyName
        }
        return candidate
    }

    private func dynamicObjectDecodeCustomTypeDeclaration() -> FunctionDeclSyntax {
        return SwiftGeneratedSyntax.parse("dynamicObjectDecodeCustomTypeDeclaration") {
            try FunctionDeclSyntax(
                """
                    private static func decodeCustomType<T: Decodable>(_ container: KeyedDecodingContainer<CodingKeys>) throws -> T {
                        if let value = try container.decodeIfPresent(T.self, forKey: .extras) {
                            return value
                        }

                        if let value = try container.decodeIfPresent(T.self, forKey: .extra) {
                            return value
                        }

                    throw DecodingError.dataCorrupted(
                        DecodingError.Context(codingPath: container.codingPath, debugDescription: "Missing object data")
                    )
                }
                """
            )
        }
    }

    private func dynamicObjectCodingKeysDeclaration(
        objectTypePropertyName: String,
        objectDataPropertyName: String?,
        alternateObjectDataPropertyName: String?,
        extraProperties: [ApiModelProperty]
    ) -> EnumDeclSyntax {
        SwiftGeneratedSyntax.parse("dynamic object coding keys") {
            try EnumDeclSyntax("public enum CodingKeys: String, CodingKey") {
                try EnumCaseDeclSyntax("case contentType = \(raw: objectTypePropertyName.swiftVaporStringLiteral)")
                if let objectDataPropertyName {
                    try EnumCaseDeclSyntax("case extras = \(raw: objectDataPropertyName.swiftVaporStringLiteral)")
                }
                if let alternateObjectDataPropertyName {
                    try EnumCaseDeclSyntax("case extra = \(raw: alternateObjectDataPropertyName.swiftVaporStringLiteral)")
                }
                for property in extraProperties {
                    try EnumCaseDeclSyntax("case \(raw: property.propertyName) = \(raw: property.rawName.swiftVaporStringLiteral)")
                }
            }
        }
    }

    private func dynamicObjectTypeEnumDeclaration(
        objectTypes: [(objectTypeName: String, objectTypeRawName: String, objectType: ApiTypeSchema)],
        supportGarbage: Bool
    ) -> EnumDeclSyntax {
        SwiftGeneratedSyntax.parse("dynamic object type enum") {
            try EnumDeclSyntax("public enum ObjectType: String, Codable, Sendable, CaseIterable, Identifiable") {
                if supportGarbage {
                    try EnumCaseDeclSyntax("case garbage = \"__garbage__\"")
                }
                for objectType in objectTypes {
                    let caseName = objectType.objectTypeName.swiftEnumValueDeclaration
                    if caseName == objectType.objectTypeRawName {
                        try EnumCaseDeclSyntax("case \(raw: caseName)")
                    } else {
                        try EnumCaseDeclSyntax("case \(raw: caseName) = \(raw: objectType.objectTypeRawName.swiftVaporStringLiteral)")
                    }
                }
                try VariableDeclSyntax("public var id: String { rawValue }")
                if supportGarbage {
                    try InitializerDeclSyntax("public init(from decoder: Decoder) throws") {
                        """
                        do {
                            let container = try decoder.singleValueContainer()
                            let value = try container.decode(String.self)
                            self = Self(rawValue: value) ?? .garbage
                        } catch {
                            self = .garbage
                        }
                        """
                    }
                }
            }
        }
    }

    private func dynamicObjectTypePropertyDeclaration(
        objectTypes: [(objectTypeName: String, objectTypeRawName: String, objectType: ApiTypeSchema)],
        supportGarbage: Bool
    ) -> VariableDeclSyntax {
        var lines = supportGarbage ? [
            """
                    case .garbage:
                        return .garbage
            """
        ] : []
        lines.append(contentsOf: objectTypes.map { objectType in
            let caseName = objectType.objectTypeName.swiftEnumValueDeclaration
            return """
                    case .\(caseName):
                        return .\(caseName)
            """
        })

        return SwiftGeneratedSyntax.parse("dynamicObjectTypePropertyDeclaration") {
            try VariableDeclSyntax(
                """
                    public var objectType: ObjectType {
                        switch self {
                \(raw: lines.joined(separator: "\n"))
                        }
                    }
                """
            )
        }
    }

    private func dynamicObjectIDDeclaration(
        objectTypes: [(objectTypeName: String, objectTypeRawName: String, objectType: ApiTypeSchema)],
        supportGarbage: Bool,
        extraProperties: [ApiModelProperty]
    ) -> VariableDeclSyntax {
        var idLines = supportGarbage ? [
            """
                    case .garbage:
                        return ObjectType.garbage.rawValue
            """
        ] : []
        let ignoredExtraValues = extraProperties.map { _ in "_, " }.joined()
        idLines.append(contentsOf: objectTypes.map { objectType in
            let caseName = objectType.objectTypeName.swiftEnumValueDeclaration
            return """
                    case let .\(caseName)(\(ignoredExtraValues)value):
                        return "\\(ObjectType.\(caseName).rawValue)_\\(value.id)"
            """
        })

        return SwiftGeneratedSyntax.parse("dynamicObjectIDDeclaration") {
            try VariableDeclSyntax(
                """
                    public var id: String {
                        switch self {
                \(raw: idLines.joined(separator: "\n"))
                        }
                    }
                """
            )
        }
    }

    private func dynamicObjectEquatableDeclaration(
        objectTypes: [(objectTypeName: String, objectTypeRawName: String, objectType: ApiTypeSchema)],
        supportGarbage: Bool,
        extraProperties: [ApiModelProperty]
    ) -> FunctionDeclSyntax {
        var lines = supportGarbage ? [
            """
                    case (.garbage, .garbage):
                        return true
            """
        ] : []
        lines.append(contentsOf: objectTypes.map { objectType in
            let caseName = objectType.objectTypeName.swiftEnumValueDeclaration
            let lhsValues = dynamicObjectAssociatedValueNames(prefix: "lhs", extraProperties: extraProperties)
            let rhsValues = dynamicObjectAssociatedValueNames(prefix: "rhs", extraProperties: extraProperties)
            let comparisons = zip(lhsValues, rhsValues)
                .map { "\($0) == \($1)" }
                .joined(separator: " && ")
            return """
                    case let (.\(caseName)(\(lhsValues.joined(separator: ", "))), .\(caseName)(\(rhsValues.joined(separator: ", ")))):
                        return \(comparisons)
            """
        })
        lines.append("""
                default:
                    return false
        """)

        return SwiftGeneratedSyntax.parse("dynamicObjectEquatableDeclaration") {
            try FunctionDeclSyntax(
                """
                    public static func == (lhs: Self, rhs: Self) -> Bool {
                        switch (lhs, rhs) {
                \(raw: lines.joined(separator: "\n"))
                        }
                    }
                """
            )
        }
    }

    private func dynamicObjectHashableDeclaration(
        objectTypes: [(objectTypeName: String, objectTypeRawName: String, objectType: ApiTypeSchema)],
        supportGarbage: Bool,
        extraProperties: [ApiModelProperty]
    ) -> FunctionDeclSyntax {
        var lines = supportGarbage ? [
            """
                    case .garbage:
                        hasher.combine(ObjectType.garbage)
            """
        ] : []
        lines.append(contentsOf: objectTypes.map { objectType in
            let caseName = objectType.objectTypeName.swiftEnumValueDeclaration
            let values = dynamicObjectAssociatedValueNames(prefix: "value", extraProperties: extraProperties)
            let hashes = values.map { "            hasher.combine(\($0))" }.joined(separator: "\n")
            return """
                    case let .\(caseName)(\(values.joined(separator: ", "))):
                        hasher.combine(ObjectType.\(caseName))
            \(hashes)
            """
        })

        return SwiftGeneratedSyntax.parse("dynamicObjectHashableDeclaration") {
            try FunctionDeclSyntax(
                """
                    public func hash(into hasher: inout Hasher) {
                        switch self {
                \(raw: lines.joined(separator: "\n"))
                        }
                    }
                """
            )
        }
    }

    private func dynamicObjectAssociatedValueNames(prefix: String, extraProperties: [ApiModelProperty]) -> [String] {
        extraProperties.indices.map { "\(prefix)Extra\($0)" } + ["\(prefix)Payload"]
    }

    private func supportsDynamicObjectIdentifiable(_ dataType: ApiTypeSchema) -> Bool {
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

    private func dynamicObjectSupportsEquatable(
        objectTypes: [(objectTypeName: String, objectTypeRawName: String, objectType: ApiTypeSchema)],
        extraProperties: [ApiModelProperty]
    ) -> Bool {
        objectTypes.allSatisfy { supportsSwiftVaporEquatable($0.objectType) }
            && extraProperties.allSatisfy { supportsSwiftVaporEquatable($0.dataType) }
    }

    private func dynamicObjectSupportsHashable(
        objectTypes: [(objectTypeName: String, objectTypeRawName: String, objectType: ApiTypeSchema)],
        extraProperties: [ApiModelProperty]
    ) -> Bool {
        objectTypes.allSatisfy { supportsSwiftVaporHashable($0.objectType) }
            && extraProperties.allSatisfy { supportsSwiftVaporHashable($0.dataType) }
    }

    private func supportsSwiftVaporEquatable(_ dataType: ApiTypeSchema) -> Bool {
        switch dataType {
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
                supportsSwiftVaporEquatable(type)
            case let .object(_, properties, protocols, _, _, _):
                protocols.contains("Equatable") || properties.contains { $0.publishedAsField && ($0.equatable || $0.hashable) }
            case let .dynamicObject(_, _, _, _, objectTypes, _, _, _, extraProperties):
                dynamicObjectSupportsEquatable(objectTypes: objectTypes, extraProperties: extraProperties)
            case let .reference(_, _, _, _, dataType):
                dataType.map(supportsSwiftVaporEquatable) ?? false
            case .genericReference:
                false
        }
    }

    private func supportsSwiftVaporHashable(_ dataType: ApiTypeSchema) -> Bool {
        switch dataType {
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
                supportsSwiftVaporHashable(type)
            case let .object(_, properties, protocols, _, _, _):
                protocols.contains("Hashable") || properties.contains { $0.publishedAsField && $0.hashable }
            case let .dynamicObject(_, _, _, _, objectTypes, _, _, _, extraProperties):
                dynamicObjectSupportsHashable(objectTypes: objectTypes, extraProperties: extraProperties)
            case let .reference(_, _, _, _, dataType):
                dataType.map(supportsSwiftVaporHashable) ?? false
            case .genericReference:
                false
        }
    }

    private func codingKeyLine(_ property: ApiModelProperty) -> String {
        if property.rawName == property.propertyName {
            return "case \(property.propertyName)"
        }
        return "case \(property.propertyName) = \(property.rawName.swiftVaporStringLiteral)"
    }

    private func decodeLine(_ property: ApiModelProperty) -> String {
        let type = registry.swiftType(for: property.dataType)
        if property.dataType.isSwiftVaporPatchableValue {
            return "self.\(property.propertyName) = try container.decodePatchable(\(type).self, forKey: .\(property.propertyName))"
        }
        if property.required {
            return "self.\(property.propertyName) = try container.decode(\(type).self, forKey: .\(property.propertyName))"
        }
        return "self.\(property.propertyName) = try container.decodeIfPresent(\(type).self, forKey: .\(property.propertyName))"
    }

    private func encodeLine(_ property: ApiModelProperty) -> String {
        let name = property.propertyName
        if property.dataType.isSwiftVaporPatchableValue {
            return "try container.encodePatchable(self.\(name), forKey: .\(name))"
        }
        if property.required {
            return "try container.encode(self.\(name), forKey: .\(name))"
        }
        return "try container.encodeIfPresent(self.\(name), forKey: .\(name))"
    }
}

private extension ApiModelProperty {
    var swiftVaporOptionalSuffix: String {
        required || dataType.isSwiftVaporPatchableValue ? "" : "?"
    }

    func swiftVaporDefaultValue(registry: SwiftVaporTypeRegistry) -> String? {
        if dataType.isSwiftVaporPatchableValue {
            return ".unmodified"
        }
        if !required {
            return "nil"
        }

        return switch dataType {
            case let .string(value):
                value?.swiftVaporStringLiteral
            case let .int(value):
                value.map { "\($0)" }
            case let .int64(value):
                value.map { "\($0)" }
            case let .int32(value):
                value.map { "\($0)" }
            case let .int16(value):
                value.map { "\($0)" }
            case let .int8(value):
                value.map { "\($0)" }
            case let .uint(value):
                value.map { "\($0)" }
            case let .uint64(value):
                value.map { "\($0)" }
            case let .uint32(value):
                value.map { "\($0)" }
            case let .uint16(value):
                value.map { "\($0)" }
            case let .uint8(value):
                value.map { "\($0)" }
            case let .url(value):
                value.map { "URL(string: \($0.absoluteString.swiftVaporStringLiteral))!" }
            case let .double(value):
                value.map { "\($0)" }
            case let .date(value):
                value.map { "Date(timeIntervalSince1970: \($0.timeIntervalSince1970))" }
            case let .bool(value):
                String(value)
            case let .stringEnum(_, values, value, _, _):
                value.flatMap { selectedValue in
                    values.first { $0.name == selectedValue }
                        .map { ".\($0.name.swiftEnumValueDeclaration)" }
                }
            case let .intEnum(_, values, value, _):
                value.flatMap { selectedValue in
                    values.first { $0.rawValue == selectedValue }
                        .map { ".\(swiftVaporIntCaseName($0))" }
                }
            default:
                nil
        }
    }
}

private extension String {
    var swiftVaporUnescapedIdentifier: String {
        if hasPrefix("`"), hasSuffix("`"), count > 1 {
            return String(dropFirst().dropLast())
        }
        return self
    }
}

private extension Int {
    var swiftVaporIntCaseName: String {
        switch self {
            case 0:
                "zero"
            case 1:
                "one"
            case 2:
                "two"
            case 3:
                "three"
            case 4:
                "four"
            case 5:
                "five"
            case 6:
                "six"
            case 7:
                "seven"
            case 8:
                "eight"
            case 9:
                "nine"
            default:
                swiftEnumValueDeclaration
        }
    }
}

private func swiftVaporIntCaseName(_ value: (name: String?, rawValue: Int)) -> String {
    if let name = value.name, !name.isEmpty {
        return name.swiftEnumValueDeclaration
    }
    return value.rawValue.swiftVaporIntCaseName
}

extension ApiTypeSchema {
    var isSwiftVaporPatchableValue: Bool {
        guard case let .genericReference(typeName, _) = self else {
            return false
        }
        return typeName == "PatchableValue"
    }

    var swiftVaporImports: [ApiImport] {
        var seen = Set<UUID>()
        return swiftVaporImports(seen: &seen)
    }

    private func swiftVaporImports(seen: inout Set<UUID>) -> [ApiImport] {
        if let uuid = uuid ?? referenceUUID,
           !seen.insert(uuid).inserted {
            return imports
        }

        return switch self {
            case let .object(_, properties, _, imports, _, _):
                imports + properties.flatMap { $0.dataType.swiftVaporImports(seen: &seen) }
            case let .dynamicObject(_, _, _, _, objectTypes, _, imports, _, extraProperties):
                imports
                    + objectTypes.flatMap { $0.objectType.swiftVaporImports(seen: &seen) }
                    + extraProperties.flatMap { $0.dataType.swiftVaporImports(seen: &seen) }
            case let .reference(_, _, imports, _, dataType):
                imports + (dataType?.swiftVaporImports(seen: &seen) ?? [])
            case let .array(type),
                 let .keyedByString(type, _):
                type.swiftVaporImports(seen: &seen)
            case let .genericReference(_, types):
                types.flatMap { $0.swiftVaporImports(seen: &seen) }
            default:
                []
        }
    }
}

extension ApiImport {
    var swiftVaporImportLine: String {
        "\(annotation.map { "@\($0) " } ?? "")import \(name)"
    }
}
