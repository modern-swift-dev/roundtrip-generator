import Foundation
import GeneratorBuilder
import GeneratorModels

// swiftlint:disable file_length
struct KotlinApiMocksEmitter {
    let package: ApiPackage
    let options: KotlinGeneratorOptions

    init(package: ApiPackage, options: KotlinGeneratorOptions = .init()) {
        self.package = package
        self.options = options
    }

    func write(url: URL) throws {
        let fileURL = url.appendingPathComponent("ApiModulesMocks.kt")
        try kotlinCode().toString().data(using: .utf8)?.write(to: fileURL, options: [.atomic])
    }

    func kotlinCode(packageName: String? = nil) -> any Node {
        let targetPackage = packageName ?? options.basePackage
        return KotlinFileEmitter.renderNode(
            packageName: targetPackage,
            imports: Array(imports(currentPackage: targetPackage)),
            body: declaration()
        )
    }

    private func declaration() -> any Node {
        let modules = package.referencedModules + package.modules
        let modulesWithDefinitions = modules.filter { !$0.definitions.isEmpty }
        return Block {
            modulesWithDefinitions.flatMap { module in
                module.definitions.map { mockDeclaration(module: module, definition: $0).toString() }
            }
            .joined(separator: "\n\n")
            NewLine()
            apiModulesMocksDeclaration(modules: modulesWithDefinitions)
        }
    }

    private func mockDeclaration(module: ApiModule, definition: ApiService) -> any Node {
        let methods = definition.operations.flatMap { operation in
            [callStorage(operation: operation), handlerStorage(operation: operation), mockMethod(operation: operation)]
        }
        let pagedMethods = definition.operations
            .filter { KotlinOperationEmitter(operation: $0, options: options).hasPagedResultsResponse }
            .flatMap { operation in
                [
                    nextPageCallStorage(operation: operation),
                    nextPageHandlerStorage(operation: operation),
                    nextPageMockMethod(operation: operation)
                ]
            }

        return Block {
            "class \(definition.kotlinApiTypeName(moduleName: module.name))Mock : \(definition.kotlinApiTypeName(moduleName: module.name)) {"
            Indentation {
                (methods + pagedMethods + [resetMockFunction(definition: definition)])
                    .map { $0.toString() }
                    .joined(separator: "\n\n")
            }
            "}"
        }
    }

    private func callStorage(operation: ApiOperation) -> any Node {
        if operation.request.mockRequiresProgress {
            return Block {
                "data class \(operation.kotlinOperationTypeName)Call("
                Indentation {
                    "val request: \(operation.kotlinOperationTypeName).Request,"
                    "val progress: ApiProgress?,"
                }
                ")"
                "val \(operation.kotlinMethodName)Calls = mutableListOf<\(operation.kotlinOperationTypeName)Call>()"
            }
        }
        return "val \(operation.kotlinMethodName)Calls = mutableListOf<\(operation.kotlinOperationTypeName).Request>()"
    }

    private func handlerStorage(operation: ApiOperation) -> any Node {
        if operation.request.mockRequiresProgress {
            return """
            var \(operation.kotlinMethodName)Handler: suspend (\(operation.kotlinOperationTypeName).Request, ApiProgress?) -> \(returnType(operation: operation)) = { _, _ ->
                error("No mock handler for \(operation.kotlinMethodName)")
            }
            """
        }
        return """
        var \(operation.kotlinMethodName)Handler: suspend (\(operation.kotlinOperationTypeName).Request) -> \(returnType(operation: operation)) = {
            error("No mock handler for \(operation.kotlinMethodName)")
        }
        """
    }

    private func mockMethod(operation: ApiOperation) -> any Node {
        let emitter = KotlinOperationEmitter(operation: operation, options: options)
        if operation.request.mockRequiresProgress {
            return """
            override \(emitter.serviceMethodDeclaration(includeProgressDefault: false)) {
                \(operation.kotlinMethodName)Calls += \(operation.kotlinOperationTypeName)Call(request, progress)
                return \(operation.kotlinMethodName)Handler(request, progress)
            }
            """
        }
        return """
        override \(emitter.serviceMethodDeclaration(includeProgressDefault: false)) {
            \(operation.kotlinMethodName)Calls += request
            return \(operation.kotlinMethodName)Handler(request)
        }
        """
    }

    private func nextPageCallStorage(operation: ApiOperation) -> any Node {
        """
        data class \(nextPageName(operation: operation).kotlinTypeName)Call(
            val currentPage: \(operation.response.dataType?.kotlinTypeDeclaration(options: options) ?? "Unit"),
            val request: \(operation.kotlinOperationTypeName).Request,
        )
        val \(nextPageName(operation: operation))Calls = mutableListOf<\(nextPageName(operation: operation).kotlinTypeName)Call>()
        """
    }

