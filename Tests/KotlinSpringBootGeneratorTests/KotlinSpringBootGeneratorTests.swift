import Foundation
import GeneratorModels
@testable import KotlinSpringBootGenerator
import Testing

@Suite(.serialized) struct KotlinSpringBootGeneratorTests {
    @Test func optionsExposeDefaults() {
        let options = KotlinSpringBootGeneratorOptions()

        #expect(options.basePackage == "com.example.api")
        #expect(options.applicationName == "GeneratedApiApplication")
        #expect(options.gradle.projectName == "generated-api")
        #expect(options.gradle.springBootVersion == "4.1.0")
        #expect(options.gradle.kotlinVersion == "2.4.0")
        #expect(options.gradle.jvmToolchain == 21)
        #expect(options.generateApplication)
        #expect(options.generateRuntime)
        #expect(options.overwritePolicy == .replaceManagedFiles)
    }

    @Test func invalidBasePackageFailsValidation() {
        for packageName in ["1.invalid", ".com", "com.", "com..example"] {
            let options = KotlinSpringBootGeneratorOptions(basePackage: packageName)

            #expect(throws: KotlinSpringBootGeneratorError.invalidBasePackage(packageName)) {
                try KotlinSpringBootApiPackageGenerator(package: testPackage(), options: options)
                    .generatedFiles()
            }
        }
    }

    @Test func generatedSpringEnumRawValueCollisionsFailValidation() {
        let enumRawCollision = ApiTypeSchema.stringEnum(
            typeName: "State",
            values: [
                (name: "Open", rawName: "active"),
                (name: "Closed", rawName: "active")
            ]
        )

        #expect(throws: KotlinSpringBootGeneratorError.invalidPackage(
            reason: #"enum State has duplicate raw values: ["active"]"#
        )) {
            try KotlinSpringBootApiPackageGenerator(
                package: testPackage(response: enumRawCollision.asRef, references: [enumRawCollision])
            )
            .generatedFiles()
        }

        let enumGarbageCaseCollision = ApiTypeSchema.stringEnum(
            typeName: "State",
            values: [
                (name: "Garbage", rawName: "garbage")
            ],
            supportGarbage: true
        )

        #expect(throws: KotlinSpringBootGeneratorError.invalidPackage(
            reason: #"enum State has duplicate case names: ["Garbage"]"#
        )) {
            try KotlinSpringBootApiPackageGenerator(
                package: testPackage(
                    response: enumGarbageCaseCollision.asRef,
                    references: [enumGarbageCaseCollision]
                )
            )
            .generatedFiles()
        }

        let enumGarbageRawCollision = ApiTypeSchema.stringEnum(
            typeName: "State",
            values: [
                (name: "Open", rawName: "__garbage__")
            ],
            supportGarbage: true
        )

        #expect(throws: KotlinSpringBootGeneratorError.invalidPackage(
            reason: #"enum State has duplicate raw values: ["__garbage__"]"#
        )) {
            try KotlinSpringBootApiPackageGenerator(
                package: testPackage(
                    response: enumGarbageRawCollision.asRef,
                    references: [enumGarbageRawCollision]
                )
            )
            .generatedFiles()
        }

        let intEnumRawCollision = ApiTypeSchema.intEnum(
            typeName: "Score",
            values: [
                (name: "Low", rawValue: 1),
                (name: "High", rawValue: 1)
            ]
        )

        #expect(throws: KotlinSpringBootGeneratorError.invalidPackage(
            reason: "enum Score has duplicate raw values: [1]"
        )) {
            try KotlinSpringBootApiPackageGenerator(
                package: testPackage(response: intEnumRawCollision.asRef, references: [intEnumRawCollision])
            )
            .generatedFiles()
        }
    }

    @Test func generatedSpringReferenceValidationMatchesSwiftClient() {
        let nonReferenceable = ApiTypeSchema.array(.string())
        #expect(throws: KotlinSpringBootGeneratorError.invalidPackage(
            reason: "definition Users references are not all referenceable: [\"[String]\"]"
        )) {
            try KotlinSpringBootApiPackageGenerator(
                package: testPackage(response: nil, references: [nonReferenceable])
            )
            .generatedFiles()
        }

        let nonFiniteDouble = ApiTypeSchema.object(typeName: "Measurement", properties: [
            .double("value", initialValue: .infinity)
        ])
        #expect(throws: KotlinSpringBootGeneratorError.invalidPackage(
            reason: "double initial value must be finite"
        )) {
            try KotlinSpringBootApiPackageGenerator(
                package: testPackage(response: nonFiniteDouble.asRef, references: [nonFiniteDouble])
            )
            .generatedFiles()
        }

        let rawNameCollision = ApiTypeSchema.object(typeName: "Collision", properties: [
            .string("trace-id", propertyName: "traceId"),
            .string("trace-id", propertyName: "alternateTraceId")
        ])
        #expect(throws: KotlinSpringBootGeneratorError.invalidPackage(
            reason: #"model Collision has duplicate raw property names: ["trace-id"]"#
        )) {
            try KotlinSpringBootApiPackageGenerator(
                package: testPackage(response: rawNameCollision.asRef, references: [rawNameCollision])
            )
            .generatedFiles()
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
        #expect(throws: KotlinSpringBootGeneratorError.invalidPackage(
            reason: #"dynamic object Envelope has self-encoded property names that collide with reserved names: ["kind"]"#
        )) {
            try KotlinSpringBootApiPackageGenerator(
                package: testPackage(response: dynamic.asRef, references: [dynamic, payload])
            )
            .generatedFiles()
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
            try KotlinSpringBootApiPackageGenerator(
                package: testPackage(response: dynamicWithDataKey.asRef, references: [dynamicWithDataKey, payloadWithDataKey])
            )
            .generatedFiles()
        }
    }

    @Test func generatedSpringNameAndFilePathCollisionsFailValidation() throws {
        let operationCollision = [
            ApiOperation.get(name: "get-user", path: .relative("/one"), security: .unsecured),
            ApiOperation.get(name: "get_user", path: .relative("/two"), security: .unsecured)
        ]
        let operationCollisionPackage = ApiPackage(
            name: "Test",
            targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(
                UUID().uuidString, isDirectory: true
            ),
            modules: [
                ApiModule(name: "Admin", definitions: [
                    ApiService(name: "Users", operations: operationCollision)
                ])
            ],
            referencedModules: [],
            references: [],
            commonReferences: [],
            imports: []
        )

        #expect(throws: KotlinSpringBootGeneratorError.invalidPackage(
            reason: #"definition Users has duplicate request type names: ["AdminUsersGetUserRequest"]"#
        )) {
            try KotlinSpringBootApiPackageGenerator(package: operationCollisionPackage).generatedFiles()
        }

        let operation = ApiOperation.get(name: "list", path: .relative("/items"), security: .unsecured)
        let definitionCollisionPackage = ApiPackage(
            name: "Test",
            targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(
                UUID().uuidString, isDirectory: true
            ),
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

        #expect(throws: KotlinSpringBootGeneratorError.invalidPackage(
            reason: #"module Admin has duplicate service type names: ["AdminUserGroupService"]"#
        )) {
            try KotlinSpringBootApiPackageGenerator(package: definitionCollisionPackage).generatedFiles()
        }

        #expect(throws: KotlinSpringBootGeneratorError.invalidPackage(
            reason: #"has duplicate generated file paths: ["src/main/kotlin/com/example/api/ApiRuntime.kt"]"#
        )) {
            try KotlinSpringBootApiPackageGenerator(
                package: testPackage(),
                options: KotlinSpringBootGeneratorOptions(applicationName: "ApiRuntime")
            )
            .generatedFiles()
        }

        let files = try #require(try? KotlinSpringBootApiPackageGenerator(
            package: testPackage(),
            options: KotlinSpringBootGeneratorOptions(applicationName: "class")
        )
        .generatedFiles())
        let application = try #require(files.first {
            $0.relativePath == "src/main/kotlin/com/example/api/Class.kt"
        })

        #expect(application.contents.contains("class Class"))
        #expect(application.contents.contains("runApplication<Class>(*args)"))
    }

    @Test func springPathPlaceholderValidationOnlyChecksRoutableRelativeOperations() {
        let skippedInvalid = ApiOperation.get(
            name: "skipped",
            path: .absolute("https://api.example.com/items/{id}"),
            security: .unsecured,
            parameters: [.path("item_id", .string())]
        )
        let validRelative = ApiOperation.get(
            name: "list",
            path: .relative("/items"),
            security: .unsecured
        )
        let skippedPackage = ApiPackage(
            name: "Test",
            targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(
                UUID().uuidString, isDirectory: true
            ),
            modules: [
                ApiModule(name: "Catalog", definitions: [
                    ApiService(name: "Items", operations: [skippedInvalid, validRelative])
                ])
            ],
            referencedModules: [],
            references: [],
            commonReferences: [],
            imports: []
        )

        #expect(throws: Never.self) {
            try KotlinSpringBootApiPackageGenerator(package: skippedPackage).generatedFiles()
        }

        let pathMismatch = ApiOperation.get(
            name: "fetch",
            path: .relative("/items/{id}"),
            security: .unsecured,
            parameters: [.path("item_id", .string())]
        )

        #expect(throws: KotlinSpringBootGeneratorError.invalidOperation(
            operationName: pathMismatch.name,
            reason: "has path parameters that do not match url placeholders"
        )) {
            try KotlinSpringBootApiPackageGenerator(
                package: ApiPackage(
                    name: "Test",
                    targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(
                        UUID().uuidString, isDirectory: true
                    ),
                    modules: [
                        ApiModule(name: "Catalog", definitions: [
                            ApiService(name: "Items", operations: [pathMismatch])
                        ])
                    ],
                    referencedModules: [],
                    references: [],
                    commonReferences: [],
                    imports: []
                )
            )
            .generatedFiles()
        }

        let optionalPath = ApiOperation.get(
            name: "optional",
            path: .relative("/items/{id}"),
            security: .unsecured,
            parameters: [.path("id", .string()).optional]
        )

        #expect(throws: KotlinSpringBootGeneratorError.invalidOperation(
            operationName: optionalPath.name,
            reason: "has optional path parameters"
        )) {
            try KotlinSpringBootApiPackageGenerator(
                package: ApiPackage(
                    name: "Test",
                    targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(
                        UUID().uuidString, isDirectory: true
                    ),
                    modules: [
                        ApiModule(name: "Catalog", definitions: [
                            ApiService(name: "Items", operations: [optionalPath])
                        ])
                    ],
                    referencedModules: [],
                    references: [],
                    commonReferences: [],
                    imports: []
                )
            )
            .generatedFiles()
        }

        let malformedPath = ApiOperation.get(
            name: "malformed",
            path: .relative("/items/{id"),
            security: .unsecured,
            parameters: [.path("id", .string())]
        )

        #expect(throws: KotlinSpringBootGeneratorError.invalidOperation(
            operationName: malformedPath.name,
            reason: "has malformed path placeholders"
        )) {
            try KotlinSpringBootApiPackageGenerator(
                package: ApiPackage(
                    name: "Test",
                    targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(
                        UUID().uuidString, isDirectory: true
                    ),
                    modules: [
                        ApiModule(name: "Catalog", definitions: [
                            ApiService(name: "Items", operations: [malformedPath])
                        ])
                    ],
                    referencedModules: [],
                    references: [],
                    commonReferences: [],
                    imports: []
                )
            )
            .generatedFiles()
        }

        let queryPlaceholder = ApiOperation.get(
            name: "queryPlaceholder",
            path: .relative("/items?filter={id}"),
            security: .unsecured,
            parameters: [.path("id", .string())]
        )

        #expect(throws: KotlinSpringBootGeneratorError.invalidOperation(
            operationName: queryPlaceholder.name,
            reason: "has path parameters that do not match url placeholders"
        )) {
            try KotlinSpringBootApiPackageGenerator(
                package: springValidationPackage(operations: [queryPlaceholder])
            )
            .generatedFiles()
        }

        let fragmentPlaceholder = ApiOperation.get(
            name: "fragmentPlaceholder",
            path: .relative("/items#{id}"),
            security: .unsecured,
            parameters: [.path("id", .string())]
        )

        #expect(throws: KotlinSpringBootGeneratorError.invalidOperation(
            operationName: fragmentPlaceholder.name,
            reason: "has path parameters that do not match url placeholders"
        )) {
            try KotlinSpringBootApiPackageGenerator(
                package: springValidationPackage(operations: [fragmentPlaceholder])
            )
            .generatedFiles()
        }

        let wildcardPath = ApiOperation.get(
            name: "wildcard",
            path: .relative("/files/*/**"),
            security: .unsecured
        )

        #expect(throws: KotlinSpringBootGeneratorError.invalidOperation(
            operationName: wildcardPath.name,
            reason: "has Spring wildcard path components"
        )) {
            try KotlinSpringBootApiPackageGenerator(
                package: springValidationPackage(operations: [wildcardPath])
            )
            .generatedFiles()
        }
    }

    @Test func springAcceptableStatusesValidationMatchesBodyRules() {
        let user = ApiTypeSchema.object(typeName: "User", properties: [.string("name")])
        let emptyStatuses = ApiOperation.get(
            name: "ping",
            path: .relative("/ping"),
            security: .unsecured,
            response: nil,
            acceptableStatuses: []
        )

        #expect(throws: KotlinSpringBootGeneratorError.invalidOperation(
            operationName: emptyStatuses.name,
            reason: "must have at least one acceptable status"
        )) {
            try KotlinSpringBootApiPackageGenerator(
                package: springValidationPackage(operations: [emptyStatuses])
            )
            .generatedFiles()
        }

        for statusCode in [99, 600] {
            let operation = ApiOperation.get(
                name: "ping",
                path: .relative("/ping"),
                security: .unsecured,
                response: nil,
                acceptableStatuses: [statusCode]
            )

            #expect(throws: KotlinSpringBootGeneratorError.invalidOperation(
                operationName: operation.name,
                reason: "has invalid acceptable status \(statusCode)"
            )) {
                try KotlinSpringBootApiPackageGenerator(
                    package: springValidationPackage(operations: [operation])
                )
                .generatedFiles()
            }
        }

        let typedBodylessOnly = ApiOperation.get(
            name: "fetch",
            path: .relative("/users"),
            security: .unsecured,
            response: user.asRef,
            acceptableStatuses: [100, 204, 304]
        )

        #expect(throws: KotlinSpringBootGeneratorError.invalidOperation(
            operationName: typedBodylessOnly.name,
            reason: "has a typed response but no acceptable status can carry a response body"
        )) {
            try KotlinSpringBootApiPackageGenerator(
                package: springValidationPackage(operations: [typedBodylessOnly], references: [user])
            )
            .generatedFiles()
        }

        let jsonWithoutType = ApiOperation(
            name: "emptyJson",
            method: .get,
            path: .relative("/empty"),
            security: .unsecured,
            parameters: [],
            request: .none,
            response: .json(nil),
            acceptableStatuses: [200],
            extraImports: []
        )

        #expect(throws: KotlinSpringBootGeneratorError.invalidOperation(
            operationName: jsonWithoutType.name,
            reason: "has a typed response without a data type"
        )) {
            try KotlinSpringBootApiPackageGenerator(
                package: springValidationPackage(operations: [jsonWithoutType])
            )
            .generatedFiles()
        }

        let mixedBodyAndBodyless = ApiOperation.get(
            name: "fetch",
            path: .relative("/users"),
            security: .unsecured,
            response: user.asRef,
            acceptableStatuses: [200, 204]
        )

        #expect(throws: Never.self) {
            let files = try KotlinSpringBootApiPackageGenerator(
                package: springValidationPackage(operations: [mixedBodyAndBodyless], references: [user])
            )
            .generatedFiles()
            let controller = try #require(files.first {
                $0.relativePath == "src/main/kotlin/com/example/api/catalog/items/CatalogItemsController.kt"
            })
            #expect(controller.contents.contains("GeneratedResponseEntityEncoder.json(serviceResponse, validStatusCodes = setOf(200, 204))"))
        }
    }

    @Test func springOperationParameterValidationMatchesClientRules() {
        let duplicateProperty = ApiOperation.get(
            name: "search",
            path: .relative("/items"),
            security: .unsecured,
            parameters: [
                .query("first", .string(), propertyName: "traceId"),
                .header("second", .string(), propertyName: "traceId")
            ]
        )

        #expect(throws: KotlinSpringBootGeneratorError.invalidOperation(
            operationName: duplicateProperty.name,
            reason: "has duplicate parameter property names"
        )) {
            try KotlinSpringBootApiPackageGenerator(
                package: springValidationPackage(operations: [duplicateProperty])
            )
            .generatedFiles()
        }

        let servletRequestCollision = ApiOperation.get(
            name: "search",
            path: .relative("/items"),
            security: .unsecured,
            parameters: [
                .query("servlet_request", .string(), propertyName: "servletRequest")
            ]
        )

        #expect(throws: KotlinSpringBootGeneratorError.invalidOperation(
            operationName: servletRequestCollision.name,
            reason: #"has parameter names that collide with generated controller parameters: ["servletRequest"]"#
        )) {
            try KotlinSpringBootApiPackageGenerator(
                package: springValidationPackage(operations: [servletRequestCollision])
            )
            .generatedFiles()
        }

        let duplicateWireHeader = ApiOperation.get(
            name: "trace",
            path: .relative("/trace"),
            security: .unsecured,
            parameters: [
                .header("X-Trace", .string()),
                .header("x-trace", .string(), propertyName: "trace2")
            ]
        )

        #expect(throws: KotlinSpringBootGeneratorError.invalidOperation(
            operationName: duplicateWireHeader.name,
            reason: "has duplicate parameter wire names"
        )) {
            try KotlinSpringBootApiPackageGenerator(
                package: springValidationPackage(operations: [duplicateWireHeader])
            )
            .generatedFiles()
        }

        let cookieConflict = ApiOperation.get(
            name: "cookies",
            path: .relative("/cookies"),
            security: .unsecured,
            parameters: [
                .header("Cookie", .string()),
                .cookie("session", .string())
            ]
        )

        #expect(throws: KotlinSpringBootGeneratorError.invalidOperation(
            operationName: cookieConflict.name,
            reason: "cannot combine Cookie header parameters with cookie parameters"
        )) {
            try KotlinSpringBootApiPackageGenerator(
                package: springValidationPackage(operations: [cookieConflict])
            )
            .generatedFiles()
        }

        let invalidEnumType = ApiOperation.get(
            name: "invalidEnumType",
            path: .relative("/items"),
            security: .unsecured,
            parameters: [
                .query("status", .stringEnumValue(type: .string()))
            ]
        )

        #expect(throws: KotlinSpringBootGeneratorError.invalidOperation(
            operationName: invalidEnumType.name,
            reason: "has invalid enum parameter type"
        )) {
            try KotlinSpringBootApiPackageGenerator(
                package: springValidationPackage(operations: [invalidEnumType])
            )
            .generatedFiles()
        }

        let status = ApiTypeSchema.stringEnum(
            typeName: "Status",
            values: [
                (name: "Open", rawName: "open"),
                (name: "Closed", rawName: "closed")
            ]
        )
        let invalidEnumDefault = ApiOperation.get(
            name: "invalidEnumDefault",
            path: .relative("/items"),
            security: .unsecured,
            parameters: [
                .query("status", .stringEnumValue(type: status.asRef, defaultValue: "missing"))
            ]
        )

        #expect(throws: KotlinSpringBootGeneratorError.invalidOperation(
            operationName: invalidEnumDefault.name,
            reason: "has invalid enum parameter default value"
        )) {
            try KotlinSpringBootApiPackageGenerator(
                package: springValidationPackage(operations: [invalidEnumDefault], references: [status])
            )
            .generatedFiles()
        }
    }

    @Test func springMultipartPartsFailValidationWhenGeneratedParametersAreInvalid() {
        let emptyParts = ApiOperation.postMultipart(
            name: "upload",
            path: .relative("/upload"),
            security: .unsecured,
            multiParts: []
        )

        #expect(throws: KotlinSpringBootGeneratorError.invalidOperation(
            operationName: emptyParts.name,
            reason: "has no multipart part names"
        )) {
            try KotlinSpringBootApiPackageGenerator(
                package: multipartValidationPackage(operation: emptyParts)
            )
            .generatedFiles()
        }

        let emptyPartName = ApiOperation.postMultipart(
            name: "upload",
            path: .relative("/upload"),
            security: .unsecured,
            multiParts: [""]
        )

        #expect(throws: KotlinSpringBootGeneratorError.invalidOperation(
            operationName: emptyPartName.name,
            reason: "has empty multipart part names"
        )) {
            try KotlinSpringBootApiPackageGenerator(
                package: multipartValidationPackage(operation: emptyPartName)
            )
            .generatedFiles()
        }

        let duplicateGeneratedParameter = ApiOperation.postMultipart(
            name: "upload",
            path: .relative("/upload"),
            security: .unsecured,
            multiParts: ["file-name", "file_name"]
        )

        #expect(throws: KotlinSpringBootGeneratorError.invalidOperation(
            operationName: duplicateGeneratedParameter.name,
            reason: "has multipart part names that generate duplicate parameters"
        )) {
            try KotlinSpringBootApiPackageGenerator(
                package: multipartValidationPackage(operation: duplicateGeneratedParameter)
            )
            .generatedFiles()
        }

        let servletRequestPartCollision = ApiOperation.postMultipart(
            name: "upload",
            path: .relative("/upload"),
            security: .unsecured,
            multiParts: ["servlet_request"]
        )

        #expect(throws: KotlinSpringBootGeneratorError.invalidOperation(
            operationName: servletRequestPartCollision.name,
            reason: #"has multipart part names that collide with generated controller parameters: ["servletRequest"]"#
        )) {
            try KotlinSpringBootApiPackageGenerator(
                package: multipartValidationPackage(operation: servletRequestPartCollision)
            )
            .generatedFiles()
        }

        let partParameterCollision = ApiOperation.postMultipart(
            name: "upload",
            path: .relative("/upload"),
            security: .unsecured,
            parameters: [.query("file", .string())],
            multiParts: ["file"]
        )

        #expect(throws: KotlinSpringBootGeneratorError.invalidOperation(
            operationName: partParameterCollision.name,
            reason: #"has multipart part names that collide with generated parameters: ["`file`"]"#
        )) {
            try KotlinSpringBootApiPackageGenerator(
                package: multipartValidationPackage(operation: partParameterCollision)
            )
            .generatedFiles()
        }

        let bodyParameterCollision = ApiOperation.postMultipart(
            name: "upload",
            path: .relative("/upload"),
            security: .unsecured,
            parameters: [.query("body", .string())],
            multiParts: ["file"]
        )

        #expect(throws: KotlinSpringBootGeneratorError.invalidOperation(
            operationName: bodyParameterCollision.name,
            reason: #"has parameter names that collide with generated request members: ["body"]"#
        )) {
            try KotlinSpringBootApiPackageGenerator(
                package: multipartValidationPackage(operation: bodyParameterCollision)
            )
            .generatedFiles()
        }
    }

    @Test func generatedProjectIncludesGradleRuntimeControllersServicesRequestsAndModels() throws {
        let files = try KotlinSpringBootApiPackageGenerator(package: testPackage()).generatedFiles()
        let paths = Set(files.map(\.relativePath))
        let output = files.map(\.contents).joined(separator: "\n")

        #expect(paths.contains("settings.gradle.kts"))
        #expect(paths.contains("build.gradle.kts"))
        #expect(paths.contains("gradle/libs.versions.toml"))
        #expect(paths.contains("gradle.properties"))
        #expect(paths.contains(".editorconfig"))
        #expect(paths.contains("src/main/kotlin/com/example/api/GeneratedApiApplication.kt"))
        #expect(paths.contains("src/main/kotlin/com/example/api/ApiRuntime.kt"))
        #expect(paths.contains("src/main/kotlin/com/example/api/admin/users/AdminUsersController.kt"))
        #expect(paths.contains("src/main/kotlin/com/example/api/admin/users/AdminUsersService.kt"))
        #expect(
            paths.contains("src/main/kotlin/com/example/api/admin/users/AdminUsersCreateRequest.kt")
        )
        #expect(paths.contains("src/main/kotlin/com/example/api/admin/users/models/User.kt"))

        #expect(output.contains("springBoot = \"4.1.0\""))
        #expect(output.contains("kotlin = \"2.4.0\""))
        #expect(output.contains("alias(libs.plugins.spring.boot)"))
        #expect(output.contains("alias(libs.plugins.kotlin.jvm)"))
        #expect(output.contains("alias(libs.plugins.kotlin.plugin.spring)"))
        #expect(!output.contains("implementation(libs.jackson.dataformat.yaml)"))
        #expect(output.contains("implementation(libs.kotlinx.coroutines.reactor)"))
        #expect(
            !output.contains(
                "jackson-dataformat-yaml = { module = \"tools.jackson.dataformat:jackson-dataformat-yaml\" }"
            )
        )
        #expect(
            output.contains(
                "kotlinx-coroutines-reactor = { module = \"org.jetbrains.kotlinx:kotlinx-coroutines-reactor\" }"
            )
        )
        #expect(output.contains("implementation(libs.spring.boot.starter.web)"))
        #expect(output.contains("@SpringBootApplication"))
        #expect(output.contains("runApplication<GeneratedApiApplication>(*args)"))
        #expect(output.contains("KotlinSerializationJsonHttpMessageConverter(GeneratedJson.instance)"))
        #expect(!output.contains("JacksonYamlHttpMessageConverter"))
        #expect(!output.contains("GeneratedMediaTypes"))
        #expect(!output.contains("APPLICATION_YAML"))
        #expect(output.contains("data class PagedResults<T>"))
        #expect(output.contains("val count: Int? = null"))
        #expect(output.contains("val hasNext: Boolean get() = next != null && results.isNotEmpty()"))
        #expect(output.contains("data class LocalizedData<T>"))
        #expect(output.contains("data class DateInterval"))
        #expect(output.contains("interface Identifiable<out ID> {\n    val id: ID\n}"))
        #expect(output.contains("sealed class PatchableValue<out T>"))
        #expect(output.contains("interface AdminUsersService"))
        #expect(output.contains("@ConditionalOnMissingBean(AdminUsersService::class)\n@Service\nclass NotImplementedAdminUsersService : AdminUsersService"))
        #expect(output.contains("@ConditionalOnMissingBean(GeneratedSecurityMiddleware::class)\n@Component\nclass AllowAllGeneratedSecurityMiddleware"))
        #expect(output.contains("@RestController"))
        #expect(output.contains("private val security: GeneratedSecurityMiddleware"))
    }

    @Test func generatedSpringGradleFilesEscapeKotlinStrings() throws {
        let options = KotlinSpringBootGeneratorOptions(
            gradle: KotlinSpringBootGradleOptions(
                projectName: "generated \"api\" $",
                group: "com.example \"group\" $",
                version: "1.0 \"$",
                ktlintVersion: "1.7 \"$"
            )
        )
        let files = try KotlinSpringBootApiPackageGenerator(package: testPackage(), options: options)
            .generatedFiles()
        let settings = try #require(files.first { $0.relativePath == "settings.gradle.kts" })
        let build = try #require(files.first { $0.relativePath == "build.gradle.kts" })

        #expect(settings.contents.contains(#"rootProject.name = "generated \"api\" \$""#))
        #expect(build.contents.contains(#"group = "com.example \"group\" \$""#))
        #expect(build.contents.contains(#"version = "1.0 \"\$""#))
        #expect(build.contents.contains(#"version.set("1.7 \"\$")"#))
    }

    @Test func springRouteLiteralsIgnoreStaticQueryAndFragment() throws {
        let operation = ApiOperation.get(
            name: "search",
            path: .relative("/users?active=true#top"),
            security: .unsecured
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
            commonReferences: [],
            imports: []
        )

        let files = try KotlinSpringBootApiPackageGenerator(package: package).generatedFiles()
        let controller = try #require(files.first {
            $0.relativePath == "src/main/kotlin/com/example/api/admin/users/AdminUsersController.kt"
        })

        #expect(controller.contents.contains("@GetMapping(\"/users\")"))
        #expect(!controller.contents.contains("active=true"))
        #expect(!controller.contents.contains("#top"))
    }

    @Test func generatedControllersCoverSupportedRequestAndResponseShapes() throws {
        let files = try KotlinSpringBootApiPackageGenerator(package: testPackage()).generatedFiles()
        let output = files.map(\.contents).joined(separator: "\n")
        let controller = try #require(files.first { $0.relativePath.hasSuffix("/AdminUsersController.kt") })

        #expect(
            output.contains(
                "@GetMapping(\"/admin/users/{user_id}\", produces = [MediaType.APPLICATION_JSON_VALUE])"
            )
        )
        #expect(
            output.contains(
                "@PostMapping(\"/admin/users\", consumes = [MediaType.APPLICATION_JSON_VALUE], produces = [MediaType.APPLICATION_JSON_VALUE])"
            )
        )
        #expect(
            output.contains(
                "@PostMapping(\"/admin/users/binary\", consumes = [MediaType.APPLICATION_OCTET_STREAM_VALUE], produces = [\"application/zip\"])"
            )
        )
        #expect(
            output.contains(
                "@PostMapping(\"/admin/users/file\", consumes = [MediaType.APPLICATION_OCTET_STREAM_VALUE], produces = [MediaType.APPLICATION_JSON_VALUE])"
            )
        )
        #expect(
            output.contains(
                "@PostMapping(\"/admin/users/multipart\", consumes = [MediaType.MULTIPART_FORM_DATA_VALUE], produces = [MediaType.APPLICATION_JSON_VALUE])"
            )
        )
        #expect(!output.contains("/admin/users.yaml"))
        #expect(!output.contains("GeneratedMediaTypes"))
        #expect(!output.contains("APPLICATION_YAML"))
        #expect(output.contains("// Skipped followRuntimeUrl: runtime paths cannot be registered by a backend."))
        #expect(!output.contains("suspend fun followRuntimeUrl"))
        #expect(!output.contains("FollowRuntimeUrlRequest"))

        #expect(output.contains("@PathVariable(\"user_id\") userId: Long"))
        #expect(
            output.contains("@RequestParam(\"visibility\", required = false) visibility: String? = null")
        )
        #expect(
            output.contains("@RequestParam(\"created_at\", required = false) createdAt: String? = null")
        )
        #expect(
            output.contains("@RequestHeader(\"X-Trace-Id\", required = false) traceId: String? = null")
        )
        #expect(
            output.contains("@CookieValue(\"session_id\", required = false) sessionId: String? = null")
        )
        #expect(output.contains("@RequestHeader(\"Authorization\") apiKey: String"))
        #expect(output.contains("visibility = visibility?.let { this.badRequestOnParse { Visibility.fromValue(it) } }"))
        #expect(output.contains("createdAt = createdAt?.let { this.badRequestOnParse { Instant.parse(it) } }"))
        #expect(output.contains("@RequestBody body: User"))
        #expect(output.contains("@RequestBody body: ByteArray"))
        #expect(output.contains("import jakarta.servlet.http.Part"))
        #expect(output.contains("@RequestPart(\"file\", required = false) `file`: Part?"))
        #expect(output.contains("data class GeneratedMultipartPart("))
        #expect(output.contains("fileName = part.submittedFileName"))
        #expect(output.contains("bytes = part.inputStream.use { it.readBytes() }"))
        #expect(output.contains("val body: Map<String, GeneratedMultipartPart?>"))
        #expect(
            output.contains(
                "body = mapOf(\"file\" to `file`?.let(GeneratedMultipartPart::from), \"metadata\" to metadata?.let(GeneratedMultipartPart::from))"
            )
        )
        #expect(!output.contains("AdminUsersExportYamlRequest"))
        #expect(output.contains("security.requireAuthorization(securityRequest)"))
        #expect(output.contains("security.authorizeOptional(securityRequest)"))
        let authRange = try #require(controller.contents.range(of: "security.requireAuthorization(securityRequest)"))
        let serviceRequestRange = try #require(controller.contents.range(of: "AdminUsersGetRequest("))
        #expect(authRange.lowerBound < serviceRequestRange.lowerBound)
        #expect(!output.contains("GeneratedResponseEntityEncoder.yaml(serviceResponse)"))
        #expect(
            output.contains(
                "GeneratedResponseEntityEncoder.binary(serviceResponse, MediaType.parseMediaType(\"application/zip\"), validStatusCodes = setOf(200, 201, 204))"
            )
        )
        #expect(output.contains("GeneratedResponseEntityEncoder.empty(serviceResponse, validStatusCodes = setOf(200, 204, 205))"))
    }

    @Test func generatedSpringJsonNilRequestDoesNotConsumeJson() throws {
        let operation = ApiOperation.post(
            name: "archive",
            path: .relative("/items/archive"),
            security: .unsecured,
            request: nil,
            response: nil
        )
        let package = ApiPackage(
            name: "Test",
            targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(
                UUID().uuidString, isDirectory: true
            ),
            modules: [
                ApiModule(name: "Admin", definitions: [
                    ApiService(name: "Users", operations: [operation])
                ])
            ],
            referencedModules: [],
            references: [],
            commonReferences: [],
            imports: []
        )
        let files = try KotlinSpringBootApiPackageGenerator(package: package).generatedFiles()
        let controller = try #require(files.first {
            $0.relativePath == "src/main/kotlin/com/example/api/admin/users/AdminUsersController.kt"
        })

        #expect(controller.contents.contains("@PostMapping(\"/items/archive\")"))
        #expect(!controller.contents.contains("consumes = [MediaType.APPLICATION_JSON_VALUE]"))
        #expect(!controller.contents.contains("@RequestBody body"))
    }

    @Test func generatedSpringPreservesRequiredNonAuthApiKeyDefault() throws {
        let operation = ApiOperation.get(
            name: "search",
            path: .relative("/items"),
            security: .unsecured,
            parameters: [
                .query("api_key", .string("demo"), propertyName: "apiKey")
            ]
        )

        let output = try KotlinSpringBootApiPackageGenerator(
            package: springValidationPackage(operations: [operation])
        )
        .generatedFiles()
        .map(\.contents)
        .joined(separator: "\n")

        #expect(output.contains(#"@RequestParam("api_key", required = false) apiKey: String = "demo""#))
        #expect(output.contains(#"val apiKey: String = "demo","#))
    }

    @Test func generatedControllerWrapsParameterParseFailuresAsBadRequest() throws {
        let visibility = ApiTypeSchema.stringEnum(
            typeName: "Visibility",
            values: [
                (name: "Public", rawName: "public"),
                (name: "Private", rawName: "private")
            ]
        )
        let score = ApiTypeSchema.intEnum(
            typeName: "Score",
            values: [
                (name: "Low", rawValue: 1),
                (name: "High", rawValue: 2)
            ]
        )
        let operation = ApiOperation.get(
            name: "search",
            path: .relative("/items"),
            security: .unsecured,
            parameters: [
                .query("visibility", .stringEnumValue(type: visibility.asRef)).optional,
                .query("score", .intEnumValue(type: score.asRef)),
                .query("created_at", .dateTime, propertyName: "createdAt").optional,
                .query("local_date", .date, propertyName: "localDate"),
                .query("local_time", .time, propertyName: "localTime")
            ],
            response: nil
        )
        let package = ApiPackage(
            name: "Test",
            targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(
                UUID().uuidString, isDirectory: true
            ),
            modules: [
                ApiModule(
                    name: "Catalog",
                    definitions: [
                        ApiService(
                            name: "Items",
                            operations: [operation],
                            references: [visibility, score]
                        )
                    ]
                )
            ],
            referencedModules: [],
            references: [],
            commonReferences: [],
            imports: []
        )
        let files = try KotlinSpringBootApiPackageGenerator(package: package).generatedFiles()
        let controller = try #require(
            files.first {
                $0.relativePath
                    == "src/main/kotlin/com/example/api/catalog/items/CatalogItemsController.kt"
            }
        )

        #expect(controller.contents.contains("import org.springframework.http.HttpStatus"))
        #expect(controller.contents.contains("import org.springframework.web.server.ResponseStatusException"))
        #expect(controller.contents.contains("private fun <T> badRequestOnParse(block: () -> T): T ="))
        #expect(controller.contents.contains("catch (exception: Exception)"))
        #expect(
            controller.contents.contains(
                "throw ResponseStatusException(HttpStatus.BAD_REQUEST, exception.message, exception)"
            )
        )
        #expect(
            controller.contents.contains(
                "visibility = visibility?.let { this.badRequestOnParse { Visibility.fromValue(it) } }"
            )
        )
        #expect(controller.contents.contains("score = this.badRequestOnParse { Score.fromValue(score) }"))
        #expect(
            controller.contents.contains(
                "createdAt = createdAt?.let { this.badRequestOnParse { Instant.parse(it) } }"
            )
        )
        #expect(controller.contents.contains("localDate = this.badRequestOnParse { LocalDate.parse(localDate) }"))
        #expect(controller.contents.contains("localTime = this.badRequestOnParse { LocalTime.parse(localTime) }"))
        #expect(controller.contents.contains("val serviceResponse = service.search(serviceRequest)"))
        #expect(!controller.contents.contains("this.badRequestOnParse { service.search"))
    }

    @Test func generatedControllerIndentsMultilineParameterDefaults() throws {
        let operation = ApiOperation.get(
            name: "search",
            path: .relative("/items"),
            security: .unsecured,
            parameters: [
                .query(
                    "fields",
                    .stringArray([
                        "identifier",
                        "display_name",
                        "created_at",
                        "updated_at",
                        "owner_id",
                        "status",
                        "visibility"
                    ])
                )
                .optional
            ],
            response: nil
        )
        let package = ApiPackage(
            name: "Test",
            targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(
                UUID().uuidString, isDirectory: true
            ),
            modules: [
                ApiModule(
                    name: "Catalog",
                    definitions: [
                        ApiService(name: "Items", operations: [operation], references: [])
                    ]
                )
            ],
            referencedModules: [],
            references: [],
            commonReferences: [],
            imports: []
        )
        let files = try KotlinSpringBootApiPackageGenerator(package: package).generatedFiles()
        let controller = try #require(
            files.first {
                $0.relativePath == "src/main/kotlin/com/example/api/catalog/items/CatalogItemsController.kt"
            }
        )

        #expect(
            controller.contents.contains(
                """
                        @RequestParam("fields", required = false) fields: List<String> = listOf(
                            "identifier",
                """
            )
        )
        #expect(
            controller.contents.contains(
                """
                            "visibility",
                        ),
                """
            )
        )
        #expect(!controller.contents.contains("\n    \"identifier\","))
    }

    @Test func springGeneratorFiltersUnsupportedAbsoluteAndRuntimeOperations() throws {
        let user = ApiTypeSchema.object(typeName: "User", properties: [.string("name")])
        let skippedResponse = ApiTypeSchema.reference(typeName: "SkippedExternal", strict: false)
        let operations = [
            ApiOperation.get(
                name: "absolute",
                path: .absolute("https://api.example.com/users"),
                security: .unsecured,
                response: skippedResponse
            ),
            ApiOperation.get(
                name: "runtime",
                path: .runtime,
                security: .unsecured,
                response: skippedResponse
            ),
            ApiOperation.get(
                name: "relative",
                path: .relative("/users"),
                security: .unsecured,
                response: user.asRef
            )
        ]
        let package = ApiPackage(
            name: "Test",
            targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(
                UUID().uuidString, isDirectory: true
            ),
            modules: [
                ApiModule(
                    name: "Catalog",
                    definitions: [
                        ApiService(name: "Users", operations: operations, references: [user])
                    ]
                )
            ],
            referencedModules: [],
            references: [],
            commonReferences: [],
            imports: []
        )
        let files = try KotlinSpringBootApiPackageGenerator(package: package).generatedFiles()
        let paths = Set(files.map(\.relativePath))
        let output = files.map(\.contents).joined(separator: "\n")

        #expect(paths.contains("src/main/kotlin/com/example/api/catalog/users/CatalogUsersRelativeRequest.kt"))
        #expect(!paths.contains("src/main/kotlin/com/example/api/catalog/users/CatalogUsersAbsoluteRequest.kt"))
        #expect(!paths.contains("src/main/kotlin/com/example/api/catalog/users/CatalogUsersRuntimeRequest.kt"))
        #expect(output.contains("suspend fun relative(request: CatalogUsersRelativeRequest)"))
        #expect(!output.contains("suspend fun absolute"))
        #expect(!output.contains("suspend fun runtime"))
        #expect(output.contains("// Skipped absolute: absolute paths cannot be registered by a backend."))
        #expect(output.contains("// Skipped runtime: runtime paths cannot be registered by a backend."))
        #expect(output.contains("@GetMapping(\"/users\""))
    }

    @Test func springGeneratorDoesNotValidateSkippedOperationTypes() throws {
        let user = ApiTypeSchema.object(typeName: "User", properties: [.string("name")])
        let skippedPayload = ApiTypeSchema.object(
            typeName: "SkippedPayload",
            properties: [
                .object("external", of: .reference(typeName: "UnmappedSkippedExternal", strict: false))
            ]
        )
        let package = ApiPackage(
            name: "Test",
            targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(
                UUID().uuidString, isDirectory: true
            ),
            modules: [
                ApiModule(
                    name: "Catalog",
                    definitions: [
                        ApiService(
                            name: "Users",
                            operations: [
                                .get(
                                    name: "runtime",
                                    path: .runtime,
                                    security: .unsecured,
                                    response: skippedPayload.asRef
                                ),
                                .get(
                                    name: "relative",
                                    path: .relative("/users"),
                                    security: .unsecured,
                                    response: user.asRef
                                )
                            ],
                            references: [user]
                        )
                    ]
                )
            ],
            referencedModules: [],
            references: [],
            commonReferences: [],
            imports: []
        )

        #expect(throws: Never.self) {
            try KotlinSpringBootApiPackageGenerator(package: package).generatedFiles()
        }
    }

    @Test func springReferencedModulesMirrorSwiftAggregateWithoutSourceEmission() throws {
        let referencedAccount = ApiTypeSchema.object(
            typeName: "Account",
            properties: [.string("name")]
        )
        let localOperation = ApiOperation.get(
            name: "local",
            path: .relative("/local"),
            security: .unsecured,
            response: referencedAccount.asRef
        )
        let localByNameOperation = ApiOperation.get(
            name: "localByName",
            path: .relative("/local/by-name"),
            security: .unsecured,
            response: .reference(typeName: "Account")
        )
        let referencedOperation = ApiOperation.get(
            name: "remote",
            path: .relative("/remote"),
            security: .unsecured,
            response: .reference(typeName: "ExternalThing", strict: false),
            acceptableStatuses: []
        )
        let duplicateReferencedOperation = ApiOperation.get(
            name: "remote",
            path: .relative("/remote-duplicate"),
            security: .unsecured
        )
        let package = ApiPackage(
            name: "Test",
            targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(
                UUID().uuidString, isDirectory: true
            ),
            modules: [
                ApiModule(name: "Local", definitions: [
                    ApiService(name: "Users", operations: [localOperation, localByNameOperation])
                ])
            ],
            referencedModules: [
                ApiModule(name: "Parent", definitions: [
                    ApiService(
                        name: "Accounts",
                        operations: [referencedOperation, duplicateReferencedOperation],
                        references: [referencedAccount]
                    )
                ])
            ],
            references: [],
            commonReferences: [],
            imports: []
        )

        let files = try KotlinSpringBootApiPackageGenerator(package: package).generatedFiles()
        let paths = Set(files.map(\.relativePath))
        let service = try #require(files.first {
            $0.relativePath == "src/main/kotlin/com/example/api/local/users/LocalUsersService.kt"
        })

        #expect(paths.contains("src/main/kotlin/com/example/api/local/users/LocalUsersController.kt"))
        #expect(paths.contains("src/main/kotlin/com/example/api/local/users/LocalUsersLocalRequest.kt"))
        #expect(paths.contains("src/main/kotlin/com/example/api/local/users/LocalUsersLocalByNameRequest.kt"))
        #expect(!paths.contains("src/main/kotlin/com/example/api/local/users/models/Account.kt"))
        #expect(!paths.contains("src/main/kotlin/com/example/api/parent/accounts/ParentAccountsController.kt"))
        #expect(!paths.contains("src/main/kotlin/com/example/api/parent/accounts/ParentAccountsRemoteRequest.kt"))
        #expect(!paths.contains("src/main/kotlin/com/example/api/parent/accounts/models/Account.kt"))
        #expect(service.contents.contains("import com.example.api.parent.accounts.models.Account"))
        #expect(service.contents.contains("suspend fun local(request: LocalUsersLocalRequest): GeneratedResponse<Account>"))
        #expect(service.contents.contains("suspend fun localByName(request: LocalUsersLocalByNameRequest): GeneratedResponse<Account>"))
    }

    @Test func generatedSpringModelsUseScopedPackagesAndKotlinxSerialization() throws {
        let files = try KotlinSpringBootApiPackageGenerator(package: testPackage()).generatedFiles()
        let model = try #require(
            files.first {
                $0.relativePath == "src/main/kotlin/com/example/api/admin/users/models/User.kt"
            }
        )

        #expect(model.contents.contains("package com.example.api.admin.users.models"))
        #expect(model.contents.contains("import kotlinx.serialization.SerialName"))
        #expect(model.contents.contains("import kotlinx.serialization.Serializable"))
        #expect(model.contents.contains("@Serializable"))
        #expect(model.contents.contains("data class User"))
        #expect(model.contents.contains("@SerialName(\"display_name\")"))
        #expect(model.contents.contains("val displayName: String"))
    }

    @Test func generatedSpringIdentifiableModelsUseRuntimeInterface() throws {
        let user = ApiTypeSchema.object(
            typeName: "User",
            properties: [
                .int64("id"),
                .string("name")
            ],
            protocols: ["Identifiable"]
        )
        let operation = ApiOperation.get(
            name: "get",
            path: .relative("/users/{id}"),
            security: .unsecured,
            parameters: [.path("id", .int64())],
            response: user.asRef
        )
        let package = ApiPackage(
            name: "Test",
            targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true),
            modules: [
                ApiModule(name: "Admin", definitions: [
                    ApiService(name: "Users", operations: [operation], references: [user])
                ])
            ],
            referencedModules: [],
            references: [],
            commonReferences: [],
            imports: []
        )
        let files = try KotlinSpringBootApiPackageGenerator(package: package)
            .generatedFiles()
        let model = try #require(
            files.first {
                $0.relativePath == "src/main/kotlin/com/example/api/admin/users/models/User.kt"
            }
        )

        #expect(model.contents.contains("import com.example.api.Identifiable"))
        #expect(model.contents.contains("override val id: Long"))
        #expect(model.contents.contains(") : Identifiable<Long>"))
    }

    @Test func generatedSpringIdentifiableUsesNullableIDTypeWhenIDIsOptional() throws {
        let user = ApiTypeSchema.object(
            typeName: "User",
            properties: [
                .int64("id", required: false),
                .string("name")
            ],
            protocols: ["Identifiable"]
        )
        let operation = ApiOperation.get(
            name: "get",
            path: .relative("/users/{id}"),
            security: .unsecured,
            parameters: [.path("id", .int64())],
            response: user.asRef
        )
        let package = ApiPackage(
            name: "Test",
            targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true),
            modules: [
                ApiModule(name: "Admin", definitions: [
                    ApiService(name: "Users", operations: [operation], references: [user])
                ])
            ],
            referencedModules: [],
            references: [],
            commonReferences: [],
            imports: []
        )
        let files = try KotlinSpringBootApiPackageGenerator(package: package)
            .generatedFiles()
        let model = try #require(
            files.first {
                $0.relativePath == "src/main/kotlin/com/example/api/admin/users/models/User.kt"
            }
        )

        #expect(model.contents.contains("override val id: Long? = null"))
        #expect(model.contents.contains(") : Identifiable<Long?>"))
    }

    @Test func patchableRequestModelsDecodeMissingNullAndValueDistinctly() throws {
        let patch = ApiTypeSchema.object(
            typeName: "Patch",
            properties: [
                ApiModelProperty(
                    rawName: "name",
                    propertyName: "name",
                    dataType: ApiTypeSchema.string().asPatchable
                ),
                ApiModelProperty(
                    rawName: "nickname",
                    propertyName: "nickname",
                    dataType: ApiTypeSchema.string().asPatchable,
                    required: false
                )
            ]
        )
        let package = ApiPackage(
            name: "Test",
            targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(
                UUID().uuidString, isDirectory: true
            ),
            modules: [
                ApiModule(
                    name: "Admin",
                    definitions: [
                        ApiService(
                            name: "Users",
                            operations: [
                                .patch(
                                    name: "patch",
                                    path: .relative("/admin/users/{user_id}"),
                                    security: .unsecured,
                                    parameters: [
                                        .path("user_id", .int64(), propertyName: "userId")
                                    ],
                                    request: patch.asRef
                                )
                            ],
                            references: [patch]
                        )
                    ]
                )
            ],
            referencedModules: [],
            references: [],
            commonReferences: [],
            imports: []
        )

        let files = try KotlinSpringBootApiPackageGenerator(package: package).generatedFiles()
        let runtime = try #require(files.first {
            $0.relativePath == "src/main/kotlin/com/example/api/ApiRuntime.kt"
        })
        let model = try #require(files.first {
            $0.relativePath == "src/main/kotlin/com/example/api/admin/users/models/Patch.kt"
        })

        #expect(runtime.contents.contains("@Serializable(with = PatchableValueSerializer::class)"))
        #expect(runtime.contents.contains("class PatchableValueSerializer<T>"))
        #expect(runtime.contents.contains("return if (jsonDecoder.decodeNotNullMark())"))
        #expect(runtime.contents.contains("PatchableValue.Modified(null)"))
        #expect(runtime.contents.contains("jsonDecoder.decodeNull()"))
        #expect(runtime.contents.contains("jsonEncoder.encodeNull()"))
        #expect(!runtime.contents.contains("decodeJsonElement()"))
        #expect(!runtime.contents.contains("encodeToJsonElement(valueSerializer"))
        #expect(runtime.contents.contains("decodeSerializableValue(valueSerializer)"))
        #expect(runtime.contents.contains("encodeSerializableValue(valueSerializer, modifiedValue)"))

        #expect(model.contents.contains("import com.example.api.PatchableValue"))
        #expect(model.contents.contains("import kotlinx.serialization.EncodeDefault"))
        #expect(model.contents.contains("import kotlinx.serialization.ExperimentalSerializationApi"))
        #expect(model.contents.contains("@OptIn(ExperimentalSerializationApi::class)\n@Serializable"))
        #expect(model.contents.contains("@EncodeDefault(EncodeDefault.Mode.NEVER)\n    var name: PatchableValue<String> = PatchableValue.Unmodified"))
        #expect(model.contents.contains("var name: PatchableValue<String> = PatchableValue.Unmodified"))
        #expect(
            model.contents.contains(
                "@EncodeDefault(EncodeDefault.Mode.NEVER)\n    var nickname: PatchableValue<String> = PatchableValue.Unmodified"
            )
        )
        #expect(
            model.contents.contains(
                "var nickname: PatchableValue<String> = PatchableValue.Unmodified"
            )
        )
        #expect(!model.contents.contains("val nickname: PatchableValue<String>?"))
        #expect(model.contents.contains("fun resetPatchableFields()"))
        #expect(model.contents.contains("name = PatchableValue.Unmodified"))
        #expect(model.contents.contains("nickname = PatchableValue.Unmodified"))
        #expect(model.contents.contains("fun isUnmodified(): Boolean ="))
        #expect(model.contents.contains("name == PatchableValue.Unmodified &&\n        nickname == PatchableValue.Unmodified"))
    }

    @Test func generatedSpringRuntimeDoesNotMutateResponseHeadersForContentType() {
        let runtime = KotlinSpringBootRuntimeEmitter().file(packageName: "com.example.api").contents

        #expect(runtime.contains("private fun headersWithContentType("))
        #expect(runtime.contains("private fun validateStatus("))
        #expect(runtime.contains("private fun isBodyAllowed(status: HttpStatusCode): Boolean"))
        #expect(runtime.contains("return code !in 100..199 && code != 204 && code != 205 && code != 304"))
        #expect(runtime.contains("require(response.status.value() in validStatusCodes)"))
        #expect(runtime.contains("HttpHeaders(headers).apply { contentType = mediaType }"))
        #expect(runtime.contains("if (!isBodyAllowed(response.status))"))
        #expect(runtime.contains(".headers(headersWithContentType(response.headers, mediaType))"))
        #expect(runtime.contains(".body(requireNotNull(response.body) { \"Missing response body for status ${response.status.value()}\" })"))
        #expect(!runtime.contains("GeneratedResponseEntityEncoder.yaml"))
        #expect(!runtime.contains("GeneratedMediaTypes"))
        #expect(!runtime.contains("response.headers.apply { contentType ="))
    }

    @Test func generatedSpringSanitizesPackageSegmentsWithLeadingDigits() throws {
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
            targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(
                UUID().uuidString, isDirectory: true
            ),
            modules: [
                ApiModule(
                    name: "2FA",
                    definitions: [
                        ApiService(name: "Users", operations: [operation], references: [user])
                    ]
                )
            ],
            referencedModules: [],
            references: [],
            commonReferences: [],
            imports: []
        )

        let files = try KotlinSpringBootApiPackageGenerator(package: package).generatedFiles()
        let service = try #require(
            files.first {
                $0.relativePath == "src/main/kotlin/com/example/api/_2fa/users/_2FAUsersService.kt"
            }
        )

        #expect(service.contents.contains("package com.example.api._2fa.users"))
        #expect(service.contents.contains("suspend fun `get`(request: _2FAUsersGetRequest)"))
    }

    @Test func generatedSpringSanitizesKeywordPackageSegments() throws {
        let operation = ApiOperation.get(
            name: "get",
            path: .relative("/users"),
            security: .unsecured
        )
        let package = ApiPackage(
            name: "Test",
            targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(
                UUID().uuidString, isDirectory: true
            ),
            modules: [
                ApiModule(
                    name: "Class",
                    definitions: [
                        ApiService(name: "Object", operations: [operation])
                    ]
                )
            ],
            referencedModules: [],
            references: [],
            commonReferences: [],
            imports: []
        )

        let files = try KotlinSpringBootApiPackageGenerator(package: package).generatedFiles()
        let service = try #require(files.first {
            $0.relativePath == "src/main/kotlin/com/example/api/_class_/_object_/ClassObjectService.kt"
        })

        #expect(service.contents.contains("package com.example.api._class_._object_"))
    }

    @Test func generatedSpringEmptyObjectUsesRegularClass() throws {
        let empty = ApiTypeSchema.object(typeName: "Empty", properties: [])
        let operation = ApiOperation.get(
            name: "get",
            path: .relative("/items"),
            security: .unsecured,
            response: empty.asRef
        )
        let package = ApiPackage(
            name: "Test",
            targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(
                UUID().uuidString, isDirectory: true
            ),
            modules: [
                ApiModule(
                    name: "Catalog",
                    definitions: [
                        ApiService(name: "Items", operations: [operation], references: [empty])
                    ]
                )
            ],
            referencedModules: [],
            references: [],
            commonReferences: [],
            imports: []
        )
        let files = try KotlinSpringBootApiPackageGenerator(package: package).generatedFiles()
        let model = try #require(files.first {
            $0.relativePath == "src/main/kotlin/com/example/api/catalog/items/models/Empty.kt"
        })

        #expect(model.contents.contains("class Empty"))
        #expect(!model.contents.contains("data class Empty"))
    }

    @Test func dynamicObjectsUseConfiguredPayloadSerialName() throws {
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
        let package = ApiPackage(
            name: "Test",
            targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(
                UUID().uuidString, isDirectory: true
            ),
            modules: [],
            referencedModules: [],
            references: [dynamic, payload],
            commonReferences: [],
            imports: []
        )
        let files = try KotlinSpringBootApiPackageGenerator(package: package).generatedFiles()
        let model = try #require(
            files.first {
                $0.relativePath == "src/main/kotlin/com/example/api/EventEnvelope.kt"
            }
        )

        #expect(model.contents.contains("@JsonClassDiscriminator(\"kind\")"))
        #expect(model.contents.contains("@SerialName(\"extras\")"))
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
        let operation = ApiOperation.get(
            name: "get",
            path: .relative("/items/{id}"),
            security: .unsecured,
            parameters: [.path("id", .int64())],
            response: visibility.asRef
        )
        let package = ApiPackage(
            name: "Test",
            targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(
                UUID().uuidString, isDirectory: true
            ),
            modules: [
                ApiModule(
                    name: "Catalog",
                    definitions: [
                        ApiService(name: "Items", operations: [operation], references: [visibility])
                    ]
                )
            ],
            referencedModules: [],
            references: [],
            commonReferences: [],
            imports: []
        )
        let files = try KotlinSpringBootApiPackageGenerator(package: package).generatedFiles()
        let model = try #require(files.first { $0.relativePath.hasSuffix("/Visibility.kt") })

        #expect(model.contents.contains("@Serializable(with = Visibility.Serializer::class)"))
        #expect(model.contents.contains("object Serializer : KSerializer<Visibility>"))
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
        let package = ApiPackage(
            name: "Test",
            targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(
                UUID().uuidString, isDirectory: true
            ),
            modules: [],
            referencedModules: [],
            references: [dynamic, payload],
            commonReferences: [],
            imports: []
        )
        let files = try KotlinSpringBootApiPackageGenerator(package: package).generatedFiles()
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
            ]
        )
        let package = ApiPackage(
            name: "Test",
            targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(
                UUID().uuidString, isDirectory: true
            ),
            modules: [],
            referencedModules: [],
            references: [dynamic, payload],
            commonReferences: [],
            imports: []
        )
        let files = try KotlinSpringBootApiPackageGenerator(package: package).generatedFiles()
        let model = try #require(files.first { $0.relativePath.hasSuffix("/EventEnvelope.kt") })

        #expect(model.contents.contains("@Serializable(with = EventEnvelope.Serializer::class)"))
        #expect(model.contents.contains("object Serializer : KSerializer<EventEnvelope>"))
        #expect(model.contents.contains("val alternatePayload = remove(\"data\")"))
        #expect(model.contents.contains("if (\"payload\" !in this && alternatePayload != null)"))
        #expect(model.contents.contains("put(\"payload\", alternatePayload)"))
        #expect(model.contents.contains("else -> throw SerializationException(\"Unknown EventEnvelope discriminator: $objectType\")"))
        #expect(!model.contents.contains("data class Garbage"))
    }

    @Test func intEnumUsesRawValueSerializerForJsonValues() throws {
        let score = ApiTypeSchema.intEnum(
            typeName: "Score",
            values: [
                (name: "Low", rawValue: 10),
                (name: "High", rawValue: 100)
            ]
        )
        let operation = ApiOperation.get(
            name: "get",
            path: .relative("/items/{id}"),
            security: .unsecured,
            parameters: [.path("id", .int64())],
            response: score.asRef
        )
        let package = ApiPackage(
            name: "Test",
            targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(
                UUID().uuidString, isDirectory: true
            ),
            modules: [
                ApiModule(
                    name: "Catalog",
                    definitions: [
                        ApiService(name: "Items", operations: [operation], references: [score])
                    ]
                )
            ],
            referencedModules: [],
            references: [],
            commonReferences: [],
            imports: []
        )
        let files = try KotlinSpringBootApiPackageGenerator(package: package).generatedFiles()
        let model = try #require(files.first { $0.relativePath.hasSuffix("/Score.kt") })

        #expect(model.contents.contains("@Serializable(with = Score.Serializer::class)"))
        #expect(model.contents.contains("object Serializer : KSerializer<Score>"))
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
                .string("trace_id", propertyName: "traceId", required: false),
                .string("internal", propertyName: "internalValue").unpublished
            ]
        )
        let package = ApiPackage(
            name: "Test",
            targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(
                UUID().uuidString, isDirectory: true
            ),
            modules: [],
            referencedModules: [],
            references: [dynamic, payload],
            commonReferences: [],
            imports: []
        )
        let files = try KotlinSpringBootApiPackageGenerator(package: package).generatedFiles()
        let model = try #require(files.first { $0.relativePath.hasSuffix("/EventEnvelope.kt") })

        #expect(model.contents.contains("@Serializable(with = EventEnvelope.Serializer::class)"))
        #expect(model.contents.contains("@SerialName(\"__self__\")"))
        #expect(model.contents.contains("@SerialName(\"trace_id\")\n        val traceId: String? = null"))
        #expect(model.contents.contains("@SerialName(\"internal\")\n        val internalValue: String"))
        let extraParameter = try #require(model.contents.range(of: "val internalValue: String"))
        let payloadParameter = try #require(model.contents.range(of: "val payload:"))
        #expect(extraParameter.lowerBound < payloadParameter.lowerBound)

        #expect(model.contents.contains("private val metadataKeys: Set<String> = setOf(\"kind\", \"trace_id\", \"internal\")"))
        #expect(model.contents.contains("put(\"__self__\", JsonObject(payload))"))
        #expect(model.contents.contains("\"message\" -> jsonDecoder.json.decodeFromJsonElement(Message.serializer(), element.withNestedPayload())"))
        #expect(model.contents.contains("remove(\"__self__\")"))
        #expect(model.contents.contains("putAll(payload)"))
        #expect(model.contents.contains(".withFlattenedPayload(\"message\")"))
        #expect(model.contents.contains("else -> throw SerializationException(\"Unknown EventEnvelope discriminator: $objectType\")"))
        #expect(!model.contents.contains("is Garbage ->"))
    }

    @Test func generatedSpringOmitsUnpublishedObjectFields() throws {
        let audit = ApiTypeSchema.object(
            typeName: "Audit",
            properties: [
                .string("public_note", propertyName: "publicNote"),
                .object(
                    "internal_note",
                    propertyName: "internalNote",
                    of: .reference(typeName: "InternalOnly", strict: false)
                )
                .unpublished,
                .object(
                    "mapped_note",
                    propertyName: "mappedNote",
                    of: .reference(typeName: "MappedInternal", strict: false)
                )
                .unpublished
            ]
        )
        let operation = ApiOperation.get(
            name: "get",
            path: .relative("/audit"),
            security: .unsecured,
            response: audit.asRef
        )
        let package = ApiPackage(
            name: "Test",
            targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(
                UUID().uuidString, isDirectory: true
            ),
            modules: [
                ApiModule(
                    name: "Catalog",
                    definitions: [
                        ApiService(name: "Audit", operations: [operation], references: [audit])
                    ]
                )
            ],
            referencedModules: [],
            references: [],
            commonReferences: [],
            imports: []
        )
        let options = KotlinSpringBootGeneratorOptions(
            typeMappings: KotlinSpringBootTypeMapping.defaultMappings + [
                KotlinSpringBootTypeMapping(
                    apiTypeName: "MappedInternal",
                    kotlinType: "MappedInternal",
                    imports: ["com.example.shared.MappedInternal"]
                )
            ]
        )
        let files = try KotlinSpringBootApiPackageGenerator(package: package, options: options)
            .generatedFiles()
        let model = try #require(files.first { $0.relativePath.hasSuffix("/Audit.kt") })

        #expect(model.contents.contains("val publicNote: String"))
        #expect(!model.contents.contains("internalNote"))
        #expect(!model.contents.contains("mappedNote"))
        #expect(!model.contents.contains("@SerialName(\"internal_note\")"))
        #expect(!model.contents.contains("@SerialName(\"mapped_note\")"))
        #expect(!model.contents.contains("import com.example.shared.MappedInternal"))
    }

    @Test func generatedSpringModelsAndRequestsUseContentEqualityForBinaryFields() throws {
        let document = ApiTypeSchema.object(
            typeName: "Document",
            properties: [
                .string("id"),
                .binary("payload"),
                .binary("class").optional
            ]
        )
        let files = try KotlinSpringBootApiPackageGenerator(
            package: testPackage(response: document.asRef, references: [document])
        )
        .generatedFiles()
        let model = try #require(files.first {
            $0.relativePath == "src/main/kotlin/com/example/api/admin/users/models/Document.kt"
        })
        let request = try #require(files.first {
            $0.relativePath == "src/main/kotlin/com/example/api/admin/users/AdminUsersUploadBinaryRequest.kt"
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
        #expect(request.contents.contains("override fun equals(other: Any?): Boolean"))
        #expect(request.contents.contains("if (!body.contentEquals(other.body)) return false"))
        #expect(request.contents.contains("var result = body.contentHashCode()"))

        let runtime = try #require(files.first {
            $0.relativePath == "src/main/kotlin/com/example/api/ApiRuntime.kt"
        })
        #expect(runtime.contents.contains("object ByteArrayBase64Serializer : KSerializer<ByteArray>"))
        #expect(runtime.contents.contains("PrimitiveSerialDescriptor(\"ByteArrayBase64\", PrimitiveKind.STRING)"))
    }

    @Test func mappedEnumParameterDefaultUsesMappedTypeName() throws {
        let visibility = ApiTypeSchema.stringEnum(
            typeName: "Visibility",
            values: [
                (name: "Public", rawName: "public"),
                (name: "Private", rawName: "private")
            ]
        )
        let operation = ApiOperation.get(
            name: "search",
            path: .relative("/items"),
            security: .unsecured,
            parameters: [
                .query(
                    "visibility",
                    .stringEnumValue(type: visibility.asRef, defaultValue: "public")
                ).optional
            ]
        )
        let package = ApiPackage(
            name: "Test",
            targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(
                UUID().uuidString, isDirectory: true
            ),
            modules: [
                ApiModule(
                    name: "Catalog",
                    definitions: [
                        ApiService(
                            name: "Items",
                            operations: [operation],
                            references: [visibility]
                        )
                    ]
                )
            ],
            referencedModules: [],
            references: [],
            commonReferences: [],
            imports: []
        )
        let options = KotlinSpringBootGeneratorOptions(
            typeMappings: KotlinSpringBootTypeMapping.defaultMappings + [
                KotlinSpringBootTypeMapping(
                    apiTypeName: "Visibility",
                    kotlinType: "ExternalVisibility",
                    imports: ["com.example.shared.ExternalVisibility"]
                )
            ]
        )
        let files = try KotlinSpringBootApiPackageGenerator(package: package, options: options)
            .generatedFiles()
        let request = try #require(
            files.first {
                $0.relativePath
                    == "src/main/kotlin/com/example/api/catalog/items/CatalogItemsSearchRequest.kt"
            }
        )

        #expect(request.contents.contains("import com.example.shared.ExternalVisibility"))
        #expect(
            request.contents.contains(
                "val visibility: ExternalVisibility = ExternalVisibility.fromValue(\"public\")"
            )
        )
        #expect(!request.contents.contains("= Visibility.fromValue(\"public\")"))
    }

    @Test func mappedEnumModelDefaultDoesNotUseOriginalType() throws {
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
        let files = try KotlinSpringBootApiPackageGenerator(
            package: testPackage(response: container.asRef, references: [container, visibility]),
            options: KotlinSpringBootGeneratorOptions(typeMappings: KotlinSpringBootTypeMapping.defaultMappings + [
                KotlinSpringBootTypeMapping(
                    apiTypeName: "Visibility",
                    kotlinType: "ExternalVisibility",
                    imports: ["com.example.shared.ExternalVisibility"]
                )
            ])
        )
        .generatedFiles()
        let model = try #require(files.first {
            $0.relativePath == "src/main/kotlin/com/example/api/admin/users/models/Container.kt"
        })

        #expect(model.contents.contains("import com.example.shared.ExternalVisibility"))
        #expect(model.contents.contains("val visibility: ExternalVisibility"))
        #expect(!model.contents.contains("Visibility.Public"))
    }

    @Test func mappedObjectIgnoresInternalExternalReferences() throws {
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
            targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(
                UUID().uuidString, isDirectory: true
            ),
            modules: [
                ApiModule(
                    name: "Catalog",
                    definitions: [
                        ApiService(name: "Mapped", operations: [operation], references: [mappedThing])
                    ]
                )
            ],
            referencedModules: [],
            references: [],
            commonReferences: [],
            imports: []
        )
        let options = KotlinSpringBootGeneratorOptions(typeMappings: KotlinSpringBootTypeMapping.defaultMappings + [
            KotlinSpringBootTypeMapping(
                apiTypeName: "MappedThing",
                kotlinType: "ExternalThing",
                imports: ["com.example.shared.ExternalThing"]
            )
        ])

        #expect(throws: Never.self) {
            try KotlinSpringBootApiPackageGenerator(package: package, options: options).generatedFiles()
        }
    }

    @Test func commonReferencesResolveWithoutGeneratingSpringModels() throws {
        let sharedUser = ApiTypeSchema.object(
            typeName: "SharedUser",
            properties: [.string("name")]
        )
        let operations = [
            ApiOperation.get(
                name: "fetchResolved",
                path: .relative("/shared/resolved"),
                security: .unsecured,
                response: sharedUser.asRef
            ),
            ApiOperation.get(
                name: "fetchByName",
                path: .relative("/shared/by-name"),
                security: .unsecured,
                response: .reference(typeName: "SharedUser")
            )
        ]
        let files = try KotlinSpringBootApiPackageGenerator(
            package: springValidationPackage(
                operations: operations,
                commonReferences: [sharedUser]
            )
        )
        .generatedFiles()
        let paths = Set(files.map(\.relativePath))
        let service = try #require(files.first {
            $0.relativePath == "src/main/kotlin/com/example/api/catalog/items/CatalogItemsService.kt"
        })

        #expect(!paths.contains("src/main/kotlin/com/example/api/SharedUser.kt"))
        #expect(!paths.contains("src/main/kotlin/com/example/api/catalog/items/models/SharedUser.kt"))
        #expect(service.contents.contains("import com.example.api.SharedUser"))
    }

    @Test func writeRefusesUserOwnedFiles() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString, isDirectory: true
        )
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let buildFile = directory.appendingPathComponent("build.gradle.kts")
        try "user file\n".write(to: buildFile, atomically: true, encoding: .utf8)

        #expect(
            throws: KotlinSpringBootGeneratedTextFileError.refusingToOverwriteUserFile("build.gradle.kts")
        ) {
            try KotlinSpringBootApiPackageGenerator(package: testPackage(targetDirUrl: directory)).write()
        }
    }

    @Test func writeRefusesUserOwnedEditorConfig() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString, isDirectory: true
        )
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let editorConfig = directory.appendingPathComponent(".editorconfig")
        try "root = true\n".write(to: editorConfig, atomically: true, encoding: .utf8)

        #expect(
            throws: KotlinSpringBootGeneratedTextFileError.refusingToOverwriteUserFile(".editorconfig")
        ) {
            try KotlinSpringBootApiPackageGenerator(package: testPackage(targetDirUrl: directory)).write()
        }
    }

    @Test func generatedFileWriteRejectsSymlinkEscape() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString, isDirectory: true
        )
        let outside = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString, isDirectory: true
        )
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: outside, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: directory)
            try? FileManager.default.removeItem(at: outside)
        }

        try FileManager.default.createSymbolicLink(
            at: directory.appendingPathComponent("linked"),
            withDestinationURL: outside
        )
        let file = KotlinSpringBootGeneratedTextFile(relativePath: "linked/Escaped.kt", contents: "class Escaped")

        #expect(throws: KotlinSpringBootGeneratedTextFileError.invalidRelativePath("linked/Escaped.kt")) {
            try file.write(to: directory)
        }
        #expect(!FileManager.default.fileExists(atPath: outside.appendingPathComponent("Escaped.kt").path))
    }

    @Test func writeRemovesStaleManagedKotlinSources() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString, isDirectory: true
        )
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let staleFile = directory.appendingPathComponent("src/main/kotlin/com/example/api/Stale.kt")
        try FileManager.default.createDirectory(
            at: staleFile.deletingLastPathComponent(), withIntermediateDirectories: true
        )
        try "\(KotlinSpringBootGeneratedTextFile.managedHeader)\nclass Stale\n".write(
            to: staleFile, atomically: true, encoding: .utf8
        )

        try KotlinSpringBootApiPackageGenerator(package: testPackage(targetDirUrl: directory)).write()

        #expect(!FileManager.default.fileExists(atPath: staleFile.path))
    }
}

