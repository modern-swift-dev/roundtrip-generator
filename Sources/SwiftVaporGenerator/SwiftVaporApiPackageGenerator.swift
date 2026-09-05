import Foundation
import GeneratorBuilder
import GeneratorModels
import SwiftApiGenerator

public enum SwiftVaporGeneratorError: Error, LocalizedError, Equatable {
    case invalidAppName(String)
    case invalidModuleName(String)
    case unsupportedAppleFrameworkImport(String)

    public var errorDescription: String? {
        switch self {
            case let .invalidAppName(value):
                "Invalid Swift Vapor app name: \(value)"
            case let .invalidModuleName(value):
                "Invalid Swift Vapor module name: \(value)"
            case let .unsupportedAppleFrameworkImport(value):
                "Swift Vapor generated code does not support Apple-only framework import: \(value)"
        }
    }
}

public struct SwiftVaporApiPackageGenerator {
    public let package: ApiPackage
    public let options: SwiftVaporGeneratorOptions

    public init(package: ApiPackage, options: SwiftVaporGeneratorOptions = .init()) {
        self.package = package
        self.options = options
    }

    public func write() throws {
        let files = try generatedFiles()
        for file in files {
            try file.write(to: package.targetDirUrl.resolvingSymlinksInPath().standardizedFileURL, overwritePolicy: options.overwritePolicy)
        }
        if options.overwritePolicy == .replaceManagedFiles {
            try removeStaleManagedSwiftSources(keeping: Set(files.map(\.relativePath)))
        }
    }

    public func generatedFiles() throws -> [SwiftVaporGeneratedTextFile] {
        try validate()

        var registry = SwiftVaporTypeRegistry()
        registry.registerPackage(package)

        var files: [SwiftVaporGeneratedTextFile] = []
        if options.layout == .standaloneProject, options.generatePackage {
            files.append(packageFile())
        }
        if options.layout == .standaloneProject, options.generateRunTarget {
            files.append(runFile())
        }
        if options.layout == .standaloneProject, options.generatePackage, options.generateRunTarget, options.generateDockerfile {
            files.append(dockerfile())
        }
        if options.layout == .standaloneProject {
            files.append(configureFile())
        }
        files.append(SwiftVaporRuntimeEmitter(sourceRoot: sourceRoot).file())
        files.append(contentsOf: registry.types.map {
            SwiftVaporModelEmitter(
                registry: registry,
                sourceRoot: sourceRoot,
                packageImports: package.imports
            )
            .file(for: $0)
        })
        files.append(contentsOf: routeEmitterFiles(registry: registry))
        files.append(routesFile(registry: registry))
        try validateUniqueGeneratedPaths(files)
        return files
    }

    private func validate() throws {
        try ApiPackageValidator(package: vaporValidationPackage).validate()
        guard options.layout == .existingProject || options.appName.isValidSwiftVaporPackageName else {
            throw SwiftVaporGeneratorError.invalidAppName(options.appName)
        }
        guard options.moduleName.isValidSwiftVaporIdentifier else {
            throw SwiftVaporGeneratorError.invalidModuleName(options.moduleName)
        }
        guard options.layout == .existingProject || !options.generateRunTarget || options.moduleName != "Run" else {
            throw SwiftVaporGeneratorError.invalidModuleName(options.moduleName)
        }
        try validateResponseTypes()
        try validateMultipartParts()
        try validateRouteRegistrations()
        try validateLinuxPortableImports()
    }

    private func validateResponseTypes() throws {
        for module in package.modules {
            for definition in module.definitions {
                for operation in definition.operations where operation.isSwiftVaporRoutable {
                    switch operation.response {
                        case .json(nil):
                            throw ApiValidationError.failed(
                                "Swift Vapor operation \(operation.name) in \(module.name).\(definition.name) has a typed response without a data type"
                            )
                        case .json,
                             .binary:
                            let bodyStatuses = operation.acceptableStatuses.filter(Self.statusCodeCanCarryResponseBody)
                            guard !bodyStatuses.isEmpty else {
                                throw ApiValidationError.failed(
                                    "Swift Vapor operation \(operation.name) in \(module.name).\(definition.name) has a typed response but no acceptable status can carry a response body"
                                )
                            }
                        default:
                            break
                    }
                }
            }
        }
    }

