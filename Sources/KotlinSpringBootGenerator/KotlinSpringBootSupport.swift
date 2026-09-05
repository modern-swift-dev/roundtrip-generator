import Foundation
import GeneratorBuilder
import GeneratorModels

struct KotlinSpringBootTypeName: Hashable {
    var declaration: String
    var imports: Set<String>

    init(_ declaration: String, imports: Set<String> = []) {
        self.declaration = declaration
        self.imports = imports
    }

    var nullable: KotlinSpringBootTypeName {
        declaration.hasSuffix("?") ? self : .init("\(declaration)?", imports: imports)
    }
}

struct KotlinSpringBootProperty: Hashable {
    var mutable: Bool = false
    var name: String
    var typeName: KotlinSpringBootTypeName
    var nullable: Bool = false
    var defaultValue: String?
    var annotations: [String] = []
    var modifiers: [String] = []
    var additionalImports: Set<String> = []

    var imports: Set<String> {
        typeName.imports.union(additionalImports)
    }

    var declaration: String {
        let keyword = mutable ? "var" : "val"
        let typeDeclaration = nullable ? typeName.nullable.declaration : typeName.declaration
        let defaultDeclaration = defaultValue.map { " = \($0)" } ?? ""
        let modifierDeclaration = modifiers.isEmpty ? "" : "\(modifiers.joined(separator: " ")) "
        let propertyDeclaration = "\(modifierDeclaration)\(keyword) \(name): \(typeDeclaration)\(defaultDeclaration)"
        return annotations.isEmpty
            ? propertyDeclaration : (annotations + [propertyDeclaration]).joined(separator: "\n")
    }

    var isDirectByteArray: Bool {
        typeName.declaration == "ByteArray"
    }

    var hashCodeExpression: String {
        if isDirectByteArray {
            return nullable ? "(\(name)?.contentHashCode() ?: 0)" : "\(name).contentHashCode()"
        }
        return nullable ? "(\(name)?.hashCode() ?: 0)" : "\(name).hashCode()"
    }

    func byteArrayEqualityExpression(otherPrefix: String, otherValueName: String) -> String {
        if !nullable {
            return "if (!\(name).contentEquals(\(otherPrefix).\(name))) return false"
        }
        return """
        val \(otherValueName) = \(otherPrefix).\(name)
        if (\(name) == null) {
            if (\(otherValueName) != null) return false
        } else if (\(otherValueName) == null || !\(name).contentEquals(\(otherValueName))) return false
        """
    }
}

struct KotlinSpringBootDataClass: Node {
    var name: String
    var properties: [KotlinSpringBootProperty]
    var annotations: [String] = []
    var interfaces: [String] = []
    var nestedDeclarations: [String] = []
    var isDataClass: Bool = true
    var includeGeneratedComment: Bool = true

    func toString() -> String {
        var header: [any Node] = []
        if includeGeneratedComment {
            header.append("// Generated code. Modify at your own risk.")
        }
        header.append(contentsOf: annotations)

        let inheritance = interfaces.isEmpty ? "" : " : \(interfaces.joined(separator: ", "))"
        let declaration: String
        if properties.isEmpty {
            declaration = "class \(name)\(inheritance)"
        } else {
            let classKeyword = isDataClass ? "data class" : "class"
            declaration = Block {
                "\(classKeyword) \(name)("
                Indentation {
                    NodeList(properties.map { $0.declaration.appendingCommaToLastLine() as any Node })
                }
                ")\(inheritance)"
            }.toString()
        }

        let members = nestedDeclarations + byteArrayEqualityMembers()
        let memberNodes = members.enumerated().flatMap { index, member -> [any Node] in
            var nodes: [any Node] = [member as any Node]
            if index < members.count - 1 {
                nodes.append(NewLine())
            }
            return nodes
        }
        let body =
            if members.isEmpty {
                declaration
            } else {
                Block {
                    "\(declaration) {"
                    Indentation {
                        NodeList(memberNodes)
                    }
                    "}"
                }
                .toString()
            }

        return Block {
            NodeList(header)
            body
        }
        .toString()
    }

    private func byteArrayEqualityMembers() -> [String] {
        guard isDataClass, properties.contains(where: \.isDirectByteArray) else {
            return []
        }
        return [
            kotlinSpringBootEqualsFunction(className: name, properties: properties),
            kotlinSpringBootHashCodeFunction(properties: properties)
        ]
    }
}

private func kotlinSpringBootEqualsFunction(
    className: String,
    properties: [KotlinSpringBootProperty],
) -> String {
    Block {
        "override fun equals(other: Any?): Boolean {"
        Indentation {
            "if (this === other) return true"
            "if (other !is \(className)) return false"
            for (index, property) in properties.enumerated() {
                if property.isDirectByteArray {
                    property.byteArrayEqualityExpression(
                        otherPrefix: "other",
                        otherValueName: "otherByteArray\(index)",
                    )
                } else {
                    "if (\(property.name) != other.\(property.name)) return false"
                }
            }
            "return true"
        }
        "}"
    }
    .toString()
}

private func kotlinSpringBootHashCodeFunction(properties: [KotlinSpringBootProperty]) -> String {
    guard let firstProperty = properties.first else {
        return "override fun hashCode(): Int = 0"
    }
    let remainingProperties = properties.dropFirst()
    return Block {
        "override fun hashCode(): Int {"
        Indentation {
            "var result = \(firstProperty.hashCodeExpression)"
            for property in remainingProperties {
                "result = 31 * result + \(property.hashCodeExpression)"
            }
            "return result"
        }
        "}"
    }
    .toString()
}

struct KotlinSpringBootEnumCase: Hashable {
    var name: String
    var arguments: [String] = []
    var annotations: [String] = []

    var declaration: String {
        let argumentDeclaration = arguments.isEmpty ? "" : "(\(arguments.joined(separator: ", ")))"
        let caseDeclaration = "\(name)\(argumentDeclaration)"
        return annotations.isEmpty
            ? caseDeclaration : (annotations + [caseDeclaration]).joined(separator: "\n")
    }
}

struct KotlinSpringBootEnumClass: Node {
    var name: String
    var cases: [KotlinSpringBootEnumCase]
    var rawValuePropertyName: String?
    var rawValueType: KotlinSpringBootTypeName?
    var annotations: [String] = []
    var interfaces: [String] = []
    var functions: [String] = []
    var includeGeneratedComment: Bool = true