    private func nextPageHandlerStorage(operation: ApiOperation) -> any Node {
        """
        var \(nextPageName(operation: operation))Handler: suspend (
            \(operation.response.dataType?.kotlinTypeDeclaration(options: options) ?? "Unit"),
            \(operation.kotlinOperationTypeName).Request,
        ) -> \(returnType(operation: operation)) = { _, _ ->
            error("No mock handler for getNextPage")
        }
        """
    }

    private func nextPageMockMethod(operation: ApiOperation) -> any Node {
        let emitter = KotlinOperationEmitter(operation: operation, options: options)
        return """
        override \(emitter.nextPageMethodDeclaration()) {
            \(nextPageName(operation: operation))Calls += \(nextPageName(operation: operation).kotlinTypeName)Call(currentPage, request)
            return \(nextPageName(operation: operation))Handler(currentPage, request)
        }
        """
    }

    private func resetMockFunction(definition: ApiService) -> any Node {
        let resets = definition.operations.flatMap { operation in
            [
                "\(operation.kotlinMethodName)Calls.clear()",
                "\(operation.kotlinMethodName)Handler = \(resetHandler(operation: operation))"
            ] + (
                KotlinOperationEmitter(operation: operation, options: options).hasPagedResultsResponse
                    ? [
                        "\(nextPageName(operation: operation))Calls.clear()",
                        "\(nextPageName(operation: operation))Handler = { _, _ -> error(\"No mock handler for getNextPage\") }"
                    ]
                    : []
            )
        }
        return Block {
            "fun resetMock() {"
            Indentation {
                NodeList(resets)
            }
            "}"
        }
    }

    private func resetHandler(operation: ApiOperation) -> String {
        if operation.request.mockRequiresProgress {
            return "{ _, _ -> error(\"No mock handler for \(operation.kotlinMethodName)\") }"
        }
        return "{ error(\"No mock handler for \(operation.kotlinMethodName)\") }"
    }

    private func apiModulesMocksDeclaration(modules: [ApiModule]) -> any Node {
        let apiProperties = modules.flatMap { module in
            module.definitions.map { definition in
                "lateinit var \(mockPropertyName(module: module, definition: definition)): \(definition.kotlinApiTypeName(moduleName: module.name))Mock"
            }
        }
        let moduleProperties = modules.map { "lateinit var \($0.kotlinModulePropertyName): \($0.kotlinApiModuleTypeName)" }
        let apiSetups = modules.flatMap { module in
            module.definitions.map { definition in
                "\(mockPropertyName(module: module, definition: definition)) = \(definition.kotlinApiTypeName(moduleName: module.name))Mock()"
            }
        }
        let moduleSetups = modules.map { module in
            let args = module.definitions
                .map { "\($0.kotlinApiPropertyName) = \(mockPropertyName(module: module, definition: $0))" }
                .joined(separator: ", ")
            return "\(module.kotlinModulePropertyName) = \(module.kotlinApiModuleTypeName)(\(args))"
        }
        let apiModulesArgs = modules
            .map { "\($0.kotlinModulePropertyName) = \($0.kotlinModulePropertyName)" }
            .joined(separator: ", ")
        let apiResets = modules.flatMap { module in
            module.definitions.map { "\(mockPropertyName(module: module, definition: $0)).resetMock()" }
        }

        return Block {
            "class ApiModulesMocks {"
            Indentation {
                NodeList(apiProperties)
                NodeList(moduleProperties)
                if package.generateApiModules {
                    "lateinit var apiModules: ApiModules"
                }
                NewLine()
                "fun setUp() {"
                Indentation {
                    NodeList(apiSetups)
                    NodeList(moduleSetups)
                    if package.generateApiModules {
                        "apiModules = ApiModules(\(apiModulesArgs))"
                    }
                }
                "}"
                NewLine()
                "fun tearDown() {"
                Indentation {
                    NodeList(apiResets)
                }
                "}"
            }
            "}"
        }
    }

    private func returnType(operation: ApiOperation) -> String {
        guard let dataType = operation.response.dataType else {
            return "ApiResponse"
        }
        return "ApiOperationResult<\(dataType.kotlinTypeDeclaration(options: options))>"
    }

    private func nextPageName(operation: ApiOperation) -> String {
        "getNextPageFor\(operation.kotlinOperationTypeName)".kotlinPropertyName
    }

    private func mockPropertyName(module: ApiModule, definition: ApiService) -> String {
        "\(module.name)\(definition.name)Api".kotlinPropertyName
    }