    private func validateMultipartParts() throws {
        for module in package.modules {
            for definition in module.definitions {
                for operation in definition.operations where operation.isSwiftVaporRoutable {
                    guard case let .multiPart(parts) = operation.request else {
                        continue
                    }
                    let propertyNames = parts.map(\.swiftPropertyName)
                    guard Set(propertyNames).count == propertyNames.count else {
                        throw ApiValidationError.failed(
                            "Swift Vapor operation \(operation.name) in \(module.name).\(definition.name) has multipart part names that generate duplicate properties"
                        )
                    }
                }
            }
        }
    }

    private func validateRouteRegistrations() throws {
        var routes: [String] = []
        for module in package.modules {
            for definition in module.definitions {
                for operation in definition.operations where operation.isSwiftVaporRoutable {
                    guard case let .relative(path) = operation.path else {
                        continue
                    }
                    routes.append("\(operation.method.httpMethod) \(path.swiftVaporRouteSignature)")
                }
            }
        }

        guard Set(routes).count == routes.count else {
            let duplicates = Dictionary(grouping: routes, by: { $0 })
                .filter { $0.value.count > 1 }
                .keys
                .sorted()
            throw ApiValidationError.failed("Duplicate generated Swift Vapor routes: \(duplicates)")
        }
    }

    private func validateLinuxPortableImports() throws {
        for importName in vaporValidationPackage.swiftVaporPortableImports.map(\.name) where importName.isSwiftVaporAppleOnlyFrameworkImport {
            throw SwiftVaporGeneratorError.unsupportedAppleFrameworkImport(importName)
        }
    }

    private var vaporValidationPackage: ApiPackage {
        ApiPackage(
            name: package.name,
            targetDirUrl: package.targetDirUrl,
            modules: package.modules.map(\.swiftVaporRoutableModule),
            referencedModules: package.referencedModules.map(\.swiftVaporRoutableModule),
            references: package.references,
            commonReferences: package.commonReferences + referencedModuleDataTypes,
            imports: package.imports,
            generateApiModules: package.generateApiModules
        )
    }

    private var referencedModuleDataTypes: [ApiTypeSchema] {
        var seen: Set<UUID> = []
        return package.referencedModules.flatMap(\.swiftVaporDataTypes).filter { dataType in
            guard let uuid = dataType.swiftVaporTypeID else {
                return true
            }
            return seen.insert(uuid).inserted
        }
    }

    private static func statusCodeCanCarryResponseBody(_ statusCode: Int) -> Bool {
        !(100 ..< 200 ~= statusCode || statusCode == 204 || statusCode == 205 || statusCode == 304)
    }

    private func validateUniqueGeneratedPaths(_ files: [SwiftVaporGeneratedTextFile]) throws {
        let paths = files.map(\.relativePath)
        guard Set(paths).count == paths.count else {
            let duplicates = Dictionary(grouping: paths, by: { $0 })
                .filter { $0.value.count > 1 }
                .keys
                .sorted()
            throw ApiValidationError.failed("Duplicate generated Swift Vapor file paths: \(duplicates)")
        }
    }

    private func routeEmitterFiles(registry: SwiftVaporTypeRegistry) -> [SwiftVaporGeneratedTextFile] {
        var files: [SwiftVaporGeneratedTextFile] = []
        for module in package.modules {
            for definition in module.definitions {
                let emitter = SwiftVaporOperationEmitter(
                    module: module,
                    definition: definition,
                    registry: registry,
                    sourceRoot: sourceRoot,
                    packageImports: package.imports
                )
                files.append(contentsOf: emitter.requestFiles())
                files.append(emitter.serviceFile())
                files.append(emitter.controllerFile())
            }
        }
        return files
    }