    func toString() -> String {
        var header: [any Node] = []
        if includeGeneratedComment {
            header.append("// Generated code. Modify at your own risk.")
        }
        header.append(contentsOf: annotations)

        let constructorDeclaration =
            if let rawValuePropertyName, let rawValueType {
                "(\n    val \(rawValuePropertyName): \(rawValueType.declaration),\n)"
            } else {
                ""
            }

        var bodyLines: [any Node] = []
        for (index, item) in cases.enumerated() {
            bodyLines.append(item.declaration.prepad(1).appendingCommaToLastLine())
            if index < cases.count - 1 {
                bodyLines.append(NewLine())
            }
        }
        if !functions.isEmpty {
            bodyLines.append("    ;")
            bodyLines.append(NewLine())
            for (index, function) in functions.enumerated() {
                bodyLines.append(function.prepad(1))
                if index < functions.count - 1 {
                    bodyLines.append(NewLine())
                }
            }
        }

        return Block {
            NodeList(header)
            let inheritance = interfaces.isEmpty ? "" : " : \(interfaces.joined(separator: ", "))"
            "enum class \(name)\(constructorDeclaration)\(inheritance) {"
            NodeList(bodyLines)
            "}"
        }
        .toString()
    }
}

enum KotlinSpringBootFileEmitter {
    static func render(packageName: String? = nil, imports: [String] = [], body: String) -> String {
        renderNode(packageName: packageName, imports: imports, body: body as any Node).toString()
    }

    static func renderNode(packageName: String? = nil, imports: [String] = [], body: any Node)
        -> any Node {
        let sortedImports = sortedKotlinImports(imports)
        return Block {
            KotlinSpringBootGeneratedTextFile.managedHeader
            if let packageName, !packageName.isEmpty {
                "package \(packageName)"
            }
            if !sortedImports.isEmpty {
                NewLine()
                NodeList(sortedImports.map { "import \($0)" as any Node })
            }
            NewLine()
            body
        }
    }

    private static func sortedKotlinImports(_ imports: [String]) -> [String] {
        Array(Set(imports))
            .filter { !$0.isEmpty }
            .sorted { lhs, rhs in
                let leftGroup = importSortGroup(lhs)
                let rightGroup = importSortGroup(rhs)
                if leftGroup != rightGroup {
                    return leftGroup < rightGroup
                }
                return lhs < rhs
            }
    }

    private static func importSortGroup(_ importName: String) -> Int {
        if importName.hasPrefix("java.") {
            return 1
        }
        if importName.hasPrefix("javax.") {
            return 2
        }
        if importName.hasPrefix("kotlin.") {
            return 3
        }
        if importName.hasPrefix("alias ") {
            return 4
        }
        return 0
    }
}

struct KotlinSpringBootTypeEmitter {
    let dataType: ApiTypeSchema
    let options: KotlinSpringBootGeneratorOptions

    var typeName: KotlinSpringBootTypeName {
        switch dataType {
            case .uuid,
                 .string,
                 .url:
                return .init("String")
            case .int,
                 .int32:
                return .init("Int")
            case .int64:
                return .init("Long")
            case .int16:
                return .init("Short")
            case .int8:
                return .init("Byte")
            case .uint,
                 .uint32:
                return .init("UInt")
            case .uint64:
                return .init("ULong")
            case .uint16:
                return .init("UShort")
            case .uint8:
                return .init("UByte")
            case .double:
                return .init("Double")
            case .date:
                return .init("Instant", imports: ["kotlin.time.Instant"])
            case .timelessDate:
                return .init("LocalDate", imports: ["kotlinx.datetime.LocalDate"])
            case .time:
                return .init("LocalTime", imports: ["kotlinx.datetime.LocalTime"])
            case .bool:
                return .init("Boolean")
            case .binary:
                return .init("ByteArray")
            case let .keyedByString(type, isOptional):
                let valueTypeName = Self(dataType: type, options: options).typeName
                let valueDeclaration =
                    isOptional ? valueTypeName.nullable.declaration : valueTypeName.declaration
                return .init("Map<String, \(valueDeclaration)>", imports: valueTypeName.imports)
            case let .stringEnum(typeName, _, _, _, _),
                 let .intEnum(typeName, _, _, _),
                 let .object(typeName, _, _, _, _, _),
                 let .dynamicObject(typeName, _, _, _, _, _, _, _, _):
                if let mapping = options.mapping(for: typeName) {
                    return .init(mapping.kotlinType, imports: Set(mapping.imports))
                }
                return .init(typeName.kotlinSpringBootTypeReferenceName)
            case let .reference(typeName, strict, imports, _, dataType):
                if let dataType {
                    return Self(dataType: dataType, options: options).typeName
                }
                if let mapping = options.mapping(for: typeName) {
                    return .init(mapping.kotlinType, imports: Set(mapping.imports))
                }
                return .init(
                    typeName.kotlinSpringBootTypeReferenceName, imports: strict ? [] : Set(imports.map(\.name)),
                )
            case let .array(type):
                let itemTypeName = Self(dataType: type, options: options).typeName
                return .init("List<\(itemTypeName.declaration)>", imports: itemTypeName.imports)
            case let .genericReference(typeName, types):
                let typeNames = types.map { Self(dataType: $0, options: options).typeName }
                let genericDeclaration = typeNames.map(\.declaration).joined(separator: ", ")
                let imports = typeNames.reduce(Set<String>()) { $0.union($1.imports) }
                if let mapping = options.mapping(for: typeName) {
                    return .init(
                        "\(mapping.kotlinType)<\(genericDeclaration)>", imports: imports.union(mapping.imports),
                    )
                }
                return .init(
                    "\(typeName.kotlinSpringBootTypeReferenceName)<\(genericDeclaration)>", imports: imports,
                )
        }
    }

    func defaultValue(required: Bool) -> String? {
        if dataType.isKotlinSpringBootPatchableValue {
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
                return initialValue?.kotlinSpringBootStringLiteral
            case let .double(initialValue):
                return initialValue.map { "\($0)" }
            case let .date(initialValue):
                return initialValue.map { value in
                    let milliseconds = Int64((value.timeIntervalSince1970 * 1000).rounded())
                    return "Instant.fromEpochMilliseconds(\(milliseconds)L)"
                }
            case let .url(initialValue):
                return initialValue.map(\.absoluteString.kotlinSpringBootStringLiteral)
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
                return
                    "\(typeName.kotlinSpringBootTypeReferenceName).\(selectedCase.name.kotlinSpringBootEnumCaseName)"
            case let .intEnum(typeName, values, initialValue, _):
                guard options.mapping(for: typeName) == nil else {
                    return nil
                }
                guard let initialValue,
                      let selectedCase = values.first(where: { $0.rawValue == initialValue }) else {
                    return nil
                }
                let caseName =
                    selectedCase.name?.isEmpty == false
                        ? selectedCase.name?.kotlinSpringBootEnumCaseName
                        : selectedCase.rawValue.description.kotlinSpringBootEnumCaseName
                return caseName.map { "\(typeName.kotlinSpringBootTypeReferenceName).\($0)" }
            case let .reference(typeName, _, _, _, dataType):
                guard options.mapping(for: typeName) == nil else {
                    return nil
                }
                return dataType.flatMap {
                    Self(dataType: $0, options: options).defaultValue(required: required)
                }
            case .int,
                 .int64,
                 .int32,
                 .int16,
                 .int8,
                 .uint,
                 .uint64,
                 .uint32,
                 .uint16,
                 .uint8:
                return integerDefaultValue
            default:
                return nil
        }
    }

