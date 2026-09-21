import Foundation
import GeneratorModels

public struct TypeScriptBackendApiPackageGenerator {
    public let package: ApiPackage
    public let options: TypeScriptBackendGeneratorOptions

    public init(package: ApiPackage, options: TypeScriptBackendGeneratorOptions = .init()) {
        self.package = package
        self.options = options
    }

    public func write() throws {
        let files = try generatedFiles()
        let targetDirectory = package.targetDirUrl.resolvingSymlinksInPath().standardizedFileURL
        for file in files {
            try file.write(to: targetDirectory, overwritePolicy: options.overwritePolicy)
        }
        if options.overwritePolicy == .replaceManagedFiles {
            try removeStaleManagedTypeScriptBackendSources(keeping: Set(files.map(\.relativePath)))
        }
    }

    public func generatedFiles() throws -> [TypeScriptBackendGeneratedTextFile] {
        try validate()
        let types = generatedDataTypes()
        let models = TypeScriptBackendModelEmitter(dataTypes: types)
        let sourceRoot = options.sourceDirectory
        var files: [TypeScriptBackendGeneratedTextFile] = []
        if options.layout == .standaloneProject {
            files += [
                .init(relativePath: "package.json", contents: packageJSON()),
                .init(relativePath: "tsconfig.json", contents: tsconfigJSON()),
                .init(relativePath: "src/index.ts", contents: rootIndex()),
                .init(relativePath: "src/app.ts", contents: appBootstrap())
            ]
        }
        files += [
            .init(relativePath: "\(sourceRoot)/runtime.ts", contents: TypeScriptBackendRuntimeEmitter().source()),
            .init(relativePath: "\(sourceRoot)/models.ts", contents: models.source()),
            .init(relativePath: "\(sourceRoot)/routes.ts", contents: TypeScriptBackendRoutesEmitter(package: package, models: models).source()),
            .init(relativePath: "\(sourceRoot)/index.ts", contents: generatedIndex())
        ]
        try validateGeneratedFilePaths(files)
        return files
    }

    private func validate() throws {
        guard options.layout == .existingProject || options.packageName.isValidBackendPackageName else {
            throw TypeScriptBackendGeneratorError.invalidPackageName(options.packageName)
        }
        guard isValidRelativeDirectory(options.sourceDirectory) else {
            throw TypeScriptBackendGeneratorError.invalidSourceDirectory(options.sourceDirectory)
        }
        for operation in allOperations() {
            try validate(operation: operation)
            guard case .relative = operation.path else {
                throw TypeScriptBackendGeneratorError.unsupportedPath(operationName: operation.name)
            }
            switch operation.request {
                case let .json(requestType):
                    guard requestType != nil else {
                        throw TypeScriptBackendGeneratorError.unsupportedRequest(operationName: operation.name)
                    }
                case let .multiPart(parts):
                    guard !parts.isEmpty,
                          parts.allSatisfy({ !$0.isEmpty }),
                          Set(parts).count == parts.count else {
                        throw TypeScriptBackendGeneratorError.invalidPackage(reason: "operation \(operation.name) has invalid multipart part names")
                    }
                case .none,
                     .binary,
                     .file:
                    break
            }
            switch operation.response {
                case let .json(responseType):
                    guard responseType != nil else {
                        throw TypeScriptBackendGeneratorError.unsupportedResponse(operationName: operation.name)
                    }
                case .none,
                     .binary:
                    break
            }
            guard !operation.acceptableStatuses.isEmpty else {
                throw TypeScriptBackendGeneratorError.invalidPackage(reason: "operation \(operation.name) has no acceptable status")
            }
        }
        try validateGeneratedTypeNames(generatedDataTypes())
        for dataType in packageDataTypes() {
            try validate(dataType: dataType)
        }
    }

