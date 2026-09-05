import Foundation
import GeneratorBuilder
import GeneratorModels
@testable import KotlinAndroidApiGenerator
import Testing

@Suite(.serialized) struct KotlinAndroidApiGeneratorTests {
    @Test func dynamicObjectsUseSerializationOptIn() throws {
        let payload = ApiTypeSchema.object(typeName: "Payload", properties: [.string("value")])
        let dynamic = ApiTypeSchema.dynamicObject(
            typeName: "EventEnvelope",
            objectTypePropertyName: "kind",
            objectTypes: [
                (
                    objectTypeName: "Message",
                    objectTypeRawName: "message",
                    objectType: payload.asRef
                )
            ]
        )
        let files = try KotlinAndroidApiPackageGenerator(
            package: testPackage(response: dynamic.asRef, references: [dynamic, payload])
        )
        .generatedFiles()
        let output = files.map(\.contents).joined(separator: "\n")

        #expect(output.contains("import kotlinx.serialization.ExperimentalSerializationApi"))
        #expect(output.contains("@OptIn(ExperimentalSerializationApi::class)"))
        #expect(output.contains("@JsonClassDiscriminator(\"kind\")"))
        #expect(output.contains("@SerialName(\"extras\")"))
    }

    @Test func stringEnumGarbageUsesCustomSerializerForUnknownJsonValues() throws {
        let visibility = ApiTypeSchema.stringEnum(
            typeName: "Visibility",
            values: [
                (name: "Public", rawName: "public"),
                (name: "Private", rawName: "private")
            ],
            supportGarbage: true
        )
        let files = try KotlinAndroidApiPackageGenerator(
            package: testPackage(response: visibility.asRef, references: [visibility])
        )
        .generatedFiles()
        let model = try #require(files.first { $0.relativePath.hasSuffix("/Visibility.kt") })

        #expect(model.contents.contains("@Serializable(with = Visibility.Serializer::class)"))
        #expect(model.contents.contains("object Serializer : KSerializer<Visibility>"))
        #expect(model.contents.contains("import com.example.api.Identifiable"))
        #expect(model.contents.contains("enum class Visibility(\n    val rawValue: String,\n) : Identifiable<String>"))
        #expect(model.contents.contains("override val id: String\n        get() = rawValue"))
        #expect(model.contents.contains("runCatching {"))
        #expect(model.contents.contains("Visibility.fromValue(decoder.decodeString())"))
        #expect(model.contents.contains("}.getOrElse { Garbage }"))
        #expect(model.contents.contains("encoder.encodeString(value.rawValue)"))
    }

    @Test func dynamicObjectGarbageUsesCustomSerializerForUnknownDiscriminator() throws {
        let payload = ApiTypeSchema.object(
            typeName: "Payload",
            properties: [
                .int64("id"),
                .string("value")
            ],
            protocols: ["Identifiable"]
        )
        let dynamic = ApiTypeSchema.dynamicObject(
            typeName: "EventEnvelope",
            objectTypePropertyName: "kind",
            objectDataPropertyName: "payload",
            alternateObjectDataPropertyName: "data",
            objectTypes: [
                (
                    objectTypeName: "Message",
                    objectTypeRawName: "message",
                    objectType: payload.asRef
                )
            ],
            supportGarbage: true
        )
        let files = try KotlinAndroidApiPackageGenerator(
            package: testPackage(response: dynamic.asRef, references: [dynamic, payload])
        )
        .generatedFiles()
        let model = try #require(files.first { $0.relativePath.hasSuffix("/EventEnvelope.kt") })

        #expect(model.contents.contains("@Serializable(with = EventEnvelope.Serializer::class)"))
        #expect(model.contents.contains("object Serializer : KSerializer<EventEnvelope>"))
        #expect(model.contents.contains("val objectType = element.jsonObject[\"kind\"]?.jsonPrimitive?.contentOrNull"))
        #expect(model.contents.contains("\"message\" -> jsonDecoder.json.decodeFromJsonElement(Message.serializer(), element.withoutObjectType())"))
        #expect(model.contents.contains("put(\"kind\", JsonPrimitive(objectType))"))
        #expect(model.contents.contains("val alternatePayload = remove(\"data\")"))
        #expect(model.contents.contains("if (\"payload\" !in this && alternatePayload != null)"))
        #expect(model.contents.contains(".withObjectType(\"message\")"))
        #expect(model.contents.contains("else -> Garbage(element)"))
        #expect(model.contents.contains("return runCatching {"))
        #expect(model.contents.contains("}.getOrElse { Garbage(element) }"))
        #expect(model.contents.contains("is Garbage -> jsonEncoder.encodeJsonElement(value.raw ?: JsonObject(emptyMap()))"))
        #expect(model.contents.contains("import com.example.api.Identifiable"))
        #expect(model.contents.contains("sealed class EventEnvelope : Identifiable<String>"))
        #expect(model.contents.contains("override val id: String"))
        #expect(model.contents.contains("is Garbage -> \"__garbage__\""))
        #expect(model.contents.contains("is Message -> \"message_\" + payload.id.toString()"))
        #expect(model.contents.contains("import kotlinx.serialization.json.decodeFromJsonElement"))
        #expect(model.contents.contains("import kotlinx.serialization.json.encodeToJsonElement"))
    }

    @Test func dynamicObjectAlternatePayloadUsesCustomSerializerWithoutGarbage() throws {
        let payload = ApiTypeSchema.object(typeName: "Payload", properties: [.string("value")])
        let dynamic = ApiTypeSchema.dynamicObject(
            typeName: "EventEnvelope",
            objectTypePropertyName: "kind",
            objectDataPropertyName: "payload",
            alternateObjectDataPropertyName: "data",
            objectTypes: [
                (
                    objectTypeName: "Message",
                    objectTypeRawName: "message",
                    objectType: payload.asRef
                )
            ],
            extraProperties: [
                .string("internal", propertyName: "internalValue").unpublished
            ]
        )
        let files = try KotlinAndroidApiPackageGenerator(
            package: testPackage(response: dynamic.asRef, references: [dynamic, payload])
        )
        .generatedFiles()
        let model = try #require(files.first { $0.relativePath.hasSuffix("/EventEnvelope.kt") })

        #expect(model.contents.contains("@Serializable(with = EventEnvelope.Serializer::class)"))
        #expect(model.contents.contains("val alternatePayload = remove(\"data\")"))
        #expect(model.contents.contains("if (\"payload\" !in this && alternatePayload != null)"))
        #expect(model.contents.contains("else -> throw SerializationException(\"Unknown EventEnvelope discriminator: $objectType\")"))
        #expect(model.contents.contains("@SerialName(\"internal\")\n        val internalValue: String"))
        let extraParameter = try #require(model.contents.range(of: "val internalValue: String"))
        let payloadParameter = try #require(model.contents.range(of: "val payload:"))
        #expect(extraParameter.lowerBound < payloadParameter.lowerBound)

    }