    private var integerDefaultValue: String? {
        switch dataType {
            case let .int(initialValue):
                initialValue.map { "\($0)" }
            case let .int64(initialValue):
                initialValue.map { "\($0)L" }
            case let .int32(initialValue):
                initialValue.map { "\($0)" }
            case let .int16(initialValue):
                initialValue.map { "\($0)" }
            case let .int8(initialValue):
                initialValue.map { "\($0)" }
            case let .uint(initialValue):
                initialValue.map { "\($0)u" }
            case let .uint64(initialValue):
                initialValue.map { "\($0)uL" }
            case let .uint32(initialValue):
                initialValue.map { "\($0)u" }
            case let .uint16(initialValue):
                initialValue.map { "\($0)u" }
            case let .uint8(initialValue):
                initialValue.map { "\($0)u" }
            default:
                nil
        }
    }
}

struct KotlinSpringBootModelEmitter {
    let dataType: ApiTypeSchema
    let options: KotlinSpringBootGeneratorOptions
    let excludedNestedTypeIDs: Set<UUID>

    var declaration: String? {
        switch dataType {
            case let .object(typeName, properties, protocols, _, isValueType, _):
                let fields = properties.filter(\.publishedAsField)
                let usesPatchableValue = fields.contains { $0.dataType.isKotlinSpringBootPatchableValue }
                let modelProperties = fields.map { field in
                    var property = field.kotlinSpringBootProperty(options: options)
                    property.mutable = field.dataType.isKotlinSpringBootPatchableValue
                    if protocols.contains("Identifiable"), field.propertyName.kotlinSpringBootPropertyName == "id" {
                        property.modifiers = ["override"]
                    }
                    return property
                }
                let interfaces = Self.interfaces(protocols: protocols, properties: fields, options: options)
                let nestedDeclarations =
                    fields
                        .flatMap {
                            Self.nestedEmitters(
                                for: $0.dataType, options: options, excludedTypeIDs: excludedNestedTypeIDs,
                            )
                        }
                        .compactMap(\.declaration)
                return KotlinSpringBootDataClass(
                    name: typeName.kotlinSpringBootTypeName,
                    properties: modelProperties,
                    annotations: (usesPatchableValue ? ["@OptIn(ExperimentalSerializationApi::class)"] : []) + ["@Serializable"],
                    interfaces: interfaces,
                    nestedDeclarations: nestedDeclarations + Self.patchableDeclarations(properties: fields),
                    isDataClass: isValueType,
                )
                .toString()

            case let .stringEnum(typeName, values, _, _, supportGarbage):
                var cases = values.map { value in
                    KotlinSpringBootEnumCase(
                        name: value.name.kotlinSpringBootEnumCaseName,
                        arguments: [value.rawName.kotlinSpringBootStringLiteral],
                        annotations: ["@SerialName(\(value.rawName.kotlinSpringBootStringLiteral))"],
                    )
                }
                if supportGarbage {
                    cases.insert(
                        KotlinSpringBootEnumCase(
                            name: "Garbage",
                            arguments: ["__garbage__".kotlinSpringBootStringLiteral],
                            annotations: ["@SerialName(\"__garbage__\")"],
                        ),
                        at: 0,
                    )
                }
                let annotations =
                    supportGarbage
                        ? ["@Serializable(with = \(typeName.kotlinSpringBootTypeName).Serializer::class)"]
                        : ["@Serializable"]
                var functions = [
                    """
                    override val id: String
                        get() = rawValue
                    """,
                    """
                    companion object {
                        fun fromValue(value: String): \(typeName.kotlinSpringBootTypeName) =
                            entries.firstOrNull { it.rawValue == value }
                                ?: \(supportGarbage ? "Garbage" : "throw IllegalArgumentException(\"Unknown \(typeName.kotlinSpringBootTypeName) value: $value\")")
                    }
                    """
                ]
                if supportGarbage {
                    functions.insert(
                        """
                        object Serializer : KSerializer<\(typeName.kotlinSpringBootTypeName)> {
                            override val descriptor: SerialDescriptor =
                                PrimitiveSerialDescriptor("\(typeName.kotlinSpringBootTypeName)", PrimitiveKind.STRING)

                            override fun deserialize(decoder: Decoder): \(typeName.kotlinSpringBootTypeName) =
                                runCatching {
                                    \(typeName.kotlinSpringBootTypeName).fromValue(decoder.decodeString())
                                }.getOrElse { Garbage }

                            override fun serialize(
                                encoder: Encoder,
                                value: \(typeName.kotlinSpringBootTypeName),
                            ) {
                                encoder.encodeString(value.rawValue)
                            }
                        }
                        """,
                        at: 0,
                    )
                }
                return KotlinSpringBootEnumClass(
                    name: typeName.kotlinSpringBootTypeName,
                    cases: cases,
                    rawValuePropertyName: "rawValue",
                    rawValueType: .init("String"),
                    annotations: annotations,
                    interfaces: ["Identifiable<String>"],
                    functions: functions,
                )
                .toString()

            case let .intEnum(typeName, values, _, _):
                let cases = values.map { value in
                    let name =
                        if let declaredName = value.name, !declaredName.isEmpty {
                            declaredName.kotlinSpringBootEnumCaseName
                        } else {
                            value.rawValue.description.kotlinSpringBootEnumCaseName
                        }
                    return KotlinSpringBootEnumCase(name: name, arguments: [String(value.rawValue)])
                }
                return KotlinSpringBootEnumClass(
                    name: typeName.kotlinSpringBootTypeName,
                    cases: cases,
                    rawValuePropertyName: "rawValue",
                    rawValueType: .init("Int"),
                    annotations: ["@Serializable(with = \(typeName.kotlinSpringBootTypeName).Serializer::class)"],
                    interfaces: ["Identifiable<Int>"],
                    functions: [
                        """
                        override val id: Int
                            get() = rawValue
                        """,
                        """
                        object Serializer : KSerializer<\(typeName.kotlinSpringBootTypeName)> {
                            override val descriptor: SerialDescriptor =
                                PrimitiveSerialDescriptor("\(typeName.kotlinSpringBootTypeName)", PrimitiveKind.INT)

                            override fun deserialize(decoder: Decoder): \(typeName.kotlinSpringBootTypeName) = \(typeName.kotlinSpringBootTypeName).fromValue(decoder.decodeInt())

                            override fun serialize(
                                encoder: Encoder,
                                value: \(typeName.kotlinSpringBootTypeName),
                            ) {
                                encoder.encodeInt(value.rawValue)
                            }
                        }
                        """,
                        """
                        companion object {
                            fun fromValue(value: Int): \(typeName.kotlinSpringBootTypeName) =
                                entries.firstOrNull { it.rawValue == value }
                                    ?: throw IllegalArgumentException("Unknown \(typeName.kotlinSpringBootTypeName) value: $value")
                        }
                        """
                    ],
                )
                .toString()

            case let .dynamicObject(
            typeName, objectTypePropertyName, objectDataPropertyName,
            alternateObjectDataPropertyName, objectTypes, supportGarbage, _, _, extraProperties,
        ):
                let selfEncoded = objectDataPropertyName == "__self__"
                let usesCustomSerializer = supportGarbage || selfEncoded || alternateObjectDataPropertyName != objectDataPropertyName
                let extraFields = extraProperties
                let supportsIdentity = objectTypes.allSatisfy {
                    Self.supportsDynamicObjectIdentifiable($0.objectType)
                }
                let inheritance = supportsIdentity
                    ? " : Identifiable<String>"
                    : ""
                let cases = objectTypes.map { objectType -> any Node in
                    let name = objectType.objectTypeName.kotlinSpringBootTypeName
                    let payloadType = KotlinSpringBootTypeEmitter(
                        dataType: objectType.objectType, options: options,
                    ).typeName
                    let payloadParam = KotlinSpringBootProperty(
                        name: "payload",
                        typeName: payloadType,
                        annotations: ["@SerialName(\(objectDataPropertyName.kotlinSpringBootStringLiteral))"],
                    )
                    let extraParams = extraFields.map { property in
                        property.kotlinSpringBootProperty(options: options)
                    }
                    let params =
                        extraParams + [payloadParam]
                    return KotlinSpringBootDataClass(
                        name: name,
                        properties: params,
                        annotations: [
                            "@SerialName(\(objectType.objectTypeRawName.kotlinSpringBootStringLiteral))",
                            "@Serializable"
                        ],
                        interfaces: ["\(typeName.kotlinSpringBootTypeName)()"],
                        nestedDeclarations: [],
                        isDataClass: true,
                        includeGeneratedComment: false,
                    )
                    .toString()
                }
                let annotations =
                    usesCustomSerializer
                        ? ["@Serializable(with = \(typeName.kotlinSpringBootTypeName).Serializer::class)"]
                        : ["@Serializable"]
                let decodeElement = selfEncoded ? "element.withNestedPayload()" : "element.withoutObjectType()"
                let encodeElement = selfEncoded ? "withFlattenedPayload" : "withObjectType"
                let serializerDecodeCases = objectTypes.map { objectType in
                    "\(objectType.objectTypeRawName.kotlinSpringBootStringLiteral) -> jsonDecoder.json.decodeFromJsonElement(\(objectType.objectTypeName.kotlinSpringBootTypeName).serializer(), \(decodeElement))"
                }
                let serializerEncodeCases = objectTypes.map { objectType in
                    let typeName = objectType.objectTypeName.kotlinSpringBootTypeName
                    return """
                    is \(typeName) -> jsonEncoder.encodeJsonElement(
                        jsonEncoder.json
                            .encodeToJsonElement(
                                \(typeName).serializer(),
                                value,
                            )
                            .\(encodeElement)(\(objectType.objectTypeRawName.kotlinSpringBootStringLiteral)),
                    )
                    """
                }
                let unknownObjectTypeCase =
                    supportGarbage
                        ? "else -> Garbage(element)"
                        : "else -> throw SerializationException(\"Unknown \(typeName.kotlinSpringBootTypeName) discriminator: $objectType\")"
                let nestedPayloadHelpers: String
                if selfEncoded {
                    let metadataKeys = ([objectTypePropertyName] + extraFields.map(\.rawName))
                        .map(\.kotlinSpringBootStringLiteral)
                        .joined(separator: ", ")
                    nestedPayloadHelpers = Block {
                        "private val metadataKeys: Set<String> = setOf(\(metadataKeys))"
                        NewLine()
                        "private fun JsonElement.withNestedPayload(): JsonObject {"
                        Indentation {
                            "val source = jsonObject"
                            "val metadata = source.filterKeys { it in metadataKeys }"
                            "val payload = source.filterKeys { it !in metadataKeys }"
                            "return JsonObject("
                            Indentation {
                                "metadata.toMutableMap().apply {"
                                Indentation {
                                    "put(\(objectDataPropertyName.kotlinSpringBootStringLiteral), JsonObject(payload))"
                                }
                                "},"
                            }
                            ")"
                        }
                        "}"
                        NewLine()
                        "private fun JsonElement.withFlattenedPayload(objectType: String): JsonObject {"
                        Indentation {
                            "val source = jsonObject"
                            "val payload = source[\(objectDataPropertyName.kotlinSpringBootStringLiteral)]?.jsonObject ?: JsonObject(emptyMap())"
                            "return JsonObject("
                            Indentation {
                                "source.toMutableMap().apply {"
                                Indentation {
                                    "remove(\(objectDataPropertyName.kotlinSpringBootStringLiteral))"
                                    "putAll(payload)"
                                    "put(\(objectTypePropertyName.kotlinSpringBootStringLiteral), JsonPrimitive(objectType))"
                                }
                                "},"
                            }
                            ")"
                        }
                        "}"
                        NewLine()
                    }
                    .toString()
                } else {
                    nestedPayloadHelpers = Block {
                        "private fun JsonElement.withoutObjectType(): JsonObject ="
                        Indentation {
                            "JsonObject("
                            Indentation {
                                "jsonObject.toMutableMap().apply {"
                                Indentation {
                                    "remove(\(objectTypePropertyName.kotlinSpringBootStringLiteral))"
                                    "val alternatePayload = remove(\(alternateObjectDataPropertyName.kotlinSpringBootStringLiteral))"
                                    "if (\(objectDataPropertyName.kotlinSpringBootStringLiteral) !in this && alternatePayload != null) {"
                                    Indentation {
                                        "put(\(objectDataPropertyName.kotlinSpringBootStringLiteral), alternatePayload)"
                                    }
                                    "}"
                                }
                                "},"
                            }
                            ")"
                        }
                        NewLine()
                        "private fun JsonElement.withObjectType(objectType: String): JsonObject ="
                        Indentation {
                            "JsonObject("
                            Indentation {
                                "jsonObject.toMutableMap().apply {"
                                Indentation {
                                    "put(\(objectTypePropertyName.kotlinSpringBootStringLiteral), JsonPrimitive(objectType))"
                                }
                                "},"
                            }
                            ")"
                        }
                        NewLine()
                    }
                    .toString()
                }
                let serializerDeclaration =
                    usesCustomSerializer
                        ? Block {
                            NewLine()
                            "object Serializer : KSerializer<\(typeName.kotlinSpringBootTypeName)> {"
                            Indentation {
                                "override val descriptor: SerialDescriptor = buildClassSerialDescriptor(\(typeName.kotlinSpringBootTypeName.kotlinSpringBootStringLiteral))"
                                NewLine()
                                nestedPayloadHelpers
                                "override fun deserialize(decoder: Decoder): \(typeName.kotlinSpringBootTypeName) {"
                                Indentation {
                                    "val jsonDecoder = decoder as? JsonDecoder"
                                    Indentation {
                                        "?: throw SerializationException(\"\(typeName.kotlinSpringBootTypeName) can only be decoded from JSON\")"
                                    }
                                    "val element = jsonDecoder.decodeJsonElement()"
                                    if supportGarbage {
                                        "return runCatching {"
                                        Indentation {
                                            "val objectType = element.jsonObject[\(objectTypePropertyName.kotlinSpringBootStringLiteral)]?.jsonPrimitive?.contentOrNull"
                                            "when (objectType) {"
                                            Indentation {
                                                NodeList(serializerDecodeCases.map { "\($0)" as any Node })
                                                unknownObjectTypeCase
                                            }
                                            "}"
                                        }
                                        "}.getOrElse { Garbage(element) }"
                                    } else {
                                        "val objectType = element.jsonObject[\(objectTypePropertyName.kotlinSpringBootStringLiteral)]?.jsonPrimitive?.contentOrNull"
                                        "return when (objectType) {"
                                        Indentation {
                                            NodeList(serializerDecodeCases.map { "\($0)" as any Node })
                                            unknownObjectTypeCase
                                        }
                                        "}"
                                    }
                                }
                                "}"
                                NewLine()
                                "override fun serialize("
                                Indentation {
                                    "encoder: Encoder,"
                                    "value: \(typeName.kotlinSpringBootTypeName),"
                                }
                                ") {"
                                Indentation {
                                    "val jsonEncoder = encoder as? JsonEncoder"
                                    Indentation {
                                        "?: throw SerializationException(\"\(typeName.kotlinSpringBootTypeName) can only be encoded to JSON\")"
                                    }
                                    "when (value) {"
                                    Indentation {
                                        NodeList(serializerEncodeCases.map { "\($0)" as any Node })
                                        if supportGarbage {
                                            "is Garbage -> jsonEncoder.encodeJsonElement(value.raw ?: JsonObject(emptyMap()))"
                                        }
                                    }
                                    "}"
                                }
                                "}"
                            }
                            "}"
                        }
                        .toString()
                        : ""
                let idDeclaration =
                    supportsIdentity
                        ? dynamicObjectIDDeclaration(
                            objectTypes: objectTypes,
                            supportGarbage: supportGarbage,
                        )
                        : ""
                return Block {
                    "// Generated code. Modify at your own risk."
                    "@OptIn(ExperimentalSerializationApi::class)"
                    NodeList(annotations.map { $0 as any Node })
                    "@JsonClassDiscriminator(\(objectTypePropertyName.kotlinSpringBootStringLiteral))"
                    "sealed class \(typeName.kotlinSpringBootTypeName)\(inheritance) {"
                    Indentation {
                        cases.map { $0.toString() }.joined(separator: "\n\n")
                        if supportGarbage {
                            NewLine()
                            "@Serializable"
                            "data class Garbage("
                            Indentation {
                                "val raw: JsonElement? = null,"
                            }
                            ") : \(typeName.kotlinSpringBootTypeName)()"
                        }
                        idDeclaration
                        serializerDeclaration
                    }
                    "}"
                }
                .toString()

            default:
                return nil
        }
    }

