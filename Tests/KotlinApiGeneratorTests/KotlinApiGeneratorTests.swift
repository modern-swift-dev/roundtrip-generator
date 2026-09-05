import Foundation
import GeneratorBuilder
import GeneratorModels
@testable import KotlinApiGenerator
import Testing

@Suite(.serialized) struct KotlinApiGeneratorTests {
    @Test func `options expose gradle and ktlint defaults`() {
        let options = KotlinGeneratorOptions()

        #expect(options.basePackage == "com.example.api")
        #expect(options.gradle.moduleName == "generated-api")
        #expect(options.gradle.kotlinVersion == "2.4.0")
        #expect(options.gradle.androidGradlePluginVersion == "9.2.1")
        #expect(options.gradle.koinVersion == "4.2.2")
        #expect(options.gradle.kotlinxSerializationVersion == "1.11.0")
        #expect(options.gradle.kotlinxDateTimeVersion == "0.8.0")
        #expect(options.gradle.kotlinxCoroutinesVersion == "1.11.0")
        #expect(options.gradle.nativeCoroutinesVersion == "1.0.4")
        #expect(options.gradle.ktlintGradlePluginVersion == "14.2.0")
        #expect(options.gradle.jvmToolchain == 21)
        #expect(options.gradle.ktlintCodeStyle == .ktlintOfficial)
        #expect(options.generateRuntime)
        #expect(options.generateKoinModule)
    }

    @Test func `generated project includes gradle editor config and ktlint`() throws {
        let files = try KotlinApiPackageGenerator(package: testPackage()).generatedFiles()
        let paths = Set(files.map(\.relativePath))

        #expect(paths.contains("settings.gradle.kts"))
        #expect(paths.contains("build.gradle.kts"))
        #expect(paths.contains("gradle/libs.versions.toml"))
        #expect(paths.contains("gradle.properties"))
        #expect(paths.contains(".editorconfig"))
        #expect(paths.contains("generated-api/build.gradle.kts"))

        let versionCatalog = try #require(files.first { $0.relativePath == "gradle/libs.versions.toml" }?.contents)
        #expect(versionCatalog.hasPrefix("# Generated code. Do not edit."))
        #expect(!versionCatalog.hasPrefix("//"))
        #expect(versionCatalog.contains("kotlin = \"2.4.0\""))
        #expect(versionCatalog.contains("androidGradlePlugin = \"9.2.1\""))
        #expect(versionCatalog.contains("koin = \"4.2.2\""))
        #expect(versionCatalog.contains("kotlinxSerialization = \"1.11.0\""))
        #expect(versionCatalog.contains("kotlinxDateTime = \"0.8.0\""))
        #expect(versionCatalog.contains("kotlinxCoroutines = \"1.11.0\""))
        #expect(versionCatalog.contains("nativeCoroutines = \"1.0.4\""))
        #expect(versionCatalog.contains("ktlintGradle = \"14.2.0\""))
        #expect(versionCatalog.contains("native-coroutines = { id = \"com.rickclephas.kmp.nativecoroutines\", version.ref = \"nativeCoroutines\" }"))

        let gradleProperties = try #require(files.first { $0.relativePath == "gradle.properties" }?.contents)
        #expect(gradleProperties.hasPrefix("# Generated code. Do not edit."))
        #expect(!gradleProperties.hasPrefix("//"))

        let settings = try #require(files.first { $0.relativePath == "settings.gradle.kts" }?.contents)
        #expect(settings.hasPrefix("// Generated code. Do not edit."))

        let editorConfig = try #require(files.first { $0.relativePath == ".editorconfig" }?.contents)
        #expect(editorConfig.hasPrefix("# Generated code. Do not edit."))
        #expect(!editorConfig.hasPrefix("//"))
        #expect(editorConfig.contains("root = true"))
        #expect(editorConfig.contains("ktlint_code_style = ktlint_official"))

        let moduleBuild = try #require(files.first { $0.relativePath == "generated-api/build.gradle.kts" }?.contents)
        #expect(moduleBuild.contains("alias(libs.plugins.ktlint)"))
        #expect(moduleBuild.contains("alias(libs.plugins.android.kotlin.multiplatform.library)"))
        #expect(moduleBuild.contains("alias(libs.plugins.native.coroutines)"))
        #expect(moduleBuild.contains("android {"))
        #expect(moduleBuild.contains("compileSdk = 36"))
        #expect(moduleBuild.contains("minSdk = 23"))
        #expect(moduleBuild.contains("optIn.add(\"kotlin.time.ExperimentalTime\")"))
        #expect(moduleBuild.contains("optIn.add(\"kotlin.experimental.ExperimentalObjCName\")"))
        #expect(!moduleBuild.contains("languageSettings.optIn(\"kotlin.experimental.ExperimentalObjCName\")"))
        #expect(moduleBuild.contains("jvmToolchain(21)"))
        #expect(!moduleBuild.contains("jvmToolchain(17)"))
        #expect(moduleBuild.contains("implementation(project.dependencies.platform(libs.koin.bom))"))
        #expect(!moduleBuild.contains("androidTarget()"))
        #expect(!moduleBuild.contains("alias(libs.plugins.android.library)"))
        #expect(!moduleBuild.contains("implementation(platform(libs.koin.bom))"))
        #expect(moduleBuild.contains("ktlint {"))
    }

    @Test func `generated kotlin gradle files escape kotlin strings`() throws {
        let options = KotlinGeneratorOptions(
            basePackage: "com.example.api",
            gradle: KotlinGradleOptions(
                projectName: "generated \"api\" $",
                moduleName: "generated-api",
                namespace: "com.example.generated$",
                group: "com.example \"group\" $",
                version: "1.0 \"$",
                ktlintVersion: "1.7 \"$",
            ),
        )
        let files = try KotlinApiPackageGenerator(package: testPackage(), options: options).generatedFiles()
        let settings = try #require(files.first { $0.relativePath == "settings.gradle.kts" })
        let moduleBuild = try #require(files.first { $0.relativePath == "generated-api/build.gradle.kts" })

        #expect(settings.contents.contains(#"rootProject.name = "generated \"api\" \$""#))
        #expect(moduleBuild.contents.contains(#"group = "com.example \"group\" \$""#))
        #expect(moduleBuild.contents.contains(#"version = "1.0 \"\$""#))
        #expect(moduleBuild.contents.contains(#"namespace = "com.example.generated\$""#))
        #expect(moduleBuild.contents.contains(#"version.set("1.7 \"\$")"#))
    }

