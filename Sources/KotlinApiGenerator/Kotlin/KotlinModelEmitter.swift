import Foundation
import GeneratorBuilder
import GeneratorModels

struct KotlinModelEmitter {
    let dataType: ApiTypeSchema
    let options: KotlinGeneratorOptions
    let excludedNestedTypeIDs: Set<UUID>

    init(dataType: ApiTypeSchema, options: KotlinGeneratorOptions = .init(), excludedNestedTypeIDs: Set<UUID> = []) {
        self.dataType = dataType
        self.options = options
        self.excludedNestedTypeIDs = excludedNestedTypeIDs
    }

    var declaration: String? {
        switch dataType {
            case let .object(typeName, properties, protocols, _, isValueType, _):
                let fields = properties.filter(\.publishedAsField)
                let usesPatchableValue = fields.contains { $0.dataType.isKotlinPatchableValue }
                let modelProperties = fields.map { field in
                    var property = field.kotlinProperty(options: options)
                    property.mutable = field.dataType.isKotlinPatchableValue
                    if protocols.contains("Identifiable"), field.propertyName.kotlinPropertyName == "id" {
                        property.modifiers = ["override"]
                    }
                    return property
                }
                let interfaces = Self.interfaces(protocols: protocols, properties: fields, options: options)
                let nestedDeclarations = fields
                    .flatMap { Self.nestedEmitters(for: $0.dataType, options: options, excludedTypeIDs: excludedNestedTypeIDs) }
                    .compactMap(\.declaration)

                return KotlinDataClass(
                    name: typeName.kotlinTypeName,
                    properties: modelProperties,
                    annotations: (usesPatchableValue ? ["@OptIn(ExperimentalSerializationApi::class)"] : []) + ["@Serializable"],
                    interfaces: interfaces,
                    nestedDeclarations: nestedDeclarations + Self.patchableDeclarations(properties: fields),
                    isDataClass: isValueType,
                    additionalImports: Set(["kotlinx.serialization.Serializable"])
                        .union(usesPatchableValue ? ["kotlinx.serialization.ExperimentalSerializationApi"] : []),
                )
                .toString()

            case let .stringEnum(typeName, values, _, _, supportGarbage):
                var cases = values.map { value in
                    KotlinEnumCase(
                        name: value.name.kotlinEnumCaseName,
                        arguments: [value.rawName.kotlinStringLiteral],
                        annotations: ["@SerialName(\(value.rawName.kotlinStringLiteral))"],
                    )
                }
                if supportGarbage {
                    cases.insert(
                        KotlinEnumCase(
                            name: "Garbage",
                            arguments: ["__garbage__".kotlinStringLiteral],
                            annotations: ["@SerialName(\"__garbage__\")"],
                        ),
                        at: 0,
                    )
                }

                let annotations = supportGarbage
                    ? ["@Serializable(with = \(typeName.kotlinTypeName).Serializer::class)"]
                    : ["@Serializable"]
                var functions = [
                    """
                    override val id: String
                        get() = rawValue
                    """,
                    """
                    companion object {
                        fun fromValue(value: String): \(typeName.kotlinTypeName) =
                            entries.firstOrNull { it.rawValue == value }
                                ?: \(supportGarbage ? "Garbage" : "throw IllegalArgumentException(\"Unknown \(typeName.kotlinTypeName) value: $value\")")
                    }
                    """
                ]
                if supportGarbage {
                    functions.insert(
                        """
                        object Serializer : KSerializer<\(typeName.kotlinTypeName)> {
                            override val descriptor: SerialDescriptor =
                                PrimitiveSerialDescriptor("\(typeName.kotlinTypeName)", PrimitiveKind.STRING)

                            override fun deserialize(decoder: Decoder): \(typeName.kotlinTypeName) =
                                runCatching {
                                    \(typeName.kotlinTypeName).fromValue(decoder.decodeString())
                                }.getOrElse { Garbage }

                            override fun serialize(encoder: Encoder, value: \(typeName.kotlinTypeName)) {
                                encoder.encodeString(value.rawValue)
                            }
                        }
                        """,
                        at: 0,
                    )
                }

                let additionalImports = Set([
                    "kotlinx.serialization.SerialName",
                    "kotlinx.serialization.Serializable"
                ]).union(
                    supportGarbage
                        ? [
                            "kotlinx.serialization.KSerializer",
                            "kotlinx.serialization.descriptors.PrimitiveKind",
                            "kotlinx.serialization.descriptors.PrimitiveSerialDescriptor",
                            "kotlinx.serialization.descriptors.SerialDescriptor",
                            "kotlinx.serialization.encoding.Decoder",
                            "kotlinx.serialization.encoding.Encoder"
                        ]
                        : [],
                )

                return KotlinEnumClass(
                    name: typeName.kotlinTypeName,
                    cases: cases,
                    rawValuePropertyName: "rawValue",
                    rawValueType: KotlinTypeName("String"),
                    annotations: annotations,
                    interfaces: ["Identifiable<String>"],
                    functions: functions,
                    additionalImports: additionalImports,
                )
                .toString()

            case let .intEnum(typeName, values, _, _):
                let cases = values.map { value in
                    let name = if let declaredName = value.name, !declaredName.isEmpty {
                        declaredName.kotlinEnumCaseName
                    } else {
                        value.rawValue.description.kotlinEnumCaseName
                    }
                    return KotlinEnumCase(name: name, arguments: [String(value.rawValue)])
                }

                return KotlinEnumClass(
                    name: typeName.kotlinTypeName,
                    cases: cases,
                    rawValuePropertyName: "rawValue",
                    rawValueType: KotlinTypeName("Int"),
                    annotations: ["@Serializable(with = \(typeName.kotlinTypeName).Serializer::class)"],
                    interfaces: ["Identifiable<Int>"],
                    functions: [
                        """
                        override val id: Int
                            get() = rawValue
                        """,
                        """
                        object Serializer : KSerializer<\(typeName.kotlinTypeName)> {
                            override val descriptor: SerialDescriptor =
                                PrimitiveSerialDescriptor("\(typeName.kotlinTypeName)", PrimitiveKind.INT)

                            override fun deserialize(decoder: Decoder): \(typeName.kotlinTypeName) =
                                \(typeName.kotlinTypeName).fromValue(decoder.decodeInt())

                            override fun serialize(encoder: Encoder, value: \(typeName.kotlinTypeName)) {
                                encoder.encodeInt(value.rawValue)
                            }
                        }
                        """,
                        """
                        companion object {
                            fun fromValue(value: Int): \(typeName.kotlinTypeName) =
                                entries.firstOrNull { it.rawValue == value }
                                    ?: throw IllegalArgumentException("Unknown \(typeName.kotlinTypeName) value: $value")
                        }
                        """
                    ],
                    additionalImports: [
                        "kotlinx.serialization.KSerializer",
                        "kotlinx.serialization.Serializable",
                        "kotlinx.serialization.descriptors.PrimitiveKind",
                        "kotlinx.serialization.descriptors.PrimitiveSerialDescriptor",
                        "kotlinx.serialization.descriptors.SerialDescriptor",
                        "kotlinx.serialization.encoding.Decoder",
                        "kotlinx.serialization.encoding.Encoder"
                    ],
                )
                .toString()

            case let .dynamicObject(
            typeName,
            objectTypePropertyName,
            objectDataPropertyName,
            alternateObjectDataPropertyName,
            objectTypes,
            supportGarbage,
            _,
            _,
            extraProperties,
        ):
                let selfEncoded = objectDataPropertyName == "__self__"
                let usesCustomSerializer = supportGarbage || selfEncoded || alternateObjectDataPropertyName != objectDataPropertyName
                let extraFields = extraProperties
                let supportsIdentity = objectTypes.allSatisfy { Self.supportsDynamicObjectIdentifiable($0.objectType) }
                let inheritance = supportsIdentity
                    ? " : Identifiable<String>"
                    : ""
                let cases = objectTypes.map { objectType -> any Node in
                    let name = objectType.objectTypeName.kotlinTypeName
                    let payloadType = KotlinTypeEmitter(dataType: objectType.objectType, options: options).typeName
                    let payloadParam = KotlinProperty(
                        name: "payload",
                        typeName: payloadType,
                        annotations: ["@SerialName(\(objectDataPropertyName.kotlinStringLiteral))"],
                    )
                    let extraParams = extraFields.map { property in
                        property.kotlinProperty(options: options)
                    }
                    let params = extraParams + [payloadParam]
                    return KotlinDataClass(
                        name: name,
                        properties: params,
                        annotations: [
                            "@SerialName(\(objectType.objectTypeRawName.kotlinStringLiteral))",
                            "@Serializable"
                        ],
                        interfaces: ["\(typeName.kotlinTypeName)()"],
                        includeGeneratedComment: false,
                    )
                }
                let annotations = usesCustomSerializer
                    ? ["@Serializable(with = \(typeName.kotlinTypeName).Serializer::class)"]
                    : ["@Serializable"]
                let decodeElement = selfEncoded ? "element.withNestedPayload()" : "element.withoutObjectType()"
                let encodeElement = selfEncoded ? "withFlattenedPayload" : "withObjectType"
                let serializerDecodeCases = objectTypes.map { objectType in
                    "\(objectType.objectTypeRawName.kotlinStringLiteral) -> jsonDecoder.json.decodeFromJsonElement(\(objectType.objectTypeName.kotlinTypeName).serializer(), \(decodeElement))"
                }
                let serializerEncodeCases = objectTypes.map { objectType in
                    "is \(objectType.objectTypeName.kotlinTypeName) -> jsonEncoder.encodeJsonElement(jsonEncoder.json.encodeToJsonElement(\(objectType.objectTypeName.kotlinTypeName).serializer(), value).\(encodeElement)(\(objectType.objectTypeRawName.kotlinStringLiteral)))"
                }
                let unknownObjectTypeCase = supportGarbage
                    ? "else -> Garbage(element)"
                    : "else -> throw SerializationException(\"Unknown \(typeName.kotlinTypeName) discriminator: $objectType\")"
                let nestedPayloadHelpers: String
                if selfEncoded {
                    let metadataKeys = ([objectTypePropertyName] + extraFields.map(\.rawName))
                        .map(\.kotlinStringLiteral)
                        .joined(separator: ", ")
                    nestedPayloadHelpers = Block {
                        "private val metadataKeys: Set<String> = setOf(\(metadataKeys))"
                        NewLine()
                        "private fun JsonElement.withNestedPayload(): JsonObject {"
                        Indentation {
                            "val source = jsonObject"
                            "val metadata = source.filterKeys { it in metadataKeys }"
                            "val payload = source.filterKeys { it !in metadataKeys }"
                            "return JsonObject(metadata.toMutableMap().apply {"
                            Indentation {
                                "put(\(objectDataPropertyName.kotlinStringLiteral), JsonObject(payload))"
                            }
                            "})"
                        }
                        "}"
                        NewLine()
                        "private fun JsonElement.withFlattenedPayload(objectType: String): JsonObject {"
                        Indentation {
                            "val source = jsonObject"
                            "val payload = source[\(objectDataPropertyName.kotlinStringLiteral)]?.jsonObject ?: JsonObject(emptyMap())"
                            "return JsonObject(source.toMutableMap().apply {"
                            Indentation {
                                "remove(\(objectDataPropertyName.kotlinStringLiteral))"
                                "putAll(payload)"
                                "put(\(objectTypePropertyName.kotlinStringLiteral), JsonPrimitive(objectType))"
                            }
                            "})"
                        }
                        "}"
                        NewLine()
                    }
                    .toString()
                } else {
                    nestedPayloadHelpers = Block {
                        "private fun JsonElement.withoutObjectType(): JsonObject ="
                        Indentation {
                            "JsonObject(jsonObject.toMutableMap().apply {"
                            Indentation {
                                "remove(\(objectTypePropertyName.kotlinStringLiteral))"
                                "val alternatePayload = remove(\(alternateObjectDataPropertyName.kotlinStringLiteral))"
                                "if (\(objectDataPropertyName.kotlinStringLiteral) !in this && alternatePayload != null) {"
                                Indentation {
                                    "put(\(objectDataPropertyName.kotlinStringLiteral), alternatePayload)"
                                }
                                "}"
                            }
                            "})"
                        }
                        NewLine()
                        "private fun JsonElement.withObjectType(objectType: String): JsonObject ="
                        Indentation {
                            "JsonObject(jsonObject.toMutableMap().apply {"
                            Indentation {
                                "put(\(objectTypePropertyName.kotlinStringLiteral), JsonPrimitive(objectType))"
                            }
                            "})"
                        }
                        NewLine()
                    }
                    .toString()
                }
                let serializerDeclaration = usesCustomSerializer
                    ? Block {
                        NewLine()
                        "object Serializer : KSerializer<\(typeName.kotlinTypeName)> {"
                        Indentation {
                            "override val descriptor: SerialDescriptor = buildClassSerialDescriptor(\(typeName.kotlinTypeName.kotlinStringLiteral))"
                            NewLine()
                            nestedPayloadHelpers
                            "override fun deserialize(decoder: Decoder): \(typeName.kotlinTypeName) {"
                            Indentation {
                                "val jsonDecoder = decoder as? JsonDecoder"
                                Indentation {
                                    "?: throw SerializationException(\"\(typeName.kotlinTypeName) can only be decoded from JSON\")"
                                }
                                "val element = jsonDecoder.decodeJsonElement()"
                                if supportGarbage {
                                    "return runCatching {"
                                    Indentation {
                                        "val objectType = element.jsonObject[\(objectTypePropertyName.kotlinStringLiteral)]?.jsonPrimitive?.contentOrNull"
                                        "when (objectType) {"
                                        Indentation {
                                            NodeList(serializerDecodeCases.map { "\($0)" as any Node })
                                            unknownObjectTypeCase
                                        }
                                        "}"
                                    }
                                    "}.getOrElse { Garbage(element) }"
                                } else {
                                    "val objectType = element.jsonObject[\(objectTypePropertyName.kotlinStringLiteral)]?.jsonPrimitive?.contentOrNull"
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
                            "override fun serialize(encoder: Encoder, value: \(typeName.kotlinTypeName)) {"
                            Indentation {
                                "val jsonEncoder = encoder as? JsonEncoder"
                                Indentation {
                                    "?: throw SerializationException(\"\(typeName.kotlinTypeName) can only be encoded to JSON\")"
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
                let idDeclaration = supportsIdentity
                    ? dynamicObjectIDDeclaration(
                        objectTypes: objectTypes,
                        supportGarbage: supportGarbage,
                    )
                    : ""
                return Block {
                    "// Generated code. Modify at your own risk."
                    "@OptIn(ExperimentalSerializationApi::class)"
                    NodeList(annotations.map { $0 as any Node })
                    "@JsonClassDiscriminator(\(objectTypePropertyName.kotlinStringLiteral))"
                    "sealed class \(typeName.kotlinTypeName)\(inheritance) {"
                    Indentation {
                        cases.map { $0.toString() }.joined(separator: "\n\n")
                        if supportGarbage {
                            NewLine()
                            "@Serializable"
                            "data class Garbage("
                            Indentation {
                                "val raw: JsonElement? = null,"
                            }
                            ") : \(typeName.kotlinTypeName)()"
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
            "is Garbage -> \("__garbage__".kotlinStringLiteral)"
        ] : []
        cases.append(
            contentsOf: objectTypes.map { objectType in
                let caseName = objectType.objectTypeName.kotlinTypeName
                let payloadID = Self.dynamicObjectPayloadIDExpression(objectType.objectType)
                return "is \(caseName) -> \("\(objectType.objectTypeRawName)_".kotlinStringLiteral) + \(payloadID).toString()"
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
        let patchableProperties = properties.filter(\.dataType.isKotlinPatchableValue)
        guard !patchableProperties.isEmpty else {
            return []
        }
        let resetLines = patchableProperties
            .map { "\($0.propertyName.kotlinPropertyName) = PatchableValue.Unmodified" }
            .joined(separator: "\n")
        let checks = patchableProperties
            .map { "\($0.propertyName.kotlinPropertyName) == PatchableValue.Unmodified" }
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

    var imports: Set<String> {
        switch dataType {
            case let .object(_, properties, _, _, _, _):
                let fields = properties.filter(\.publishedAsField)
                let usesPatchableValue = fields.contains { $0.dataType.isKotlinPatchableValue }
                let propertyImports = fields
                    .map { $0.kotlinProperty(options: options).imports }
                    .reduce(Set<String>()) { $0.union($1) }
                let nestedImports = fields
                    .flatMap { Self.nestedEmitters(for: $0.dataType, options: options, excludedTypeIDs: excludedNestedTypeIDs) }
                    .map(\.imports)
                    .reduce(Set<String>()) { $0.union($1) }
                return propertyImports
                    .union(nestedImports)
                    .union(["kotlinx.serialization.Serializable"])
                    .union(usesPatchableValue ? ["kotlinx.serialization.ExperimentalSerializationApi"] : [])

            case let .stringEnum(_, _, _, _, supportGarbage):
                let serializerImports: Set<String> = supportGarbage
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

            case let .dynamicObject(_, _, objectDataPropertyName, alternateObjectDataPropertyName, objectTypes, supportGarbage, _, _, extraProperties):
                let usesCustomSerializer = supportGarbage || objectDataPropertyName == "__self__" || alternateObjectDataPropertyName != objectDataPropertyName
                let extraFields = extraProperties
                let payloadImports = objectTypes
                    .map { KotlinTypeEmitter(dataType: $0.objectType, options: options).typeName.imports }
                    .reduce(Set<String>()) { $0.union($1) }
                let extraImports = extraFields
                    .map { $0.kotlinProperty(options: options).imports }
                    .reduce(Set<String>()) { $0.union($1) }
                let serializerImports: Set<String> = usesCustomSerializer
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
                return payloadImports
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
        options: KotlinGeneratorOptions,
        excludedTypeIDs: Set<UUID>,
    ) -> [KotlinModelEmitter] {
        if let typeName = dataType.typeName,
           options.mapping(for: typeName) != nil {
            return []
        }
        if let uuid = dataType.declaredKotlinTypeID,
           excludedTypeIDs.contains(uuid) {
            return []
        }

        switch dataType {
            case .object,
                 .stringEnum,
                 .intEnum,
                 .dynamicObject:
                return [KotlinModelEmitter(dataType: dataType, options: options, excludedNestedTypeIDs: excludedTypeIDs)]
            case let .array(type),
                 let .keyedByString(type, _):
                return nestedEmitters(for: type, options: options, excludedTypeIDs: excludedTypeIDs)
            default:
                return []
        }
    }

    private static func interfaces(
        protocols: [String],
        properties: [ApiModelProperty],
        options: KotlinGeneratorOptions,
    ) -> [String] {
        guard protocols.contains("Identifiable"),
              let id = properties.first(where: { $0.propertyName.kotlinPropertyName == "id" }) else {
            return []
        }
        var typeName = id.dataType.kotlinTypeDeclaration(options: options)
        if !id.required, !typeName.hasSuffix("?") {
            typeName += "?"
        }
        return ["Identifiable<\(typeName)>"]
    }
}