private func testPackage(
    targetDirUrl: URL = FileManager.default.temporaryDirectory.appendingPathComponent(
        UUID().uuidString, isDirectory: true
    ),
    response: ApiTypeSchema? = nil,
    references extraReferences: [ApiTypeSchema] = []
) -> ApiPackage {
    let user = ApiTypeSchema.object(
        typeName: "User",
        properties: [
            .int64("id", equatable: true, hashable: true),
            .string("display_name", propertyName: "displayName")
        ]
    )
    let uploadReceipt = ApiTypeSchema.object(
        typeName: "UploadReceipt",
        properties: [
            .string("token")
        ]
    )
    let visibility = ApiTypeSchema.stringEnum(
        typeName: "Visibility",
        values: [
            (name: "Public", rawName: "public"),
            (name: "Private", rawName: "private")
        ]
    )

    return ApiPackage(
        name: "Test",
        targetDirUrl: targetDirUrl,
        modules: [
            ApiModule(
                name: "Admin",
                definitions: [
                    ApiService(
                        name: "Users",
                        operations: [
                            .get(
                                name: "get",
                                path: .relative("/admin/users/{user_id}"),
                                security: .secured,
                                parameters: [
                                    .path("user_id", .int64(), propertyName: "userId").immutable,
                                    .query("visibility", .stringEnumValue(type: visibility.asRef)).optional,
                                    .query("created_at", .dateTime, propertyName: "createdAt").optional,
                                    .header("X-Trace-Id", .string(), propertyName: "traceId").optional,
                                    .cookie("session_id", .string(), propertyName: "sessionId").optional
                                ],
                                response: response ?? user.asRef
                            ),
                            .post(
                                name: "create",
                                path: .relative("/admin/users"),
                                security: .optional,
                                request: user.asRef,
                                response: user.asRef
                            ),
                            .post(
                                name: "uploadBinary",
                                path: .relative("/admin/users/binary"),
                                security: .unsecured,
                                requestType: .binary(mimeType: "application/octet-stream"),
                                responseType: .binary(mimeType: "application/zip")
                            ),
                            .post(
                                name: "uploadFile",
                                path: .relative("/admin/users/file"),
                                security: .unsecured,
                                requestType: .file,
                                responseType: .json(uploadReceipt.asRef)
                            ),
                            .postMultipart(
                                name: "uploadMultipart",
                                path: .relative("/admin/users/multipart"),
                                security: .unsecured,
                                multiParts: ["file", "metadata"],
                                response: uploadReceipt.asRef
                            ),
                            .delete(
                                name: "delete",
                                path: .relative("/admin/users/{user_id}"),
                                security: .unsecured,
                                parameters: [
                                    .path("user_id", .int64(), propertyName: "userId")
                                ],
                                response: nil
                            ),
                            .get(
                                name: "followRuntimeUrl",
                                path: .runtime,
                                security: .unsecured,
                                response: user.asRef
                            )
                        ],
                        references: [user, uploadReceipt, visibility] + extraReferences
                    )
                ]
            )
        ],
        referencedModules: [],
        references: [],
        commonReferences: [],
        imports: []
    )
}

private func multipartValidationPackage(operation: ApiOperation) -> ApiPackage {
    ApiPackage(
        name: "Test",
        targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString, isDirectory: true
        ),
        modules: [
            ApiModule(name: "Admin", definitions: [
                ApiService(name: "Uploads", operations: [operation])
            ])
        ],
        referencedModules: [],
        references: [],
        commonReferences: [],
        imports: []
    )
}

private func springValidationPackage(
    operations: [ApiOperation],
    references: [ApiTypeSchema] = [],
    commonReferences: [ApiTypeSchema] = []
) -> ApiPackage {
    ApiPackage(
        name: "Test",
        targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString, isDirectory: true
        ),
        modules: [
            ApiModule(name: "Catalog", definitions: [
                ApiService(name: "Items", operations: operations, references: references)
            ])
        ],
        referencedModules: [],
        references: [],
        commonReferences: commonReferences,
        imports: []
    )
}