    private func packageFile() -> SwiftVaporGeneratedTextFile {
        let executableProduct = options.generateRunTarget
            ? ",\n        .executable(name: \"Run\", targets: [\"Run\"])"
            : ""
        let executableTarget = options.generateRunTarget
            ? """
            ,
                    .executableTarget(
                        name: "Run",
                        dependencies: [
                            .target(name: "\(options.moduleName)")
                        ]
                    )
            """
            : ""
        let packageDependencies = ([
            ".package(url: \"https://github.com/vapor/vapor.git\", from: \"\(options.vaporVersion)\")"
        ] + options.additionalPackageDependencies)
            .swiftVaporManifestLines(indentedBy: 8)
        let targetDependencies = ([
            ".product(name: \"Vapor\", package: \"vapor\")"
        ] + options.additionalTargetDependencies)
            .swiftVaporManifestLines(indentedBy: 16)
        return SwiftVaporGeneratedTextFile(relativePath: "Package.swift", contents: """
        // swift-tools-version:\(options.swiftToolsVersion)
        // Generated code. Do not edit.
        import PackageDescription

        let package = Package(
            name: "\(options.appName)",
            platforms: [
                .macOS(.v10_15)
            ],
            products: [
                .library(name: "\(options.moduleName)", targets: ["\(options.moduleName)"])\(executableProduct)
            ],
            dependencies: [
        \(packageDependencies)
            ],
            targets: [
                .target(
                    name: "\(options.moduleName)",
                    dependencies: [
        \(targetDependencies)
                    ]
                )\(executableTarget)
            ]
        )
        """)
    }

    private func runFile() -> SwiftVaporGeneratedTextFile {
        SwiftVaporGeneratedTextFile(relativePath: "Sources/Run/main.swift", contents: """
        // Generated code. Do not edit.
        import \(options.moduleName)
        import Vapor

        @main
        enum Entrypoint {
            static func main() async throws {
                var env = try Environment.detect()
                try LoggingSystem.bootstrap(from: &env)
                let app = try await Application.make(env)
                do {
                    try await configure(app)
                    try await app.execute()
                } catch {
                    try await app.asyncShutdown()
                    throw error
                }
                try await app.asyncShutdown()
            }
        }
        """)
    }

    private func dockerfile() -> SwiftVaporGeneratedTextFile {
        SwiftVaporGeneratedTextFile(relativePath: "Dockerfile", contents: """
        # Generated code. Do not edit.
        FROM swift:\(options.swiftToolsVersion) AS build

        WORKDIR /build
        COPY Package.swift ./
        RUN swift package resolve
        COPY Sources ./Sources
        RUN swift build -c release

        FROM swift:\(options.swiftToolsVersion)

        WORKDIR /app
        COPY --from=build /build/.build/release/Run ./Run

        EXPOSE 8080
        ENTRYPOINT ["./Run"]
        CMD ["serve", "--hostname", "0.0.0.0"]
        """)
    }

    private func configureFile() -> SwiftVaporGeneratedTextFile {
        SwiftVaporGeneratedTextFile(relativePath: "\(sourceRoot)/configure.swift", contents: """
        // Generated code. Do not edit.
        import Vapor

        public func configure(
            _ app: Application,
            services: GeneratedApiServices = .notImplemented,
            security: any GeneratedSecurityMiddleware = AllowAllGeneratedSecurityMiddleware()
        ) async throws {
            try routes(app, services: services, security: security)
        }
        """)
    }