    private func dynamicObjectIDDeclaration(
        objectTypes: [(objectTypeName: String, objectTypeRawName: String, objectType: ApiTypeSchema)],
        supportGarbage: Bool,
    ) -> String {
        var cases = supportGarbage ? [
            "is Garbage -> \("__garbage__".kotlinSpringBootStringLiteral)"
        ] : []
        cases.append(
            contentsOf: objectTypes.map { objectType in
                let caseName = objectType.objectTypeName.kotlinSpringBootTypeName
                let payloadID = Self.dynamicObjectPayloadIDExpression(objectType.objectType)
                return "is \(caseName) -> \("\(objectType.objectTypeRawName)_".kotlinSpringBootStringLiteral) + \(payloadID).toString()"
            },
        )
        return Block {
            "override val id: String"
            Indentation {
                "get() ="
                Indentation {
                    "when (this) {"
                    Indentation {
                        NodeList(cases.map { "\($0)" as any Node })
                    }
                    "}"
                }
            }
        }
        .toString()
    }

    private static func dynamicObjectPayloadIDExpression(_ dataType: ApiTypeSchema) -> String {
        switch dataType {
            case .object:
                "payload.id"
            case let .reference(_, _, _, _, dataType):
                dataType.map(dynamicObjectPayloadIDExpression) ?? "payload.id"
            case .stringEnum,
                 .intEnum:
                "payload.rawValue"
            default:
                "payload.id"
        }
    }