    private func validate(operation: ApiOperation) throws {
        let parameters = operation.expandedParameters
        let propertyNames = parameters.map(\.propertyName.backendPropertyName)
        guard Set(propertyNames).count == propertyNames.count else {
            throw TypeScriptBackendGeneratorError.invalidPackage(reason: "operation \(operation.name) has duplicate parameter property names")
        }
        if hasBackendBody(operation), propertyNames.contains("body") {
            throw TypeScriptBackendGeneratorError.invalidPackage(reason: "operation \(operation.name) has a parameter that collides with the body input")
        }
        let wireNames = parameters.map { parameter in
            let name = parameter.location == .header ? parameter.rawName.lowercased() : parameter.rawName
            return "\(parameter.location.rawValue):\(name)"
        }
        guard Set(wireNames).count == wireNames.count else {
            throw TypeScriptBackendGeneratorError.invalidPackage(reason: "operation \(operation.name) has duplicate parameter wire names")
        }
        if parameters.contains(where: { $0.location == .cookie }),
           parameters.contains(where: { $0.location == .header && $0.rawName.caseInsensitiveCompare("Cookie") == .orderedSame }) {
            throw TypeScriptBackendGeneratorError.invalidPackage(reason: "operation \(operation.name) cannot combine Cookie header and cookie parameters")
        }
        for parameter in parameters {
            try validate(parameter: parameter, operation: operation)
        }
        guard case let .relative(path) = operation.path else {
            return
        }
        try validatePath(path: path, operation: operation, parameters: parameters)
    }

    private func validate(parameter: ApiParameter, operation: ApiOperation) throws {
        guard let type = parameter.dataType.backendDataType else {
            return
        }
        let expectedEnum: ParameterEnumKind = switch parameter.dataType {
            case .stringEnumValue,
                 .stringEnumArray: .string
            case .intEnumValue,
                 .intEnumArray: .integer
            default: .none
        }
        guard expectedEnum != .none else {
            return
        }
        let resolved = resolvedBackendType(type)
        let valid = switch (expectedEnum, resolved) {
            case (.string, .stringEnum(_, _, _, _, _)): true
            case (.integer, .intEnum(_, _, _, _)): true
            default: false
        }
        guard valid else {
            throw TypeScriptBackendGeneratorError.invalidPackage(reason: "operation \(operation.name) has an invalid enum parameter type")
        }
        switch (parameter.dataType, resolved) {
            case let (.stringEnumValue(_, defaultValue), .stringEnum(_, values, _, _, _)):
                guard defaultValue.map({ values.map(\.rawName).contains($0) }) ?? true else {
                    throw TypeScriptBackendGeneratorError.invalidPackage(reason: "operation \(operation.name) has an invalid enum parameter default")
                }
            case let (.stringEnumArray(_, defaults), .stringEnum(_, values, _, _, _)):
                guard defaults.map({ $0.allSatisfy { values.map(\.rawName).contains($0) } }) ?? true else {
                    throw TypeScriptBackendGeneratorError.invalidPackage(reason: "operation \(operation.name) has an invalid enum parameter default")
                }
            case let (.intEnumValue(_, defaultValue), .intEnum(_, values, _, _)):
                guard defaultValue.map({ values.map(\.rawValue).contains($0) }) ?? true else {
                    throw TypeScriptBackendGeneratorError.invalidPackage(reason: "operation \(operation.name) has an invalid enum parameter default")
                }
            case let (.intEnumArray(_, defaults), .intEnum(_, values, _, _)):
                guard defaults.map({ $0.allSatisfy { values.map(\.rawValue).contains($0) } }) ?? true else {
                    throw TypeScriptBackendGeneratorError.invalidPackage(reason: "operation \(operation.name) has an invalid enum parameter default")
                }
            default:
                break
        }
    }

    private enum ParameterEnumKind {
        case none
        case string
        case integer
    }

    private func resolvedBackendType(_ type: ApiTypeSchema) -> ApiTypeSchema {
        guard case let .reference(_, _, _, _, resolved) = type, let resolved else {
            return type
        }
        return resolvedBackendType(resolved)
    }