    @Test func `generated kotlin contains model operation service runtime and koin`() throws {
        let files = try KotlinApiPackageGenerator(package: testPackage()).generatedFiles()
        let output = files.map(\.contents).joined(separator: "\n")

        #expect(output.contains("package com.example.api"))
        #expect(output.contains("data class User"))
        #expect(output.contains("@SerialName(\"display_name\")"))
        #expect(output.contains("object GetOperation"))
        #expect(output.contains("interface AdminUsersApi"))
        #expect(output.contains("class AdminUsersApiService"))
        #expect(output.contains("""
        data class AdminApiModule(
            val usersApi: AdminUsersApi,
        ) {
            constructor(client: RestClient) : this(
                usersApi = AdminUsersApiService(client = client),
            )
        }
        """))
        #expect(output.contains("""
        data class ApiModules(
            val adminModule: AdminApiModule,
            val errors: SharedFlow<ApiError> = MutableSharedFlow(),
        ) {
            constructor(client: RestClient) : this(
                adminModule = AdminApiModule(client = client),
                errors = client.errors,
            )
        }
        """))
        #expect(output.contains("interface RestClient"))
        #expect(output.contains("class KtorRestClient"))
        #expect(output.contains("fun interface DefaultHttpHeaderProvider"))
        #expect(output.contains("import com.rickclephas.kmp.nativecoroutines.NativeCoroutines"))
        #expect(output.contains("@NativeCoroutines\n    suspend fun `get`("))
        #expect(output.contains("import io.ktor.client.request.forms.MultiPartFormDataContent"))
        #expect(output.contains("import io.ktor.client.request.forms.formData"))
        #expect(output.contains("import io.ktor.http.Headers"))
        #expect(output.contains("value.contentType?.let { append(\"Content-Type\", it) }"))
        #expect(!output.contains("import io.ktor.http.content.MultiPartFormDataContent"))
        #expect(output.contains("fun apiKoinModule("))
        #expect(output.contains("httpClient: HttpClient"))
        #expect(output.contains("""
        fun apiKoinModule(
            httpClient: HttpClient,
            baseUrlProvider: BaseUrlProvider,
            apiKeyProvider: ApiKeyProvider,
            bodyCodec: BodyCodec,
            defaultHttpHeaderProvider: DefaultHttpHeaderProvider = DefaultHttpHeaderProvider { emptyMap() },
        ): Module =
        """))
        #expect(output.contains("single<DefaultHttpHeaderProvider> { defaultHttpHeaderProvider }"))
        #expect(output.contains("single<RestClient> {"))
        #expect(output.contains("KtorRestClient("))
        #expect(output.contains("""
                    KtorRestClient(
                        httpClient = get(),
                        baseUrlProvider = get(),
                        apiKeyProvider = get(),
                        bodyCodec = get(),
                        defaultHttpHeaderProvider = get(),
                    )
        """))
    }

    @Test func `dynamic objects use serialization opt in`() throws {
        let payload = ApiTypeSchema.object(typeName: "Payload", properties: [.string("value")])
        let dynamic = ApiTypeSchema.dynamicObject(
            typeName: "EventEnvelope",
            objectTypePropertyName: "kind",
            objectTypes: [
                (
                    objectTypeName: "Message",
                    objectTypeRawName: "message",
                    objectType: payload.asRef,
                )
            ],
        )
        let files = try KotlinApiPackageGenerator(
            package: testPackage(response: dynamic.asRef, references: [dynamic, payload]),
        )
        .generatedFiles()
        let output = files.map(\.contents).joined(separator: "\n")

        #expect(output.contains("import kotlinx.serialization.ExperimentalSerializationApi"))
        #expect(output.contains("@OptIn(ExperimentalSerializationApi::class)"))
        #expect(output.contains("@JsonClassDiscriminator(\"kind\")"))
        #expect(output.contains("@SerialName(\"extras\")"))
    }

    @Test func `string enum garbage uses custom serializer for unknown json values`() throws {
        let visibility = ApiTypeSchema.stringEnum(
            typeName: "Visibility",
            values: [
                (name: "Public", rawName: "public"),
                (name: "Private", rawName: "private")
            ],
            supportGarbage: true,
        )
        let files = try KotlinApiPackageGenerator(
            package: testPackage(response: visibility.asRef, references: [visibility]),
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

    @Test func `dynamic object garbage uses custom serializer for unknown discriminator`() throws {
        let payload = ApiTypeSchema.object(
            typeName: "Payload",
            properties: [
                .int64("id"),
                .string("value")
            ],
            protocols: ["Identifiable"],
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
                    objectType: payload.asRef,
                )
            ],
            supportGarbage: true,
        )
        let files = try KotlinApiPackageGenerator(
            package: testPackage(response: dynamic.asRef, references: [dynamic, payload]),
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

    @Test func `dynamic object alternate payload uses custom serializer without garbage`() throws {
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
                    objectType: payload.asRef,
                )
            ],
            extraProperties: [
                .string("internal", propertyName: "internalValue").unpublished
            ],
        )
        let files = try KotlinApiPackageGenerator(
            package: testPackage(response: dynamic.asRef, references: [dynamic, payload]),
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

    @Test func `int enum uses raw value serializer for json values`() throws {
        let score = ApiTypeSchema.intEnum(
            typeName: "Score",
            values: [
                (name: "Low", rawValue: 10),
                (name: "High", rawValue: 100)
            ],
        )
        let files = try KotlinApiPackageGenerator(
            package: testPackage(response: score.asRef, references: [score]),
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

    @Test func `dynamic object self payload uses flattening serializer`() throws {
        let payload = ApiTypeSchema.object(typeName: "Payload", properties: [.string("value")])
        let dynamic = ApiTypeSchema.dynamicObject(
            typeName: "EventEnvelope",
            objectTypePropertyName: "kind",
            objectDataPropertyName: "__self__",
            objectTypes: [
                (
                    objectTypeName: "Message",
                    objectTypeRawName: "message",
                    objectType: payload.asRef,
                )
            ],
            extraProperties: [
                .string("trace_id", propertyName: "traceId", required: false)
            ],
        )
        let files = try KotlinApiPackageGenerator(
            package: testPackage(response: dynamic.asRef, references: [dynamic, payload]),
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

    @Test func `generated kotlin omits unpublished object fields`() throws {
        let hiddenExternal = ApiTypeSchema.reference(typeName: "HiddenExternal", strict: false)
        let audit = ApiTypeSchema.object(
            typeName: "Audit",
            properties: [
                .string("public_note", propertyName: "publicNote"),
                ApiModelProperty(rawName: "internal_note", propertyName: "internalNote", dataType: hiddenExternal).unpublished
            ],
        )
        let files = try KotlinApiPackageGenerator(package: testPackage(response: audit.asRef, references: [audit])).generatedFiles()
        let model = try #require(files.first {
            $0.relativePath == "generated-api/src/commonMain/kotlin/com/example/api/admin/users/models/Audit.kt"
        })

        #expect(model.contents.contains("val publicNote: String"))
        #expect(!model.contents.contains("internalNote"))
        #expect(!model.contents.contains("@SerialName(\"internal_note\")"))
        #expect(!model.contents.contains("HiddenExternal"))
    }

    @Test func `generated kotlin models use content equality for binary fields`() throws {
        let document = ApiTypeSchema.object(
            typeName: "Document",
            properties: [
                .string("id"),
                .binary("payload"),
                .binary("class").optional
            ],
        )
        let files = try KotlinApiPackageGenerator(
            package: testPackage(response: document.asRef, references: [document]),
        )
        .generatedFiles()
        let model = try #require(files.first {
            $0.relativePath == "generated-api/src/commonMain/kotlin/com/example/api/admin/users/models/Document.kt"
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

    @Test func `nullable byte array escaped property uses valid equality expression`() throws {
        let blob = ApiTypeSchema.object(
            typeName: "Blob",
            properties: [
                .binary("class", propertyName: "class", required: false)
            ],
        )
        let files = try KotlinApiPackageGenerator(package: testPackage(response: blob.asRef, references: [blob])).generatedFiles()
        let model = try #require(files.first {
            $0.relativePath == "generated-api/src/commonMain/kotlin/com/example/api/admin/users/models/Blob.kt"
        })

        #expect(model.contents.contains("val `class`: ByteArray? = null"))
        #expect(model.contents.contains("val otherByteArray0 = other.`class`"))
        #expect(model.contents.contains("if (`class` == null) {"))
        #expect(model.contents.contains("if (otherByteArray0 != null) return false"))
        #expect(model.contents.contains("} else if (otherByteArray0 == null || !`class`.contentEquals(otherByteArray0)) return false"))
        #expect(model.contents.contains("@Serializable(with = ByteArrayBase64Serializer::class)"))
        #expect(!model.contents.contains("val other`Class`"))
    }

    @Test func `generated kotlin uses scoped packages and imports`() throws {
        let files = try KotlinApiPackageGenerator(package: testPackage()).generatedFiles()

        let service = try #require(files.first {
            $0.relativePath == "generated-api/src/commonMain/kotlin/com/example/api/admin/users/AdminUsersApi.kt"
        })
        #expect(service.contents.hasPrefix("// Generated code. Do not edit.\npackage com.example.api.admin.users"))
        #expect(service.contents.contains("import com.example.api.RestClient"))
        #expect(service.contents.contains("import com.example.api.admin.users.models.User"))

        let operation = try #require(files.first {
            $0.relativePath == "generated-api/src/commonMain/kotlin/com/example/api/admin/users/GetOperation.kt"
        })
        #expect(operation.contents.contains("package com.example.api.admin.users"))
        #expect(operation.contents.contains("import com.example.api.ApiRequest"))
        #expect(!operation.contents.contains("import com.example.api.admin.users.models.User"))

        let model = try #require(files.first {
            $0.relativePath == "generated-api/src/commonMain/kotlin/com/example/api/admin/users/models/User.kt"
        })
        #expect(model.contents.contains("package com.example.api.admin.users.models"))
        #expect(model.contents.contains("import com.example.api.Identifiable"))
        #expect(model.contents.contains("data class User("))
        #expect(model.contents.contains("override val id: Long"))
        #expect(model.contents.contains(") : Identifiable<Long>"))
    }

    @Test func `generated kotlin identifiable uses nullable ID type when ID is optional`() throws {
        let user = ApiTypeSchema.object(
            typeName: "User",
            properties: [
                .int64("id", required: false),
                .string("name")
            ],
            protocols: ["Identifiable"],
        )
        let files = try KotlinApiPackageGenerator(
            package: testPackage(response: user.asRef, references: [user]),
        )
        .generatedFiles()
        let model = try #require(files.first {
            $0.relativePath == "generated-api/src/commonMain/kotlin/com/example/api/admin/users/models/User.kt"
        })

        #expect(model.contents.contains("override val id: Long? = null"))
        #expect(model.contents.contains(") : Identifiable<Long?>"))
    }

    @Test func `generated kotlin sanitizes package segments with leading digits`() throws {
        let user = ApiTypeSchema.object(
            typeName: "User",
            properties: [.string("name")],
        )
        let operation = ApiOperation.get(
            name: "get",
            path: .relative("/users"),
            security: .unsecured,
            response: user.asRef,
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
            imports: [],
        )

        let files = try KotlinApiPackageGenerator(package: package).generatedFiles()
        let service = try #require(files.first {
            $0.relativePath == "generated-api/src/commonMain/kotlin/com/example/api/_2fa/users/_2FAUsersApi.kt"
        })

        #expect(service.contents.contains("package com.example.api._2fa.users"))
        #expect(service.contents.contains("import com.example.api._2fa.users.models.User"))
    }

    @Test func `generated kotlin sanitizes keyword package segments`() throws {
        let operation = ApiOperation.get(
            name: "get",
            path: .relative("/users"),
            security: .unsecured,
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
            imports: [],
        )

        let files = try KotlinApiPackageGenerator(package: package).generatedFiles()
        let service = try #require(files.first {
            $0.relativePath == "generated-api/src/commonMain/kotlin/com/example/api/_class_/_object_/ClassObjectApi.kt"
        })

        #expect(service.contents.contains("package com.example.api._class_._object_"))
    }

    @Test func `generated kotlin reuses shared model declarations`() throws {
        let rootStatus = ApiTypeSchema.stringEnum(
            typeName: "RootStatus",
            values: [
                (name: "Enabled", rawName: "enabled"),
                (name: "Disabled", rawName: "disabled")
            ],
        )
        let moduleStatus = ApiTypeSchema.stringEnum(
            typeName: "ModuleStatus",
            values: [
                (name: "Open", rawName: "open"),
                (name: "Closed", rawName: "closed")
            ],
        )
        let rootStamp = ApiTypeSchema.object(
            typeName: "RootStamp",
            properties: [
                .date("created_at")
            ],
        )
        let item = ApiTypeSchema.object(
            typeName: "Item",
            properties: [
                .ref("root_status", propertyName: "rootStatus", of: rootStatus),
                .ref("module_status", propertyName: "moduleStatus", of: moduleStatus),
                .object("root_stamp", propertyName: "rootStamp", of: rootStamp)
            ],
        )
        let operation = ApiOperation.get(
            name: "list",
            path: .relative("/items"),
            security: .unsecured,
            parameters: [
                .query("module_status", .stringEnumValue(type: moduleStatus.asRef), propertyName: "moduleStatus").optional
            ],
            response: .array(item.asRef),
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
                            references: [item, rootStatus, moduleStatus, rootStamp],
                        )
                    ],
                    references: [moduleStatus],
                )
            ],
            referencedModules: [],
            references: [rootStatus, rootStamp],
            commonReferences: [],
            imports: [],
        )
        let files = try KotlinApiPackageGenerator(package: package).generatedFiles()
        let paths = Set(files.map(\.relativePath))

        #expect(files.count == paths.count)
        #expect(paths.contains("generated-api/src/commonMain/kotlin/com/example/api/RootStatus.kt"))
        #expect(paths.contains("generated-api/src/commonMain/kotlin/com/example/api/RootStamp.kt"))
        #expect(paths.contains("generated-api/src/commonMain/kotlin/com/example/api/catalog/shared/ModuleStatus.kt"))
        #expect(paths.contains("generated-api/src/commonMain/kotlin/com/example/api/catalog/items/models/Item.kt"))
        #expect(!paths.contains("generated-api/src/commonMain/kotlin/com/example/api/catalog/items/models/RootStatus.kt"))
        #expect(!paths.contains("generated-api/src/commonMain/kotlin/com/example/api/catalog/items/models/RootStamp.kt"))
        #expect(!paths.contains("generated-api/src/commonMain/kotlin/com/example/api/catalog/items/models/ModuleStatus.kt"))

        let model = try #require(files.first {
            $0.relativePath == "generated-api/src/commonMain/kotlin/com/example/api/catalog/items/models/Item.kt"
        })
        #expect(model.contents.contains("import com.example.api.RootStatus"))
        #expect(model.contents.contains("import com.example.api.RootStamp"))
        #expect(model.contents.contains("import com.example.api.catalog.shared.ModuleStatus"))
        #expect(!model.contents.contains("data class RootStamp"))

        let operationFile = try #require(files.first {
            $0.relativePath == "generated-api/src/commonMain/kotlin/com/example/api/catalog/items/ListOperation.kt"
        })
        #expect(operationFile.contents.contains("import com.example.api.catalog.shared.ModuleStatus"))
    }

    @Test func `generated kotlin skips mapped model declarations`() throws {
        let mappedThing = ApiTypeSchema.object(
            typeName: "MappedThing",
            properties: [
                .string("name")
            ],
        )
        let operation = ApiOperation.get(
            name: "get",
            path: .relative("/mapped/{id}"),
            security: .unsecured,
            parameters: [
                .path("id", .int64())
            ],
            response: mappedThing.asRef,
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
            imports: [],
        )
        let options = KotlinGeneratorOptions(typeMappings: KotlinTypeMapping.defaultMappings + [
            KotlinTypeMapping(
                apiTypeName: "MappedThing",
                kotlinType: "ExternalThing",
                imports: ["com.example.shared.ExternalThing"],
            )
        ])
        let files = try KotlinApiPackageGenerator(package: package, options: options).generatedFiles()
        let paths = Set(files.map(\.relativePath))

        #expect(!paths.contains("generated-api/src/commonMain/kotlin/com/example/api/MappedThing.kt"))
        #expect(!paths.contains("generated-api/src/commonMain/kotlin/com/example/api/catalog/mapped/models/MappedThing.kt"))

        let service = try #require(files.first {
            $0.relativePath == "generated-api/src/commonMain/kotlin/com/example/api/catalog/mapped/CatalogMappedApi.kt"
        })
        #expect(service.contents.contains("import com.example.shared.ExternalThing"))
        #expect(service.contents.contains("ApiOperationResult<ExternalThing>"))
    }

    @Test func `generated kotlin empty object uses regular class`() throws {
        let empty = ApiTypeSchema.object(typeName: "Empty", properties: [])
        let files = try KotlinApiPackageGenerator(
            package: testPackage(response: empty.asRef, references: [empty]),
        )
        .generatedFiles()
        let model = try #require(files.first {
            $0.relativePath == "generated-api/src/commonMain/kotlin/com/example/api/admin/users/models/Empty.kt"
        })

        #expect(model.contents.contains("class Empty"))
        #expect(!model.contents.contains("data class Empty()"))
    }

    @Test func `generated kotlin patchable fields are non nullable with unmodified default`() throws {
        let patch = ApiTypeSchema.object(typeName: "Patch", properties: [
            ApiModelProperty(rawName: "name", propertyName: "name", dataType: ApiTypeSchema.string().asPatchable),
            ApiModelProperty(rawName: "nickname", propertyName: "nickname", dataType: ApiTypeSchema.string().asPatchable, required: false)
        ])
        let files = try KotlinApiPackageGenerator(
            package: testPackage(response: patch.asRef, references: [patch]),
        )
        .generatedFiles()
        let model = try #require(files.first {
            $0.relativePath == "generated-api/src/commonMain/kotlin/com/example/api/admin/users/models/Patch.kt"
        })
        let runtime = try #require(files.first {
            $0.relativePath == "generated-api/src/commonMain/kotlin/com/example/api/ApiRuntime.kt"
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

    @Test func `generated kotlin respects generate api modules flag`() throws {
        let package = ApiPackage(
            name: "Test",
            targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true),
            modules: [
                ApiModule(name: "Admin", definitions: [
                    ApiService(name: "Users", operations: [
                        ApiOperation.get(name: "get", path: .relative("/users"), security: .unsecured)
                    ])
                ])
            ],
            referencedModules: [],
            references: [],
            commonReferences: [],
            imports: [],
            generateApiModules: false,
        )

        let files = try KotlinApiPackageGenerator(package: package).generatedFiles()
        let paths = Set(files.map(\.relativePath))
        let koin = try #require(files.first {
            $0.relativePath == "generated-api/src/commonMain/kotlin/com/example/api/ApiKoinModule.kt"
        })

        #expect(!paths.contains("generated-api/src/commonMain/kotlin/com/example/api/ApiModules.kt"))
        #expect(!koin.contents.contains("ApiModules("))
        #expect(!koin.contents.contains("AdminApiModule("))
    }

    @Test func `generated kotlin skips api modules when no definitions exist`() throws {
        let package = ApiPackage(
            name: "Test",
            targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true),
            modules: [],
            referencedModules: [],
            references: [],
            commonReferences: [],
            imports: [],
        )

        let files = try KotlinApiPackageGenerator(package: package).generatedFiles()
        let paths = Set(files.map(\.relativePath))
        let koin = try #require(files.first {
            $0.relativePath == "generated-api/src/commonMain/kotlin/com/example/api/ApiKoinModule.kt"
        })

        #expect(!paths.contains("generated-api/src/commonMain/kotlin/com/example/api/ApiModules.kt"))
        #expect(!koin.contents.contains("ApiModules("))
    }

    @Test func `kotlin api mocks emitter builds mock apis and modules`() {
        let receipt = ApiTypeSchema.object(typeName: "UploadReceipt", properties: [.string("id")])
        let listOperation = ApiOperation.get(
            name: "list",
            path: .relative("/users"),
            security: .secured,
            response: .genericReference(typeName: "PagedResults", genericTypes: [.string()]),
        )
        let uploadOperation = ApiOperation.post(
            name: "uploadAvatar",
            path: .relative("/users/avatar"),
            security: .unsecured,
            requestType: .file,
            responseType: .json(receipt.asRef),
        )
        let output = KotlinApiMocksEmitter(
            package: testPackage(operations: [listOperation, uploadOperation], references: [receipt]),
        )
        .kotlinCode()
        .toString()

        #expect(output.contains("class AdminUsersApiMock : AdminUsersApi"))
        #expect(output.contains("val listCalls = mutableListOf<ListOperation.Request>()"))
        #expect(output.contains("var listHandler: suspend (ListOperation.Request) -> ApiOperationResult<PagedResults<String>>"))
        #expect(output.contains("override suspend fun list(request: ListOperation.Request): ApiOperationResult<PagedResults<String>>"))
        #expect(output.contains("listCalls += request"))
        #expect(output.contains("return listHandler(request)"))
        #expect(output.contains("data class UploadAvatarOperationCall("))
        #expect(output.contains("val progress: ApiProgress?"))
        #expect(output.contains("var uploadAvatarHandler: suspend (UploadAvatarOperation.Request, ApiProgress?) -> ApiOperationResult<UploadReceipt>"))
        #expect(output.contains("override suspend fun uploadAvatar(\n        request: UploadAvatarOperation.Request,\n        progress: ApiProgress?,\n    ): ApiOperationResult<UploadReceipt>"))
        #expect(output.contains("uploadAvatarCalls += UploadAvatarOperationCall(request, progress)"))
        #expect(output.contains("data class GetNextPageForListOperationCall("))
        #expect(output.contains("override suspend fun getNextPage(currentPage: PagedResults<String>, request: ListOperation.Request): ApiOperationResult<PagedResults<String>>"))
        #expect(output.contains("lateinit var adminUsersApi: AdminUsersApiMock"))
        #expect(output.contains("lateinit var adminModule: AdminApiModule"))
        #expect(output.contains("lateinit var apiModules: ApiModules"))
        #expect(output.contains("adminModule = AdminApiModule(usersApi = adminUsersApi)"))
        #expect(output.contains("apiModules = ApiModules(adminModule = adminModule)"))
        #expect(output.contains("adminUsersApi.resetMock()"))

        let outputWithoutApiModules = KotlinApiMocksEmitter(
            package: ApiPackage(
                name: "Test",
                targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true),
                modules: [
                    ApiModule(name: "Admin", definitions: [
                        ApiService(name: "Users", operations: [listOperation], references: [])
                    ])
                ],
                referencedModules: [],
                references: [],
                commonReferences: [],
                imports: [],
                generateApiModules: false,
            ),
        )
        .kotlinCode()
        .toString()
        #expect(!outputWithoutApiModules.contains("lateinit var apiModules: ApiModules"))
        #expect(!outputWithoutApiModules.contains("apiModules = ApiModules("))

        let externalPackageOutput = KotlinApiMocksEmitter(
            package: testPackage(operations: [listOperation], references: []),
        )
        .kotlinCode(packageName: "com.example.api.tests")
        .toString()
        #expect(externalPackageOutput.contains("import com.example.api.ApiModules"))
        #expect(externalPackageOutput.contains("import com.example.api.AdminApiModule"))
        #expect(externalPackageOutput.contains("import com.example.api.ApiOperationResult"))
        #expect(externalPackageOutput.contains("import com.example.api.admin.users.AdminUsersApi"))
    }

    @Test func `kotlin api mocks emitter imports shared models from real package`() {
        let sharedReceipt = ApiTypeSchema.object(typeName: "SharedReceipt", properties: [.string("id")])
        let operation = ApiOperation.get(
            name: "get",
            path: .relative("/users"),
            security: .unsecured,
            response: sharedReceipt.asRef,
        )
        let package = ApiPackage(
            name: "Test",
            targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true),
            modules: [
                ApiModule(name: "Admin", definitions: [
                    ApiService(name: "Users", operations: [operation], references: [])
                ])
            ],
            referencedModules: [],
            references: [sharedReceipt],
            commonReferences: [],
            imports: [],
        )
        let output = KotlinApiMocksEmitter(package: package)
            .kotlinCode(packageName: "com.example.api.tests")
            .toString()

        #expect(output.contains("import com.example.api.SharedReceipt"))
        #expect(!output.contains("import com.example.api.admin.users.models.SharedReceipt"))
    }

    @Test func `generated kotlin referenced modules mirror swift aggregate without source emission`() throws {
        let localOperation = ApiOperation.get(
            name: "local",
            path: .relative("/local"),
            security: .unsecured,
        )
        let referencedAccount = ApiTypeSchema.object(
            typeName: "Account",
            properties: [.string("name")],
        )
        let referencedOperation = ApiOperation.get(
            name: "remote",
            path: .relative("/remote"),
            security: .unsecured,
            response: referencedAccount.asRef,
        )
        let package = ApiPackage(
            name: "Test",
            targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true),
            modules: [
                ApiModule(name: "Local", definitions: [
                    ApiService(name: "Users", operations: [localOperation])
                ])
            ],
            referencedModules: [
                ApiModule(name: "Parent", definitions: [
                    ApiService(name: "Accounts", operations: [referencedOperation], references: [referencedAccount])
                ])
            ],
            references: [],
            commonReferences: [],
            imports: [],
        )

        let files = try KotlinApiPackageGenerator(package: package).generatedFiles()
        let paths = Set(files.map(\.relativePath))
        let apiModules = try #require(files.first {
            $0.relativePath == "generated-api/src/commonMain/kotlin/com/example/api/ApiModules.kt"
        })
        let koin = try #require(files.first {
            $0.relativePath == "generated-api/src/commonMain/kotlin/com/example/api/ApiKoinModule.kt"
        })

        #expect(paths.contains("generated-api/src/commonMain/kotlin/com/example/api/local/users/LocalUsersApi.kt"))
        #expect(paths.contains("generated-api/src/commonMain/kotlin/com/example/api/local/users/LocalOperation.kt"))
        #expect(!paths.contains("generated-api/src/commonMain/kotlin/com/example/api/parent/accounts/ParentAccountsApi.kt"))
        #expect(!paths.contains("generated-api/src/commonMain/kotlin/com/example/api/parent/accounts/RemoteOperation.kt"))
        #expect(!paths.contains("generated-api/src/commonMain/kotlin/com/example/api/parent/accounts/models/Account.kt"))
        #expect(apiModules.contents.contains("val accountsApi: ParentAccountsApi"))
        #expect(apiModules.contents.contains("val parentModule: ParentApiModule"))
        #expect(apiModules.contents.contains("val localModule: LocalApiModule"))
        #expect(koin.contents.contains("import com.example.api.parent.accounts.ParentAccountsApi"))
        #expect(koin.contents.contains("import com.example.api.parent.accounts.ParentAccountsApiService"))
        #expect(koin.contents.contains("single<ParentAccountsApi>"))
        #expect(koin.contents.contains("single { ParentApiModule(accountsApi = get()) }"))
        #expect(koin.contents.contains("single { ApiModules(parentModule = get(), localModule = get(), errors = get<RestClient>().errors) }"))
    }

    @Test func `generated kotlin recognizes common references without emitting them`() throws {
        let shared = ApiTypeSchema.object(
            typeName: "SharedThing",
            properties: [.string("name")],
        )
        let operation = ApiOperation.get(
            name: "lookup",
            path: .relative("/lookup"),
            security: .unsecured,
            response: shared.asRef,
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
            imports: [],
        )

        let files = try KotlinApiPackageGenerator(package: package).generatedFiles()
        let paths = Set(files.map(\.relativePath))
        let service = try #require(files.first {
            $0.relativePath == "generated-api/src/commonMain/kotlin/com/example/api/admin/users/AdminUsersApi.kt"
        })

        #expect(!paths.contains("generated-api/src/commonMain/kotlin/com/example/api/SharedThing.kt"))
        #expect(service.contents.contains("import com.example.api.SharedThing"))
        #expect(service.contents.contains("ApiOperationResult<SharedThing>"))
    }

    @Test func `generated kotlin validation ignores referenced module external types`() throws {
        let external = ApiTypeSchema.reference(typeName: "ExternalThing", strict: false)
        let referencedOperation = ApiOperation.get(
            name: "remote",
            path: .relative("/remote"),
            security: .unsecured,
            response: external,
            acceptableStatuses: [],
        )
        let duplicateReferencedOperation = ApiOperation.get(
            name: "remote",
            path: .relative("/remote-duplicate"),
            security: .unsecured,
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
            generateApiModules: false,
        )

        let files = try KotlinApiPackageGenerator(package: package).generatedFiles()
        let paths = Set(files.map(\.relativePath))

        #expect(paths.contains("generated-api/src/commonMain/kotlin/com/example/api/local/users/LocalUsersApi.kt"))
        #expect(!paths.contains("generated-api/src/commonMain/kotlin/com/example/api/parent/accounts/RemoteOperation.kt"))
    }

    @Test func `generated kotlin json nil request does not send content type`() throws {
        let operation = ApiOperation.post(
            name: "archive",
            path: .relative("/archive"),
            security: .unsecured,
            request: nil,
            response: nil,
        )
        let files = try KotlinApiPackageGenerator(
            package: testPackage(operations: [operation], references: []),
        )
        .generatedFiles()
        let operationFile = try #require(files.first {
            $0.relativePath == "generated-api/src/commonMain/kotlin/com/example/api/admin/users/ArchiveOperation.kt"
        })

        #expect(operationFile.contents.contains("body = null,"))
        #expect(operationFile.contents.contains("contentType = null,"))
        #expect(!operationFile.contents.contains("contentType = \"application/json\","))
    }

    @Test func `generated kotlin mapped enum model default does not use original type`() throws {
        let visibility = ApiTypeSchema.stringEnum(
            typeName: "Visibility",
            values: [
                (name: "Public", rawName: "public"),
                (name: "Private", rawName: "private")
            ],
            initialValue: "Public",
        )
        let container = ApiTypeSchema.object(
            typeName: "Container",
            properties: [.ref("visibility", of: visibility)],
        )
        let files = try KotlinApiPackageGenerator(
            package: testPackage(response: container.asRef, references: [container, visibility]),
            options: KotlinGeneratorOptions(typeMappings: KotlinTypeMapping.defaultMappings + [
                KotlinTypeMapping(
                    apiTypeName: "Visibility",
                    kotlinType: "ExternalVisibility",
                    imports: ["com.example.shared.ExternalVisibility"],
                )
            ]),
        )
        .generatedFiles()
        let model = try #require(files.first {
            $0.relativePath == "generated-api/src/commonMain/kotlin/com/example/api/admin/users/models/Container.kt"
        })

        #expect(model.contents.contains("import com.example.shared.ExternalVisibility"))
        #expect(model.contents.contains("val visibility: ExternalVisibility"))
        #expect(!model.contents.contains("Visibility.Public"))
    }

    @Test func `generated kotlin mapped object ignores internal external references`() throws {
        let mappedThing = ApiTypeSchema.object(
            typeName: "MappedThing",
            properties: [
                .object("nested", of: .reference(typeName: "UnmappedNested", strict: false))
            ],
        )
        let operation = ApiOperation.get(
            name: "get",
            path: .relative("/mapped"),
            security: .unsecured,
            response: mappedThing.asRef,
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
            imports: [],
        )
        let options = KotlinGeneratorOptions(typeMappings: KotlinTypeMapping.defaultMappings + [
            KotlinTypeMapping(
                apiTypeName: "MappedThing",
                kotlinType: "ExternalThing",
                imports: ["com.example.shared.ExternalThing"],
            )
        ])

        #expect(throws: Never.self) {
            try KotlinApiPackageGenerator(package: package, options: options).generatedFiles()
        }
    }

    @Test func `write removes stale managed kotlin sources`() throws {
        let sharedStatus = ApiTypeSchema.stringEnum(
            typeName: "SharedStatus",
            values: [
                (name: "Ready", rawName: "ready"),
                (name: "Done", rawName: "done")
            ],
        )
        let item = ApiTypeSchema.object(
            typeName: "Item",
            properties: [
                .ref("status", of: sharedStatus)
            ],
        )
        let operation = ApiOperation.get(
            name: "get",
            path: .relative("/items/{id}"),
            security: .unsecured,
            parameters: [
                .path("id", .int64())
            ],
            response: item.asRef,
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
            imports: [],
        )
        let staleRelativePath = "generated-api/src/commonMain/kotlin/com/example/api/catalog/items/models/SharedStatus.kt"
        let sharedRelativePath = "generated-api/src/commonMain/kotlin/com/example/api/SharedStatus.kt"
        let userRelativePath = "generated-api/src/commonMain/kotlin/com/example/api/catalog/items/models/UserOwned.kt"
        func fileURL(relativePath: String) -> URL {
            relativePath.split(separator: "/").reduce(targetDirURL) { partialURL, component in
                partialURL.appendingPathComponent(String(component))
            }
        }

        try KotlinGeneratedTextFile(
            relativePath: staleRelativePath,
            contents: """
            // Generated code. Do not edit.
            package com.example.api.catalog.items.models

            enum class SharedStatus
            """,
        )
        .write(to: targetDirURL)
        let userURL = fileURL(relativePath: userRelativePath)
        try FileManager.default.createDirectory(at: userURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try """
        package com.example.api.catalog.items.models

        // Generated code. Do not edit.
        class UserOwned
        """.write(to: userURL, atomically: true, encoding: .utf8)

        try KotlinApiPackageGenerator(package: package).write()

        #expect(!FileManager.default.fileExists(atPath: fileURL(relativePath: staleRelativePath).path))
        #expect(FileManager.default.fileExists(atPath: fileURL(relativePath: sharedRelativePath).path))
        #expect(FileManager.default.fileExists(atPath: userURL.path))
    }

    @Test func `write refuses user owned editor config`() throws {
        let targetDirURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: targetDirURL, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: targetDirURL) }

        try "root = true\n".write(to: targetDirURL.appendingPathComponent(".editorconfig"), atomically: true, encoding: .utf8)
        let file = try #require(
            KotlinApiPackageGenerator(package: testPackage())
                .generatedFiles()
                .first { $0.relativePath == ".editorconfig" },
        )

        #expect(throws: KotlinGeneratedTextFileError.refusingToOverwriteUserFile(".editorconfig")) {
            try file.write(to: targetDirURL)
        }
    }

    @Test func `generated file write rejects symlink escape`() throws {
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
            withDestinationURL: outsideURL,
        )
        let file = KotlinGeneratedTextFile(relativePath: "linked/escaped.kt", contents: "class Escaped")

        #expect(throws: KotlinGeneratedTextFileError.invalidRelativePath("linked/escaped.kt")) {
            try file.write(to: targetDirURL)
        }
        #expect(!FileManager.default.fileExists(atPath: outsideURL.appendingPathComponent("escaped.kt").path))
    }

    @Test func `standalone gradle project files can be written twice`() throws {
        let targetDirURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: targetDirURL, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: targetDirURL) }
        let files = KotlinGradleProjectEmitter(
            projectName: "standalone",
            kotlinPluginVersion: "2.4.0",
            ktlintGradlePluginVersion: "14.2.0",
        )
        .files()

        for file in files {
            try file.write(to: targetDirURL)
            try file.write(to: targetDirURL)
        }

        let settings = try String(contentsOf: targetDirURL.appendingPathComponent("settings.gradle.kts"), encoding: .utf8)
        let properties = try String(contentsOf: targetDirURL.appendingPathComponent("gradle.properties"), encoding: .utf8)
        let editorConfig = try String(contentsOf: targetDirURL.appendingPathComponent(".editorconfig"), encoding: .utf8)

        #expect(settings.hasPrefix("// Generated code. Do not edit."))
        #expect(properties.hasPrefix("# Generated code. Do not edit."))
        #expect(editorConfig.hasPrefix("# Generated code. Do not edit."))
    }

    @Test func `mapped external imports do not leak swift imports`() throws {
        let external = ApiTypeSchema.reference(typeName: "DateInterval", strict: false, imports: ["Foundation"])
        let files = try KotlinApiPackageGenerator(package: testPackage(response: external)).generatedFiles()
        let service = try #require(files.first {
            $0.relativePath == "generated-api/src/commonMain/kotlin/com/example/api/admin/users/AdminUsersApi.kt"
        })

        #expect(service.contents.contains("import com.example.api.DateInterval"))
        #expect(!service.contents.contains("import Foundation"))
    }

    @Test func `operation extra imports do not leak swift imports`() throws {
        let operation = ApiOperation.get(
            name: "search",
            path: .relative("/search"),
            security: .unsecured,
            extraImports: ["UniformTypeIdentifiers"],
        )
        let files = try KotlinApiPackageGenerator(package: testPackage(operations: [operation], references: [])).generatedFiles()
        let operationFile = try #require(files.first {
            $0.relativePath == "generated-api/src/commonMain/kotlin/com/example/api/admin/users/SearchOperation.kt"
        })

        #expect(!operationFile.contents.contains("import UniformTypeIdentifiers"))
    }

    @Test func `service imports primitive response types`() throws {
        let files = try KotlinApiPackageGenerator(package: testPackage(response: .date())).generatedFiles()
        let service = try #require(files.first {
            $0.relativePath == "generated-api/src/commonMain/kotlin/com/example/api/admin/users/AdminUsersApi.kt"
        })

        #expect(service.contents.contains("import kotlin.time.Instant"))
        #expect(service.contents.contains("ApiOperationResult<Instant>"))
        #expect(service.contents.contains("ApiResponseType<Instant>(typeName = \"Instant\", mimeType = \"application/json\")"))
    }

    @Test func `paged results get next page uses next url headers security and statuses`() throws {
        let operation = ApiOperation.get(
            name: "list",
            path: .relative("/users"),
            security: .optional,
            parameters: [
                .header("X-Trace-Id", .string(), propertyName: "traceId").optional
            ],
            response: .genericReference(typeName: "PagedResults", genericTypes: [.string()]),
            acceptableStatuses: [200, 206],
        )
        let files = try KotlinApiPackageGenerator(
            package: testPackage(operations: [operation], references: []),
        )
        .generatedFiles()
        let service = try #require(files.first {
            $0.relativePath == "generated-api/src/commonMain/kotlin/com/example/api/admin/users/AdminUsersApi.kt"
        })

        #expect(service.contents.contains("import com.example.api.ApiRequest"))
        #expect(service.contents.contains("import com.example.api.ApiRequestConvertible"))
        #expect(service.contents.contains("import com.example.api.ApiRequestPath"))
        #expect(service.contents.contains("import com.example.api.ApiError"))
        #expect(service.contents.contains("import com.example.api.PagedResults"))
        #expect(
            service.contents
                .contains("@NativeCoroutines\n    suspend fun getNextPage(currentPage: PagedResults<String>, request: ListOperation.Request): ApiOperationResult<PagedResults<String>>"),
        )
        #expect(service.contents.contains("private data class NextPageRequest("))
        #expect(service.contents.contains("path = ApiRequestPath.Runtime(requestUrl = requestUrl)"))
        #expect(service.contents.contains("accept = \"application/json\""))
        #expect(service.contents.contains("val next = currentPage.next ?: throw ApiError.InvalidUrl"))
        #expect(service.contents.contains("val adaptedRequest = request.copy(apiKey = request.apiKey?.takeIf { it.isNotBlank() } ?: client.apiKey())"))
        #expect(service.contents.contains("headers = adaptedRequest.toApiRequest().headers"))
        #expect(service.contents.contains("responseType = ApiResponseType<PagedResults<String>>(typeName = \"PagedResults<String>\", mimeType = \"application/json\")"))
        #expect(service.contents.contains("validStatusCodes = setOf(200, 206)"))
        #expect(!service.contents.contains("validStatusCodes = setOf(100"))
    }

    @Test func `enum parameters use raw values for form and path values`() throws {
        let visibility = ApiTypeSchema.stringEnum(
            typeName: "Visibility",
            values: [
                (name: "public", rawName: "public"),
                (name: "private", rawName: "private")
            ],
        )
        let score = ApiTypeSchema.intEnum(
            typeName: "Score",
            values: [
                (name: "low", rawValue: 10),
                (name: "high", rawValue: 100)
            ],
        )
        let operation = ApiOperation.get(
            name: "search",
            path: .relative("/search/{visibility}"),
            security: .unsecured,
            parameters: [
                .path("visibility", .stringEnumValue(type: visibility.asRef)),
                .query("scores", .intEnumArray(type: score.asRef)).optional,
                .header("X-Visibility", .stringEnumValue(type: visibility.asRef), propertyName: "headerVisibility").optional
            ],
        )
        let files = try KotlinApiPackageGenerator(
            package: testPackage(operations: [operation], references: [visibility, score]),
        )
        .generatedFiles()
        let operationFile = try #require(files.first {
            $0.relativePath == "generated-api/src/commonMain/kotlin/com/example/api/admin/users/SearchOperation.kt"
        })

        #expect(operationFile.contents.contains(".replace(\"{visibility}\", visibility.rawValue.toApiPathSegment())"))
        #expect(operationFile.contents.contains("values[\"scores\"] = it.joinToString(\",\") { it.rawValue.toApiFormValue() }"))
        #expect(operationFile.contents.contains("headerVisibility?.let { values[\"X-Visibility\"] = it.rawValue.toApiFormValue() }"))
        #expect(!operationFile.contents.contains("values[\"scores\"] = it.toApiFormValue()"))
        #expect(!operationFile.contents.contains("values[\"X-Visibility\"] = it.toApiFormValue()"))
    }

    @Test func `required collection parameters are always emitted`() throws {
        let operation = ApiOperation.get(
            name: "search",
            path: .relative("/search"),
            security: .unsecured,
            parameters: [
                .query("tags", .stringArray())
            ],
        )
        let files = try KotlinApiPackageGenerator(package: testPackage(operations: [operation], references: [])).generatedFiles()
        let operationFile = try #require(files.first {
            $0.relativePath == "generated-api/src/commonMain/kotlin/com/example/api/admin/users/SearchOperation.kt"
        })

        #expect(operationFile.contents.contains("values[\"tags\"] = tags.toApiFormValue()"))
        #expect(!operationFile.contents.contains("if (tags.isNotEmpty())"))
    }

    @Test func `only generated authorization api key is nullable and blank filtered`() throws {
        let operation = ApiOperation.post(
            name: "lookup",
            path: .relative("/lookup"),
            security: .unsecured,
            parameters: [
                .header("X-Api-Key", .string(), propertyName: "apiKey")
            ],
            requestType: .binary(mimeType: "application/octet-stream"),
        )
        let files = try KotlinApiPackageGenerator(package: testPackage(operations: [operation], references: [])).generatedFiles()
        let operationFile = try #require(files.first {
            $0.relativePath == "generated-api/src/commonMain/kotlin/com/example/api/admin/users/LookupOperation.kt"
        })

        #expect(operationFile.contents.contains("val apiKey: String,"))
        #expect(operationFile.contents.contains("values[\"X-Api-Key\"] = apiKey.toApiFormValue()"))
        #expect(operationFile.contents.contains("var result = apiKey.hashCode()"))
        #expect(!operationFile.contents.contains("val apiKey: String? = null"))
        #expect(!operationFile.contents.contains("values[\"X-Api-Key\"] = it.toApiFormValue()"))
        #expect(!operationFile.contents.contains("apiKey?.hashCode()"))
    }

    @Test func `operation extra imports are emitted`() throws {
        let operation = ApiOperation.get(
            name: "lookup",
            path: .relative("/lookup"),
            security: .unsecured,
            extraImports: ["com.example.CustomThing"],
        )
        let files = try KotlinApiPackageGenerator(package: testPackage(operations: [operation], references: [])).generatedFiles()
        let operationFile = try #require(files.first {
            $0.relativePath == "generated-api/src/commonMain/kotlin/com/example/api/admin/users/LookupOperation.kt"
        })

        #expect(operationFile.contents.contains("import com.example.CustomThing"))
    }

    @Test func `progress overrides do not repeat default value`() throws {
        let receipt = ApiTypeSchema.object(typeName: "Receipt", properties: [.string("id")])
        let operation = ApiOperation.postMultipart(
            name: "upload",
            path: .relative("/upload"),
            security: .unsecured,
            multiParts: ["file"],
            response: receipt.asRef,
            acceptableStatuses: [200, 201],
        )
        let files = try KotlinApiPackageGenerator(package: testPackage(operations: [operation], references: [receipt])).generatedFiles()
        let service = try #require(files.first {
            $0.relativePath == "generated-api/src/commonMain/kotlin/com/example/api/admin/users/AdminUsersApi.kt"
        })

        #expect(service.contents.contains("suspend fun upload(request: UploadOperation.Request, progress: ApiProgress? = null): ApiOperationResult<Receipt>"))
        #expect(service.contents.contains("override suspend fun upload(request: UploadOperation.Request, progress: ApiProgress?): ApiOperationResult<Receipt>"))
        #expect(!service.contents.contains("override suspend fun upload(request: UploadOperation.Request, progress: ApiProgress? = null):"))
    }

    @Test func `binary requests use swift client execute shape and content equality`() throws {
        let operation = ApiOperation.post(
            name: "uploadBinary",
            path: .relative("/upload"),
            security: .unsecured,
            requestType: .binary(mimeType: "application/octet-stream"),
        )
        let files = try KotlinApiPackageGenerator(package: testPackage(operations: [operation], references: [])).generatedFiles()
        let service = try #require(files.first {
            $0.relativePath == "generated-api/src/commonMain/kotlin/com/example/api/admin/users/AdminUsersApi.kt"
        })
        let operationFile = try #require(files.first {
            $0.relativePath == "generated-api/src/commonMain/kotlin/com/example/api/admin/users/UploadBinaryOperation.kt"
        })

        #expect(!service.contents.contains("import com.example.api.ApiProgress"))
        #expect(service.contents.contains("suspend fun uploadBinary(request: UploadBinaryOperation.Request): ApiResponse"))
        #expect(service.contents.contains("override suspend fun uploadBinary(request: UploadBinaryOperation.Request): ApiResponse"))
        #expect(service.contents.contains("return client.execute("))
        #expect(!service.contents.contains("return client.upload("))
        #expect(!service.contents.contains("progress = progress"))
        #expect(operationFile.contents.contains("override fun equals(other: Any?): Boolean"))
        #expect(operationFile.contents.contains("if (!body.contentEquals(other.body)) return false"))
        #expect(operationFile.contents.contains("var result = body.contentHashCode()"))
    }

    @Test func `multipart requests use dedicated body type`() throws {
        let operation = ApiOperation.postMultipart(
            name: "upload",
            path: .relative("/upload"),
            security: .unsecured,
            multiParts: ["file"],
        )
        let files = try KotlinApiPackageGenerator(package: testPackage(operations: [operation], references: [])).generatedFiles()
        let operationFile = try #require(files.first {
            $0.relativePath == "generated-api/src/commonMain/kotlin/com/example/api/admin/users/UploadOperation.kt"
        })
        let runtime = try #require(files.first {
            $0.relativePath == "generated-api/src/commonMain/kotlin/com/example/api/ApiRuntime.kt"
        })

        #expect(operationFile.contents.contains("val body: MultipartBody = MultipartBody()"))
        #expect(operationFile.contents.contains("copy(body = body.copy(parts = body.parts + (\"file\" to part)))"))
        #expect(!operationFile.contents.contains("Map<String, MultipartBody.Part>"))
        #expect(runtime.contents.contains("val parts: Map<String, Part> = emptyMap()"))
    }

    @Test func `json map request bodies do not use multipart runtime branch`() throws {
        let operation = ApiOperation.post(
            name: "updateLabels",
            path: .relative("/labels"),
            security: .unsecured,
            request: ApiTypeSchema.keyedByString(.string(), isOptional: true),
        )
        let files = try KotlinApiPackageGenerator(package: testPackage(operations: [operation], references: [])).generatedFiles()
        let operationFile = try #require(files.first {
            $0.relativePath == "generated-api/src/commonMain/kotlin/com/example/api/admin/users/UpdateLabelsOperation.kt"
        })
        let runtime = try #require(files.first {
            $0.relativePath == "generated-api/src/commonMain/kotlin/com/example/api/ApiRuntime.kt"
        })

        #expect(operationFile.contents.contains("val body: Map<String, String?>"))
        #expect(operationFile.contents.contains("contentType = \"application/json\""))
        #expect(runtime.contents.contains("is MultipartBody ->"))
        #expect(!runtime.contents.contains("is Map<*, *> ->"))
    }

    @Test func `multipart part setters must be unique`() {
        let operation = ApiOperation.postMultipart(
            name: "upload",
            path: .relative("/upload"),
            security: .unsecured,
            multiParts: ["file-name", "file_name"],
        )

        #expect(throws: KotlinGeneratorError.invalidOperation(
            operationName: operation.name,
            reason: "has multipart part names that generate duplicate setters",
        )) {
            try KotlinApiPackageGenerator(package: testPackage(operations: [operation], references: [])).generatedFiles()
        }
    }

    @Test func `multipart part list must not be empty`() {
        let operation = ApiOperation.postMultipart(
            name: "upload",
            path: .relative("/upload"),
            security: .unsecured,
            multiParts: [],
        )

        #expect(throws: KotlinGeneratorError.invalidOperation(
            operationName: operation.name,
            reason: "has no multipart part names",
        )) {
            try KotlinApiPackageGenerator(package: testPackage(operations: [operation], references: [])).generatedFiles()
        }
    }

    @Test func `json request bodies carry static ktor type info`() throws {
        let payload = ApiTypeSchema.object(typeName: "Payload", properties: [.string("name")])
        let operation = ApiOperation.post(
            name: "create",
            path: .relative("/payloads"),
            security: .unsecured,
            request: payload.asRef,
        )
        let files = try KotlinApiPackageGenerator(package: testPackage(operations: [operation], references: [payload])).generatedFiles()
        let operationFile = try #require(files.first {
            $0.relativePath == "generated-api/src/commonMain/kotlin/com/example/api/admin/users/CreateOperation.kt"
        })
        let runtime = try #require(files.first {
            $0.relativePath == "generated-api/src/commonMain/kotlin/com/example/api/ApiRuntime.kt"
        })

        #expect(operationFile.contents.contains("import io.ktor.util.reflect.typeInfo"))
        #expect(operationFile.contents.contains("body = body,"))
        #expect(operationFile.contents.contains("bodyType = typeInfo<Payload>(),"))
        #expect(runtime.contents.contains("val bodyType: TypeInfo? = null"))
        #expect(runtime.contents.contains("else -> request.bodyType?.let { setBody(body, it) } ?: setBody(body)"))
    }

    @Test func `generated ktor runtime wires upload progress`() {
        let runtime = KotlinRuntimeEmitter().kotlinCode(packageName: "com.example.api").toString()

        #expect(runtime.contains("import io.ktor.client.plugins.onUpload"))
        #expect(runtime.components(separatedBy: "executeRaw(request.toApiRequest(), validStatusCodes, progress)").count - 1 == 2)
        #expect(runtime.contains("progress?.let { uploadProgress ->"))
        #expect(runtime.contains("onUpload { bytesSent, totalBytes ->"))
        #expect(runtime.contains("uploadProgress.update(bytesSent, totalBytes)"))
    }

    @Test func `generated ktor runtime always sets multipart content disposition`() {
        let runtime = KotlinRuntimeEmitter().kotlinCode(packageName: "com.example.api").toString()

        #expect(runtime.contains("append(\"form-data; name=\\\"\")"))
        #expect(runtime.contains("value.fileName?.let {"))
        #expect(runtime.contains("append(\"; filename=\\\"\")"))
    }

    @Test func `generated ktor runtime uses content equality for binary containers`() {
        let runtime = KotlinRuntimeEmitter().kotlinCode(packageName: "com.example.api").toString()

        #expect(runtime.contains("if (!bytes.contentEquals(other.bytes)) return false"))
        #expect(runtime.contains("bytes.contentHashCode()"))
        #expect(runtime.contains("if (!bodyContentEquals(other.body)) return false"))
        #expect(runtime.contains("bodyContentHashCode()"))
        #expect(runtime.contains("if (!valueContentEquals(other.value)) return false"))
        #expect(runtime.contains("valueContentHashCode()"))
        #expect(runtime.contains("val otherBody = other.body"))
        #expect(runtime.contains("!body.contentEquals(otherBody)"))
        #expect(runtime.contains("body?.contentHashCode() ?: 0"))
    }

    @Test func `generated ktor runtime filters auth and preserves explicit accept`() {
        let runtime = KotlinRuntimeEmitter().kotlinCode(packageName: "com.example.api").toString()

        #expect(runtime.contains("override suspend fun apiKey(): String? = apiKeyProvider.apiKey()?.takeIf { it.isNotBlank() }"))
        #expect(runtime.contains("""
        sealed class ApiError(message: String) : Exception(message) {
            data object ApiKeyRequired : ApiError("API key is required")
            data object InvalidUrl : ApiError("Invalid URL")
            data object RequestEncodingFailed : ApiError("Request encoding failed")
            data class UnexpectedStatusCode(val statusCode: Int) : ApiError("Unexpected HTTP status $statusCode")
        }
        """))
        #expect(runtime.contains("""
        class KtorRestClient(
            private val httpClient: HttpClient,
            private val baseUrlProvider: BaseUrlProvider,
            private val apiKeyProvider: ApiKeyProvider,
            private val bodyCodec: BodyCodec,
            private val defaultHttpHeaderProvider: DefaultHttpHeaderProvider = DefaultHttpHeaderProvider { emptyMap() },
            private val errorFlow: MutableSharedFlow<ApiError> = MutableSharedFlow(extraBufferCapacity = 64),
        ) : RestClient {
        """))
        #expect(runtime.contains("val errors: SharedFlow<ApiError>"))
        #expect(runtime.contains("override val errors: SharedFlow<ApiError> = errorFlow"))
        #expect(runtime.contains("val effectiveHeaders = defaultHttpHeaderProvider.headers() + apiRequest.headers"))
        #expect(runtime.contains("for ((name, value) in effectiveHeaders)"))
        #expect(runtime.contains("if (effectiveHeaders.keys.none { it.equals(\"Accept\", ignoreCase = true) })"))
        #expect(runtime.contains("expectSuccess = false"))
        #expect(runtime.contains("override suspend fun requireApiKey(): String = apiKey() ?: throwError(ApiError.ApiKeyRequired)"))
        #expect(runtime.contains("throwError(ApiError.UnexpectedStatusCode(statusCode))"))
        #expect(runtime.contains("""
            private suspend fun throwError(error: ApiError): Nothing {
                errorFlow.emit(error)
                throw error
            }
        """))
        #expect(runtime.contains("body = ktorResponse.bodyAsBytes()"))
        #expect(runtime.contains("mimeType = ktorResponse.headers[\"Content-Type\"]"))
        #expect(!runtime.contains("Unexpected HTTP status ${response.statusCode}"))
    }

    @Test func `generated ktor runtime carries swift response convenience metadata`() {
        let runtime = KotlinRuntimeEmitter().kotlinCode(packageName: "com.example.api").toString()

        #expect(runtime.contains("""
        data class ApiResponse(
            val statusCode: Int,
            val headers: Map<String, List<String>> = emptyMap(),
            val body: ByteArray? = null,
            val mimeType: String? = null,
        ) {
        """))
        #expect(runtime.contains("val is200: Boolean get() = statusCode == 200"))
        #expect(runtime.contains("val is201: Boolean get() = statusCode == 201"))
        #expect(runtime.contains("val is20x: Boolean get() = statusCode in 200..299"))
        #expect(runtime.contains("val is304: Boolean get() = statusCode == 304"))
        #expect(runtime.contains("val is400: Boolean get() = statusCode == 400"))
        #expect(runtime.contains("val is401: Boolean get() = statusCode == 401"))
        #expect(runtime.contains("val is403: Boolean get() = statusCode == 403"))
        #expect(runtime.contains("val is404: Boolean get() = statusCode == 404"))
        #expect(runtime.contains("val is50x: Boolean get() = statusCode in 500..599"))
        #expect(runtime.contains("if (mimeType != other.mimeType) return false"))
    }

    @Test func `generated ktor paged results carries count and has next`() {
        let runtime = KotlinRuntimeEmitter().kotlinCode(packageName: "com.example.api").toString()

        #expect(runtime.contains("""
        data class PagedResults<T>(
            val results: List<T>,
            val next: String? = null,
            val count: Int? = null,
        )
        """))
        #expect(runtime.contains("val hasNext: Boolean get() = next != null && results.isNotEmpty()"))
        #expect(runtime.contains("interface Identifiable<out ID> {\n    val id: ID\n}"))
    }

    @Test func `generated ktor runtime carries response mime and binary serializer`() {
        let runtime = KotlinRuntimeEmitter().kotlinCode(packageName: "com.example.api").toString()

        #expect(runtime.contains("val mimeType: String"))
        #expect(runtime.contains("object ByteArrayBase64Serializer : KSerializer<ByteArray>"))
        #expect(runtime.contains("PrimitiveSerialDescriptor(\"ByteArrayBase64\", PrimitiveKind.STRING)"))
        #expect(runtime.contains("Base64.Default.decode(decoder.decodeString())"))
        #expect(runtime.contains("encoder.encodeString(Base64.Default.encode(value))"))
    }

    @Test func `generated ktor runtime preserves date time parameter fractions`() {
        let runtime = KotlinRuntimeEmitter().kotlinCode(packageName: "com.example.api").toString()

        #expect(runtime.contains("is Instant -> toApiDateTimeValue()"))
        #expect(runtime.contains("private fun Instant.toApiDateTimeValue(): String ="))
        #expect(runtime.contains("toString()"))
        #expect(!runtime.contains(#"replace(Regex("\\.\\d+Z$"), "Z")"#))
    }

    @Test func `generated ktor runtime escapes multipart header values`() {
        let runtime = KotlinRuntimeEmitter().kotlinCode(packageName: "com.example.api").toString()

        #expect(runtime.contains("append(name.toMultipartHeaderValue())"))
        #expect(runtime.contains("append(it.toMultipartHeaderValue())"))
        #expect(!runtime.contains(#"append("Content-Disposition", disposition)"#))
        #expect(runtime.contains("private fun String.toMultipartHeaderValue(): String ="))
        #expect(runtime.contains(#".replace("\r", "%0D")"#))
        #expect(runtime.contains(#".replace("\n", "%0A")"#))
    }

    @Test func `generated ktor runtime exposes multipart part helpers`() {
        let runtime = KotlinRuntimeEmitter().kotlinCode(packageName: "com.example.api").toString()

        #expect(runtime.contains("companion object {\n            fun bytes("))
        #expect(runtime.contains("fun text("))
        #expect(runtime.contains("contentType: String = \"text/plain\""))
        #expect(runtime.contains("bytes = value.encodeToByteArray()"))
        #expect(runtime.contains("import kotlinx.serialization.json.Json"))
        #expect(runtime.contains("fun <T> json("))
        #expect(runtime.contains("serializer: KSerializer<T>"))
        #expect(runtime.contains("contentType: String = \"application/json\""))
        #expect(runtime.contains("bytes = json.encodeToString(serializer, value).encodeToByteArray()"))
    }

    @Test func `generated ktor runtime encodes json byte array as base 64 string`() {
        let runtime = KotlinRuntimeEmitter().kotlinCode(packageName: "com.example.api").toString()

        #expect(runtime.contains("if (request.bodyType != null)"))
        #expect(runtime.contains("@OptIn(ExperimentalEncodingApi::class)"))
        #expect(runtime.contains("private fun HttpRequestBuilder.applyBody"))
        #expect(runtime.contains(#"("\"" + Base64.Default.encode(body) + "\"").encodeToByteArray()"#))
        #expect(runtime.contains(#"ContentType.parse(request.contentType ?: "application/json")"#))
        #expect(runtime.contains(#"ContentType.parse(request.contentType ?: "application/octet-stream")"#))
    }

    @Test func `generated ktor runtime encodes path segments from utf 8 bytes`() {
        let runtime = KotlinRuntimeEmitter().kotlinCode(packageName: "com.example.api").toString()

        #expect(runtime.contains("for (byte in value.encodeToByteArray())"))
        #expect(runtime.contains("val code = byte.toInt().and(0xff)"))
        #expect(runtime.contains("char in 'A'..'Z' || char in 'a'..'z' || char in '0'..'9' || char in \"-._~\""))
        #expect(!runtime.contains("char.toString().encodeToByteArray()"))
    }

    @Test func `unsecured service methods use request directly`() throws {
        let ping = ApiOperation.get(
            name: "ping",
            path: .relative("/ping"),
            security: .unsecured,
        )
        let secure = ApiOperation.get(
            name: "secure",
            path: .relative("/secure"),
            security: .secured,
        )
        let files = try KotlinApiPackageGenerator(package: testPackage(operations: [ping, secure], references: [])).generatedFiles()
        let service = try #require(files.first {
            $0.relativePath == "generated-api/src/commonMain/kotlin/com/example/api/admin/users/AdminUsersApi.kt"
        })
        let secureOperation = try #require(files.first {
            $0.relativePath == "generated-api/src/commonMain/kotlin/com/example/api/admin/users/SecureOperation.kt"
        })

        #expect(service.contents.contains("override suspend fun ping(request: PingOperation.Request): ApiResponse"))
        #expect(service.contents.contains("request = request,"))
        #expect(!service.contents.contains("val adaptedRequest = request\n"))
        #expect(service.contents.contains("val adaptedRequest = request.copy(apiKey = request.apiKey?.takeIf { it.isNotBlank() } ?: client.requireApiKey())"))
        #expect(secureOperation.contents.contains("apiKey?.takeIf { it.isNotBlank() }?.let { values[\"Authorization\"] = it.toApiFormValue() }"))
        #expect(!secureOperation.contents.contains("values[\"Authorization\"] = apiKey.toApiFormValue()"))
    }

    @Test func `mapped operation imports use generator options`() throws {
        let mappedStatus = ApiTypeSchema.reference(typeName: "MappedStatus", strict: false, imports: ["Foundation"])
        let operation = ApiOperation.get(
            name: "search",
            path: .relative("/search"),
            security: .unsecured,
            parameters: [
                .query("status", .stringEnumValue(type: mappedStatus))
            ],
        )
        let options = KotlinGeneratorOptions(typeMappings: KotlinTypeMapping.defaultMappings + [
            KotlinTypeMapping(
                apiTypeName: "MappedStatus",
                kotlinType: "ExternalStatus",
                imports: ["com.example.shared.ExternalStatus"],
            )
        ])
        let files = try KotlinApiPackageGenerator(
            package: testPackage(operations: [operation], references: []),
            options: options,
        )
        .generatedFiles()
        let operationFile = try #require(files.first {
            $0.relativePath == "generated-api/src/commonMain/kotlin/com/example/api/admin/users/SearchOperation.kt"
        })

        #expect(operationFile.contents.contains("import com.example.shared.ExternalStatus"))
        #expect(!operationFile.contents.contains("import Foundation"))
    }

    @Test func `mapped operation defaults use generator options`() throws {
        let mappedStatus = ApiTypeSchema.reference(typeName: "MappedStatus", strict: false, imports: ["Foundation"])
        let operation = ApiOperation.get(
            name: "search",
            path: .relative("/search"),
            security: .unsecured,
            parameters: [
                .query("status", .stringEnumValue(type: mappedStatus, defaultValue: "active"))
            ],
        )
        let options = KotlinGeneratorOptions(typeMappings: KotlinTypeMapping.defaultMappings + [
            KotlinTypeMapping(
                apiTypeName: "MappedStatus",
                kotlinType: "ExternalStatus",
                imports: ["com.example.shared.ExternalStatus"],
            )
        ])
        let files = try KotlinApiPackageGenerator(
            package: testPackage(operations: [operation], references: []),
            options: options,
        )
        .generatedFiles()
        let operationFile = try #require(files.first {
            $0.relativePath == "generated-api/src/commonMain/kotlin/com/example/api/admin/users/SearchOperation.kt"
        })

        #expect(operationFile.contents.contains("val status: ExternalStatus = ExternalStatus.fromValue(\"active\")"))
        #expect(!operationFile.contents.contains("MappedStatus.fromValue"))
    }

    @Test func `invalid base package fails validation`() {
        for packageName in ["1.invalid", ".com", "com.", "com..example"] {
            let options = KotlinGeneratorOptions(basePackage: packageName)

            #expect(throws: KotlinGeneratorError.invalidBasePackage(packageName)) {
                try KotlinApiPackageGenerator(package: testPackage(), options: options).generatedFiles()
            }
        }
    }

    @Test func `invalid gradle module name fails validation`() {
        for moduleName in [".", "generated api", "generated/api", "generated:api", "generated\napi"] {
            let options = KotlinGeneratorOptions(gradle: KotlinGradleOptions(moduleName: moduleName))

            #expect(throws: KotlinGeneratorError.invalidModuleName(moduleName)) {
                try KotlinApiPackageGenerator(package: testPackage(), options: options).generatedFiles()
            }
        }
    }

    @Test func `generated kotlin name collisions fail validation`() {
        let operationCollision = [
            ApiOperation.get(name: "get-user", path: .relative("/one"), security: .unsecured),
            ApiOperation.get(name: "get_user", path: .relative("/two"), security: .unsecured)
        ]

        #expect(throws: KotlinGeneratorError.invalidPackage(
            reason: #"definition Users has duplicate operation type names: ["GetUserOperation"]"#,
        )) {
            try KotlinApiPackageGenerator(package: testPackage(operations: operationCollision, references: [])).generatedFiles()
        }

        let fieldCollision = ApiTypeSchema.object(typeName: "Collision", properties: [
            .string("user-id", propertyName: "user-id"),
            .string("user_id", propertyName: "user_id")
        ])

        #expect(throws: KotlinGeneratorError.invalidPackage(
            reason: #"model Collision has duplicate property names: ["userId"]"#,
        )) {
            try KotlinApiPackageGenerator(package: testPackage(response: fieldCollision.asRef, references: [fieldCollision])).generatedFiles()
        }

        let enumCollision = ApiTypeSchema.stringEnum(
            typeName: "State",
            values: [
                (name: "in-progress", rawName: "in-progress"),
                (name: "in_progress", rawName: "in_progress")
            ],
        )

        #expect(throws: KotlinGeneratorError.invalidPackage(
            reason: #"enum State has duplicate case names: ["InProgress"]"#,
        )) {
            try KotlinApiPackageGenerator(package: testPackage(response: enumCollision.asRef, references: [enumCollision])).generatedFiles()
        }

        let enumRawCollision = ApiTypeSchema.stringEnum(
            typeName: "State",
            values: [
                (name: "Open", rawName: "active"),
                (name: "Closed", rawName: "active")
            ],
        )

        #expect(throws: KotlinGeneratorError.invalidPackage(
            reason: #"enum State has duplicate raw values: ["active"]"#,
        )) {
            try KotlinApiPackageGenerator(package: testPackage(response: enumRawCollision.asRef, references: [enumRawCollision])).generatedFiles()
        }

        let enumGarbageCaseCollision = ApiTypeSchema.stringEnum(
            typeName: "State",
            values: [
                (name: "Garbage", rawName: "garbage")
            ],
            supportGarbage: true,
        )

        #expect(throws: KotlinGeneratorError.invalidPackage(
            reason: #"enum State has duplicate case names: ["Garbage"]"#,
        )) {
            try KotlinApiPackageGenerator(package: testPackage(response: enumGarbageCaseCollision.asRef, references: [enumGarbageCaseCollision])).generatedFiles()
        }

        let enumGarbageRawCollision = ApiTypeSchema.stringEnum(
            typeName: "State",
            values: [
                (name: "Open", rawName: "__garbage__")
            ],
            supportGarbage: true,
        )

        #expect(throws: KotlinGeneratorError.invalidPackage(
            reason: #"enum State has duplicate raw values: ["__garbage__"]"#,
        )) {
            try KotlinApiPackageGenerator(package: testPackage(response: enumGarbageRawCollision.asRef, references: [enumGarbageRawCollision])).generatedFiles()
        }

        let intEnumRawCollision = ApiTypeSchema.intEnum(
            typeName: "Score",
            values: [
                (name: "Low", rawValue: 1),
                (name: "High", rawValue: 1)
            ],
        )

        #expect(throws: KotlinGeneratorError.invalidPackage(
            reason: "enum Score has duplicate raw values: [1]",
        )) {
            try KotlinApiPackageGenerator(package: testPackage(response: intEnumRawCollision.asRef, references: [intEnumRawCollision])).generatedFiles()
        }
    }

    @Test func `generated kotlin reference validation matches swift client`() {
        let nonReferenceable = ApiTypeSchema.array(.string())
        #expect(throws: KotlinGeneratorError.invalidPackage(
            reason: "definition Users references are not all referenceable: [\"[String]\"]",
        )) {
            try KotlinApiPackageGenerator(
                package: testPackage(response: nil, references: [nonReferenceable]),
            )
            .generatedFiles()
        }

        let nonFiniteDouble = ApiTypeSchema.object(typeName: "Measurement", properties: [
            .double("value", initialValue: .infinity)
        ])
        #expect(throws: KotlinGeneratorError.invalidPackage(
            reason: "double initial value must be finite",
        )) {
            try KotlinApiPackageGenerator(package: testPackage(response: nonFiniteDouble.asRef, references: [nonFiniteDouble])).generatedFiles()
        }

        let rawNameCollision = ApiTypeSchema.object(typeName: "Collision", properties: [
            .string("trace-id", propertyName: "traceId"),
            .string("trace-id", propertyName: "alternateTraceId")
        ])
        #expect(throws: KotlinGeneratorError.invalidPackage(
            reason: #"model Collision has duplicate raw property names: ["trace-id"]"#,
        )) {
            try KotlinApiPackageGenerator(package: testPackage(response: rawNameCollision.asRef, references: [rawNameCollision])).generatedFiles()
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
            ],
        )
        #expect(throws: KotlinGeneratorError.invalidPackage(
            reason: #"dynamic object Envelope has self-encoded property names that collide with reserved names: ["kind"]"#,
        )) {
            try KotlinApiPackageGenerator(package: testPackage(response: dynamic.asRef, references: [dynamic, payload])).generatedFiles()
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
            ],
        )
        #expect(throws: Never.self) {
            try KotlinApiPackageGenerator(
                package: testPackage(response: dynamicWithDataKey.asRef, references: [dynamicWithDataKey, payloadWithDataKey]),
            )
            .generatedFiles()
        }
    }

    @Test func `generated kotlin package collisions fail validation`() {
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
            imports: [],
        )

        #expect(throws: KotlinGeneratorError.invalidPackage(
            reason: #"has duplicate module type names: ["ClassApiModule"]"#,
        )) {
            try KotlinApiPackageGenerator(package: moduleCollision).generatedFiles()
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
            imports: [],
        )

        #expect(throws: KotlinGeneratorError.invalidPackage(
            reason: #"module Admin has duplicate API type names: ["AdminUserGroupApi"]"#,
        )) {
            try KotlinApiPackageGenerator(package: definitionCollision).generatedFiles()
        }
    }

    @Test func `acceptable statuses must be non empty http statuses`() {
        let emptyStatuses = ApiOperation.get(
            name: "ping",
            path: .relative("/ping"),
            security: .unsecured,
            response: nil,
            acceptableStatuses: [],
        )

        #expect(throws: KotlinGeneratorError.emptyAcceptableStatuses(operationName: emptyStatuses.name)) {
            try KotlinApiPackageGenerator(package: testPackage(operations: [emptyStatuses], references: [])).generatedFiles()
        }

        for statusCode in [99, 600] {
            let operation = ApiOperation.get(
                name: "ping",
                path: .relative("/ping"),
                security: .unsecured,
                response: nil,
                acceptableStatuses: [statusCode],
            )

            #expect(throws: KotlinGeneratorError.invalidAcceptableStatus(operationName: operation.name, statusCode: statusCode)) {
                try KotlinApiPackageGenerator(package: testPackage(operations: [operation], references: [])).generatedFiles()
            }
        }
    }

    @Test func `invalid operation shapes fail before generating broken kotlin client`() {
        let user = ApiTypeSchema.object(typeName: "User", properties: [.string("name")])
        let bodyCollision = ApiOperation.post(
            name: "create",
            path: .relative("/users"),
            security: .unsecured,
            parameters: [
                .query("body", .string())
            ],
            request: user.asRef,
        )

        #expect(throws: KotlinGeneratorError.invalidOperation(
            operationName: bodyCollision.name,
            reason: #"has parameter names that collide with generated request members: ["body"]"#,
        )) {
            try KotlinApiPackageGenerator(package: testPackage(operations: [bodyCollision], references: [user])).generatedFiles()
        }

        let cookieConflict = ApiOperation.get(
            name: "search",
            path: .relative("/users"),
            security: .unsecured,
            parameters: [
                .header("Cookie", .string()),
                .cookie("session", .string())
            ],
        )

        #expect(throws: KotlinGeneratorError.invalidOperation(
            operationName: cookieConflict.name,
            reason: "cannot combine Cookie header parameters with cookie parameters",
        )) {
            try KotlinApiPackageGenerator(package: testPackage(operations: [cookieConflict], references: [])).generatedFiles()
        }

        let caseInsensitiveHeaderConflict = ApiOperation.get(
            name: "trace",
            path: .relative("/trace"),
            security: .unsecured,
            parameters: [
                .header("X-Trace", .string()),
                .header("x-trace", .string(), propertyName: "trace2")
            ],
        )

        #expect(throws: KotlinGeneratorError.invalidOperation(
            operationName: caseInsensitiveHeaderConflict.name,
            reason: "has duplicate parameter wire names",
        )) {
            try KotlinApiPackageGenerator(package: testPackage(operations: [caseInsensitiveHeaderConflict], references: [])).generatedFiles()
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
            extraImports: [],
        )

        #expect(throws: KotlinGeneratorError.invalidOperation(
            operationName: nilJsonResponse.name,
            reason: "has a typed response without a data type",
        )) {
            try KotlinApiPackageGenerator(package: testPackage(operations: [nilJsonResponse], references: [])).generatedFiles()
        }

        let pathMismatch = ApiOperation.get(
            name: "fetch",
            path: .relative("/users/{id}"),
            security: .unsecured,
            parameters: [
                .path("user_id", .string())
            ],
        )

        #expect(throws: KotlinGeneratorError.invalidOperation(
            operationName: pathMismatch.name,
            reason: "has path parameters that do not match url placeholders",
        )) {
            try KotlinApiPackageGenerator(package: testPackage(operations: [pathMismatch], references: [])).generatedFiles()
        }

        let runtimePathParameter = ApiOperation.get(
            name: "follow",
            path: .runtime,
            security: .unsecured,
            parameters: [
                .path("id", .string())
            ],
        )

        #expect(throws: KotlinGeneratorError.invalidOperation(
            operationName: runtimePathParameter.name,
            reason: "uses runtime url with path parameters",
        )) {
            try KotlinApiPackageGenerator(package: testPackage(operations: [runtimePathParameter], references: [])).generatedFiles()
        }

        let relativeQueryPlaceholder = ApiOperation.get(
            name: "relativeQuery",
            path: .relative("/users?filter={filter}"),
            security: .unsecured,
            parameters: [.path("filter", .string())],
        )

        #expect(throws: KotlinGeneratorError.invalidOperation(
            operationName: relativeQueryPlaceholder.name,
            reason: "has path parameters that do not match url placeholders",
        )) {
            try KotlinApiPackageGenerator(package: testPackage(operations: [relativeQueryPlaceholder], references: [])).generatedFiles()
        }

        let absoluteHostPlaceholder = ApiOperation.get(
            name: "absoluteHost",
            path: .absolute("https://{tenant}.example.com/users"),
            security: .unsecured,
            parameters: [.path("tenant", .string())],
        )

        #expect(throws: KotlinGeneratorError.invalidOperation(
            operationName: absoluteHostPlaceholder.name,
            reason: "has path parameters that do not match url placeholders",
        )) {
            try KotlinApiPackageGenerator(package: testPackage(operations: [absoluteHostPlaceholder], references: [])).generatedFiles()
        }

        let absoluteQueryPlaceholder = ApiOperation.get(
            name: "absoluteQuery",
            path: .absolute("https://api.example.com/users?filter={filter}"),
            security: .unsecured,
            parameters: [.path("filter", .string())],
        )

        #expect(throws: KotlinGeneratorError.invalidOperation(
            operationName: absoluteQueryPlaceholder.name,
            reason: "has path parameters that do not match url placeholders",
        )) {
            try KotlinApiPackageGenerator(package: testPackage(operations: [absoluteQueryPlaceholder], references: [])).generatedFiles()
        }

        let invalidEnumType = ApiOperation.get(
            name: "invalidEnum",
            path: .relative("/users"),
            security: .unsecured,
            parameters: [
                .query("visibility", .stringEnumValue(type: .string()))
            ],
        )

        #expect(throws: KotlinGeneratorError.invalidOperation(
            operationName: invalidEnumType.name,
            reason: "has invalid enum parameter type",
        )) {
            try KotlinApiPackageGenerator(package: testPackage(operations: [invalidEnumType], references: [])).generatedFiles()
        }

        let visibility = ApiTypeSchema.stringEnum(
            typeName: "Visibility",
            values: [(name: "Public", rawName: "public")],
        )
        let invalidEnumDefault = ApiOperation.get(
            name: "invalidEnumDefault",
            path: .relative("/users"),
            security: .unsecured,
            parameters: [
                .query("visibility", .stringEnumValue(type: visibility.asRef, defaultValue: "private"))
            ],
        )

        #expect(throws: KotlinGeneratorError.invalidOperation(
            operationName: invalidEnumDefault.name,
            reason: "has invalid enum parameter default",
        )) {
            try KotlinApiPackageGenerator(package: testPackage(operations: [invalidEnumDefault], references: [visibility])).generatedFiles()
        }

        let enumArrayPath = ApiOperation.get(
            name: "enumArrayPath",
            path: .relative("/users/{visibility}"),
            security: .unsecured,
            parameters: [
                .path("visibility", .stringEnumArray(type: visibility.asRef))
            ],
        )

        #expect(throws: KotlinGeneratorError.invalidOperation(
            operationName: enumArrayPath.name,
            reason: "has enum array path parameter",
        )) {
            try KotlinApiPackageGenerator(package: testPackage(operations: [enumArrayPath], references: [visibility])).generatedFiles()
        }
    }

    @Test func `typed responses reject mixed bodyless statuses`() {
        let user = ApiTypeSchema.object(typeName: "User", properties: [.string("name")])
        let operation = ApiOperation.get(
            name: "fetch",
            path: .relative("/users"),
            security: .unsecured,
            response: user.asRef,
            acceptableStatuses: [100, 199, 200, 204, 205, 304],
        )

        #expect(throws: KotlinGeneratorError.typedResponseWithBodylessStatus(operationName: operation.name, statusCode: 100)) {
            try KotlinApiPackageGenerator(package: testPackage(operations: [operation], references: [user])).generatedFiles()
        }
    }

    @Test func `typed responses reject only bodyless statuses`() {
        let user = ApiTypeSchema.object(typeName: "User", properties: [.string("name")])
        for statusCodes in [[100, 199], [204, 205, 304]] {
            let operation = ApiOperation.get(
                name: "fetch",
                path: .relative("/users"),
                security: .unsecured,
                response: user.asRef,
                acceptableStatuses: statusCodes,
            )

            #expect(throws: KotlinGeneratorError.typedResponseWithBodylessStatus(operationName: operation.name, statusCode: statusCodes[0])) {
                try KotlinApiPackageGenerator(package: testPackage(operations: [operation], references: [user])).generatedFiles()
            }
        }
    }

    @Test func `unresolved external reference fails validation`() {
        let external = ApiTypeSchema.reference(typeName: "ExternalThing", strict: false)
        let package = testPackage(response: external)

        #expect(throws: KotlinGeneratorError.unresolvedExternalType("ExternalThing")) {
            try KotlinApiPackageGenerator(package: package).generatedFiles()
        }
    }

    private func testPackage(
        response: ApiTypeSchema? = nil,
        operations: [ApiOperation]? = nil,
        references: [ApiTypeSchema]? = nil,
    ) -> ApiPackage {
        let user = ApiTypeSchema.object(
            typeName: "User",
            properties: [
                .string("display_name", propertyName: "displayName"),
                .int64("id")
            ],
            protocols: ["Identifiable"],
        )
        let operation = ApiOperation.get(
            name: "get",
            path: .relative("/users/{id}"),
            security: .optional,
            parameters: [
                .path("id", .int64()),
                .query("fields", .stringArray()).optional
            ],
            response: response ?? user.asRef,
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
            imports: [],
        )
    }
}