    private static func patchableDeclarations(properties: [ApiModelProperty]) -> [String] {
        let patchableProperties = properties.filter(\.dataType.isKotlinSpringBootPatchableValue)
        guard !patchableProperties.isEmpty else {
            return []
        }
        let resetLines =
            patchableProperties
                .map { "\($0.propertyName.kotlinSpringBootPropertyName) = PatchableValue.Unmodified" }
                .joined(separator: "\n")
        let checks =
            patchableProperties
                .map { "\($0.propertyName.kotlinSpringBootPropertyName) == PatchableValue.Unmodified" }
                .joined(separator: " &&\n")

        return [
            Block {
                "fun resetPatchableFields() {"
                Indentation {
                    resetLines
                }
                "}"
            }
            .toString(),
            Block {
                "fun isUnmodified(): Boolean ="
                Indentation {
                    checks
                }
            }
            .toString()
        ]
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

    private static func interfaces(
        protocols: [String],
        properties: [ApiModelProperty],
        options: KotlinSpringBootGeneratorOptions,
    ) -> [String] {
        guard protocols.contains("Identifiable"),
              let id = properties.first(where: { $0.propertyName.kotlinSpringBootPropertyName == "id" }) else {
            return []
        }
        var typeName = id.dataType.kotlinSpringBootTypeName(options: options).declaration
        if !id.required, !typeName.hasSuffix("?") {
            typeName += "?"
        }
        return ["Identifiable<\(typeName)>"]
    }

    var imports: Set<String> {
        switch dataType {
            case let .object(_, properties, _, _, _, _):
                let fields = properties.filter(\.publishedAsField)
                let usesPatchableValue = fields.contains { $0.dataType.isKotlinSpringBootPatchableValue }
                let propertyImports =
                    fields
                        .map { $0.kotlinSpringBootProperty(options: options).imports }
                        .reduce(Set<String>()) { $0.union($1) }
                let nestedImports =
                    fields
                        .flatMap {
                            Self.nestedEmitters(
                                for: $0.dataType, options: options, excludedTypeIDs: excludedNestedTypeIDs,
                            )
                        }
                        .map(\.imports)
                        .reduce(Set<String>()) { $0.union($1) }
                return propertyImports
                    .union(nestedImports)
                    .union(["kotlinx.serialization.Serializable"])
                    .union(usesPatchableValue ? ["kotlinx.serialization.ExperimentalSerializationApi"] : [])
            case let .stringEnum(_, _, _, _, supportGarbage):
                let serializerImports: Set<String> =
                    supportGarbage
                        ? [
                            "kotlinx.serialization.KSerializer",
                            "kotlinx.serialization.descriptors.PrimitiveKind",
                            "kotlinx.serialization.descriptors.PrimitiveSerialDescriptor",
                            "kotlinx.serialization.descriptors.SerialDescriptor",
                            "kotlinx.serialization.encoding.Decoder",
                            "kotlinx.serialization.encoding.Encoder"
                        ]
                        : []
                return Set([
                    "kotlinx.serialization.SerialName",
                    "kotlinx.serialization.Serializable"
                ]).union(serializerImports)
            case .intEnum:
                return [
                    "kotlinx.serialization.KSerializer",
                    "kotlinx.serialization.Serializable",
                    "kotlinx.serialization.descriptors.PrimitiveKind",
                    "kotlinx.serialization.descriptors.PrimitiveSerialDescriptor",
                    "kotlinx.serialization.descriptors.SerialDescriptor",
                    "kotlinx.serialization.encoding.Decoder",
                    "kotlinx.serialization.encoding.Encoder"
                ]
            case let .dynamicObject(
            _, _, objectDataPropertyName, alternateObjectDataPropertyName, objectTypes, supportGarbage, _, _,
            extraProperties,
        ):
                let usesCustomSerializer = supportGarbage || objectDataPropertyName == "__self__" || alternateObjectDataPropertyName != objectDataPropertyName
                let extraFields = extraProperties
                let payloadImports =
                    objectTypes
                        .map {
                            KotlinSpringBootTypeEmitter(dataType: $0.objectType, options: options).typeName.imports
                        }
                        .reduce(Set<String>()) { $0.union($1) }
                let extraImports =
                    extraFields
                        .map { $0.kotlinSpringBootProperty(options: options).imports }
                        .reduce(Set<String>()) { $0.union($1) }
                let serializerImports: Set<String> =
                    usesCustomSerializer
                        ? [
                            "kotlinx.serialization.KSerializer",
                            "kotlinx.serialization.SerializationException",
                            "kotlinx.serialization.descriptors.SerialDescriptor",
                            "kotlinx.serialization.descriptors.buildClassSerialDescriptor",
                            "kotlinx.serialization.encoding.Decoder",
                            "kotlinx.serialization.encoding.Encoder",
                            "kotlinx.serialization.json.JsonDecoder",
                            "kotlinx.serialization.json.JsonEncoder",
                            "kotlinx.serialization.json.JsonObject",
                            "kotlinx.serialization.json.JsonPrimitive",
                            "kotlinx.serialization.json.contentOrNull",
                            "kotlinx.serialization.json.decodeFromJsonElement",
                            "kotlinx.serialization.json.encodeToJsonElement",
                            "kotlinx.serialization.json.jsonObject",
                            "kotlinx.serialization.json.jsonPrimitive"
                        ]
                        : []
                return
                    payloadImports
                        .union(extraImports)
                        .union([
                            "kotlinx.serialization.ExperimentalSerializationApi",
                            "kotlinx.serialization.SerialName",
                            "kotlinx.serialization.Serializable",
                            "kotlinx.serialization.json.JsonClassDiscriminator"
                        ])
                        .union(usesCustomSerializer ? ["kotlinx.serialization.json.JsonElement"] : [])
                        .union(serializerImports)
            default:
                return []
        }
    }

    private static func nestedEmitters(
        for dataType: ApiTypeSchema,
        options: KotlinSpringBootGeneratorOptions,
        excludedTypeIDs: Set<UUID>,
    ) -> [KotlinSpringBootModelEmitter] {
        if let typeName = dataType.typeName,
           options.mapping(for: typeName) != nil {
            return []
        }
        if let uuid = dataType.declaredKotlinSpringBootTypeID,
           excludedTypeIDs.contains(uuid) {
            return []
        }

        switch dataType {
            case .object,
                 .stringEnum,
                 .intEnum,
                 .dynamicObject:
                return [
                    KotlinSpringBootModelEmitter(
                        dataType: dataType, options: options, excludedNestedTypeIDs: excludedTypeIDs,
                    )
                ]
            case let .array(type),
                 let .keyedByString(type, _):
                return nestedEmitters(for: type, options: options, excludedTypeIDs: excludedTypeIDs)
            default:
                return []
        }
    }
}

extension ApiModelProperty {
    func kotlinSpringBootProperty(options: KotlinSpringBootGeneratorOptions)
        -> KotlinSpringBootProperty {
        let name = propertyName.kotlinSpringBootPropertyName
        let needsSerialName = rawName != propertyName
        let patchable = dataType.isKotlinSpringBootPatchableValue
        let serialNameAnnotations =
            needsSerialName ? ["@SerialName(\(rawName.kotlinSpringBootStringLiteral))"] : []
        let patchableAnnotations = patchable ? ["@EncodeDefault(EncodeDefault.Mode.NEVER)"] : []
        let serializerAnnotations = dataType.usesDirectKotlinSpringBootByteArraySerializer
            ? ["@Serializable(with = ByteArrayBase64Serializer::class)"]
            : []
        var imports: Set<String> = needsSerialName ? ["kotlinx.serialization.SerialName"] : []
        if patchable {
            imports.insert("kotlinx.serialization.EncodeDefault")
        }
        if dataType.usesDirectKotlinSpringBootByteArraySerializer {
            imports.insert("\(options.basePackage).ByteArrayBase64Serializer")
        }
        return KotlinSpringBootProperty(
            name: name,
            typeName: KotlinSpringBootTypeEmitter(dataType: dataType, options: options).typeName,
            nullable: patchable ? false : !required,
            defaultValue: dataType.kotlinSpringBootDefaultValue(required: required, options: options),
            annotations: serialNameAnnotations + patchableAnnotations + serializerAnnotations,
            additionalImports: imports,
        )
    }
}

extension ApiTypeSchema {
    var usesDirectKotlinSpringBootByteArraySerializer: Bool {
        switch self {
            case .binary:
                true
            case let .reference(_, _, _, _, dataType):
                dataType?.usesDirectKotlinSpringBootByteArraySerializer ?? false
            default:
                false
        }
    }