    private func validatePath(path: String, operation: ApiOperation, parameters: [ApiParameter]) throws {
        var placeholders: [String] = []
        var index = path.startIndex
        while let start = path[index...].firstIndex(of: "{") {
            guard let end = path[start...].firstIndex(of: "}") else {
                throw TypeScriptBackendGeneratorError.invalidPackage(reason: "operation \(operation.name) has malformed path placeholders")
            }
            let nameStart = path.index(after: start)
            guard nameStart < end else {
                throw TypeScriptBackendGeneratorError.invalidPackage(reason: "operation \(operation.name) has an empty path placeholder")
            }
            let name = String(path[nameStart ..< end])
            guard !name.contains("{") else {
                throw TypeScriptBackendGeneratorError.invalidPackage(reason: "operation \(operation.name) has malformed path placeholders")
            }
            placeholders.append(name)
            index = path.index(after: end)
            guard index <= path.endIndex else {
                break
            }
        }
        let pathParameters = parameters.filter { $0.location == .path }
        guard pathParameters.allSatisfy(\.isRequired),
              Set(placeholders) == Set(pathParameters.map(\.rawName)),
              placeholders.count == Set(placeholders).count,
              pathParameters.count == Set(pathParameters.map(\.rawName)).count else {
            throw TypeScriptBackendGeneratorError.invalidPackage(reason: "operation \(operation.name) has path parameters that do not match its placeholders")
        }
    }

    private func hasBackendBody(_ operation: ApiOperation) -> Bool {
        switch operation.request {
            case .none: false
            case .json,
                 .binary,
                 .file,
                 .multiPart: true
        }
    }

    private func validate(dataType: ApiTypeSchema) throws {
        switch dataType {
            case .string,
                 .bool,
                 .uuid,
                 .int,
                 .int8,
                 .int16,
                 .int32,
                 .int64,
                 .uint,
                 .uint8,
                 .uint16,
                 .uint32,
                 .uint64,
                 .double,
                 .date,
                 .timelessDate,
                 .time,
                 .url,
                 .binary:
                break
            case let .object(_, properties, _, _, _, _):
                for property in properties where property.publishedAsField {
                    try validate(dataType: property.dataType)
                }
            case let .reference(_, _, _, _, resolved):
                if let resolved {
                    try validate(dataType: resolved)
                }
            case let .dynamicObject(_, _, _, _, objectTypes, _, _, _, extraProperties):
                for objectType in objectTypes {
                    try validate(dataType: objectType.objectType)
                }
                for property in extraProperties where property.publishedAsField {
                    try validate(dataType: property.dataType)
                }
            case let .array(type),
                 let .keyedByString(type, _):
                try validate(dataType: type)
            case .stringEnum,
                 .intEnum:
                break
            case let .genericReference(typeName, types) where typeName == "PatchableValue" && types.count == 1:
                try validate(dataType: types[0])
            case let .genericReference(_, types):
                for type in types {
                    try validate(dataType: type)
                }
        }
    }

    private func generatedDataTypes() -> [ApiTypeSchema] {
        var result: [ApiTypeSchema] = []
        var seen: Set<UUID> = []
        for dataType in packageDataTypes() {
            dataType.appendBackendDeclaredTypes(to: &result, seen: &seen)
        }
        return result
    }

    private func validateGeneratedTypeNames(_ dataTypes: [ApiTypeSchema]) throws {
        var names: [String: (id: UUID, source: String)] = [:]
        for dataType in dataTypes {
            guard let id = dataType.backendDeclaredTypeID,
                  let source = dataType.backendDeclaredTypeName else {
                continue
            }
            let generatedName = source.backendTypeName
            if let existing = names[generatedName], existing.id != id {
                throw TypeScriptBackendGeneratorError.typeNameCollision(
                    generatedName: generatedName,
                    firstType: existing.source,
                    secondType: source,
                )
            }
            names[generatedName] = (id, source)
        }
    }

    private func packageDataTypes() -> [ApiTypeSchema] {
        package.references
            + package.modules.flatMap { module in
                module.references
                    + module.definitions.flatMap { definition in
                        definition.referencedTypes + definition.operations.flatMap(\.backendDataTypes)
                    }
            }
    }

    private func allOperations() -> [ApiOperation] {
        package.modules.flatMap { $0.definitions.flatMap(\.operations) }
    }

    private func packageJSON() -> String {
        """
        {
          "x-generated": "Generated code. Do not edit.",
          "name": \(options.packageName.backendStringLiteral),
          "version": \(options.packageVersion.backendStringLiteral),
          "type": "module",
          "main": "./dist/index.js",
          "types": "./dist/index.d.ts",
          "scripts": {
            "build": "tsc -p tsconfig.json"
          },
          "dependencies": {
            "express": "^5.2.1",
            "lossless-json": "^4.3.0",
            "zod": "^4.4.3"
          },
          "devDependencies": {
            "@types/express": "^5.0.5",
            "@types/node": "^24.0.0",
            "typescript": "^6.0.0"
          }
        }
        """
    }