    private func imports(currentPackage: String) -> Set<String> {
        var imports: Set<String> = []
        let modules = package.referencedModules + package.modules
        if package.generateApiModules, options.basePackage != currentPackage {
            imports.insert("\(options.basePackage).ApiModules")
        }
        for module in modules where !module.definitions.isEmpty {
            if options.basePackage != currentPackage {
                imports.insert("\(options.basePackage).\(module.kotlinApiModuleTypeName)")
            }
            for definition in module.definitions {
                let definitionPackage = packageName(module: module, definition: definition)
                imports.insert("\(definitionPackage).\(definition.kotlinApiTypeName(moduleName: module.name))")
                for operation in definition.operations {
                    imports.insert("\(definitionPackage).\(operation.kotlinOperationTypeName)")
                    if operation.request.mockRequiresProgress {
                        imports.formUnion(runtimeImports(["ApiProgress"], currentPackage: currentPackage))
                    }
                    imports.formUnion(runtimeImports(["ApiOperationResult", "ApiResponse"], currentPackage: currentPackage))
                    if let responseType = operation.response.dataType {
                        imports.formUnion(responseType.kotlinTypeImports(options: options))
                        imports.formUnion(typeImports(for: responseType, currentPackage: currentPackage, module: module, definition: definition))
                    }
                }
            }
        }
        return imports
    }

    private func runtimeImports(_ names: [String], currentPackage: String) -> Set<String> {
        guard currentPackage != options.basePackage else {
            return []
        }
        return Set(names.map { "\(options.basePackage).\($0)" })
    }

    private func typeImports(
        for dataType: ApiTypeSchema,
        currentPackage: String,
        module: ApiModule,
        definition: ApiService
    ) -> Set<String> {
        switch dataType {
            case let .array(type),
                 let .keyedByString(type, _):
                return typeImports(for: type, currentPackage: currentPackage, module: module, definition: definition)
            case let .genericReference(typeName, types):
                var imports = types
                    .map { typeImports(for: $0, currentPackage: currentPackage, module: module, definition: definition) }
                    .reduce(Set<String>()) { $0.union($1) }
                if options.mapping(for: typeName) == nil {
                    imports.formUnion(modelTypeImport(typeName: typeName, currentPackage: currentPackage, module: module, definition: definition))
                }
                return imports
            case let .reference(typeName, _, imports, _, dataType):
                var localImports = Set(imports.map(\.name))
                if options.mapping(for: typeName) == nil {
                    localImports.formUnion(modelTypeImport(typeName: typeName, currentPackage: currentPackage, module: module, definition: definition))
                }
                if let dataType {
                    localImports.formUnion(typeImports(for: dataType, currentPackage: currentPackage, module: module, definition: definition))
                }
                return localImports
            default:
                return []
        }
    }

    private func modelTypeImport(
        typeName: String,
        currentPackage: String,
        module: ApiModule,
        definition: ApiService
    ) -> Set<String> {
        let modelPackage = "\(packageName(module: module, definition: definition)).models"
        let resolvedModelPackage = packageName(forModelTypeName: typeName, module: module, definition: definition) ?? modelPackage
        guard resolvedModelPackage != currentPackage else {
            return []
        }
        return ["\(resolvedModelPackage).\(typeName.kotlinTypeName)"]
    }

    private func packageName(module: ApiModule, definition: ApiService? = nil) -> String {
        var segments = [options.basePackage, module.name.kotlinPackageSegment]
        if let definition {
            segments.append(definition.name.kotlinPackageSegment)
        }
        return segments.joined(separator: ".")
    }

    private func packageName(forModelTypeName typeName: String, module currentModule: ApiModule, definition currentDefinition: ApiService) -> String? {
        for dataType in currentDefinition.referencedTypes where dataType.typeName == typeName {
            return "\(packageName(module: currentModule, definition: currentDefinition)).models"
        }
        for dataType in currentModule.references where dataType.typeName == typeName {
            return packageName(module: currentModule)
        }
        for module in package.referencedModules + package.modules {
            if module.name == currentModule.name {
                continue
            }
            for dataType in module.references where dataType.typeName == typeName {
                return packageName(module: module)
            }
            for definition in module.definitions {
                for dataType in definition.referencedTypes where dataType.typeName == typeName {
                    return "\(packageName(module: module, definition: definition)).models"
                }
            }
        }
        for dataType in package.commonReferences + package.references where dataType.typeName == typeName {
            return options.basePackage
        }

        return nil
    }
}

private extension ApiRequestBody {
    var mockRequiresProgress: Bool {
        switch self {
            case .file,
                 .multiPart:
                true
            default:
                false
        }
    }
}