    private func routesFile(registry _: SwiftVaporTypeRegistry) -> SwiftVaporGeneratedTextFile {
        let serviceProperties = serviceDefinitions.map { item in
            "    public let \(item.propertyName): any \(item.serviceTypeName)"
        }
        .joined(separator: "\n")
        let initParameters = serviceDefinitions.map { item in
            "\(item.propertyName): any \(item.serviceTypeName)"
        }
        .joined(separator: ", ")
        let initAssignments = serviceDefinitions.map { item in
            "        self.\(item.propertyName) = \(item.propertyName)"
        }
        .joined(separator: "\n")
        let defaultArguments = serviceDefinitions.map { item in
            "            \(item.propertyName): NotImplemented\(item.serviceTypeName)()"
        }
        .joined(separator: ",\n")
        let controllerRegistrations = serviceDefinitions.map { item in
            """
                try \(item.controllerTypeName)(
                    service: services.\(item.propertyName),
                    security: security
                ).register(routes: routes)
            """
        }
        .joined(separator: "\n")

        return SwiftVaporGeneratedTextFile(relativePath: "\(sourceRoot)/routes.generated.swift", contents: """
        // Generated code. Do not edit.
        import Vapor

        public struct GeneratedApiServices: Sendable {
        \(serviceProperties)

            public init(\(initParameters)) {
        \(initAssignments)
            }

            public static var notImplemented: GeneratedApiServices {
                GeneratedApiServices(
        \(defaultArguments)
                )
            }
        }

        public func routes(
            _ app: Application,
            services: GeneratedApiServices = .notImplemented,
            security: any GeneratedSecurityMiddleware = AllowAllGeneratedSecurityMiddleware()
        ) throws {
            try routes(app.routes, services: services, security: security)
        }

        public func routes(
            _ routes: RoutesBuilder,
            services: GeneratedApiServices = .notImplemented,
            security: any GeneratedSecurityMiddleware = AllowAllGeneratedSecurityMiddleware()
        ) throws {
        \(controllerRegistrations)
        }
        """)
    }

    private var serviceDefinitions: [(propertyName: String, serviceTypeName: String, controllerTypeName: String)] {
        package.modules.flatMap { module in
            module.definitions.map { definition in
                (
                    propertyName: "\(module.name)\(definition.name)Service".swiftPropertyName,
                    serviceTypeName: definition.swiftVaporServiceTypeName(moduleName: module.name),
                    controllerTypeName: definition.swiftVaporControllerTypeName(moduleName: module.name)
                )
            }
        }
    }

    private func removeStaleManagedSwiftSources(keeping generatedRelativePaths: Set<String>) throws {
        let sourceRootURL = url(forRelativePath: "Sources", in: package.targetDirUrl)
        guard let enumerator = FileManager.default.enumerator(
            at: sourceRootURL,
            includingPropertiesForKeys: [.isRegularFileKey]
        ) else {
            return
        }

        let basePath = package.targetDirUrl.resolvingSymlinksInPath().standardizedFileURL.path
        for case let fileURL as URL in enumerator where fileURL.pathExtension == "swift" {
            let filePath = fileURL.resolvingSymlinksInPath().standardizedFileURL.path
            guard filePath.hasPrefix("\(basePath)/") else {
                continue
            }
            let relativePath = String(filePath.dropFirst(basePath.count + 1))
            guard !generatedRelativePaths.contains(relativePath),
                  isVaporManagedSwiftSource(relativePath),
                  let contents = try? String(contentsOf: fileURL, encoding: .utf8),
                  contents.hasPrefix(SwiftVaporGeneratedTextFile.managedHeader) else {
                continue
            }
            try FileManager.default.removeItem(at: fileURL)
        }
    }

    private func isVaporManagedSwiftSource(_ relativePath: String) -> Bool {
        isManagedSwiftSource(relativePath, sourceRoot: sourceRoot)
            || isManagedSwiftSource(relativePath, sourceRoot: "Sources/App")
            || relativePath == "Sources/Run/main.swift"
    }

    private func isManagedSwiftSource(_ relativePath: String, sourceRoot: String) -> Bool {
        relativePath.hasPrefix("\(sourceRoot)/Generated/")
            || relativePath == "\(sourceRoot)/routes.generated.swift"
            || relativePath == "\(sourceRoot)/configure.swift"
    }

    private func url(forRelativePath relativePath: String, in baseURL: URL) -> URL {
        relativePath.split(separator: "/").reduce(baseURL) { partialURL, component in
            partialURL.appendingPathComponent(String(component))
        }
    }

    private var sourceRoot: String {
        "Sources/\(options.moduleName)"
    }
}

private extension ApiModule {
    var swiftVaporDataTypes: [ApiTypeSchema] {
        references + definitions.flatMap(\.swiftVaporDataTypes)
    }
}