    @Test func intEnumUsesRawValueSerializerForJsonValues() throws {
        let score = ApiTypeSchema.intEnum(
            typeName: "Score",
            values: [
                (name: "Low", rawValue: 10),
                (name: "High", rawValue: 100)
            ]
        )
        let files = try KotlinAndroidApiPackageGenerator(
            package: testPackage(response: score.asRef, references: [score])
        )
        .generatedFiles()
        let model = try #require(files.first { $0.relativePath.hasSuffix("/Score.kt") })

        #expect(model.contents.contains("@Serializable(with = Score.Serializer::class)"))
        #expect(model.contents.contains("object Serializer : KSerializer<Score>"))
        #expect(model.contents.contains("import com.example.api.Identifiable"))
        #expect(model.contents.contains("enum class Score(\n    val rawValue: Int,\n) : Identifiable<Int>"))
        #expect(model.contents.contains("override val id: Int\n        get() = rawValue"))
        #expect(model.contents.contains("PrimitiveSerialDescriptor(\"Score\", PrimitiveKind.INT)"))
        #expect(model.contents.contains("Score.fromValue(decoder.decodeInt())"))
        #expect(model.contents.contains("encoder.encodeInt(value.rawValue)"))
    }

    @Test func dynamicObjectSelfPayloadUsesFlatteningSerializer() throws {
        let payload = ApiTypeSchema.object(typeName: "Payload", properties: [.string("value")])
        let dynamic = ApiTypeSchema.dynamicObject(
            typeName: "EventEnvelope",
            objectTypePropertyName: "kind",
            objectDataPropertyName: "__self__",
            objectTypes: [
                (
                    objectTypeName: "Message",
                    objectTypeRawName: "message",
                    objectType: payload.asRef
                )
            ],
            extraProperties: [
                .string("trace_id", propertyName: "traceId", required: false)
            ]
        )
        let files = try KotlinAndroidApiPackageGenerator(
            package: testPackage(response: dynamic.asRef, references: [dynamic, payload])
        )
        .generatedFiles()
        let model = try #require(files.first { $0.relativePath.hasSuffix("/EventEnvelope.kt") })

        #expect(model.contents.contains("@Serializable(with = EventEnvelope.Serializer::class)"))
        #expect(model.contents.contains("@SerialName(\"__self__\")"))
        #expect(model.contents.contains("private val metadataKeys: Set<String> = setOf(\"kind\", \"trace_id\")"))
        #expect(model.contents.contains("@SerialName(\"trace_id\")\n        val traceId: String? = null"))
        #expect(model.contents.contains("put(\"__self__\", JsonObject(payload))"))
        #expect(model.contents.contains("\"message\" -> jsonDecoder.json.decodeFromJsonElement(Message.serializer(), element.withNestedPayload())"))
        #expect(model.contents.contains("remove(\"__self__\")"))
        #expect(model.contents.contains("putAll(payload)"))
        #expect(model.contents.contains(".withFlattenedPayload(\"message\")"))
        #expect(model.contents.contains("else -> throw SerializationException(\"Unknown EventEnvelope discriminator: $objectType\")"))
        #expect(!model.contents.contains("is Garbage ->"))
    }