    private func tsconfigJSON() -> String {
        """
        // Generated code. Do not edit.
        {
          "compilerOptions": {
            "target": "ES2022",
            "lib": ["DOM", "DOM.Iterable", "ES2022"],
            "module": "NodeNext",
            "moduleResolution": "NodeNext",
            "declaration": true,
            "outDir": "dist",
            "rootDir": "src",
            "strict": true,
            "esModuleInterop": true,
            "skipLibCheck": true
          },
          "include": ["src/**/*.ts"]
        }
        """
    }

    private func rootIndex() -> String {
        """
        // Generated code. Do not edit.

        export * from "./generated/index.js";
        export * from "./app.js";
        """
    }

    private func appBootstrap() -> String {
        """
        // Generated code. Do not edit.

        import express, { type Express } from "express";
        import {
            registerGeneratedRoutes,
            type GeneratedHandlers,
            type GeneratedMultipartAdapters,
            type GeneratedRequestIntegration,
            type GeneratedSchemaBindings,
            type GeneratedRouteOptions
        } from "./generated/routes.js";

        export function createApp<Bindings extends GeneratedSchemaBindings = {}, Integration extends GeneratedRequestIntegration = {}, Multipart extends GeneratedMultipartAdapters = {}>(
            handlers: GeneratedHandlers<Bindings, Integration, Multipart>,
            bindings?: Bindings,
            options?: GeneratedRouteOptions<Integration, Multipart>,
        ): Express {
            const app = express();
            registerGeneratedRoutes(app, handlers, bindings, options);
            return app;
        }
        """
    }

    private func generatedIndex() -> String {
        """
        // Generated code. Do not edit.

        export * from "./runtime.js";
        export * from "./models.js";
        export * from "./routes.js";
        """
    }

    private func isValidRelativeDirectory(_ path: String) -> Bool {
        let components = path.split(separator: "/", omittingEmptySubsequences: false)
        return !path.isEmpty
            && !path.contains("\\")
            && components.allSatisfy { !$0.isEmpty && $0 != "." && $0 != ".." }
    }

    private func validateGeneratedFilePaths(_ files: [TypeScriptBackendGeneratedTextFile]) throws {
        var paths: Set<String> = []
        for file in files {
            let path = try file.validatedPathComponents().joined(separator: "/")
            guard paths.insert(path).inserted else {
                throw TypeScriptBackendGeneratorError.invalidSourceDirectory(options.sourceDirectory)
            }
        }
        for path in paths {
            var components = path.split(separator: "/")
            while components.count > 1 {
                components.removeLast()
                guard !paths.contains(components.joined(separator: "/")) else {
                    throw TypeScriptBackendGeneratorError.invalidSourceDirectory(options.sourceDirectory)
                }
            }
        }
    }

    private func removeStaleManagedTypeScriptBackendSources(keeping relativePaths: Set<String>) throws {
        let sourceURL = options.sourceDirectory
            .split(separator: "/")
            .map(String.init)
            .reduce(package.targetDirUrl) { $0.appendingPathComponent($1, isDirectory: true) }
        guard FileManager.default.fileExists(atPath: sourceURL.path) else {
            return
        }

        let enumerator = FileManager.default.enumerator(
            at: sourceURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles],
        )
        let basePath = package.targetDirUrl.resolvingSymlinksInPath().standardizedFileURL.path
        while let fileURL = enumerator?.nextObject() as? URL {
            let values = try fileURL.resourceValues(forKeys: [.isRegularFileKey])
            guard values.isRegularFile == true else {
                continue
            }
            let filePath = fileURL.resolvingSymlinksInPath().standardizedFileURL.path
            guard filePath.hasPrefix(basePath + "/") else {
                continue
            }
            let relativePath = String(filePath.dropFirst(basePath.count + 1))
            guard !relativePaths.contains(relativePath) else {
                continue
            }
            let contents = (try? String(contentsOf: fileURL, encoding: .utf8)) ?? ""
            guard contents.hasPrefix(TypeScriptBackendGeneratedTextFile.managedHeader) else {
                continue
            }
            try FileManager.default.removeItem(at: fileURL)
        }
    }
}
