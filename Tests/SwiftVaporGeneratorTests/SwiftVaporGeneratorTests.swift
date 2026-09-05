import Foundation
import GeneratorModels
@testable import SwiftVaporGenerator
import Testing

@Suite(.serialized) struct SwiftVaporGeneratorTests {
    @Test func optionsExposeDefaults() {
        let options = SwiftVaporGeneratorOptions()

        #expect(options.appName == "GeneratedApi")
        #expect(options.moduleName == "App")
        #expect(options.swiftToolsVersion == "6.0")
        #expect(options.vaporVersion == "4.121.4")
        #expect(options.additionalPackageDependencies.isEmpty)
        #expect(options.additionalTargetDependencies.isEmpty)
        #expect(options.generatePackage)
        #expect(options.generateRunTarget)
        #expect(options.generateDockerfile)
        #expect(options.overwritePolicy == .replaceManagedFiles)
    }

    @Test func generatedProjectIncludesManifestRuntimeRoutesAndServices() throws {
        let files = try SwiftVaporApiPackageGenerator(package: testPackage()).generatedFiles()
        let paths = Set(files.map(\.relativePath))
        let output = files.map(\.contents).joined(separator: "\n")

        #expect(paths.contains("Package.swift"))
        #expect(paths.contains("Dockerfile"))
        #expect(paths.contains("Sources/Run/main.swift"))
        #expect(paths.contains("Sources/App/configure.swift"))
        #expect(paths.contains("Sources/App/routes.generated.swift"))
        #expect(paths.contains("Sources/App/Generated/Runtime/VaporApiRuntime.generated.swift"))
        #expect(paths.contains("Sources/App/Generated/Services/AdminUsersService.generated.swift"))
        #expect(paths.contains("Sources/App/Generated/Controllers/AdminUsersController.generated.swift"))
        #expect(paths.contains("Sources/App/Generated/Requests/AdminUsersCreateOperationRequest.generated.swift"))
        #expect(paths.contains("Sources/App/Generated/Models/AdminUsersUser.generated.swift"))

        #expect(output.contains(".package(url: \"https://github.com/vapor/vapor.git\", from: \"4.121.4\")"))
        #expect(output.contains("FROM swift:6.0 AS build"))
        #expect(output.contains("RUN swift build -c release"))
        #expect(output.contains("COPY --from=build /build/.build/release/Run ./Run"))
        #expect(output.contains("CMD [\"serve\", \"--hostname\", \"0.0.0.0\"]"))
        #expect(output.contains(".macOS(.v10_15)"))
        #expect(!output.contains(".macOS(.v15)"))
        #expect(output.contains("import Foundation"))
        #expect(output.contains("<Data>"))
        #expect(output.contains("DateFormatter"))
        #expect(output.contains("ISO8601DateFormatter"))
        #expect(!output.contains("CocoaError"))
        #expect(!output.contains("UniformTypeIdentifiers"))
        #expect(!output.contains("SLFoundation"))
        #expect(!output.contains("Yams"))
        #expect(output.contains("public struct GeneratedApiServices: Sendable"))
        #expect(output.contains("public protocol AdminUsersService: Sendable"))
        #expect(output.contains("public struct NotImplementedAdminUsersService: AdminUsersService"))
        #expect(output.contains("try await security.requireAuthorization(securityRequest)"))
        #expect(output.contains("try await security.authorizeOptional(securityRequest)"))
        #expect(output.contains("try routes(app.routes, services: services, security: security)"))
        #expect(output.contains("_ routes: RoutesBuilder"))
        #expect(output.contains(").register(routes: routes)"))
    }

    @Test func generatedManifestIncludesAdditionalDependencies() throws {
        let manifest = try #require(
            SwiftVaporApiPackageGenerator(
                package: testPackage(),
                options: SwiftVaporGeneratorOptions(
                    additionalPackageDependencies: [
                        ".package(name: \"ExternalKit\", path: \"../ExternalKit\")"
                    ],
                    additionalTargetDependencies: [
                        ".product(name: \"ExternalKit\", package: \"ExternalKit\")"
                    ]
                )
            ).generatedFiles().first {
                $0.relativePath == "Package.swift"
            }
        )