private extension ApiService {
    var swiftVaporDataTypes: [ApiTypeSchema] {
        referencedTypes + operations.filter(\.isSwiftVaporRoutable).flatMap { operation in
            operation.swiftVaporDeclaredDataTypes + operation.parameters.compactMap(\.swiftVaporDeclaredDataType)
        }
    }
}

private extension ApiTypeSchema {
    var swiftVaporTypeID: UUID? {
        switch self {
            case let .object(_, _, _, _, _, uuid),
                 let .stringEnum(_, _, _, uuid, _),
                 let .intEnum(_, _, _, uuid),
                 let .dynamicObject(_, _, _, _, _, _, _, uuid, _),
                 let .reference(_, _, _, uuid, _):
                uuid
            default:
                nil
        }
    }
}

private extension ApiPackage {
    var swiftVaporPortableImports: [ApiImport] {
        imports
            + modules.flatMap(\.swiftVaporPortableImports)
            + referencedModules.flatMap(\.swiftVaporPortableImports)
            + references.flatMap(\.swiftVaporImports)
            + commonReferences.flatMap(\.swiftVaporImports)
    }
}

private extension ApiModule {
    var swiftVaporPortableImports: [ApiImport] {
        references.flatMap(\.swiftVaporImports)
            + definitions.flatMap(\.swiftVaporPortableImports)
    }
}

private extension ApiService {
    var swiftVaporPortableImports: [ApiImport] {
        referencedTypes.flatMap(\.swiftVaporImports)
            + operations.flatMap(\.swiftVaporPortableImports)
    }
}

private extension ApiOperation {
    var swiftVaporPortableImports: [ApiImport] {
        extraImports
            + [request.dataType, response.dataType]
            .compactMap(\.self)
            .flatMap(\.swiftVaporImports)
            + parameters.compactMap(\.swiftVaporPortableDeclaredDataType)
            .flatMap(\.swiftVaporImports)
    }
}

private extension ApiParameter {
    var swiftVaporPortableDeclaredDataType: ApiTypeSchema? {
        switch dataType {
            case let .stringEnumValue(type, _),
                 let .stringEnumArray(type, _),
                 let .intEnumValue(type, _),
                 let .intEnumArray(type, _):
                type
            default:
                nil
        }
    }
}

private extension String {
    var isSwiftVaporAppleOnlyFrameworkImport: Bool {
        Set([
            "AppKit",
            "Cocoa",
            "Combine",
            "CoreData",
            "CoreGraphics",
            "CoreLocation",
            "CoreML",
            "Darwin",
            "MapKit",
            "Metal",
            "ObjectiveC",
            "OSLog",
            "QuartzCore",
            "SwiftUI",
            "UIKit",
            "UniformTypeIdentifiers",
            "UserNotifications",
            "WebKit"
        ]).contains(self)
    }
}

private extension String {
    var swiftVaporRouteSignature: String {
        let routePath = split(whereSeparator: { $0 == "?" || $0 == "#" })
            .first
            .map(String.init) ?? ""
        return routePath
            .split(separator: "/")
            .map(String.init)
            .filter { !$0.isEmpty }
            .map { component in
                if component.hasPrefix("{"), component.hasSuffix("}") {
                    return "{}"
                }
                return component
            }
            .joined(separator: "/")
    }

    var isValidSwiftVaporIdentifier: Bool {
        guard self != "_" else {
            return false
        }
        guard let first, first == "_" || first.isLetter else {
            return false
        }
        return allSatisfy { $0 == "_" || $0.isLetter || $0.isNumber }
            && swiftIdentifier == self
    }

    var isValidSwiftVaporPackageName: Bool {
        guard !isEmpty, !contains("..") else {
            return false
        }
        return allSatisfy { character in
            character == "-" || character == "_" || character == "." || character.isLetter || character.isNumber
        }
    }
}

private extension [String] {
    func swiftVaporManifestLines(indentedBy spaceCount: Int) -> String {
        let indentation = String(repeating: " ", count: spaceCount)
        return map { snippet in
            snippet
                .split(separator: "\n", omittingEmptySubsequences: false)
                .map { "\(indentation)\($0)" }
                .joined(separator: "\n")
        }
        .joined(separator: ",\n")
    }
}
