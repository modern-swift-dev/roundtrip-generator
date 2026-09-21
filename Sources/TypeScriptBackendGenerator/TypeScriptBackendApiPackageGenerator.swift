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
        for file in files {
            try file.write(to: package.targetDirUrl.resolvingSymlinksInPath().standardizedFileURL, overwritePolicy: options.overwritePolicy)
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
                .init(relativePath: "src/index.ts", contents: rootIndex())
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
            guard operation.security == .unsecured else {
                throw TypeScriptBackendGeneratorError.unsupportedSecurity(operationName: operation.name)
            }
            guard case .relative = operation.path else {
                throw TypeScriptBackendGeneratorError.unsupportedPath(operationName: operation.name)
            }
            guard case let .json(requestType) = operation.request, requestType != nil else {
                throw TypeScriptBackendGeneratorError.unsupportedRequest(operationName: operation.name)
            }
            guard case let .json(responseType) = operation.response, responseType != nil else {
                throw TypeScriptBackendGeneratorError.unsupportedResponse(operationName: operation.name)
            }
            guard !operation.acceptableStatuses.isEmpty else {
                throw TypeScriptBackendGeneratorError.invalidPackage(reason: "operation \(operation.name) has no acceptable status")
            }
        }
        for dataType in packageDataTypes() {
            try validate(dataType: dataType)
            if let external = dataType.backendExternalTypeName {
                throw TypeScriptBackendGeneratorError.unresolvedExternalType(external)
            }
        }
    }

    private func validate(dataType: ApiTypeSchema) throws {
        switch dataType {
            case .string,
                 .bool,
                 .double:
                break
            case let .object(_, properties, _, _, _, _):
                for property in properties where property.publishedAsField {
                    try validate(dataType: property.dataType)
                }
            case let .reference(_, _, _, _, resolved):
                if let resolved {
                    try validate(dataType: resolved)
                }
            case .uuid,
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
                 .date,
                 .timelessDate,
                 .time,
                 .url,
                 .binary,
                 .keyedByString,
                 .stringEnum,
                 .intEnum,
                 .array,
                 .dynamicObject,
                 .genericReference:
                throw TypeScriptBackendGeneratorError.unsupportedDataType(String(describing: dataType))
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
            "zod": "^4.4.3"
          },
          "devDependencies": {
            "@types/express": "^5.0.5",
            "@types/node": "^24.0.0",
            "typescript": "^5.9.0"
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
    }
}