        #expect(manifest.contents.contains(".package(name: \"ExternalKit\", path: \"../ExternalKit\")"))
        #expect(manifest.contents.contains(".product(name: \"ExternalKit\", package: \"ExternalKit\")"))
    }

    @Test func vaporGeneratorRejectsAppleOnlyImports() throws {
        let operation = ApiOperation.get(
            name: "get",
            path: .relative("/widgets"),
            security: .unsecured,
            response: nil,
            extraImports: ["UniformTypeIdentifiers"]
        )
        let package = ApiPackage(
            name: "Test",
            targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true),
            modules: [
                ApiModule(name: "Admin", definitions: [
                    ApiService(name: "Widgets", operations: [operation])
                ])
            ],
            referencedModules: [],
            references: [],
            commonReferences: [],
            imports: []
        )

        #expect(throws: SwiftVaporGeneratorError.unsupportedAppleFrameworkImport("UniformTypeIdentifiers")) {
            try SwiftVaporApiPackageGenerator(package: package).generatedFiles()
        }
    }

    @Test func vaporGeneratorAllowsFoundationImports() throws {
        let externalType = ApiTypeSchema.reference(
            typeName: "DateInterval",
            strict: false,
            imports: ["Foundation"]
        )
        let operation = ApiOperation.get(
            name: "get",
            path: .relative("/widgets"),
            security: .unsecured,
            response: externalType
        )
        let package = ApiPackage(
            name: "Test",
            targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true),
            modules: [
                ApiModule(name: "Admin", definitions: [
                    ApiService(name: "Widgets", operations: [operation])
                ])
            ],
            referencedModules: [],
            references: [],
            commonReferences: [],
            imports: []
        )

        let files = try SwiftVaporApiPackageGenerator(package: package).generatedFiles()
        let service = try #require(files.first {
            $0.relativePath == "Sources/App/Generated/Services/AdminWidgetsService.generated.swift"
        })
        #expect(service.contents.contains("import Foundation"))
        #expect(service.contents.contains("GeneratedResponse<DateInterval>"))
    }

    @Test func customModuleNameControlsManifestAndSourcePaths() throws {
        let files = try SwiftVaporApiPackageGenerator(
            package: testPackage(),
            options: SwiftVaporGeneratorOptions(moduleName: "Server")
        ).generatedFiles()
        let paths = Set(files.map(\.relativePath))
        let manifest = try #require(files.first { $0.relativePath == "Package.swift" })
        let runFile = try #require(files.first { $0.relativePath == "Sources/Run/main.swift" })

        #expect(paths.contains("Sources/Server/configure.swift"))
        #expect(paths.contains("Sources/Server/routes.generated.swift"))
        #expect(paths.contains("Sources/Server/Generated/Runtime/VaporApiRuntime.generated.swift"))
        #expect(paths.contains("Sources/Server/Generated/Services/AdminUsersService.generated.swift"))
        #expect(!paths.contains { $0.hasPrefix("Sources/App/") })
        #expect(manifest.contents.contains(".library(name: \"Server\", targets: [\"Server\"])"))
        #expect(manifest.contents.contains("name: \"Server\""))
        #expect(runFile.contents.contains("import Server"))
    }

    @Test func generatedManifestOmitsRunTargetWhenDisabled() throws {
        let files = try SwiftVaporApiPackageGenerator(
            package: testPackage(),
            options: SwiftVaporGeneratorOptions(generateRunTarget: false)
        ).generatedFiles()
        let paths = Set(files.map(\.relativePath))
        let manifest = try #require(files.first { $0.relativePath == "Package.swift" })

        #expect(!paths.contains("Sources/Run/main.swift"))
        #expect(!paths.contains("Dockerfile"))
        #expect(!manifest.contents.contains(".executable(name: \"Run\""))
        #expect(!manifest.contents.contains(".executableTarget("))
        #expect(manifest.contents.contains(".library(name: \"App\", targets: [\"App\"])"))
        #expect(manifest.contents.contains("name: \"App\""))
    }

    @Test func operationImportsAreEmittedInRouteFiles() throws {
        let externalType = ApiTypeSchema.reference(
            typeName: "ExternalKit.Widget",
            strict: false,
            imports: ["ExternalKit"]
        )
        let operation = ApiOperation.post(
            name: "create",
            path: .relative("/widgets"),
            security: .unsecured,
            request: externalType,
            response: externalType,
            extraImports: ["OperationKit"]
        )
        let package = ApiPackage(
            name: "Test",
            targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true),
            modules: [
                ApiModule(name: "Admin", definitions: [
                    ApiService(name: "Widgets", operations: [operation])
                ])
            ],
            referencedModules: [],
            references: [],
            commonReferences: [],
            imports: []
        )
        let files = try SwiftVaporApiPackageGenerator(package: package).generatedFiles()
        let request = try #require(files.first {
            $0.relativePath == "Sources/App/Generated/Requests/AdminWidgetsCreateOperationRequest.generated.swift"
        })
        let service = try #require(files.first {
            $0.relativePath == "Sources/App/Generated/Services/AdminWidgetsService.generated.swift"
        })
        let controller = try #require(files.first {
            $0.relativePath == "Sources/App/Generated/Controllers/AdminWidgetsController.generated.swift"
        })

        for file in [request, service, controller] {
            #expect(file.contents.contains("import ExternalKit"))
            #expect(file.contents.contains("import OperationKit"))
            #expect(file.contents.contains("ExternalKit.Widget"))
            #expect(!file.contents.contains("ExternalKitWidget"))
        }
    }

    @Test func packageImportsAreEmittedInVaporFiles() throws {
        let widget = ApiTypeSchema.object(
            typeName: "Widget",
            properties: [.string("name")]
        )
        let operation = ApiOperation.post(
            name: "create",
            path: .relative("/widgets"),
            security: .unsecured,
            request: widget.asRef,
            response: widget.asRef
        )
        let package = ApiPackage(
            name: "Test",
            targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true),
            modules: [
                ApiModule(name: "Admin", definitions: [
                    ApiService(name: "Widgets", operations: [operation], references: [widget])
                ])
            ],
            referencedModules: [],
            references: [],
            commonReferences: [],
            imports: ["SharedKit"]
        )
        let files = try SwiftVaporApiPackageGenerator(package: package).generatedFiles()
        let model = try #require(files.first {
            $0.relativePath == "Sources/App/Generated/Models/AdminWidgetsWidget.generated.swift"
        })
        let request = try #require(files.first {
            $0.relativePath == "Sources/App/Generated/Requests/AdminWidgetsCreateOperationRequest.generated.swift"
        })
        let service = try #require(files.first {
            $0.relativePath == "Sources/App/Generated/Services/AdminWidgetsService.generated.swift"
        })
        let controller = try #require(files.first {
            $0.relativePath == "Sources/App/Generated/Controllers/AdminWidgetsController.generated.swift"
        })

        for file in [model, request, service, controller] {
            #expect(file.contents.contains("import SharedKit"))
        }
    }

    @Test func commonReferencesResolveWithoutGeneratingVaporModels() throws {
        let sharedThing = ApiTypeSchema.object(
            typeName: "SharedThing",
            properties: [.string("name")]
        )
        let operations = [
            ApiOperation.get(
                name: "fetchResolved",
                path: .relative("/shared/resolved"),
                security: .unsecured,
                response: sharedThing.asRef
            ),
            ApiOperation.get(
                name: "fetchByName",
                path: .relative("/shared/by-name"),
                security: .unsecured,
                response: .reference(typeName: "SharedThing")
            )
        ]
        let package = ApiPackage(
            name: "Test",
            targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true),
            modules: [
                ApiModule(name: "Admin", definitions: [
                    ApiService(name: "Shared", operations: operations)
                ])
            ],
            referencedModules: [],
            references: [],
            commonReferences: [sharedThing],
            imports: []
        )

        let files = try SwiftVaporApiPackageGenerator(package: package).generatedFiles()
        let paths = Set(files.map(\.relativePath))
        let service = try #require(files.first {
            $0.relativePath == "Sources/App/Generated/Services/AdminSharedService.generated.swift"
        })

        #expect(!paths.contains("Sources/App/Generated/Models/SharedThing.generated.swift"))
        #expect(!paths.contains("Sources/App/Generated/Models/AdminSharedSharedThing.generated.swift"))
        #expect(service.contents.contains("GeneratedResponse<SharedThing>"))
    }

    @Test func suppliedDottedReferenceKeepsQualifiedVaporTypeName() throws {
        let externalWidget = ApiTypeSchema.reference(
            typeName: "ExternalKit.Widget",
            strict: false,
            imports: ["ExternalKit"]
        )
        let commonWrapper = ApiTypeSchema.object(
            typeName: "CommonWrapper",
            properties: [
                .object("widget", of: externalWidget)
            ]
        )
        let localWidget = ApiTypeSchema.object(
            typeName: "LocalWidget",
            properties: [
                .object("widget", of: externalWidget)
            ]
        )
        let package = ApiPackage(
            name: "Test",
            targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true),
            modules: [],
            referencedModules: [],
            references: [localWidget],
            commonReferences: [commonWrapper],
            imports: []
        )

        let files = try SwiftVaporApiPackageGenerator(package: package).generatedFiles()
        let model = try #require(files.first {
            $0.relativePath == "Sources/App/Generated/Models/LocalWidget.generated.swift"
        })

        #expect(model.contents.contains("import ExternalKit"))
        #expect(model.contents.contains("widget: ExternalKit.Widget"))
        #expect(!model.contents.contains("ExternalKitWidget"))
    }

    @Test func referencedModulesAreNotGeneratedAsVaporRoutes() throws {
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
            response: referencedAccount.asRef
        )
        let package = ApiPackage(
            name: "Test",
            targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true),
            modules: [
                ApiModule(name: "Local", definitions: [
                    ApiService(name: "Users", operations: [localOperation, localByNameOperation])
                ])
            ],
            referencedModules: [
                ApiModule(name: "Parent", definitions: [
                    ApiService(name: "Accounts", operations: [referencedOperation], references: [referencedAccount])
                ])
            ],
            references: [],
            commonReferences: [],
            imports: []
        )

        let files = try SwiftVaporApiPackageGenerator(package: package).generatedFiles()
        let paths = Set(files.map(\.relativePath))
        let routes = try #require(files.first { $0.relativePath == "Sources/App/routes.generated.swift" })
        let service = try #require(files.first {
            $0.relativePath == "Sources/App/Generated/Services/LocalUsersService.generated.swift"
        })

        #expect(paths.contains("Sources/App/Generated/Services/LocalUsersService.generated.swift"))
        #expect(paths.contains("Sources/App/Generated/Controllers/LocalUsersController.generated.swift"))
        #expect(!paths.contains("Sources/App/Generated/Services/ParentAccountsService.generated.swift"))
        #expect(!paths.contains("Sources/App/Generated/Controllers/ParentAccountsController.generated.swift"))
        #expect(!paths.contains("Sources/App/Generated/Requests/ParentAccountsRemoteOperationRequest.generated.swift"))
        #expect(!paths.contains("Sources/App/Generated/Models/LocalUsersAccount.generated.swift"))
        #expect(!paths.contains("Sources/App/Generated/Models/ParentAccountsAccount.generated.swift"))
        #expect(routes.contents.contains("public let localUsersService: any LocalUsersService"))
        #expect(!routes.contents.contains("parentAccountsService"))
        #expect(service.contents.contains("GeneratedResponse<ParentAccountsAccount>"))
    }

    @Test func classModelsPreserveReferenceSemanticsAndDropImplicitSendable() throws {
        let session = ApiTypeSchema.object(
            typeName: "Session",
            properties: [.string("token")],
            isValueType: false
        )
        let operation = ApiOperation.post(
            name: "create",
            path: .relative("/sessions"),
            security: .unsecured,
            request: session.asRef,
            response: session.asRef
        )
        let package = ApiPackage(
            name: "Test",
            targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true),
            modules: [
                ApiModule(name: "Admin", definitions: [
                    ApiService(name: "Sessions", operations: [operation], references: [session])
                ])
            ],
            referencedModules: [],
            references: [],
            commonReferences: [],
            imports: []
        )
        let files = try SwiftVaporApiPackageGenerator(package: package).generatedFiles()
        let model = try #require(files.first {
            $0.relativePath == "Sources/App/Generated/Models/AdminSessionsSession.generated.swift"
        })
        let request = try #require(files.first {
            $0.relativePath == "Sources/App/Generated/Requests/AdminSessionsCreateOperationRequest.generated.swift"
        })
        let service = try #require(files.first {
            $0.relativePath == "Sources/App/Generated/Services/AdminSessionsService.generated.swift"
        })
        let runtime = try #require(files.first {
            $0.relativePath == "Sources/App/Generated/Runtime/VaporApiRuntime.generated.swift"
        })

        #expect(model.contents.contains("public class AdminSessionsSession: Codable"))
        #expect(!model.contents.contains("public struct AdminSessionsSession"))
        #expect(!model.contents.contains("AdminSessionsSession: Codable, Sendable"))
        #expect(request.contents.contains("public struct AdminSessionsCreateOperationRequest {"))
        #expect(!request.contents.contains("public struct AdminSessionsCreateOperationRequest: Sendable"))
        #expect(service.contents.contains("GeneratedResponse<AdminSessionsSession>"))
        #expect(runtime.contents.contains("public struct GeneratedResponse<Value>"))
        #expect(runtime.contents.contains("public var headers: HTTPHeaders"))
        #expect(runtime.contents.contains("Response(status: response.status, headers: response.headers)"))
        #expect(runtime.contents.contains("public var count: Int?"))
        #expect(runtime.contents.contains("public var hasNext: Bool"))
        #expect(runtime.contents.contains("extension GeneratedResponse: Sendable where Value: Sendable"))
        #expect(runtime.contents.contains("part.split(separator: \"=\", maxSplits: 1, omittingEmptySubsequences: false)"))
        #expect(runtime.contents.contains("private static let dateFormatters = DateFormatters()"))
        #expect(runtime.contents.contains("DateFormatter"))
        #expect(runtime.contents.contains("ISO8601DateFormatter"))
    }

    @Test func generatedRoutesCoverSupportedRequestAndResponseShapes() throws {
        let files = try SwiftVaporApiPackageGenerator(package: testPackage()).generatedFiles()
        let output = files.map(\.contents).joined(separator: "\n")

        #expect(output.contains("routes.on(.GET, .constant(\"admin\"), .constant(\"users\"), .parameter(\"user_id\"), use: get)"))
        #expect(output.contains("routes.on(.POST, .constant(\"admin\"), .constant(\"users\"), use: create)"))
        #expect(output.contains("routes.on(.POST, .constant(\"admin\"), .constant(\"users\"), .constant(\"binary\"), use: uploadBinary)"))
        #expect(output.contains("routes.on(.POST, .constant(\"admin\"), .constant(\"users\"), .constant(\"file\"), use: uploadFile)"))
        #expect(output.contains("routes.on(.POST, .constant(\"admin\"), .constant(\"users\"), .constant(\"multipart\"), use: uploadMultipart)"))
        #expect(output.contains("Skipped followRuntimeUrl: runtime paths cannot be registered by a backend."))

        #expect(output.contains("let body = try req.content.decode(AdminUsersUser.self)"))
        #expect(output.contains("let body = try GeneratedBodyReader.data(from: req, expectedContentType: \"application/octet-stream\")"))
        #expect(output.contains("let body = try GeneratedBodyReader.data(from: req)\n"))
        #expect(output.contains("let decodedMultipart = try req.content.decode(AdminUsersUploadMultipartOperationMultipartBodyDecode.self)"))
        #expect(output.contains("let apiKey = try GeneratedRequestValueParser.requiredString(req.headers.first(name: \"Authorization\"), name: \"Authorization\")"))
        #expect(!output.contains("apiKey = (GeneratedRequestValueParser.optionalString(req.headers.first(name: \"Authorization\"))) ?? \"\""))
        #expect(!output.contains("GeneratedResponseEncoder.yaml"))
        #expect(output.contains("try GeneratedResponseEncoder.binary(serviceResponse, contentType: \"application/zip\", validStatusCodes: [200, 201, 204])"))
        #expect(output.contains("try GeneratedResponseEncoder.empty(serviceResponse, validStatusCodes: [200, 204, 205])"))
    }

    @Test func routeLiteralsUseExplicitPathComponents() throws {
        let operation = ApiOperation.get(
            name: "lookup",
            path: .relative("/files/:literal/*/**/{file_id}"),
            security: .unsecured,
            parameters: [
                .path("file_id", .string(), propertyName: "fileId")
            ],
            response: nil
        )
        let package = ApiPackage(
            name: "Test",
            targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true),
            modules: [
                ApiModule(name: "Admin", definitions: [
                    ApiService(name: "Files", operations: [operation])
                ])
            ],
            referencedModules: [],
            references: [],
            commonReferences: [],
            imports: []
        )
        let controller = try #require(
            SwiftVaporApiPackageGenerator(package: package).generatedFiles().first {
                $0.relativePath == "Sources/App/Generated/Controllers/AdminFilesController.generated.swift"
            }
        )

        #expect(controller.contents.contains("routes.on(.GET, .constant(\"files\"), .constant(\":literal\"), .constant(\"*\"), .constant(\"**\"), .parameter(\"file_id\"), use: lookup)"))
        #expect(controller.contents.contains("let fileId = try GeneratedRequestValueParser.requiredString(req.parameters.get(\"file_id\"), name: \"file_id\")"))
    }

    @Test func enumParameterDefaultsUseDeclaredCases() throws {
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
                (name: "Low", rawValue: 10),
                (name: "High", rawValue: 100)
            ]
        )
        let operation = ApiOperation.get(
            name: "list",
            path: .relative("/items"),
            security: .unsecured,
            parameters: [
                .query("visibility", .stringEnumValue(type: visibility.asRef, defaultValue: "public")).optional,
                .query("visibilities", .stringEnumArray(type: visibility.asRef, defaultValues: ["private", "public"])).optional,
                .query("score", .intEnumValue(type: score.asRef, defaultValue: 100)).optional,
                .query("scores", .intEnumArray(type: score.asRef, defaultValues: [10, 100])).optional
            ],
            response: nil
        )
        let package = ApiPackage(
            name: "Test",
            targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true),
            modules: [
                ApiModule(name: "Admin", definitions: [
                    ApiService(
                        name: "Items",
                        operations: [operation],
                        references: [visibility, score]
                    )
                ])
            ],
            referencedModules: [],
            references: [],
            commonReferences: [],
            imports: []
        )
        let controller = try #require(
            SwiftVaporApiPackageGenerator(package: package).generatedFiles().first {
                $0.relativePath == "Sources/App/Generated/Controllers/AdminItemsController.generated.swift"
            }
        )

        #expect(controller.contents.contains("?? .`public`"))
        #expect(controller.contents.contains("?? [.`private`, .`public`]"))
        #expect(controller.contents.contains("?? .high"))
        #expect(controller.contents.contains("?? [.low, .high]"))
        #expect(!controller.contents.contains("(rawValue:"))
        #expect(!controller.contents.contains(")!"))
    }

    @Test func typedJsonResponsesKeepDeclaredBodylessStatusesForEncoding() throws {
        let payload = ApiTypeSchema.object(typeName: "Payload", properties: [.string("value")])
        let operation = ApiOperation.get(
            name: "fetch",
            path: .relative("/payload"),
            security: .unsecured,
            response: payload.asRef,
            acceptableStatuses: [100, 200, 204]
        )
        let package = ApiPackage(
            name: "Test",
            targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true),
            modules: [
                ApiModule(name: "Admin", definitions: [
                    ApiService(name: "Payload", operations: [operation], references: [payload])
                ])
            ],
            referencedModules: [],
            references: [],
            commonReferences: [],
            imports: []
        )
        let controller = try #require(
            SwiftVaporApiPackageGenerator(package: package).generatedFiles().first {
                $0.relativePath == "Sources/App/Generated/Controllers/AdminPayloadController.generated.swift"
            }
        )

        #expect(controller.contents.contains("try GeneratedResponseEncoder.json(serviceResponse, validStatusCodes: [100, 200, 204])"))
    }

    @Test func absoluteOperationPathsAreSkippedForBackendRoutes() throws {
        let package = ApiPackage(
            name: "Test",
            targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true),
            modules: [
                ApiModule(name: "Admin", definitions: [
                    ApiService(name: "Exports", operations: [
                        .get(
                            name: "export",
                            path: .absolute("https://api.example.com/admin/export"),
                            security: .unsecured,
                            response: nil
                        )
                    ])
                ])
            ],
            referencedModules: [],
            references: [],
            commonReferences: [],
            imports: []
        )
        let files = try SwiftVaporApiPackageGenerator(package: package).generatedFiles()
        let paths = Set(files.map(\.relativePath))
        let controller = try #require(
            files.first {
                $0.relativePath == "Sources/App/Generated/Controllers/AdminExportsController.generated.swift"
            }
        )
        let service = try #require(
            files.first {
                $0.relativePath == "Sources/App/Generated/Services/AdminExportsService.generated.swift"
            }
        )

        #expect(!controller.contents.contains("routes.on(.GET, \"admin\", \"export\""))
        #expect(controller.contents.contains("// Skipped export: absolute paths cannot be registered by a backend."))
        #expect(!controller.contents.contains("private func export"))
        #expect(!service.contents.contains("func export"))
        #expect(!paths.contains("Sources/App/Generated/Requests/AdminExportsExportOperationRequest.generated.swift"))
    }

    @Test func requiredUserApiKeyParameterKeepsDefaultValue() throws {
        let operation = ApiOperation.get(
            name: "lookup",
            path: .relative("/lookup"),
            security: .unsecured,
            parameters: [
                .query("api_key", .string("demo"), propertyName: "apiKey")
            ]
        )
        let package = ApiPackage(
            name: "Test",
            targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true),
            modules: [
                ApiModule(name: "Admin", definitions: [
                    ApiService(name: "Keys", operations: [operation])
                ])
            ],
            referencedModules: [],
            references: [],
            commonReferences: [],
            imports: []
        )
        let controller = try #require(
            SwiftVaporApiPackageGenerator(package: package).generatedFiles().first {
                $0.relativePath == "Sources/App/Generated/Controllers/AdminKeysController.generated.swift"
            }
        )

        #expect(controller.contents.contains("let apiKey = (GeneratedRequestValueParser.optionalString(req.query[String.self, at: \"api_key\"])) ?? \"demo\""))
    }

    @Test func generatedRuntimeUsesStringDatesAndSharedWrapperShapes() throws {
        let runtime = try #require(
            SwiftVaporApiPackageGenerator(package: testPackage()).generatedFiles().first {
                $0.relativePath == "Sources/App/Generated/Runtime/VaporApiRuntime.generated.swift"
            }
        )

        #expect(runtime.contents.contains("description = try container.decode(String.self)"))
        #expect(runtime.contents.contains("try container.encode(description)"))
        #expect(runtime.contents.contains("public struct LocalizedData<Value: Codable>: Codable"))
        #expect(runtime.contents.contains("extension LocalizedData: Sendable where Value: Sendable"))
        #expect(runtime.contents.contains("public var values: [String: Value]"))
        #expect(runtime.contents.contains("public var results: [Value]"))
        #expect(!runtime.contents.contains("public typealias LocalizedData<T> = [String: T]"))
        #expect(!runtime.contents.contains("public var values: [Value]"))
        #expect(runtime.contents.contains("public var value: Value?"))
        #expect(runtime.contents.contains("public init(status: HTTPResponseStatus, headers: HTTPHeaders = HTTPHeaders())"))
        #expect(runtime.contents.contains("headerValues[header.name.lowercased()] = header.value"))
        #expect(runtime.contents.contains("return Response(status: response.status, headers: response.headers)"))
        #expect(!runtime.contents.contains("import Yams"))
        #expect(!runtime.contents.contains("public static func yaml"))
        #expect(!runtime.contents.contains("application/x-yaml"))
        #expect(!runtime.contents.contains("YAMLEncoder"))
        #expect(runtime.contents.contains("!(100 ..< 200 ~= Int(status.code) || [204, 205, 304].contains(Int(status.code)))"))
        #expect(runtime.contents.contains("throw Abort(.badRequest, reason: \"Missing request body\")"))
        #expect(runtime.contents.contains("throw Abort(.unsupportedMediaType, reason: \"Expected Content-Type: \\(expectedContentType)\")"))
        #expect(runtime.contents.contains("validStatusCodes.contains(Int(status.code))"))
        #expect(runtime.contents.contains("throw Abort(.internalServerError, reason: \"Unexpected response status: \\(status.code)\")"))
    }

    @Test func objectModelsPreserveImportsDefaultsAndIdentityConformance() throws {
        let item = ApiTypeSchema.object(
            typeName: "Item",
            properties: [
                .int64("id", equatable: true, hashable: true),
                .string("title", initialValue: "Untitled"),
                .bool("enabled", initialValue: true),
                .url("callback_url", propertyName: "callbackUrl").optional,
                .object("external", of: .reference(typeName: "ExternalKit.Widget", strict: false, imports: ["ExternalKit"]))
            ],
            imports: ["ModelKit"]
        )
        let protocolHashableItem = ApiTypeSchema.object(
            typeName: "ProtocolHashableItem",
            properties: [
                .int64("id", equatable: true),
                .string("name")
            ],
            protocols: ["Hashable"]
        )
        let classHashableItem = ApiTypeSchema.object(
            typeName: "ClassHashableItem",
            properties: [
                .string("name")
            ],
            protocols: ["Hashable"],
            isValueType: false
        )
        let package = ApiPackage(
            name: "Test",
            targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true),
            modules: [],
            referencedModules: [],
            references: [item, protocolHashableItem, classHashableItem],
            commonReferences: [],
            imports: []
        )
        let files = try SwiftVaporApiPackageGenerator(package: package).generatedFiles()
        let model = try #require(
            files.first {
                $0.relativePath == "Sources/App/Generated/Models/Item.generated.swift"
            }
        )
        let protocolHashableModel = try #require(
            files.first {
                $0.relativePath == "Sources/App/Generated/Models/ProtocolHashableItem.generated.swift"
            }
        )
        let classHashableModel = try #require(
            files.first {
                $0.relativePath == "Sources/App/Generated/Models/ClassHashableItem.generated.swift"
            }
        )

        #expect(model.contents.contains("import ExternalKit"))
        #expect(model.contents.contains("import ModelKit"))
        #expect(model.contents.contains("public struct Item: Codable, Sendable, Equatable, Hashable"))
        #expect(model.contents.contains("public init(id: Int64, title: String = \"Untitled\", enabled: Bool = true, callbackUrl: URL? = nil, external: ExternalKit.Widget)"))
        #expect(!model.contents.contains("ExternalKitWidget"))
        #expect(model.contents.contains("public static func == (lhs: Item, rhs: Item) -> Bool {\n        lhs.id == rhs.id\n    }"))
        #expect(model.contents.contains("public func hash(into hasher: inout Hasher) {\n        hasher.combine(self.id)\n    }"))
        #expect(protocolHashableModel.contents.contains("public struct ProtocolHashableItem: Codable, Sendable, Equatable, Hashable"))
        #expect(!protocolHashableModel.contents.contains("public static func =="))
        #expect(classHashableModel.contents.contains("public class ClassHashableItem: Codable, Hashable"))
        #expect(classHashableModel.contents.contains("public static func == (lhs: ClassHashableItem, rhs: ClassHashableItem) -> Bool {\n        lhs === rhs\n    }"))
        #expect(classHashableModel.contents.contains("public func hash(into hasher: inout Hasher) {\n        hasher.combine(ObjectIdentifier(self))\n    }"))
    }

    @Test func negativeIntEnumCasesUseValidSwiftIdentifiers() throws {
        let score = ApiTypeSchema.intEnum(
            typeName: "Score",
            values: [
                (name: nil, rawValue: -1),
                (name: nil, rawValue: 10)
            ]
        )
        let package = ApiPackage(
            name: "Test",
            targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true),
            modules: [],
            referencedModules: [],
            references: [score],
            commonReferences: [],
            imports: []
        )
        let model = try #require(
            SwiftVaporApiPackageGenerator(package: package).generatedFiles().first {
                $0.relativePath == "Sources/App/Generated/Models/Score.generated.swift"
            }
        )

        #expect(model.contents.contains("case minusOne = -1"))
        #expect(model.contents.contains("case ten = 10"))
        #expect(!model.contents.contains("case _-1"))
    }

    @Test func securedRoutesAuthorizeBeforeDecodingRequestValues() throws {
        let controller = try #require(
            SwiftVaporApiPackageGenerator(package: testPackage()).generatedFiles().first {
                $0.relativePath == "Sources/App/Generated/Controllers/AdminUsersController.generated.swift"
            }
        )
        let securityRequestRange = try #require(controller.contents.range(of: "let securityRequest = GeneratedSecurityRequest(request: req, operationID: \"Admin.Users.Get\")"))
        let authorizationRange = try #require(controller.contents.range(of: "try await security.requireAuthorization(securityRequest)"))
        let pathDecodeRange = try #require(controller.contents.range(of: "let userId = try GeneratedRequestValueParser.required(req.parameters.get(\"user_id\"), name: \"user_id\", as: Int64.self)"))
        let createSecurityRequestRange = try #require(controller.contents.range(of: "let securityRequest = GeneratedSecurityRequest(request: req, operationID: \"Admin.Users.Create\")"))
        let optionalAuthorizationRange = try #require(controller.contents.range(of: "try await security.authorizeOptional(securityRequest)"))
        let bodyDecodeRange = try #require(controller.contents.range(of: "let body = try req.content.decode(AdminUsersUser.self)"))

        #expect(securityRequestRange.lowerBound < authorizationRange.lowerBound)
        #expect(authorizationRange.lowerBound < pathDecodeRange.lowerBound)
        #expect(createSecurityRequestRange.lowerBound < optionalAuthorizationRange.lowerBound)
        #expect(optionalAuthorizationRange.lowerBound < bodyDecodeRange.lowerBound)
    }

    @Test func patchableRequestModelsDecodeMissingNullAndValueDistinctly() throws {
        let patch = ApiTypeSchema.object(
            typeName: "Patch",
            properties: [
                ApiModelProperty(rawName: "name", propertyName: "name", dataType: ApiTypeSchema.string().asPatchable),
                ApiModelProperty(rawName: "nickname", propertyName: "nickname", dataType: ApiTypeSchema.string().asPatchable, required: false)
            ],
            isValueType: false
        )
        let package = ApiPackage(
            name: "Test",
            targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true),
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

        let files = try SwiftVaporApiPackageGenerator(package: package).generatedFiles()
        let runtime = try #require(files.first {
            $0.relativePath == "Sources/App/Generated/Runtime/VaporApiRuntime.generated.swift"
        })
        let model = try #require(files.first {
            $0.relativePath == "Sources/App/Generated/Models/AdminUsersPatch.generated.swift"
        })

        #expect(runtime.contents.contains("case unmodified"))
        #expect(runtime.contents.contains("func decodePatchable<Value: Codable>"))
        #expect(runtime.contents.contains("guard contains(key) else"))
        #expect(runtime.contents.contains("return .unmodified"))
        #expect(runtime.contents.contains("if try decodeNil(forKey: key)"))
        #expect(runtime.contents.contains("return .null"))
        #expect(runtime.contents.contains("func encodePatchable<Value: Codable>"))

        #expect(model.contents.contains("public class AdminUsersPatch: Codable"))
        #expect(model.contents.contains("public var name: PatchableValue<String>"))
        #expect(model.contents.contains("public var nickname: PatchableValue<String>"))
        #expect(model.contents.contains("public init(name: PatchableValue<String> = .unmodified, nickname: PatchableValue<String> = .unmodified)"))
        #expect(model.contents.contains("public required init(from decoder: any Decoder) throws"))
        #expect(!model.contents.contains("PatchableValue<String>?"))
        #expect(model.contents.contains("self.name = try container.decodePatchable(PatchableValue<String>.self, forKey: .name)"))
        #expect(model.contents.contains("self.nickname = try container.decodePatchable(PatchableValue<String>.self, forKey: .nickname)"))
        #expect(model.contents.contains("try container.encodePatchable(self.name, forKey: .name)"))
        #expect(model.contents.contains("try container.encodePatchable(self.nickname, forKey: .nickname)"))
        #expect(!model.contents.contains("if let nickname"))
    }

    @Test func dynamicObjectRequestsResponsesUseTypedEnums() throws {
        let payload = ApiTypeSchema.object(
            typeName: "Payload",
            properties: [
                .string("message")
            ]
        )
        let envelope = ApiTypeSchema.dynamicObject(
            typeName: "EventEnvelope",
            objectTypePropertyName: "kind",
            objectDataPropertyName: "data",
            alternateObjectDataPropertyName: "payload",
            objectTypes: [
                (objectTypeName: "pushEvent", objectTypeRawName: "push.event", objectType: payload.asRef)
            ],
            supportGarbage: true,
            extraProperties: [
                .string("trace_id", propertyName: "traceId", required: false),
                .string("value", propertyName: "value", required: false)
            ]
        )
        let files = try SwiftVaporApiPackageGenerator(package: dynamicObjectPackage(envelope: envelope)).generatedFiles()
        let model = try #require(files.first {
            $0.relativePath == "Sources/App/Generated/Models/AdminEventsEventEnvelope.generated.swift"
        })
        let controller = try #require(files.first {
            $0.relativePath == "Sources/App/Generated/Controllers/AdminEventsController.generated.swift"
        })
        let service = try #require(files.first {
            $0.relativePath == "Sources/App/Generated/Services/AdminEventsService.generated.swift"
        })

        #expect(model.contents.contains("public enum AdminEventsEventEnvelope: Codable, Sendable"))
        #expect(model.contents.contains("case pushEvent(String?, String?, AdminEventsEventEnvelopePayload)"))
        #expect(model.contents.contains("case contentType = \"kind\""))
        #expect(model.contents.contains("case extras = \"data\""))
        #expect(model.contents.contains("case extra = \"payload\""))
        #expect(model.contents.contains("case traceId = \"trace_id\""))
        #expect(model.contents.contains("case value"))
        #expect(model.contents.contains("let container = try decoder.container(keyedBy: CodingKeys.self)"))
        #expect(model.contents.contains("let traceId = try container.decodeIfPresent(String.self, forKey: .traceId)"))
        #expect(model.contents.contains("self = .pushEvent(traceId, value, try Self.decodeCustomType(container))"))
        #expect(model.contents.contains("self = .garbage"))
        #expect(model.contents.contains("let container = try decoder.singleValueContainer()"))
        #expect(model.contents.contains("self = Self(rawValue: value) ?? .garbage"))
        #expect(model.contents.contains("case let .pushEvent(traceId, value, value1):"))
        #expect(model.contents.contains("try container.encodeIfPresent(traceId, forKey: .traceId)"))
        #expect(model.contents.contains("try container.encodeIfPresent(value, forKey: .value)"))
        #expect(model.contents.contains("try container.encode(value1, forKey: .extras)"))
        #expect(!model.contents.contains("rawValue: GeneratedJSONValue"))
        #expect(!model.contents.contains("init(rawValue: GeneratedJSONValue)"))
        #expect(controller.contents.contains("let body = try req.content.decode(AdminEventsEventEnvelope.self)"))
        #expect(service.contents.contains("func echo(_ request: AdminEventsEchoOperationRequest) async throws -> GeneratedResponse<AdminEventsEventEnvelope>"))
    }

    @Test func dynamicObjectEqualityUsesAssociatedValuesWhenSupported() throws {
        let payload = ApiTypeSchema.object(
            typeName: "Payload",
            properties: [
                .uuid("id", equatable: true, hashable: true),
                .string("message", equatable: true, hashable: true)
            ],
            protocols: ["Identifiable"]
        )
        let envelope = ApiTypeSchema.dynamicObject(
            typeName: "EventEnvelope",
            objectTypePropertyName: "kind",
            objectDataPropertyName: "data",
            alternateObjectDataPropertyName: "payload",
            objectTypes: [
                (objectTypeName: "pushEvent", objectTypeRawName: "push.event", objectType: payload.asRef)
            ],
            supportGarbage: true,
            extraProperties: [
                .string("trace_id", propertyName: "traceId", required: false)
            ]
        )
        let model = try #require(
            SwiftVaporApiPackageGenerator(package: dynamicObjectPackage(envelope: envelope)).generatedFiles().first {
                $0.relativePath == "Sources/App/Generated/Models/AdminEventsEventEnvelope.generated.swift"
            }
        )

        #expect(model.contents.contains("public enum AdminEventsEventEnvelope: Codable, Sendable, Identifiable, Equatable, Hashable"))
        #expect(model.contents.contains("case let (.pushEvent(lhsExtra0, lhsPayload), .pushEvent(rhsExtra0, rhsPayload)):"))
        #expect(model.contents.contains("return lhsExtra0 == rhsExtra0 && lhsPayload == rhsPayload"))
        #expect(model.contents.contains("hasher.combine(valueExtra0)"))
        #expect(model.contents.contains("hasher.combine(valuePayload)"))
        #expect(!model.contents.contains("lhs.id == rhs.id"))
    }

    @Test func routeHandlersAvoidReservedLocalNameCollisions() throws {
        let operation = ApiOperation.get(
            name: "lookup",
            path: .relative("/lookup"),
            security: .unsecured,
            parameters: [
                .query("service_response", .string(), propertyName: "serviceResponse"),
                .header("security_request", .string(), propertyName: "securityRequest")
            ],
            response: nil
        )
        let package = ApiPackage(
            name: "Test",
            targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true),
            modules: [
                ApiModule(name: "Admin", definitions: [
                    ApiService(name: "Lookup", operations: [operation])
                ])
            ],
            referencedModules: [],
            references: [],
            commonReferences: [],
            imports: []
        )
        let controller = try #require(
            SwiftVaporApiPackageGenerator(package: package).generatedFiles().first {
                $0.relativePath == "Sources/App/Generated/Controllers/AdminLookupController.generated.swift"
            }
        )

        #expect(controller.contents.contains("let serviceResponseValue = try GeneratedRequestValueParser.requiredString(req.query[String.self, at: \"service_response\"], name: \"service_response\")"))
        #expect(controller.contents.contains("let securityRequestValue = try GeneratedRequestValueParser.requiredString(req.headers.first(name: \"security_request\"), name: \"security_request\")"))
        #expect(controller.contents.contains("serviceResponse: serviceResponseValue"))
        #expect(controller.contents.contains("securityRequest: securityRequestValue"))
    }

    @Test func dateParametersUseFoundationDates() throws {
        let operation = ApiOperation.get(
            name: "search",
            path: .relative("/events"),
            security: .unsecured,
            parameters: [
                .query("from", .date, propertyName: "from"),
                .query("to", .date, propertyName: "to").optional,
                .query("created_after", .dateTime, propertyName: "createdAfter"),
                .query("starts_at", .time, propertyName: "startsAt"),
                .query("ends_at", .time, propertyName: "endsAt").optional
            ],
            response: nil
        )
        let package = ApiPackage(
            name: "Test",
            targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true),
            modules: [
                ApiModule(name: "Admin", definitions: [
                    ApiService(name: "Events", operations: [operation])
                ])
            ],
            referencedModules: [],
            references: [],
            commonReferences: [],
            imports: []
        )
        let files = try SwiftVaporApiPackageGenerator(package: package).generatedFiles()
        let request = try #require(files.first {
            $0.relativePath == "Sources/App/Generated/Requests/AdminEventsSearchOperationRequest.generated.swift"
        })
        let controller = try #require(files.first {
            $0.relativePath == "Sources/App/Generated/Controllers/AdminEventsController.generated.swift"
        })

        #expect(request.contents.contains("public var from: Date"))
        #expect(request.contents.contains("public var to: Date?"))
        #expect(controller.contents.contains("try GeneratedRequestValueParser.requiredDateOnly(req.query[String.self, at: \"from\"], name: \"from\")"))
        #expect(controller.contents.contains("try GeneratedRequestValueParser.optionalDateOnly(req.query[String.self, at: \"to\"], name: \"to\")"))
        #expect(controller.contents.contains("try GeneratedRequestValueParser.requiredDate(req.query[String.self, at: \"created_after\"], name: \"created_after\")"))
        #expect(controller.contents.contains("try GeneratedRequestValueParser.requiredTime(req.query[String.self, at: \"starts_at\"], name: \"starts_at\")"))
        #expect(controller.contents.contains("try GeneratedRequestValueParser.optionalTime(req.query[String.self, at: \"ends_at\"], name: \"ends_at\")"))
        let runtime = try #require(files.first {
            $0.relativePath == "Sources/App/Generated/Runtime/VaporApiRuntime.generated.swift"
        })
        #expect(runtime.contents.contains("public static func requiredDateOnly(_ value: String?, name: String) throws -> Date"))
        #expect(runtime.contents.contains("private static func parseDateTime(_ value: String) -> Date?"))
        #expect(runtime.contents.contains("private final class DateFormatters: @unchecked Sendable"))
        #expect(runtime.contents.components(separatedBy: "defer { lock.unlock() }").count == 3)
        #expect(!runtime.contents.contains("makeDateOnlyFormatter()"))
        #expect(runtime.contents.contains("return dateTimeFormatter.date(from: value) ?? fractionalDateTimeFormatter.date(from: value)"))
        #expect(runtime.contents.contains("DateFormatter"))
        #expect(runtime.contents.contains("ISO8601DateFormatter"))
        #expect(runtime.contents.contains("public static func requiredTime(_ value: String?, name: String) throws -> Time"))
        #expect(runtime.contents.contains("private static let dateFormatters = DateFormatters()"))
        #expect(runtime.contents.contains("(0 ... 23).contains(hour)"))
        #expect(!request.contents.contains("TimelessDate"))
        #expect(!controller.contents.contains("TimelessDate"))
    }

    @Test func objectEncodingQualifiesPropertyNamesThatCollideWithLocals() throws {
        let patch = ApiTypeSchema.object(typeName: "Patch", properties: [
            ApiModelProperty(rawName: "container", propertyName: "container", dataType: ApiTypeSchema.string().asPatchable)
        ])
        let hashable = ApiTypeSchema.object(typeName: "HashableThing", properties: [
            .string("hasher", hashable: true)
        ])
        let package = ApiPackage(
            name: "Test",
            targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true),
            modules: [],
            referencedModules: [],
            references: [patch, hashable],
            commonReferences: [],
            imports: []
        )
        let files = try SwiftVaporApiPackageGenerator(package: package).generatedFiles()
        let patchModel = try #require(files.first {
            $0.relativePath == "Sources/App/Generated/Models/Patch.generated.swift"
        })
        let hashableModel = try #require(files.first {
            $0.relativePath == "Sources/App/Generated/Models/HashableThing.generated.swift"
        })

        #expect(patchModel.contents.contains("try container.encodePatchable(self.container, forKey: .container)"))
        #expect(hashableModel.contents.contains("hasher.combine(self.hasher)"))
    }

    @Test func dynamicObjectGarbageDoesNotRequireExtraProperties() throws {
        let payload = ApiTypeSchema.object(
            typeName: "Payload",
            properties: [
                .uuid("id", equatable: true, hashable: true)
            ],
            protocols: ["Identifiable"]
        )
        let envelope = ApiTypeSchema.dynamicObject(
            typeName: "EventEnvelope",
            objectTypePropertyName: "kind",
            objectDataPropertyName: "data",
            alternateObjectDataPropertyName: "payload",
            objectTypes: [
                (objectTypeName: "pushEvent", objectTypeRawName: "push.event", objectType: payload.asRef)
            ],
            supportGarbage: true,
            extraProperties: [
                .string("visibility")
            ]
        )
        let model = try #require(
            SwiftVaporApiPackageGenerator(package: dynamicObjectPackage(envelope: envelope)).generatedFiles().first {
                $0.relativePath == "Sources/App/Generated/Models/AdminEventsEventEnvelope.generated.swift"
            }
        )
        let garbageRange = try #require(model.contents.range(of: "case .garbage:"))
        let extraDecodeRange = try #require(model.contents.range(of: "let visibility = try container.decode(String.self, forKey: .visibility)"))

        #expect(garbageRange.lowerBound < extraDecodeRange.lowerBound)
    }

    @Test func invalidPackageNamesAreRejectedBeforeManifestEmission() throws {
        #expect(throws: SwiftVaporGeneratorError.invalidAppName("Bad\"Name")) {
            try SwiftVaporApiPackageGenerator(
                package: testPackage(),
                options: SwiftVaporGeneratorOptions(appName: "Bad\"Name")
            ).generatedFiles()
        }
    }

    @Test func invalidModuleNamesAreRejectedBeforeManifestEmission() throws {
        #expect(throws: SwiftVaporGeneratorError.invalidModuleName("class")) {
            try SwiftVaporApiPackageGenerator(
                package: testPackage(),
                options: SwiftVaporGeneratorOptions(moduleName: "class")
            ).generatedFiles()
        }
        #expect(throws: SwiftVaporGeneratorError.invalidModuleName("1App")) {
            try SwiftVaporApiPackageGenerator(
                package: testPackage(),
                options: SwiftVaporGeneratorOptions(moduleName: "1App")
            ).generatedFiles()
        }
        #expect(throws: SwiftVaporGeneratorError.invalidModuleName("_")) {
            try SwiftVaporApiPackageGenerator(
                package: testPackage(),
                options: SwiftVaporGeneratorOptions(moduleName: "_")
            ).generatedFiles()
        }
        #expect(throws: SwiftVaporGeneratorError.invalidModuleName("Run")) {
            try SwiftVaporApiPackageGenerator(
                package: testPackage(),
                options: SwiftVaporGeneratorOptions(moduleName: "Run")
            ).generatedFiles()
        }
    }

    @Test func typedBodylessJsonResponsesAreRejected() {
        let operation = ApiOperation(
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
        let package = ApiPackage(
            name: "Test",
            targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true),
            modules: [
                ApiModule(name: "Admin", definitions: [
                    ApiService(name: "Empty", operations: [operation])
                ])
            ],
            referencedModules: [],
            references: [],
            commonReferences: [],
            imports: []
        )

        #expect(throws: (any Error).self) {
            try SwiftVaporApiPackageGenerator(package: package).generatedFiles()
        }
    }

    @Test func binaryBodylessResponsesAreRejected() {
        let operation = ApiOperation(
            name: "emptyBinary",
            method: .get,
            path: .relative("/empty"),
            security: .unsecured,
            parameters: [],
            request: .none,
            response: .binary(mimeType: "application/octet-stream"),
            acceptableStatuses: [204],
            extraImports: []
        )
        let package = ApiPackage(
            name: "Test",
            targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true),
            modules: [
                ApiModule(name: "Admin", definitions: [
                    ApiService(name: "Empty", operations: [operation])
                ])
            ],
            referencedModules: [],
            references: [],
            commonReferences: [],
            imports: []
        )

        #expect(throws: (any Error).self) {
            try SwiftVaporApiPackageGenerator(package: package).generatedFiles()
        }
    }

    @Test func skippedOperationTypesAreNotValidatedOrGenerated() throws {
        let externalType = ApiTypeSchema.reference(typeName: "ExternalThing", strict: true)
        let operation = ApiOperation.get(
            name: "external",
            path: .absolute("https://api.example.com/external"),
            security: .unsecured,
            response: externalType
        )
        let package = ApiPackage(
            name: "Test",
            targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true),
            modules: [
                ApiModule(name: "Admin", definitions: [
                    ApiService(name: "External", operations: [operation])
                ])
            ],
            referencedModules: [],
            references: [],
            commonReferences: [],
            imports: []
        )
        let files = try SwiftVaporApiPackageGenerator(package: package).generatedFiles()
        let paths = Set(files.map(\.relativePath))
        let controller = try #require(files.first {
            $0.relativePath == "Sources/App/Generated/Controllers/AdminExternalController.generated.swift"
        })
        let service = try #require(files.first {
            $0.relativePath == "Sources/App/Generated/Services/AdminExternalService.generated.swift"
        })

        #expect(controller.contents.contains("// Skipped external: absolute paths cannot be registered by a backend."))
        #expect(!controller.contents.contains("private func external"))
        #expect(!service.contents.contains("func external"))
        #expect(!paths.contains("Sources/App/Generated/Requests/AdminExternalExternalOperationRequest.generated.swift"))
        #expect(!paths.contains("Sources/App/Generated/Models/ExternalThing.generated.swift"))
    }

    @Test func routeLiteralsIgnoreStaticQueryAndFragment() throws {
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

        let files = try SwiftVaporApiPackageGenerator(package: package).generatedFiles()
        let controller = try #require(files.first {
            $0.relativePath == "Sources/App/Generated/Controllers/AdminUsersController.generated.swift"
        })

        #expect(controller.contents.contains("routes.on(.GET, .constant(\"users\"), use: search)"))
        #expect(!controller.contents.contains("active=true"))
        #expect(!controller.contents.contains("#top"))
    }

    @Test func duplicateFlatVaporGeneratedPathsAreRejected() {
        let one = ApiTypeSchema.object(typeName: "D", properties: [.string("name")])
        let two = ApiTypeSchema.object(typeName: "D", properties: [.string("name")])
        let package = ApiPackage(
            name: "Test",
            targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true),
            modules: [
                ApiModule(name: "A", definitions: [
                    ApiService(name: "BC", operations: [], references: [one])
                ]),
                ApiModule(name: "AB", definitions: [
                    ApiService(name: "C", operations: [], references: [two])
                ])
            ],
            referencedModules: [],
            references: [],
            commonReferences: [],
            imports: []
        )

        #expect(throws: (any Error).self) {
            try SwiftVaporApiPackageGenerator(package: package).generatedFiles()
        }
    }

    @Test func duplicateVaporRoutesAreRejected() {
        let first = ApiOperation.get(
            name: "getById",
            path: .relative("/users/{id}?active=true"),
            security: .unsecured
        )
        let second = ApiOperation.get(
            name: "getByUserId",
            path: .relative("/users/{user_id}#top"),
            security: .unsecured
        )
        let package = ApiPackage(
            name: "Test",
            targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true),
            modules: [
                ApiModule(name: "Admin", definitions: [
                    ApiService(name: "Users", operations: [first, second])
                ])
            ],
            referencedModules: [],
            references: [],
            commonReferences: [],
            imports: []
        )

        #expect(throws: (any Error).self) {
            try SwiftVaporApiPackageGenerator(package: package).generatedFiles()
        }
    }

    @Test func duplicateVaporMultipartGeneratedPropertiesAreRejected() {
        let operation = ApiOperation.postMultipart(
            name: "upload",
            path: .relative("/upload"),
            security: .unsecured,
            multiParts: ["file-id", "file_id"]
        )
        let package = ApiPackage(
            name: "Test",
            targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true),
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

        #expect(throws: (any Error).self) {
            try SwiftVaporApiPackageGenerator(package: package).generatedFiles()
        }
    }

    @Test func staleCleanupOnlyRemovesVaporManagedSources() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let foreignFile = directory.appendingPathComponent("Sources/Other/Foreign.generated.swift")
        try FileManager.default.createDirectory(at: foreignFile.deletingLastPathComponent(), withIntermediateDirectories: true)
        try "\(SwiftVaporGeneratedTextFile.managedHeader)\nstruct Foreign {}\n".write(to: foreignFile, atomically: true, encoding: .utf8)
        let otherGeneratedFile = directory.appendingPathComponent("Sources/Other/Generated/Foo.generated.swift")
        try FileManager.default.createDirectory(at: otherGeneratedFile.deletingLastPathComponent(), withIntermediateDirectories: true)
        try "\(SwiftVaporGeneratedTextFile.managedHeader)\nstruct Foo {}\n".write(to: otherGeneratedFile, atomically: true, encoding: .utf8)

        try SwiftVaporApiPackageGenerator(package: testPackage(targetDirUrl: directory)).write()

        #expect(FileManager.default.fileExists(atPath: foreignFile.path))
        #expect(FileManager.default.fileExists(atPath: otherGeneratedFile.path))
    }

    @Test func staleCleanupRemovesOldModuleManagedSources() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let oldModel = directory.appendingPathComponent("Sources/App/Generated/Models/Old.generated.swift")
        let oldRoutes = directory.appendingPathComponent("Sources/App/routes.generated.swift")
        try FileManager.default.createDirectory(at: oldModel.deletingLastPathComponent(), withIntermediateDirectories: true)
        try "\(SwiftVaporGeneratedTextFile.managedHeader)\nstruct Old {}\n".write(to: oldModel, atomically: true, encoding: .utf8)
        try "\(SwiftVaporGeneratedTextFile.managedHeader)\nfunc oldRoutes() {}\n".write(to: oldRoutes, atomically: true, encoding: .utf8)

        try SwiftVaporApiPackageGenerator(
            package: testPackage(targetDirUrl: directory),
            options: SwiftVaporGeneratorOptions(moduleName: "Server")
        ).write()

        #expect(!FileManager.default.fileExists(atPath: oldModel.path))
        #expect(!FileManager.default.fileExists(atPath: oldRoutes.path))
        #expect(FileManager.default.fileExists(atPath: directory.appendingPathComponent("Sources/Server/routes.generated.swift").path))
    }

    @Test func writeRefusesUserOwnedFiles() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let packageFile = directory.appendingPathComponent("Package.swift")
        try "user file\n".write(to: packageFile, atomically: true, encoding: .utf8)

        #expect(throws: SwiftVaporGeneratedTextFileError.refusingToOverwriteUserFile("Package.swift")) {
            try SwiftVaporApiPackageGenerator(package: testPackage(targetDirUrl: directory)).write()
        }
    }

    @Test func writeRefusesUserOwnedDockerfile() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let dockerfile = directory.appendingPathComponent("Dockerfile")
        try "user file\n".write(to: dockerfile, atomically: true, encoding: .utf8)

        #expect(throws: SwiftVaporGeneratedTextFileError.refusingToOverwriteUserFile("Dockerfile")) {
            try SwiftVaporApiPackageGenerator(package: testPackage(targetDirUrl: directory)).write()
        }
    }

    @Test func generatedFileWriteRejectsSymlinkEscape() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let outside = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
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
        let file = SwiftVaporGeneratedTextFile(relativePath: "linked/Escaped.swift", contents: "struct Escaped {}")

        #expect(throws: SwiftVaporGeneratedTextFileError.invalidRelativePath("linked/Escaped.swift")) {
            try file.write(to: directory)
        }
        #expect(!FileManager.default.fileExists(atPath: outside.appendingPathComponent("Escaped.swift").path))
    }
}

private func testPackage(targetDirUrl: URL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)) -> ApiPackage {
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
                                    .header("X-Trace-Id", .string(), propertyName: "traceId").optional,
                                    .cookie("session_id", .string(), propertyName: "sessionId").optional
                                ],
                                response: user.asRef
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
                        references: [user, uploadReceipt, visibility]
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

private func dynamicObjectPackage(envelope: ApiTypeSchema) -> ApiPackage {
    let references = envelope.referenceDataTypes.map { reference in
        if case let .reference(_, _, _, _, dataType) = reference, let dataType {
            return dataType
        }
        return reference
    }
    return ApiPackage(
        name: "DynamicObjectTest",
        targetDirUrl: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true),
        modules: [
            ApiModule(
                name: "Admin",
                definitions: [
                    ApiService(
                        name: "Events",
                        operations: [
                            .post(
                                name: "echo",
                                path: .relative("/admin/events/echo"),
                                security: .unsecured,
                                request: envelope.asRef,
                                response: envelope.asRef
                            )
                        ],
                        references: [envelope] + references
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