    var declaredKotlinSpringBootTypeID: UUID? {
        switch self {
            case let .object(_, _, _, _, _, uuid),
                 let .stringEnum(_, _, _, uuid, _),
                 let .intEnum(_, _, _, uuid),
                 let .dynamicObject(_, _, _, _, _, _, _, uuid, _):
                uuid
            case let .reference(_, _, _, uuid, _):
                uuid
            default:
                nil
        }
    }

    var kotlinSpringBootTypeName: KotlinSpringBootTypeName {
        kotlinSpringBootTypeName(options: .init())
    }

    func kotlinSpringBootTypeName(options: KotlinSpringBootGeneratorOptions)
        -> KotlinSpringBootTypeName {
        KotlinSpringBootTypeEmitter(dataType: self, options: options).typeName
    }

    func kotlinSpringBootDefaultValue(required: Bool, options: KotlinSpringBootGeneratorOptions)
        -> String? {
        KotlinSpringBootTypeEmitter(dataType: self, options: options).defaultValue(required: required)
    }

    var typeName: String? {
        switch self {
            case let .object(typeName, _, _, _, _, _),
                 let .stringEnum(typeName, _, _, _, _),
                 let .intEnum(typeName, _, _, _),
                 let .dynamicObject(typeName, _, _, _, _, _, _, _, _),
                 let .reference(typeName, _, _, _, _),
                 let .genericReference(typeName, _):
                typeName
            default:
                nil
        }
    }