    @Test func generatedKotlinAndroidOmitsUnpublishedObjectFields() throws {
        let hiddenExternal = ApiTypeSchema.reference(typeName: "HiddenExternal", strict: false)
        let audit = ApiTypeSchema.object(
            typeName: "Audit",
            properties: [
                .string("public_note", propertyName: "publicNote"),
                ApiModelProperty(rawName: "internal_note", propertyName: "internalNote", dataType: hiddenExternal).unpublished
            ]
        )
        let files = try KotlinAndroidApiPackageGenerator(package: testPackage(response: audit.asRef, references: [audit])).generatedFiles()
        let model = try #require(files.first {
            $0.relativePath == "generated-api/src/main/kotlin/com/example/api/admin/users/models/Audit.kt"
        })

        #expect(model.contents.contains("val publicNote: String"))
        #expect(!model.contents.contains("internalNote"))
        #expect(!model.contents.contains("@SerialName(\"internal_note\")"))
        #expect(!model.contents.contains("HiddenExternal"))
    }

    @Test func generatedKotlinAndroidModelsUseContentEqualityForBinaryFields() throws {
        let document = ApiTypeSchema.object(
            typeName: "Document",
            properties: [
                .string("id"),
                .binary("payload"),
                .binary("class").optional
            ]
        )
        let files = try KotlinAndroidApiPackageGenerator(
            package: testPackage(response: document.asRef, references: [document])
        )
        .generatedFiles()
        let model = try #require(files.first {
            $0.relativePath == "generated-api/src/main/kotlin/com/example/api/admin/users/models/Document.kt"
        })

        #expect(model.contents.contains("override fun equals(other: Any?): Boolean"))
        #expect(model.contents.contains("@Serializable(with = ByteArrayBase64Serializer::class)"))
        #expect(model.contents.contains("import com.example.api.ByteArrayBase64Serializer"))
        #expect(model.contents.contains("if (id != other.id) return false"))
        #expect(model.contents.contains("if (!payload.contentEquals(other.payload)) return false"))
        #expect(model.contents.contains("val otherByteArray2 = other.`class`"))
        #expect(!model.contents.contains("val other`class`"))
        #expect(model.contents.contains("var result = id.hashCode()"))
        #expect(model.contents.contains("result = 31 * result + payload.contentHashCode()"))
    }

    @Test func nullableByteArrayEscapedPropertyUsesValidEqualityExpression() throws {
        let blob = ApiTypeSchema.object(
            typeName: "Blob",
            properties: [
                .binary("class", propertyName: "class", required: false)
            ]
        )
        let files = try KotlinAndroidApiPackageGenerator(package: testPackage(response: blob.asRef, references: [blob])).generatedFiles()
        let model = try #require(files.first {
            $0.relativePath == "generated-api/src/main/kotlin/com/example/api/admin/users/models/Blob.kt"
        })

        #expect(model.contents.contains("val `class`: ByteArray? = null"))
        #expect(model.contents.contains("val otherByteArray0 = other.`class`"))
        #expect(model.contents.contains("if (`class` == null) {"))
        #expect(model.contents.contains("if (otherByteArray0 != null) return false"))
        #expect(model.contents.contains("} else if (otherByteArray0 == null || !`class`.contentEquals(otherByteArray0)) return false"))
        #expect(model.contents.contains("@Serializable(with = ByteArrayBase64Serializer::class)"))
        #expect(!model.contents.contains("val other`Class`"))
    }

    @Test func generatedKotlinAndroidIdentifiableUsesNullableIDTypeWhenIDIsOptional() throws {
        let user = ApiTypeSchema.object(
            typeName: "User",
            properties: [
                .int64("id", required: false),
                .string("name")
            ],
            protocols: ["Identifiable"]
        )
        let files = try KotlinAndroidApiPackageGenerator(
            package: testPackage(response: user.asRef, references: [user])
        )
        .generatedFiles()
        let model = try #require(files.first {
            $0.relativePath == "generated-api/src/main/kotlin/com/example/api/admin/users/models/User.kt"
        })

        #expect(model.contents.contains("override val id: Long? = null"))
        #expect(model.contents.contains(") : Identifiable<Long?>"))
    }

    @Test func generatedKotlinAndroidSanitizesPackageSegmentsWithLeadingDigits() throws {
        let user = ApiTypeSchema.object(
            typeName: "User",
            properties: [.string("name")]
        )
        let operation = ApiOperation.get(
            name: "get",
            path: .relative("/users"),
            security: .unsecured,
            response: user.asRef
        )
        let package = ApiPackage(
            name: "Test",
            targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true),
            modules: [
                ApiModule(name: "2FA", definitions: [
                    ApiService(name: "Users", operations: [operation], references: [user])
                ])
            ],
            referencedModules: [],
            references: [],
            commonReferences: [],
            imports: []
        )

        let files = try KotlinAndroidApiPackageGenerator(package: package).generatedFiles()
        let service = try #require(files.first {
            $0.relativePath == "generated-api/src/main/kotlin/com/example/api/_2fa/users/_2FAUsersApi.kt"
        })

        #expect(service.contents.contains("package com.example.api._2fa.users"))
        #expect(service.contents.contains("import com.example.api._2fa.users.models.User"))
    }

    @Test func generatedKotlinAndroidSanitizesKeywordPackageSegments() throws {
        let operation = ApiOperation.get(
            name: "get",
            path: .relative("/users"),
            security: .unsecured
        )
        let package = ApiPackage(
            name: "Test",
            targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true),
            modules: [
                ApiModule(name: "Class", definitions: [
                    ApiService(name: "Object", operations: [operation])
                ])
            ],
            referencedModules: [],
            references: [],
            commonReferences: [],
            imports: []
        )

        let files = try KotlinAndroidApiPackageGenerator(package: package).generatedFiles()
        let service = try #require(files.first {
            $0.relativePath == "generated-api/src/main/kotlin/com/example/api/_class_/_object_/ClassObjectApi.kt"
        })

        #expect(service.contents.contains("package com.example.api._class_._object_"))
    }

    @Test func generatedKotlinAndroidReusesSharedModelDeclarations() throws {
        let rootStatus = ApiTypeSchema.stringEnum(
            typeName: "RootStatus",
            values: [
                (name: "Enabled", rawName: "enabled"),
                (name: "Disabled", rawName: "disabled")
            ]
        )
        let moduleStatus = ApiTypeSchema.stringEnum(
            typeName: "ModuleStatus",
            values: [
                (name: "Open", rawName: "open"),
                (name: "Closed", rawName: "closed")
            ]
        )
        let rootStamp = ApiTypeSchema.object(
            typeName: "RootStamp",
            properties: [
                .date("created_at")
            ]
        )
        let item = ApiTypeSchema.object(
            typeName: "Item",
            properties: [
                .ref("root_status", propertyName: "rootStatus", of: rootStatus),
                .ref("module_status", propertyName: "moduleStatus", of: moduleStatus),
                .object("root_stamp", propertyName: "rootStamp", of: rootStamp)
            ]
        )
        let operation = ApiOperation.get(
            name: "list",
            path: .relative("/items"),
            security: .unsecured,
            parameters: [
                .query("module_status", .stringEnumValue(type: moduleStatus.asRef), propertyName: "moduleStatus").optional
            ],
            response: .array(item.asRef)
        )
        let package = ApiPackage(
            name: "Test",
            targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true),
            modules: [
                ApiModule(
                    name: "Catalog",
                    definitions: [
                        ApiService(
                            name: "Items",
                            operations: [operation],
                            references: [item, rootStatus, moduleStatus, rootStamp]
                        )
                    ],
                    references: [moduleStatus]
                )
            ],
            referencedModules: [],
            references: [rootStatus, rootStamp],
            commonReferences: [],
            imports: []
        )
        let files = try KotlinAndroidApiPackageGenerator(package: package).generatedFiles()
        let paths = Set(files.map(\.relativePath))

        #expect(files.count == paths.count)
        #expect(paths.contains("generated-api/src/main/kotlin/com/example/api/RootStatus.kt"))
        #expect(paths.contains("generated-api/src/main/kotlin/com/example/api/RootStamp.kt"))
        #expect(paths.contains("generated-api/src/main/kotlin/com/example/api/catalog/shared/ModuleStatus.kt"))
        #expect(paths.contains("generated-api/src/main/kotlin/com/example/api/catalog/items/models/Item.kt"))
        #expect(!paths.contains("generated-api/src/main/kotlin/com/example/api/catalog/items/models/RootStatus.kt"))
        #expect(!paths.contains("generated-api/src/main/kotlin/com/example/api/catalog/items/models/RootStamp.kt"))
        #expect(!paths.contains("generated-api/src/main/kotlin/com/example/api/catalog/items/models/ModuleStatus.kt"))

        let model = try #require(files.first {
            $0.relativePath == "generated-api/src/main/kotlin/com/example/api/catalog/items/models/Item.kt"
        })
        #expect(model.contents.contains("import com.example.api.RootStatus"))
        #expect(model.contents.contains("import com.example.api.RootStamp"))
        #expect(model.contents.contains("import com.example.api.catalog.shared.ModuleStatus"))
        #expect(!model.contents.contains("data class RootStamp"))

        let operationFile = try #require(files.first {
            $0.relativePath == "generated-api/src/main/kotlin/com/example/api/catalog/items/ListOperation.kt"
        })
        #expect(operationFile.contents.contains("import com.example.api.catalog.shared.ModuleStatus"))
    }

    @Test func generatedKotlinAndroidSkipsMappedModelDeclarations() throws {
        let mappedThing = ApiTypeSchema.object(
            typeName: "MappedThing",
            properties: [
                .string("name")
            ]
        )
        let operation = ApiOperation.get(
            name: "get",
            path: .relative("/mapped/{id}"),
            security: .unsecured,
            parameters: [
                .path("id", .int64())
            ],
            response: mappedThing.asRef
        )
        let package = ApiPackage(
            name: "Test",
            targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true),
            modules: [
                ApiModule(name: "Catalog", definitions: [
                    ApiService(name: "Mapped", operations: [operation], references: [mappedThing])
                ])
            ],
            referencedModules: [],
            references: [mappedThing],
            commonReferences: [],
            imports: []
        )
        let options = KotlinAndroidGeneratorOptions(typeMappings: KotlinAndroidTypeMapping.defaultMappings + [
            KotlinAndroidTypeMapping(
                apiTypeName: "MappedThing",
                kotlinType: "ExternalThing",
                imports: ["com.example.shared.ExternalThing"]
            )
        ])
        let files = try KotlinAndroidApiPackageGenerator(package: package, options: options).generatedFiles()
        let paths = Set(files.map(\.relativePath))

        #expect(!paths.contains("generated-api/src/main/kotlin/com/example/api/MappedThing.kt"))
        #expect(!paths.contains("generated-api/src/main/kotlin/com/example/api/catalog/mapped/models/MappedThing.kt"))

        let service = try #require(files.first {
            $0.relativePath == "generated-api/src/main/kotlin/com/example/api/catalog/mapped/CatalogMappedApi.kt"
        })
        #expect(service.contents.contains("import com.example.shared.ExternalThing"))
        #expect(service.contents.contains("ApiOperationResult<ExternalThing>"))
    }

    @Test func generatedKotlinAndroidEmptyObjectUsesRegularClass() throws {
        let empty = ApiTypeSchema.object(typeName: "Empty", properties: [])
        let files = try KotlinAndroidApiPackageGenerator(
            package: testPackage(response: empty.asRef, references: [empty])
        )
        .generatedFiles()
        let model = try #require(files.first {
            $0.relativePath == "generated-api/src/main/kotlin/com/example/api/admin/users/models/Empty.kt"
        })

        #expect(model.contents.contains("class Empty"))
        #expect(!model.contents.contains("data class Empty()"))
    }

    @Test func generatedKotlinAndroidPatchableFieldsAreNonNullableWithUnmodifiedDefault() throws {
        let patch = ApiTypeSchema.object(typeName: "Patch", properties: [
            ApiModelProperty(rawName: "name", propertyName: "name", dataType: ApiTypeSchema.string().asPatchable),
            ApiModelProperty(rawName: "nickname", propertyName: "nickname", dataType: ApiTypeSchema.string().asPatchable, required: false)
        ])
        let files = try KotlinAndroidApiPackageGenerator(
            package: testPackage(response: patch.asRef, references: [patch])
        )
        .generatedFiles()
        let model = try #require(files.first {
            $0.relativePath == "generated-api/src/main/kotlin/com/example/api/admin/users/models/Patch.kt"
        })
        let runtime = try #require(files.first {
            $0.relativePath == "generated-api/src/main/kotlin/com/example/api/ApiRuntime.kt"
        })

        #expect(model.contents.contains("var name: PatchableValue<String> = PatchableValue.Unmodified"))
        #expect(model.contents.contains("var nickname: PatchableValue<String> = PatchableValue.Unmodified"))
        #expect(model.contents.contains("import kotlinx.serialization.EncodeDefault"))
        #expect(model.contents.contains("import kotlinx.serialization.ExperimentalSerializationApi"))
        #expect(model.contents.contains("@OptIn(ExperimentalSerializationApi::class)\n@Serializable"))
        #expect(model.contents.contains("@EncodeDefault(EncodeDefault.Mode.NEVER)\n    var name: PatchableValue<String> = PatchableValue.Unmodified"))
        #expect(model.contents.contains("@EncodeDefault(EncodeDefault.Mode.NEVER)\n    var nickname: PatchableValue<String> = PatchableValue.Unmodified"))
        #expect(!model.contents.contains("PatchableValue<String>?"))
        #expect(model.contents.contains("fun resetPatchableFields()"))
        #expect(model.contents.contains("name = PatchableValue.Unmodified"))
        #expect(model.contents.contains("nickname = PatchableValue.Unmodified"))
        #expect(model.contents.contains("fun isUnmodified(): Boolean ="))
        #expect(model.contents.contains("name == PatchableValue.Unmodified &&\n        nickname == PatchableValue.Unmodified"))
        #expect(runtime.contents.contains("@Serializable(with = PatchableValueSerializer::class)"))
        #expect(runtime.contents.contains("class PatchableValueSerializer<T>"))
        #expect(runtime.contents.contains("PatchableValue.Modified(null)"))
        #expect(runtime.contents.contains("jsonDecoder.decodeNull()"))
        #expect(runtime.contents.contains("jsonEncoder.encodeNull()"))
        #expect(!runtime.contents.contains("decodeJsonElement()"))
        #expect(!runtime.contents.contains("encodeToJsonElement(valueSerializer"))
        #expect(runtime.contents.contains("jsonDecoder.decodeSerializableValue(valueSerializer)"))
    }

    @Test func generatedKotlinAndroidRecognizesCommonReferencesWithoutEmittingThem() throws {
        let shared = ApiTypeSchema.object(
            typeName: "SharedThing",
            properties: [.string("name")]
        )
        let operation = ApiOperation.get(
            name: "lookup",
            path: .relative("/lookup"),
            security: .unsecured,
            response: shared.asRef
        )
        let package = ApiPackage(
            name: "Test",
            targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true),
            modules: [
                ApiModule(name: "Admin", definitions: [
                    ApiService(name: "Users", operations: [operation])
                ])
            ],
            referencedModules: [],
            references: [],
            commonReferences: [shared],
            imports: []
        )

        let files = try KotlinAndroidApiPackageGenerator(package: package).generatedFiles()
        let paths = Set(files.map(\.relativePath))
        let service = try #require(files.first {
            $0.relativePath == "generated-api/src/main/kotlin/com/example/api/admin/users/AdminUsersApi.kt"
        })

        #expect(!paths.contains("generated-api/src/main/kotlin/com/example/api/SharedThing.kt"))
        #expect(service.contents.contains("import com.example.api.SharedThing"))
        #expect(service.contents.contains("ApiOperationResult<SharedThing>"))
    }

    @Test func generatedKotlinAndroidValidationIgnoresReferencedModuleExternalTypes() throws {
        let external = ApiTypeSchema.reference(typeName: "ExternalThing", strict: false)
        let referencedOperation = ApiOperation.get(
            name: "remote",
            path: .relative("/remote"),
            security: .unsecured,
            response: external,
            acceptableStatuses: []
        )
        let duplicateReferencedOperation = ApiOperation.get(
            name: "remote",
            path: .relative("/remote-duplicate"),
            security: .unsecured
        )
        let package = ApiPackage(
            name: "Test",
            targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true),
            modules: [
                ApiModule(name: "Local", definitions: [
                    ApiService(name: "Users", operations: [
                        ApiOperation.get(name: "local", path: .relative("/local"), security: .unsecured)
                    ])
                ])
            ],
            referencedModules: [
                ApiModule(name: "Parent", definitions: [
                    ApiService(name: "Accounts", operations: [referencedOperation, duplicateReferencedOperation])
                ])
            ],
            references: [],
            commonReferences: [],
            imports: [],
            generateApiModules: false
        )

        let files = try KotlinAndroidApiPackageGenerator(package: package).generatedFiles()
        let paths = Set(files.map(\.relativePath))

        #expect(paths.contains("generated-api/src/main/kotlin/com/example/api/local/users/LocalUsersApi.kt"))
        #expect(!paths.contains("generated-api/src/main/kotlin/com/example/api/parent/accounts/RemoteOperation.kt"))
    }

    @Test func generatedKotlinAndroidMappedEnumModelDefaultDoesNotUseOriginalType() throws {
        let visibility = ApiTypeSchema.stringEnum(
            typeName: "Visibility",
            values: [
                (name: "Public", rawName: "public"),
                (name: "Private", rawName: "private")
            ],
            initialValue: "Public"
        )
        let container = ApiTypeSchema.object(
            typeName: "Container",
            properties: [.ref("visibility", of: visibility)]
        )
        let files = try KotlinAndroidApiPackageGenerator(
            package: testPackage(response: container.asRef, references: [container, visibility]),
            options: KotlinAndroidGeneratorOptions(typeMappings: KotlinAndroidTypeMapping.defaultMappings + [
                KotlinAndroidTypeMapping(
                    apiTypeName: "Visibility",
                    kotlinType: "ExternalVisibility",
                    imports: ["com.example.shared.ExternalVisibility"]
                )
            ])
        )
        .generatedFiles()
        let model = try #require(files.first {
            $0.relativePath == "generated-api/src/main/kotlin/com/example/api/admin/users/models/Container.kt"
        })

        #expect(model.contents.contains("import com.example.shared.ExternalVisibility"))
        #expect(model.contents.contains("val visibility: ExternalVisibility"))
        #expect(!model.contents.contains("Visibility.Public"))
    }

    @Test func generatedKotlinAndroidMappedObjectIgnoresInternalExternalReferences() throws {
        let mappedThing = ApiTypeSchema.object(
            typeName: "MappedThing",
            properties: [
                .object("nested", of: .reference(typeName: "UnmappedNested", strict: false))
            ]
        )
        let operation = ApiOperation.get(
            name: "get",
            path: .relative("/mapped"),
            security: .unsecured,
            response: mappedThing.asRef
        )
        let package = ApiPackage(
            name: "Test",
            targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true),
            modules: [
                ApiModule(name: "Catalog", definitions: [
                    ApiService(name: "Mapped", operations: [operation], references: [mappedThing])
                ])
            ],
            referencedModules: [],
            references: [],
            commonReferences: [],
            imports: []
        )
        let options = KotlinAndroidGeneratorOptions(typeMappings: KotlinAndroidTypeMapping.defaultMappings + [
            KotlinAndroidTypeMapping(
                apiTypeName: "MappedThing",
                kotlinType: "ExternalThing",
                imports: ["com.example.shared.ExternalThing"]
            )
        ])

        #expect(throws: Never.self) {
            try KotlinAndroidApiPackageGenerator(package: package, options: options).generatedFiles()
        }
    }

    @Test func writeRemovesStaleManagedKotlinAndroidSources() throws {
        let sharedStatus = ApiTypeSchema.stringEnum(
            typeName: "SharedStatus",
            values: [
                (name: "Ready", rawName: "ready"),
                (name: "Done", rawName: "done")
            ]
        )
        let item = ApiTypeSchema.object(
            typeName: "Item",
            properties: [
                .ref("status", of: sharedStatus)
            ]
        )
        let operation = ApiOperation.get(
            name: "get",
            path: .relative("/items/{id}"),
            security: .unsecured,
            parameters: [
                .path("id", .int64())
            ],
            response: item.asRef
        )
        let targetDirURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let package = ApiPackage(
            name: "Test",
            targetDirUrl: targetDirURL,
            modules: [
                ApiModule(name: "Catalog", definitions: [
                    ApiService(name: "Items", operations: [operation], references: [item, sharedStatus])
                ])
            ],
            referencedModules: [],
            references: [sharedStatus],
            commonReferences: [],
            imports: []
        )
        let staleRelativePath = "generated-api/src/main/kotlin/com/example/api/catalog/items/models/SharedStatus.kt"
        let sharedRelativePath = "generated-api/src/main/kotlin/com/example/api/SharedStatus.kt"
        let userRelativePath = "generated-api/src/main/kotlin/com/example/api/catalog/items/models/UserOwned.kt"
        func fileURL(relativePath: String) -> URL {
            relativePath.split(separator: "/").reduce(targetDirURL) { partialURL, component in
                partialURL.appendingPathComponent(String(component))
            }
        }

        try KotlinAndroidGeneratedTextFile(
            relativePath: staleRelativePath,
            contents: """
            // Generated code. Do not edit.
            package com.example.api.catalog.items.models

            enum class SharedStatus
            """
        )
        .write(to: targetDirURL)
        let userURL = fileURL(relativePath: userRelativePath)
        try FileManager.default.createDirectory(at: userURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try """
        package com.example.api.catalog.items.models

        // Generated code. Do not edit.
        class UserOwned
        """.write(to: userURL, atomically: true, encoding: .utf8)

        try KotlinAndroidApiPackageGenerator(package: package).write()

        #expect(!FileManager.default.fileExists(atPath: fileURL(relativePath: staleRelativePath).path))
        #expect(FileManager.default.fileExists(atPath: fileURL(relativePath: sharedRelativePath).path))
        #expect(FileManager.default.fileExists(atPath: userURL.path))
    }

    @Test func writeRefusesUserOwnedEditorConfig() throws {
        let targetDirURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: targetDirURL, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: targetDirURL) }

        try "root = true\n".write(to: targetDirURL.appendingPathComponent(".editorconfig"), atomically: true, encoding: .utf8)
        let file = try #require(
            KotlinAndroidApiPackageGenerator(package: testPackage())
                .generatedFiles()
                .first { $0.relativePath == ".editorconfig" }
        )

        #expect(throws: KotlinAndroidGeneratedTextFileError.refusingToOverwriteUserFile(".editorconfig")) {
            try file.write(to: targetDirURL)
        }
    }

    @Test func generatedFileWriteRejectsSymlinkEscape() throws {
        let targetDirURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let outsideURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: targetDirURL, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: outsideURL, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: targetDirURL)
            try? FileManager.default.removeItem(at: outsideURL)
        }

        try FileManager.default.createSymbolicLink(
            at: targetDirURL.appendingPathComponent("linked"),
            withDestinationURL: outsideURL
        )
        let file = KotlinAndroidGeneratedTextFile(relativePath: "linked/escaped.kt", contents: "class Escaped")

        #expect(throws: KotlinAndroidGeneratedTextFileError.invalidRelativePath("linked/escaped.kt")) {
            try file.write(to: targetDirURL)
        }
        #expect(!FileManager.default.fileExists(atPath: outsideURL.appendingPathComponent("escaped.kt").path))
    }

    @Test func mappedExternalImportsDoNotLeakSwiftImports() throws {
        let external = ApiTypeSchema.reference(typeName: "DateInterval", strict: false, imports: ["Foundation"])
        let files = try KotlinAndroidApiPackageGenerator(package: testPackage(response: external)).generatedFiles()
        let service = try #require(files.first {
            $0.relativePath == "generated-api/src/main/kotlin/com/example/api/admin/users/AdminUsersApi.kt"
        })

        #expect(service.contents.contains("import com.example.api.DateInterval"))
        #expect(!service.contents.contains("import Foundation"))
    }

    @Test func operationExtraImportsDoNotLeakSwiftImports() throws {
        let operation = ApiOperation.get(
            name: "search",
            path: .relative("/search"),
            security: .unsecured,
            extraImports: ["UniformTypeIdentifiers"]
        )
        let files = try KotlinAndroidApiPackageGenerator(package: testPackage(operations: [operation], references: [])).generatedFiles()
        let operationFile = try #require(files.first {
            $0.relativePath == "generated-api/src/main/kotlin/com/example/api/admin/users/SearchOperation.kt"
        })

        #expect(!operationFile.contents.contains("import UniformTypeIdentifiers"))
    }

    @Test func multipartPartSettersMustBeUnique() {
        let operation = ApiOperation.postMultipart(
            name: "upload",
            path: .relative("/upload"),
            security: .unsecured,
            multiParts: ["file-name", "file_name"]
        )

        #expect(throws: KotlinAndroidGeneratorError.invalidOperation(
            operationName: operation.name,
            reason: "has multipart part names that generate duplicate setters"
        )) {
            try KotlinAndroidApiPackageGenerator(package: testPackage(operations: [operation], references: [])).generatedFiles()
        }
    }

    @Test func multipartPartListMustNotBeEmpty() {
        let operation = ApiOperation.postMultipart(
            name: "upload",
            path: .relative("/upload"),
            security: .unsecured,
            multiParts: []
        )

        #expect(throws: KotlinAndroidGeneratorError.invalidOperation(
            operationName: operation.name,
            reason: "has no multipart part names"
        )) {
            try KotlinAndroidApiPackageGenerator(package: testPackage(operations: [operation], references: [])).generatedFiles()
        }
    }

    @Test func invalidBasePackageFailsValidation() {
        for packageName in ["1.invalid", ".com", "com.", "com..example"] {
            let options = KotlinAndroidGeneratorOptions(basePackage: packageName)

            #expect(throws: KotlinAndroidGeneratorError.invalidBasePackage(packageName)) {
                try KotlinAndroidApiPackageGenerator(package: testPackage(), options: options).generatedFiles()
            }
        }
    }

    @Test func invalidGradleModuleNameFailsValidation() {
        for moduleName in [".", "generated api", "generated/api", "generated:api", "generated\napi"] {
            let options = KotlinAndroidGeneratorOptions(gradle: KotlinAndroidGradleOptions(moduleName: moduleName))

            #expect(throws: KotlinAndroidGeneratorError.invalidModuleName(moduleName)) {
                try KotlinAndroidApiPackageGenerator(package: testPackage(), options: options).generatedFiles()
            }
        }
    }

    @Test func generatedKotlinAndroidNameCollisionsFailValidation() {
        let operationCollision = [
            ApiOperation.get(name: "get-user", path: .relative("/one"), security: .unsecured),
            ApiOperation.get(name: "get_user", path: .relative("/two"), security: .unsecured)
        ]

        #expect(throws: KotlinAndroidGeneratorError.invalidPackage(
            reason: #"definition Users has duplicate operation type names: ["GetUserOperation"]"#
        )) {
            try KotlinAndroidApiPackageGenerator(package: testPackage(operations: operationCollision, references: [])).generatedFiles()
        }

        let fieldCollision = ApiTypeSchema.object(typeName: "Collision", properties: [
            .string("user-id", propertyName: "user-id"),
            .string("user_id", propertyName: "user_id")
        ])

        #expect(throws: KotlinAndroidGeneratorError.invalidPackage(
            reason: #"model Collision has duplicate property names: ["userId"]"#
        )) {
            try KotlinAndroidApiPackageGenerator(package: testPackage(response: fieldCollision.asRef, references: [fieldCollision])).generatedFiles()
        }

        let enumCollision = ApiTypeSchema.stringEnum(
            typeName: "State",
            values: [
                (name: "in-progress", rawName: "in-progress"),
                (name: "in_progress", rawName: "in_progress")
            ]
        )

        #expect(throws: KotlinAndroidGeneratorError.invalidPackage(
            reason: #"enum State has duplicate case names: ["InProgress"]"#
        )) {
            try KotlinAndroidApiPackageGenerator(package: testPackage(response: enumCollision.asRef, references: [enumCollision])).generatedFiles()
        }

        let enumRawCollision = ApiTypeSchema.stringEnum(
            typeName: "State",
            values: [
                (name: "Open", rawName: "active"),
                (name: "Closed", rawName: "active")
            ]
        )

        #expect(throws: KotlinAndroidGeneratorError.invalidPackage(
            reason: #"enum State has duplicate raw values: ["active"]"#
        )) {
            try KotlinAndroidApiPackageGenerator(package: testPackage(response: enumRawCollision.asRef, references: [enumRawCollision])).generatedFiles()
        }

        let enumGarbageCaseCollision = ApiTypeSchema.stringEnum(
            typeName: "State",
            values: [
                (name: "Garbage", rawName: "garbage")
            ],
            supportGarbage: true
        )

        #expect(throws: KotlinAndroidGeneratorError.invalidPackage(
            reason: #"enum State has duplicate case names: ["Garbage"]"#
        )) {
            try KotlinAndroidApiPackageGenerator(package: testPackage(response: enumGarbageCaseCollision.asRef, references: [enumGarbageCaseCollision])).generatedFiles()
        }

        let enumGarbageRawCollision = ApiTypeSchema.stringEnum(
            typeName: "State",
            values: [
                (name: "Open", rawName: "__garbage__")
            ],
            supportGarbage: true
        )

        #expect(throws: KotlinAndroidGeneratorError.invalidPackage(
            reason: #"enum State has duplicate raw values: ["__garbage__"]"#
        )) {
            try KotlinAndroidApiPackageGenerator(package: testPackage(response: enumGarbageRawCollision.asRef, references: [enumGarbageRawCollision])).generatedFiles()
        }

        let intEnumRawCollision = ApiTypeSchema.intEnum(
            typeName: "Score",
            values: [
                (name: "Low", rawValue: 1),
                (name: "High", rawValue: 1)
            ]
        )

        #expect(throws: KotlinAndroidGeneratorError.invalidPackage(
            reason: "enum Score has duplicate raw values: [1]"
        )) {
            try KotlinAndroidApiPackageGenerator(package: testPackage(response: intEnumRawCollision.asRef, references: [intEnumRawCollision])).generatedFiles()
        }
    }

    @Test func generatedKotlinAndroidReferenceValidationMatchesSwiftClient() {
        let nonReferenceable = ApiTypeSchema.array(.string())
        #expect(throws: KotlinAndroidGeneratorError.invalidPackage(
            reason: "definition Users references are not all referenceable: [\"[String]\"]"
        )) {
            try KotlinAndroidApiPackageGenerator(
                package: testPackage(response: nil, references: [nonReferenceable])
            )
            .generatedFiles()
        }

        let nonFiniteDouble = ApiTypeSchema.object(typeName: "Measurement", properties: [
            .double("value", initialValue: .infinity)
        ])
        #expect(throws: KotlinAndroidGeneratorError.invalidPackage(
            reason: "double initial value must be finite"
        )) {
            try KotlinAndroidApiPackageGenerator(package: testPackage(response: nonFiniteDouble.asRef, references: [nonFiniteDouble])).generatedFiles()
        }

        let rawNameCollision = ApiTypeSchema.object(typeName: "Collision", properties: [
            .string("trace-id", propertyName: "traceId"),
            .string("trace-id", propertyName: "alternateTraceId")
        ])
        #expect(throws: KotlinAndroidGeneratorError.invalidPackage(
            reason: #"model Collision has duplicate raw property names: ["trace-id"]"#
        )) {
            try KotlinAndroidApiPackageGenerator(package: testPackage(response: rawNameCollision.asRef, references: [rawNameCollision])).generatedFiles()
        }

        let payload = ApiTypeSchema.object(typeName: "Payload", properties: [
            ApiModelProperty(rawName: "kind", propertyName: "kind", dataType: .string()).unpublished
        ])
        let dynamic = ApiTypeSchema.dynamicObject(
            typeName: "Envelope",
            objectTypePropertyName: "kind",
            objectDataPropertyName: "__self__",
            objectTypes: [
                (objectTypeName: "Payload", objectTypeRawName: "payload", objectType: payload.asRef)
            ]
        )
        #expect(throws: KotlinAndroidGeneratorError.invalidPackage(
            reason: #"dynamic object Envelope has self-encoded property names that collide with reserved names: ["kind"]"#
        )) {
            try KotlinAndroidApiPackageGenerator(package: testPackage(response: dynamic.asRef, references: [dynamic, payload])).generatedFiles()
        }

        let payloadWithDataKey = ApiTypeSchema.object(typeName: "PayloadWithDataKey", properties: [
            .string("extra")
        ])
        let dynamicWithDataKey = ApiTypeSchema.dynamicObject(
            typeName: "EnvelopeWithDataKey",
            objectTypePropertyName: "kind",
            objectDataPropertyName: "__self__",
            objectTypes: [
                (objectTypeName: "Payload", objectTypeRawName: "payload", objectType: payloadWithDataKey.asRef)
            ]
        )
        #expect(throws: Never.self) {
            try KotlinAndroidApiPackageGenerator(
                package: testPackage(response: dynamicWithDataKey.asRef, references: [dynamicWithDataKey, payloadWithDataKey])
            )
            .generatedFiles()
        }
    }

    @Test func generatedKotlinAndroidPackageCollisionsFailValidation() {
        let operation = ApiOperation.get(name: "list", path: .relative("/items"), security: .unsecured)
        let moduleCollision = ApiPackage(
            name: "Test",
            targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true),
            modules: [
                ApiModule(name: "Class", definitions: [ApiService(name: "Items", operations: [operation])]),
                ApiModule(name: "_class_", definitions: [ApiService(name: "Other", operations: [operation])])
            ],
            referencedModules: [],
            references: [],
            commonReferences: [],
            imports: []
        )

        #expect(throws: KotlinAndroidGeneratorError.invalidPackage(
            reason: #"has duplicate module type names: ["ClassApiModule"]"#
        )) {
            try KotlinAndroidApiPackageGenerator(package: moduleCollision).generatedFiles()
        }

        let definitionCollision = ApiPackage(
            name: "Test",
            targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true),
            modules: [
                ApiModule(name: "Admin", definitions: [
                    ApiService(name: "User-Group", operations: [operation]),
                    ApiService(name: "User_Group", operations: [operation])
                ])
            ],
            referencedModules: [],
            references: [],
            commonReferences: [],
            imports: []
        )

        #expect(throws: KotlinAndroidGeneratorError.invalidPackage(
            reason: #"module Admin has duplicate API type names: ["AdminUserGroupApi"]"#
        )) {
            try KotlinAndroidApiPackageGenerator(package: definitionCollision).generatedFiles()
        }
    }

    @Test func acceptableStatusesMustBeNonEmptyHttpStatuses() {
        let emptyStatuses = ApiOperation.get(
            name: "ping",
            path: .relative("/ping"),
            security: .unsecured,
            response: nil,
            acceptableStatuses: []
        )

        #expect(throws: KotlinAndroidGeneratorError.emptyAcceptableStatuses(operationName: emptyStatuses.name)) {
            try KotlinAndroidApiPackageGenerator(package: testPackage(operations: [emptyStatuses], references: [])).generatedFiles()
        }

        for statusCode in [99, 600] {
            let operation = ApiOperation.get(
                name: "ping",
                path: .relative("/ping"),
                security: .unsecured,
                response: nil,
                acceptableStatuses: [statusCode]
            )

            #expect(throws: KotlinAndroidGeneratorError.invalidAcceptableStatus(operationName: operation.name, statusCode: statusCode)) {
                try KotlinAndroidApiPackageGenerator(package: testPackage(operations: [operation], references: [])).generatedFiles()
            }
        }
    }

    @Test func invalidOperationShapesFailBeforeGeneratingBrokenKotlinAndroidClient() {
        let user = ApiTypeSchema.object(typeName: "User", properties: [.string("name")])
        let bodyCollision = ApiOperation.post(
            name: "create",
            path: .relative("/users"),
            security: .unsecured,
            parameters: [
                .query("body", .string())
            ],
            request: user.asRef
        )

        #expect(throws: KotlinAndroidGeneratorError.invalidOperation(
            operationName: bodyCollision.name,
            reason: #"has parameter names that collide with generated request members: ["body"]"#
        )) {
            try KotlinAndroidApiPackageGenerator(package: testPackage(operations: [bodyCollision], references: [user])).generatedFiles()
        }

        let cookieConflict = ApiOperation.get(
            name: "search",
            path: .relative("/users"),
            security: .unsecured,
            parameters: [
                .header("Cookie", .string()),
                .cookie("session", .string())
            ]
        )

        #expect(throws: KotlinAndroidGeneratorError.invalidOperation(
            operationName: cookieConflict.name,
            reason: "cannot combine Cookie header parameters with cookie parameters"
        )) {
            try KotlinAndroidApiPackageGenerator(package: testPackage(operations: [cookieConflict], references: [])).generatedFiles()
        }

        let caseInsensitiveHeaderConflict = ApiOperation.get(
            name: "trace",
            path: .relative("/trace"),
            security: .unsecured,
            parameters: [
                .header("X-Trace", .string()),
                .header("x-trace", .string(), propertyName: "trace2")
            ]
        )

        #expect(throws: KotlinAndroidGeneratorError.invalidOperation(
            operationName: caseInsensitiveHeaderConflict.name,
            reason: "has duplicate parameter wire names"
        )) {
            try KotlinAndroidApiPackageGenerator(package: testPackage(operations: [caseInsensitiveHeaderConflict], references: [])).generatedFiles()
        }

        let nilJsonResponse = ApiOperation(
            name: "nilJson",
            method: .get,
            path: .relative("/nil-json"),
            security: .unsecured,
            parameters: [],
            request: .none,
            response: .json(nil),
            acceptableStatuses: [200],
            extraImports: []
        )

        #expect(throws: KotlinAndroidGeneratorError.invalidOperation(
            operationName: nilJsonResponse.name,
            reason: "has a typed response without a data type"
        )) {
            try KotlinAndroidApiPackageGenerator(package: testPackage(operations: [nilJsonResponse], references: [])).generatedFiles()
        }

        let pathMismatch = ApiOperation.get(
            name: "fetch",
            path: .relative("/users/{id}"),
            security: .unsecured,
            parameters: [
                .path("user_id", .string())
            ]
        )

        #expect(throws: KotlinAndroidGeneratorError.invalidOperation(
            operationName: pathMismatch.name,
            reason: "has path parameters that do not match url placeholders"
        )) {
            try KotlinAndroidApiPackageGenerator(package: testPackage(operations: [pathMismatch], references: [])).generatedFiles()
        }

        let runtimePathParameter = ApiOperation.get(
            name: "follow",
            path: .runtime,
            security: .unsecured,
            parameters: [
                .path("id", .string())
            ]
        )

        #expect(throws: KotlinAndroidGeneratorError.invalidOperation(
            operationName: runtimePathParameter.name,
            reason: "uses runtime url with path parameters"
        )) {
            try KotlinAndroidApiPackageGenerator(package: testPackage(operations: [runtimePathParameter], references: [])).generatedFiles()
        }

        let relativeQueryPlaceholder = ApiOperation.get(
            name: "relativeQuery",
            path: .relative("/users?filter={filter}"),
            security: .unsecured,
            parameters: [.path("filter", .string())]
        )

        #expect(throws: KotlinAndroidGeneratorError.invalidOperation(
            operationName: relativeQueryPlaceholder.name,
            reason: "has path parameters that do not match url placeholders"
        )) {
            try KotlinAndroidApiPackageGenerator(package: testPackage(operations: [relativeQueryPlaceholder], references: [])).generatedFiles()
        }

        let absoluteHostPlaceholder = ApiOperation.get(
            name: "absoluteHost",
            path: .absolute("https://{tenant}.example.com/users"),
            security: .unsecured,
            parameters: [.path("tenant", .string())]
        )

        #expect(throws: KotlinAndroidGeneratorError.invalidOperation(
            operationName: absoluteHostPlaceholder.name,
            reason: "has path parameters that do not match url placeholders"
        )) {
            try KotlinAndroidApiPackageGenerator(package: testPackage(operations: [absoluteHostPlaceholder], references: [])).generatedFiles()
        }

        let absoluteQueryPlaceholder = ApiOperation.get(
            name: "absoluteQuery",
            path: .absolute("https://api.example.com/users?filter={filter}"),
            security: .unsecured,
            parameters: [.path("filter", .string())]
        )

        #expect(throws: KotlinAndroidGeneratorError.invalidOperation(
            operationName: absoluteQueryPlaceholder.name,
            reason: "has path parameters that do not match url placeholders"
        )) {
            try KotlinAndroidApiPackageGenerator(package: testPackage(operations: [absoluteQueryPlaceholder], references: [])).generatedFiles()
        }

        let invalidEnumType = ApiOperation.get(
            name: "invalidEnum",
            path: .relative("/users"),
            security: .unsecured,
            parameters: [
                .query("visibility", .stringEnumValue(type: .string()))
            ]
        )

        #expect(throws: KotlinAndroidGeneratorError.invalidOperation(
            operationName: invalidEnumType.name,
            reason: "has invalid enum parameter type"
        )) {
            try KotlinAndroidApiPackageGenerator(package: testPackage(operations: [invalidEnumType], references: [])).generatedFiles()
        }

        let visibility = ApiTypeSchema.stringEnum(
            typeName: "Visibility",
            values: [(name: "Public", rawName: "public")]
        )
        let invalidEnumDefault = ApiOperation.get(
            name: "invalidEnumDefault",
            path: .relative("/users"),
            security: .unsecured,
            parameters: [
                .query("visibility", .stringEnumValue(type: visibility.asRef, defaultValue: "private"))
            ]
        )

        #expect(throws: KotlinAndroidGeneratorError.invalidOperation(
            operationName: invalidEnumDefault.name,
            reason: "has invalid enum parameter default"
        )) {
            try KotlinAndroidApiPackageGenerator(package: testPackage(operations: [invalidEnumDefault], references: [visibility])).generatedFiles()
        }

        let enumArrayPath = ApiOperation.get(
            name: "enumArrayPath",
            path: .relative("/users/{visibility}"),
            security: .unsecured,
            parameters: [
                .path("visibility", .stringEnumArray(type: visibility.asRef))
            ]
        )

        #expect(throws: KotlinAndroidGeneratorError.invalidOperation(
            operationName: enumArrayPath.name,
            reason: "has enum array path parameter"
        )) {
            try KotlinAndroidApiPackageGenerator(package: testPackage(operations: [enumArrayPath], references: [visibility])).generatedFiles()
        }
    }

    @Test func typedResponsesRejectMixedBodylessStatuses() {
        let user = ApiTypeSchema.object(typeName: "User", properties: [.string("name")])
        let operation = ApiOperation.get(
            name: "fetch",
            path: .relative("/users"),
            security: .unsecured,
            response: user.asRef,
            acceptableStatuses: [100, 199, 200, 204, 205, 304]
        )

        #expect(throws: KotlinAndroidGeneratorError.typedResponseWithBodylessStatus(operationName: operation.name, statusCode: 100)) {
            try KotlinAndroidApiPackageGenerator(package: testPackage(operations: [operation], references: [user])).generatedFiles()
        }
    }

    @Test func typedResponsesRejectOnlyBodylessStatuses() {
        let user = ApiTypeSchema.object(typeName: "User", properties: [.string("name")])
        for statusCodes in [[100, 199], [204, 205, 304]] {
            let operation = ApiOperation.get(
                name: "fetch",
                path: .relative("/users"),
                security: .unsecured,
                response: user.asRef,
                acceptableStatuses: statusCodes
            )

            #expect(throws: KotlinAndroidGeneratorError.typedResponseWithBodylessStatus(operationName: operation.name, statusCode: statusCodes[0])) {
                try KotlinAndroidApiPackageGenerator(package: testPackage(operations: [operation], references: [user])).generatedFiles()
            }
        }
    }

    @Test func unresolvedExternalReferenceFailsValidation() {
        let external = ApiTypeSchema.reference(typeName: "ExternalThing", strict: false)
        let package = testPackage(response: external)

        #expect(throws: KotlinAndroidGeneratorError.unresolvedExternalType("ExternalThing")) {
            try KotlinAndroidApiPackageGenerator(package: package).generatedFiles()
        }
    }

    @Test func androidDefaultsAndProjectAreNative() throws {
        let options = KotlinAndroidGeneratorOptions()
        #expect(!options.generateKoinModule)
        #expect(!options.generateMocks)
        #expect(options.gradle.retrofitVersion == "3.0.0")
        #expect(options.gradle.okHttpVersion == "4.12.0")
        #expect(options.gradle.minSdk == 23)
        #expect(options.gradle.compileSdk == 36)
        let generator = KotlinAndroidApiPackageGenerator(package: testPackage(), options: options)
        let files = try generator.generatedFiles()
        #expect(files == (try generator.generatedFiles()))
        #expect(files.contains { $0.relativePath == "generated-api/src/main/AndroidManifest.xml" })
        #expect(files.contains { $0.relativePath.hasSuffix("/AdminUsersApi.kt") })
        #expect(!files.contains { $0.relativePath.hasSuffix("ApiKoinModule.kt") })
        #expect(!files.contains { $0.relativePath.hasSuffix("ApiModulesMocks.kt") })
        let contents = files.map(\.contents).joined(separator: "\n")
        for forbidden in ["io.ktor", "org.jetbrains.kotlin.multiplatform", "NativeCoroutines", "commonMain"] {
            #expect(!contents.contains(forbidden))
        }
        #expect(contents.contains("retrofit2.Retrofit"))
        #expect(contents.contains("okhttp3.OkHttpClient"))
    }

    @Test func androidOptionalOutputsAndNamedServiceParameters() throws {
        let files = try KotlinAndroidApiPackageGenerator(
            package: testPackage(),
            options: .init(generateKoinModule: true, generateMocks: true)
        ).generatedFiles()
        #expect(files.contains { $0.relativePath.hasSuffix("ApiKoinModule.kt") })
        #expect(files.contains { $0.relativePath.hasSuffix("testing/ApiModulesMocks.kt") })
        let service = try #require(files.first { $0.relativePath.hasSuffix("/AdminUsersApi.kt") })
        #expect(service.contents.contains("id: Long"))
        #expect(service.contents.contains("fields: List<String>? = null"))
        #expect(!service.contents.contains("suspend fun get(request:"))
        #expect(service.contents.contains("ApiOperationResult<User>"))
    }

    @Test func androidManifestCanBeRegeneratedAndUserFilesStayProtected() throws {
        let package = testPackage()
        defer { try? FileManager.default.removeItem(at: package.targetDirUrl) }
        let generator = KotlinAndroidApiPackageGenerator(package: package)
        try generator.write()
        try generator.write()
        let path = "generated-api/src/main/AndroidManifest.xml"
        let url = package.targetDirUrl.appendingPathComponent(path)
        try "<manifest />".write(to: url, atomically: true, encoding: .utf8)
        #expect(throws: KotlinAndroidGeneratedTextFileError.refusingToOverwriteUserFile(path)) {
            try generator.write()
        }
    }

    private func testPackage(
        response: ApiTypeSchema? = nil,
        operations: [ApiOperation]? = nil,
        references: [ApiTypeSchema]? = nil
    ) -> ApiPackage {
        let user = ApiTypeSchema.object(
            typeName: "User",
            properties: [
                .string("display_name", propertyName: "displayName"),
                .int64("id")
            ],
            protocols: ["Identifiable"]
        )
        let operation = ApiOperation.get(
            name: "get",
            path: .relative("/users/{id}"),
            security: .optional,
            parameters: [
                .path("id", .int64()),
                .query("fields", .stringArray()).optional
            ],
            response: response ?? user.asRef
        )
        return ApiPackage(
            name: "Test",
            targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true),
            modules: [
                ApiModule(name: "Admin", definitions: [
                    ApiService(name: "Users", operations: operations ?? [operation], references: references ?? [user])
                ])
            ],
            referencedModules: [],
            references: [],
            commonReferences: [],
            imports: []
        )
    }
}
