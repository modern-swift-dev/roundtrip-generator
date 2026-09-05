import Foundation
import GeneratorModels

public struct TypeScriptApiPackageGenerator {
    public let package: ApiPackage
    public let options: TypeScriptGeneratorOptions

    public init(package: ApiPackage, options: TypeScriptGeneratorOptions = .init()) {
        self.package = package
        self.options = options
    }

    public func write() throws {
        let files = try generatedFiles()
        for file in files {
            try file.write(to: package.targetDirUrl.resolvingSymlinksInPath().standardizedFileURL, overwritePolicy: options.overwritePolicy)
        }
        if options.overwritePolicy == .replaceManagedFiles {
            try removeStaleManagedTypeScriptSources(keeping: Set(files.map(\.relativePath)))
        }
    }

    public func generatedFiles() throws -> [TypeScriptGeneratedTextFile] {
        let rootDataTypes = rootDataTypes()
        let dataTypes = allGeneratedDataTypes(from: rootDataTypes)
        try validate(dataTypes: dataTypes, rootDataTypes: rootDataTypes)

        var files = options.layout == .standaloneProject ? projectFiles() : []
        if options.generateRuntime {
            files.append(sourceFile(name: "runtime.ts", contents: TypeScriptRuntimeEmitter().source()))
        }
        files.append(sourceFile(name: "models.ts", contents: TypeScriptModelEmitter(dataTypes: dataTypes, options: options).source()))
        files.append(sourceFile(name: "operations.ts", contents: TypeScriptOperationFileEmitter(package: package, options: options).source()))
        if options.flavor == .tanStackQuery {
            files.append(sourceFile(name: "tanstack-query.ts", contents: TypeScriptTanStackQueryEmitter(package: package, options: options).source()))
        }
        files.append(sourceFile(name: "index.ts", contents: generatedIndex()))
        if options.layout == .standaloneProject {
            files.append(TypeScriptGeneratedTextFile(relativePath: "src/index.ts", contents: rootIndex()))
        }

        try validateGeneratedFilePaths(files)
        return files
    }

    private func projectFiles() -> [TypeScriptGeneratedTextFile] {
        [
            TypeScriptGeneratedTextFile(relativePath: "package.json", contents: packageJSON()),
            TypeScriptGeneratedTextFile(relativePath: "tsconfig.json", contents: tsconfigJSON())
        ]
    }

    private func sourceFile(name: String, contents: String) -> TypeScriptGeneratedTextFile {
        TypeScriptGeneratedTextFile(relativePath: "\(options.sourceDirectory)/\(name)", contents: contents)
    }

    private func generatedIndex() -> String {
        let flavorExports = switch options.flavor {
            case .plain:
                ""
            case .tanStackQuery:
                "\nexport * from \"./tanstack-query.js\";"
        }
        return """
        // Generated code. Do not edit.

        export * from "./runtime.js";
        export * from "./models.js";
        export * from "./operations.js";\(flavorExports)
        """
    }

    private func rootIndex() -> String {
        """
        // Generated code. Do not edit.

        export * from \(rootExportPath.tsStringLiteral);
        """
    }

    private var sourcesAreUnderSrc: Bool { options.sourceDirectory.hasPrefix("src/") }

    private var rootExportPath: String {
        sourcesAreUnderSrc
            ? "./" + options.sourceDirectory.dropFirst(4) + "/index.js"
            : "../" + options.sourceDirectory + "/index.js"
    }