    var isKotlinSpringBootPatchableValue: Bool {
        switch self {
            case let .genericReference(typeName, _):
                typeName == "PatchableValue"
            case let .reference(_, _, _, _, dataType):
                dataType?.isKotlinSpringBootPatchableValue ?? false
            default:
                false
        }
    }
}

extension ApiParameter.DataType {
    func kotlinSpringBootBindingTypeName(options: KotlinSpringBootGeneratorOptions)
        -> KotlinSpringBootTypeName {
        switch self {
            case .stringEnumValue:
                .init("String")
            case .stringEnumArray:
                .init("List<String>")
            case .intEnumValue:
                .init("Int")
            case .intEnumArray:
                .init("List<Int>")
            case .dateTime,
                 .date,
                 .time:
                .init("String")
            default:
                kotlinSpringBootTypeName(options: options)
        }
    }

    var kotlinSpringBootBindingDefaultValue: String? {
        kotlinSpringBootBindingDefaultValue(options: .init())
    }

    func kotlinSpringBootBindingDefaultValue(options: KotlinSpringBootGeneratorOptions) -> String? {
        switch self {
            case let .stringEnumValue(_, value):
                value?.kotlinSpringBootStringLiteral
            case let .stringEnumArray(_, values):
                values.map { kotlinSpringBootListLiteral($0.map(\.kotlinSpringBootStringLiteral)) }
            case let .intEnumValue(_, value):
                value.map(String.init)
            case let .intEnumArray(_, values):
                values.map { kotlinSpringBootListLiteral($0.map(String.init)) }
            default:
                kotlinSpringBootDefaultValue(options: options)
        }
    }

    // swiftlint:disable:next cyclomatic_complexity
    func kotlinSpringBootTypeName(options: KotlinSpringBootGeneratorOptions)
        -> KotlinSpringBootTypeName {
        switch self {
            case .bool:
                return .init("Boolean")
            case .boolArray:
                return .init("List<Boolean>")
            case .string:
                return .init("String")
            case .stringArray:
                return .init("List<String>")
            case .int,
                 .int32:
                return .init("Int")
            case .intArray,
                 .int32Array:
                return .init("List<Int>")
            case .int16:
                return .init("Short")
            case .int16Array:
                return .init("List<Short>")
            case .int64:
                return .init("Long")
            case .int64Array:
                return .init("List<Long>")
            case .uint,
                 .uint32:
                return .init("UInt")
            case .uintArray,
                 .uint32Array:
                return .init("List<UInt>")
            case .uint16:
                return .init("UShort")
            case .uint16Array:
                return .init("List<UShort>")
            case .uint64:
                return .init("ULong")
            case .uint64Array:
                return .init("List<ULong>")
            case let .stringEnumValue(type, _),
                 let .intEnumValue(type, _):
                return type.kotlinSpringBootTypeName(options: options)
            case let .stringEnumArray(type, _),
                 let .intEnumArray(type, _):
                let typeName = type.kotlinSpringBootTypeName(options: options)
                return .init("List<\(typeName.declaration)>", imports: typeName.imports)
            case .dateTime:
                return .init("Instant", imports: ["kotlin.time.Instant"])
            case .date:
                return .init("LocalDate", imports: ["kotlinx.datetime.LocalDate"])
            case .time:
                return .init("LocalTime", imports: ["kotlinx.datetime.LocalTime"])
        }
    }

    var kotlinSpringBootDefaultValue: String? {
        kotlinSpringBootDefaultValue(options: .init())
    }

    func kotlinSpringBootDefaultValue(options: KotlinSpringBootGeneratorOptions) -> String? {
        switch self {
            case let .bool(value):
                value.map { $0 ? "true" : "false" }
            case let .boolArray(value):
                value.map { kotlinSpringBootListLiteral($0.map { $0 ? "true" : "false" }) }
            case let .string(value):
                value?.kotlinSpringBootStringLiteral
            case let .stringArray(value):
                value.map { kotlinSpringBootListLiteral($0.map(\.kotlinSpringBootStringLiteral)) }
            case let .stringEnumValue(type, value):
                value.map {
                    "\(type.kotlinSpringBootTypeName(options: options).declaration).fromValue(\($0.kotlinSpringBootStringLiteral))"
                }
            case let .stringEnumArray(type, values):
                values.map {
                    kotlinSpringBootListLiteral(
                        $0.map {
                            "\(type.kotlinSpringBootTypeName(options: options).declaration).fromValue(\($0.kotlinSpringBootStringLiteral))"
                        },
                    )
                }
            case let .intEnumValue(type, value):
                value.map { "\(type.kotlinSpringBootTypeName(options: options).declaration).fromValue(\($0))" }
            case let .intEnumArray(type, values):
                values.map {
                    kotlinSpringBootListLiteral(
                        $0.map { "\(type.kotlinSpringBootTypeName(options: options).declaration).fromValue(\($0))" },
                    )
                }
            case .dateTime,
                 .date,
                 .time:
                nil
            case .int,
                 .int32,
                 .intArray,
                 .int32Array,
                 .int16,
                 .int16Array,
                 .int64,
                 .int64Array,
                 .uint,
                 .uint32,
                 .uintArray,
                 .uint32Array,
                 .uint16,
                 .uint16Array,
                 .uint64,
                 .uint64Array:
                kotlinSpringBootIntegerDefaultValue
        }
    }