    private func packageJSON() -> String {
        let peerDependencies = switch options.flavor {
            case .plain:
                ""
            case .tanStackQuery:
                #"""
                ,
                  "peerDependencies": {
                    "@tanstack/react-query": "^5.0.0"
                  }
                """#
        }
        let devDependencies = switch options.flavor {
            case .plain:
                #"    "typescript": "^5.9.0""#
            case .tanStackQuery:
                """
                    "@tanstack/react-query": "^5.0.0",
                    "typescript": "^5.9.0"
                """
        }
        return """
        {
          "x-generated": "Generated code. Do not edit.",
          "name": \(options.packageName.tsStringLiteral),
          "version": \(options.packageVersion.tsStringLiteral),
          "type": "module",
          "main": \((sourcesAreUnderSrc ? "./dist/index.js" : "./dist/src/index.js").tsStringLiteral),
          "types": \((sourcesAreUnderSrc ? "./dist/index.d.ts" : "./dist/src/index.d.ts").tsStringLiteral),
          "scripts": {
            "build": "tsc -p tsconfig.json"
          },
          "devDependencies": {
        \(devDependencies)
          }\(peerDependencies)
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
            "module": "ES2022",
            "moduleResolution": "Bundler",
            "declaration": true,
            "outDir": "dist",
            "rootDir": \((sourcesAreUnderSrc ? "src" : ".").tsStringLiteral),
            "strict": true,
            "skipLibCheck": true
          },
          "include": ["src/index.ts", \((options.sourceDirectory + "/**/*.ts").tsStringLiteral)]
        }
        """
    }

    private func validate(dataTypes: [ApiTypeSchema], rootDataTypes: [ApiTypeSchema]) throws {
        guard options.layout == .existingProject || options.packageName.isValidTypeScriptPackageName else {
            throw TypeScriptGeneratorError.invalidPackageName(options.packageName)
        }
        guard isValidRelativeDirectory(options.sourceDirectory) else {
            throw TypeScriptGeneratorError.invalidSourceDirectory(options.sourceDirectory)
        }

        let typeNames = dataTypes.compactMap { dataType -> String? in
            guard let typeName = dataType.typeName else {
                return nil
            }
            return typeName.tsTypeName
        }
        try validateUnique(typeNames, reason: "has duplicate generated type names")
        try validateGeneratedNames()

        for typeName in unresolvedExternalTypeNames(in: rootDataTypes) {
            throw TypeScriptGeneratorError.unresolvedExternalType(typeName)
        }

        for operation in allOperations() {
            guard !operation.acceptableStatuses.isEmpty else {
                throw TypeScriptGeneratorError.emptyAcceptableStatuses(operationName: operation.name)
            }
            if let invalid = operation.acceptableStatuses.first(where: { !(100 ... 599).contains($0) }) {
                throw TypeScriptGeneratorError.invalidAcceptableStatus(operationName: operation.name, statusCode: invalid)
            }
            if operation.response.dataType != nil,
               let bodyless = operation.acceptableStatuses.first(where: \.isHttpBodylessStatus) {
                throw TypeScriptGeneratorError.typedResponseWithBodylessStatus(operationName: operation.name, statusCode: bodyless)
            }
        }
    }

    private func validateUnique(_ values: [some Hashable], reason: String) throws {
        guard Set(values).count == values.count else {
            throw TypeScriptGeneratorError.invalidPackage(reason: reason)
        }
    }

    private func validateGeneratedNames() throws {
        try validateUnique(
            package.modules.map(\.tsApiModuleTypeName),
            reason: "has duplicate module type names"
        )
        try validateUnique(
            package.modules.map(\.tsModulePropertyName),
            reason: "has duplicate module property names"
        )

        for module in package.modules {
            try validateUnique(
                module.definitions.map { $0.tsApiTypeName(moduleName: module.name) },
                reason: "module \(module.name) has duplicate API type names"
            )
            try validateUnique(
                module.definitions.map(\.tsApiPropertyName),
                reason: "module \(module.name) has duplicate API property names"
            )
            for definition in module.definitions {
                try validateUnique(
                    definition.operations.map { operation in
                        TypeScriptOperationEmitter(
                            module: module,
                            definition: definition,
                            operation: operation,
                            options: options
                        )
                        .requestTypeName
                    },
                    reason: "definition \(definition.name) has duplicate request type names"
                )
                try validateUnique(
                    definition.operations.map { operation in
                        TypeScriptOperationEmitter(
                            module: module,
                            definition: definition,
                            operation: operation,
                            options: options
                        )
                        .builderName
                    },
                    reason: "definition \(definition.name) has duplicate request builder names"
                )
                try validateUnique(
                    definition.operations.map(\.name.tsPropertyName),
                    reason: "definition \(definition.name) has duplicate method names"
                )
                for operation in definition.operations {
                    try validateUnique(
                        operation.expandedParameters.map(\.propertyName.tsPropertyName) + requestReservedNames(operation),
                        reason: "operation \(operation.name) has duplicate request property names"
                    )
                }
            }
        }
    }

    private func requestReservedNames(_ operation: ApiOperation) -> [String] {
        var names: [String] = []
        if operation.path.isRuntime {
            names.append("requestUrl")
        }
        switch operation.request {
            case .none:
                break
            case .binary,
                 .file,
                 .multiPart,
                 .json:
                names.append("body")
        }
        return names
    }

    private func isValidRelativeDirectory(_ path: String) -> Bool {
        let components = path.split(separator: "/", omittingEmptySubsequences: false)
        return !path.isEmpty && !path.contains("\\")
            && components.allSatisfy { !$0.isEmpty && $0 != "." && $0 != ".." }
    }

    private func allOperations() -> [ApiOperation] {
        package.modules.flatMap { $0.definitions.flatMap(\.operations) }
    }

    private func rootDataTypes() -> [ApiTypeSchema] {
        package.references + package.modules.flatMap { module in
            module.references + module.definitions.flatMap { definition in
                definition.referencedTypes + definition.operations.flatMap(\.usedTypeScriptDataTypes)
            }
        }
    }

    private func allGeneratedDataTypes(from roots: [ApiTypeSchema]) -> [ApiTypeSchema] {
        var result: [ApiTypeSchema] = []
        var seen: Set<UUID> = []
        for dataType in roots {
            dataType.appendDeclaredTypeScriptDataTypes(to: &result, seen: &seen)
        }
        return result
    }

    private func unresolvedExternalTypeNames(in roots: [ApiTypeSchema]) -> [String] {
        var names: Set<String> = []
        var seen: Set<UUID> = []
        for dataType in roots {
            names.formUnion(dataType.externalTypeNames(options: options, seen: &seen))
        }
        return names.sorted()
    }

    private func validateGeneratedFilePaths(_ files: [TypeScriptGeneratedTextFile]) throws {
        var paths: Set<String> = []
        for file in files {
            let path = try file.validatedPathComponents().joined(separator: "/")
            guard paths.insert(path).inserted else {
                throw TypeScriptGeneratorError.invalidSourceDirectory(options.sourceDirectory)
            }
        }
        for path in paths {
            var components = path.split(separator: "/")
            while components.count > 1 {
                components.removeLast()
                guard !paths.contains(components.joined(separator: "/")) else {
                    throw TypeScriptGeneratorError.invalidSourceDirectory(options.sourceDirectory)
                }
            }
        }
    }

    private func removeStaleManagedTypeScriptSources(keeping relativePaths: Set<String>) throws {
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
            options: [.skipsHiddenFiles]
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
            guard contents.hasPrefix(TypeScriptGeneratedTextFile.managedHeader) else {
                continue
            }
            try FileManager.default.removeItem(at: fileURL)
        }
    }
}