    private var kotlinSpringBootIntegerDefaultValue: String? {
        switch self {
            case let .int(value):
                value.map(String.init)
            case let .int32(value):
                value.map { "\($0)" }
            case let .intArray(value):
                value.map { kotlinSpringBootListLiteral($0.map(String.init)) }
            case let .int32Array(value):
                value.map { kotlinSpringBootListLiteral($0.map { "\($0)" }) }
            case let .int16(value):
                value.map { "\($0)" }
            case let .int16Array(value):
                value.map { kotlinSpringBootListLiteral($0.map { "\($0)" }) }
            case let .int64(value):
                value.map { "\($0)L" }
            case let .int64Array(value):
                value.map { kotlinSpringBootListLiteral($0.map { "\($0)L" }) }
            case let .uint(value):
                value.map { "\($0)u" }
            case let .uint32(value):
                value.map { "\($0)u" }
            case let .uintArray(value):
                value.map { kotlinSpringBootListLiteral($0.map { "\($0)u" }) }
            case let .uint32Array(value):
                value.map { kotlinSpringBootListLiteral($0.map { "\($0)u" }) }
            case let .uint16(value):
                value.map { "\($0)u" }
            case let .uint16Array(value):
                value.map { kotlinSpringBootListLiteral($0.map { "\($0)u" }) }
            case let .uint64(value):
                value.map { "\($0)uL" }
            case let .uint64Array(value):
                value.map { kotlinSpringBootListLiteral($0.map { "\($0)uL" }) }
            default:
                nil
        }
    }
}

extension ApiModule {
    var kotlinSpringBootModulePackageSegment: String {
        name.kotlinSpringBootPackageSegment
    }
}

extension ApiService {
    func kotlinSpringBootServiceTypeName(moduleName: String) -> String {
        "\(moduleName.capitalCased)\(name.capitalCased)Service".kotlinSpringBootTypeName
    }

    func kotlinSpringBootControllerTypeName(moduleName: String) -> String {
        "\(moduleName.capitalCased)\(name.capitalCased)Controller".kotlinSpringBootTypeName
    }
}

extension ApiOperation {
    var kotlinSpringBootMethodName: String {
        name.kotlinSpringBootPropertyName
    }

    func kotlinSpringBootRequestTypeName(moduleName: String, definitionName: String) -> String {
        "\(moduleName.capitalCased)\(definitionName.capitalCased)\(name.capitalCased)Request"
            .kotlinSpringBootTypeName
    }
}

extension String {
    private static let kotlinSpringBootHardKeywords: Set<String> = [
        "as", "break", "class", "continue", "do", "else", "false", "for",
        "fun", "if", "in", "interface", "is", "null", "object", "package",
        "return", "super", "this", "throw", "true", "try", "typealias",
        "typeof", "val", "var", "when", "while"
    ]

    private static let kotlinSpringBootSoftKeywords: Set<String> = [
        "by", "catch", "constructor", "delegate", "dynamic", "field", "file",
        "finally", "get", "import", "init", "param", "property", "receiver",
        "set", "setparam", "where"
    ]

    private var removingSwiftIdentifierEscapes: String {
        if hasPrefix("`"), hasSuffix("`"), count > 1 {
            return String(dropFirst().dropLast())
        }
        return self
    }

    private var kotlinSpringBootIdentifierWithValidLeadingCharacter: String {
        guard let first else {
            return "_value"
        }
        if first == "_" || first.isLetter {
            return self
        }
        return "_\(self)"
    }

    var kotlinSpringBootIdentifier: String {
        if isEmpty {
            return "_value"
        }
        if Self.kotlinSpringBootHardKeywords.contains(self)
            || Self.kotlinSpringBootSoftKeywords.contains(self) {
            return "`\(self)`"
        }
        return self
    }

    var kotlinSpringBootPropertyName: String {
        removingSwiftIdentifierEscapes
            .camelized
            .kotlinSpringBootIdentifierWithValidLeadingCharacter
            .kotlinSpringBootIdentifier
    }

    var kotlinSpringBootEnumCaseName: String {
        removingSwiftIdentifierEscapes
            .capitalCased
            .kotlinSpringBootIdentifierWithValidLeadingCharacter
            .kotlinSpringBootIdentifier
    }

    var kotlinSpringBootTypeName: String {
        removingSwiftIdentifierEscapes
            .capitalCased
            .kotlinSpringBootIdentifierWithValidLeadingCharacter
            .kotlinSpringBootIdentifier
    }

    var kotlinSpringBootTypeReferenceName: String {
        let parts = removingSwiftIdentifierEscapes.split(
            separator: ".", omittingEmptySubsequences: false,
        )
        guard parts.count > 1, let last = parts.last else {
            return kotlinSpringBootTypeName
        }
        let prefix = parts.dropLast().map(String.init).joined(separator: ".")
        return "\(prefix).\(String(last).kotlinSpringBootTypeName)"
    }

    var kotlinSpringBootStringLiteral: String {
        var result = "\""
        for scalar in unicodeScalars {
            switch scalar.value {
                case 0x08:
                    result += "\\b"
                case 0x09:
                    result += "\\t"
                case 0x0A:
                    result += "\\n"
                case 0x0C:
                    result += "\\u000c"
                case 0x0D:
                    result += "\\r"
                case 0x22:
                    result += "\\\""
                case 0x24:
                    result += "\\$"
                case 0x5C:
                    result += "\\\\"
                case 0x00 ... 0x1F:
                    let hex = String(scalar.value, radix: 16, uppercase: false)
                    result += "\\u\(String(repeating: "0", count: max(0, 4 - hex.count)))\(hex)"
                default:
                    result.unicodeScalars.append(scalar)
            }
        }
        result += "\""
        return result
    }

    var kotlinSpringBootPackageSegment: String {
        camelized
            .lowercased()
            .kotlinSpringBootIdentifierWithValidLeadingCharacter
            .kotlinSpringBootIdentifier
            .replacingOccurrences(of: "`", with: "_")
    }

    var kotlinSpringBootPackagePath: String {
        replacingOccurrences(of: ".", with: "/")
    }

    var isValidKotlinSpringBootPackage: Bool {
        let segments = split(separator: ".", omittingEmptySubsequences: false).map(String.init)
        return !segments.isEmpty
            && segments.allSatisfy { segment in
                guard let first = segment.first, first.isLetter || first == "_" else {
                    return false
                }
                return segment.allSatisfy { $0.isLetter || $0.isNumber || $0 == "_" }
            }
    }

    var isValidKotlinSpringBootIdentifier: Bool {
        guard let first, first.isLetter || first == "_" else {
            return false
        }
        return allSatisfy { $0.isLetter || $0.isNumber || $0 == "_" }
    }

    var isValidKotlinSpringBootProjectName: Bool {
        !isEmpty && !contains("/") && !contains(":") && !contains("..")
    }

    fileprivate func appendingCommaToLastLine() -> String {
        var lines = components(separatedBy: "\n")
        guard let last = lines.indices.last else {
            return self
        }
        lines[last] += ","
        return lines.joined(separator: "\n")
    }
}

private func kotlinSpringBootListLiteral(_ values: [String]) -> String {
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
