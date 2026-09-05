import Foundation
import GeneratorBuilder
import GeneratorModels

public enum KotlinAndroidGeneratorError: Error, LocalizedError, Equatable {
    case invalidBasePackage(String)
    case invalidModuleName(String)
    case invalidPackage(reason: String)
    case unresolvedExternalType(String)
    case emptyAcceptableStatuses(operationName: String)
    case invalidAcceptableStatus(operationName: String, statusCode: Int)
    case invalidOperation(operationName: String, reason: String)
    case typedResponseWithBodylessStatus(operationName: String, statusCode: Int)

    public var errorDescription: String? {
        switch self {
            case let .invalidBasePackage(value):
                "Invalid KotlinAndroid base package: \(value)"
            case let .invalidModuleName(value):
                "Invalid Gradle module name: \(value)"
            case let .invalidPackage(reason):
                "Invalid KotlinAndroid package: \(reason)"
            case let .unresolvedExternalType(value):
                "Missing KotlinAndroid type mapping for external type: \(value)"
            case let .emptyAcceptableStatuses(operationName):
                "KotlinAndroid operation \(operationName) must accept at least one HTTP status"
            case let .invalidAcceptableStatus(operationName, statusCode):
                "KotlinAndroid operation \(operationName) has invalid HTTP status \(statusCode)"
            case let .invalidOperation(operationName, reason):
                "KotlinAndroid operation \(operationName) \(reason)"
            case let .typedResponseWithBodylessStatus(operationName, statusCode):
                "KotlinAndroid operation \(operationName) has a typed response but accepts bodyless HTTP status \(statusCode)"
        }
    }
}

public struct KotlinAndroidApiPackageGenerator {
    public let package: ApiPackage
    public let options: KotlinAndroidGeneratorOptions

    /// The package and options are immutable; build lookup tables once, not per reference.
    private var declaredTypePackagesByID: [UUID: String] = [:]

    public init(package: ApiPackage, options: KotlinAndroidGeneratorOptions = .init()) {
        self.package = package
        self.options = options
        declaredTypePackagesByID = makeDeclaredTypePackagesByID()
    }

    public func write() throws {
        let files = try generatedFiles()
        for file in files {
            try file.write(to: package.targetDirUrl.resolvingSymlinksInPath().standardizedFileURL, overwritePolicy: options.gradle.overwritePolicy)
        }
        if options.gradle.overwritePolicy == .replaceManagedFiles {
            try removeStaleManagedKotlinAndroidSources(keeping: Set(files.map(\.relativePath)))
        }
    }

    public func generatedFiles() throws -> [KotlinAndroidGeneratedTextFile] {
        try validate()
        let sourceBasePath = sourcePath(packageName: options.basePackage)
        var files = options.layout == .standaloneProject ? gradleFiles() : []
        var generatedModelIDs: Set<UUID> = []
        let excludedNestedTypeIDs = topLevelModelTypeIDs
        let suppliedTypeIDs = Set((package.commonReferences + package.referencedModules.flatMap(\.allKotlinAndroidDataTypes)).compactMap(\.declaredKotlinAndroidTypeID))

        func appendModelFile(sourceBasePath: String, packageName: String, dataType: ApiTypeSchema) {
            if let uuid = dataType.declaredKotlinAndroidTypeID,
               suppliedTypeIDs.contains(uuid) || generatedModelIDs.contains(uuid) {
                return
            }
            guard let file = modelFile(
                sourceBasePath: sourceBasePath,
                packageName: packageName,
                dataType: dataType,
                excludedNestedTypeIDs: excludedNestedTypeIDs,
            ) else {
                return
            }
            if let uuid = dataType.declaredKotlinAndroidTypeID {
                generatedModelIDs.insert(uuid)
            }
            files.append(file)
        }

        if options.generateRuntime {
            files.append(sourceFile(sourceBasePath: sourceBasePath, name: "ApiRuntime.kt", node: KotlinAndroidRuntimeEmitter().kotlinCode(packageName: options.basePackage)))
        }

        let aggregateModules = package.referencedModules + package.modules
        let modulesWithDefinitions = aggregateModules.filter { !$0.definitions.isEmpty }
        if package.generateApiModules, !modulesWithDefinitions.isEmpty {
            let aggregate = KotlinAndroidApiAggregateServiceEmitter(modules: modulesWithDefinitions)
            files.append(sourceFile(
                sourceBasePath: sourceBasePath,
                name: "ApiModules.kt",
                node: aggregate.kotlinCode(packageName: options.basePackage, imports: aggregateImports(modulesWithDefinitions)),
            ))
        }

        if options.generateKoinModule {
            files.append(sourceFile(
                sourceBasePath: sourceBasePath,
                name: "ApiKoinModule.kt",
                node: KotlinAndroidKoinEmitter(package: package, options: options).kotlinCode(packageName: options.basePackage, imports: koinImports(modulesWithDefinitions)),
            ))
        }

        for dataType in package.references {
            appendModelFile(sourceBasePath: sourceBasePath, packageName: options.basePackage, dataType: dataType)
        }

        for module in package.modules {
            let modulePackage = packageName(module: module)
            for dataType in module.references {
                appendModelFile(sourceBasePath: sourcePath(packageName: "\(modulePackage).shared"), packageName: "\(modulePackage).shared", dataType: dataType)
            }

            for definition in module.definitions {
                let definitionPackage = packageName(module: module, definition: definition)
                let definitionPath = sourcePath(packageName: definitionPackage)
                let modelPackage = "\(definitionPackage).models"
                for dataType in definition.referencedTypes + definition.operationDeclaredTypes {
                    appendModelFile(sourceBasePath: sourcePath(packageName: modelPackage), packageName: modelPackage, dataType: dataType)
                }

                let service = KotlinAndroidApiServiceEmitter(definition: definition, moduleName: module.name, options: options)
                files.append(sourceFile(
                    sourceBasePath: definitionPath,
                    name: "\(definition.kotlinApiTypeName(moduleName: module.name)).kt",
                    node: service.kotlinCode(packageName: definitionPackage, imports: serviceImports(module: module, definition: definition)),
                ))

                for operation in definition.operations {
                    let emitter = KotlinAndroidOperationEmitter(operation: operation, options: options)
                    files.append(sourceFile(
                        sourceBasePath: definitionPath,
                        name: "\(operation.kotlinOperationTypeName).kt",
                        node: emitter.kotlinCode(packageName: definitionPackage, imports: operationImports(operation, currentPackage: definitionPackage)),
                    ))
                }
            }
        }

        if options.generateMocks {
            files.append(sourceFile(
                sourceBasePath: sourcePath(packageName: "\(options.basePackage).testing"),
                name: "ApiModulesMocks.kt",
                node: KotlinAndroidApiMocksEmitter(package: package, options: options, declaredTypePackages: declaredTypePackagesByID).kotlinCode(packageName: "\(options.basePackage).testing"),
            ))
        }
        try validateGeneratedFilePaths(files)
        return files
    }

    private func validate() throws {
        guard options.basePackage.isValidKotlinAndroidPackage else {
            throw KotlinAndroidGeneratorError.invalidBasePackage(options.basePackage)
        }
        if options.layout == .standaloneProject, let namespace = options.gradle.namespace, !namespace.isValidKotlinAndroidPackage {
            throw KotlinAndroidGeneratorError.invalidPackage(reason: "has invalid Android namespace: \(namespace)")
        }
        guard options.layout == .existingProject || options.gradle.moduleName.isValidGradleModuleName else {
            throw KotlinAndroidGeneratorError.invalidModuleName(options.gradle.moduleName)
        }
        try validateGeneratedNames()
        try validateGeneratedDataTypes()
        for typeName in unresolvedExternalTypeNames() {
            throw KotlinAndroidGeneratorError.unresolvedExternalType(typeName)
        }
        for operation in allOperations() {
            try validate(operation: operation)
            guard !operation.acceptableStatuses.isEmpty else {
                throw KotlinAndroidGeneratorError.emptyAcceptableStatuses(operationName: operation.name)
            }
            if let statusCode = operation.acceptableStatuses.first(where: { !(100 ... 599).contains($0) }) {
                throw KotlinAndroidGeneratorError.invalidAcceptableStatus(operationName: operation.name, statusCode: statusCode)
            }
            if case .json(nil) = operation.response {
                throw KotlinAndroidGeneratorError.invalidOperation(
                    operationName: operation.name,
                    reason: "has a typed response without a data type",
                )
            }
            if operation.response.dataType != nil,
               let statusCode = operation.acceptableStatuses.first(where: \.isHttpBodylessStatus) {
                throw KotlinAndroidGeneratorError.typedResponseWithBodylessStatus(operationName: operation.name, statusCode: statusCode)
            }
        }
    }

    private func validateGeneratedNames() throws {
        let aggregateModules = package.referencedModules + package.modules
        try validateUnique(
            aggregateModules.map(\.kotlinApiModuleTypeName),
            reason: "has duplicate module type names",
        )
        try validateUnique(
            aggregateModules.map(\.kotlinModulePropertyName),
            reason: "has duplicate module property names",
        )
        try validateUnique(
            aggregateModules.map { packageName(module: $0) },
            reason: "has duplicate module package names",
        )

        for module in aggregateModules {
            try validateUnique(
                module.definitions.map { $0.kotlinApiTypeName(moduleName: module.name) },
                reason: "module \(module.name) has duplicate API type names",
            )
            try validateUnique(
                module.definitions.map(\.kotlinApiPropertyName),
                reason: "module \(module.name) has duplicate API property names",
            )
            try validateUnique(
                module.definitions.map { packageName(module: module, definition: $0) },
                reason: "module \(module.name) has duplicate definition package names",
            )
        }

        for module in package.modules {
            for definition in module.definitions {
                try validateUnique(
                    definition.operations.map(\.kotlinOperationTypeName),
                    reason: "definition \(definition.name) has duplicate operation type names",
                )
                try validateUnique(
                    definition.operations.map(\.kotlinMethodName),
                    reason: "definition \(definition.name) has duplicate operation method names",
                )
            }
        }
    }

    private func validateGeneratedDataTypes() throws {
        var visitedTypeIDs: Set<UUID> = []
        let packageReferences = package.commonReferences + package.references
        guard packageReferences.allSatisfy(\.isKotlinAndroidReferenceable) else {
            let invalidTypes = packageReferences.filter { !$0.isKotlinAndroidReferenceable }.compactMap(\.typeName)
            throw KotlinAndroidGeneratorError.invalidPackage(reason: "package references are not all referenceable: \(invalidTypes)")
        }
        for module in package.modules {
            guard module.references.allSatisfy(\.isKotlinAndroidReferenceable) else {
                let invalidTypes = module.references.filter { !$0.isKotlinAndroidReferenceable }.compactMap(\.typeName)
                throw KotlinAndroidGeneratorError.invalidPackage(
                    reason: "module \(module.name) references are not all referenceable: \(invalidTypes)",
                )
            }
            for definition in module.definitions {
                guard definition.referencedTypes.allSatisfy(\.isKotlinAndroidReferenceable) else {
                    let invalidTypes = definition.referencedTypes.filter { !$0.isKotlinAndroidReferenceable }.compactMap(\.typeName)
                    throw KotlinAndroidGeneratorError.invalidPackage(
                        reason: "definition \(definition.name) references are not all referenceable: \(invalidTypes)",
                    )
                }
            }
        }
        for dataType in packageReferences + package.modules.flatMap(\.allKotlinAndroidDataTypes) {
            try validateGeneratedDataType(dataType, visitedTypeIDs: &visitedTypeIDs)
        }
    }

    private func validateGeneratedDataType(_ dataType: ApiTypeSchema, visitedTypeIDs: inout Set<UUID>) throws {
        if let typeName = dataType.typeName,
           options.mapping(for: typeName) != nil {
            return
        }
        if let uuid = dataType.declaredKotlinAndroidTypeID,
           !visitedTypeIDs.insert(uuid).inserted {
            return
        }

        switch dataType {
            case let .object(typeName, properties, _, _, _, _):
                let fields = properties.filter(\.publishedAsField)
                try validateUnique(
                    properties.map(\.propertyName.kotlinPropertyName),
                    reason: "model \(typeName) has duplicate property names",
                )
                try validateUnique(
                    properties.map(\.rawName),
                    reason: "model \(typeName) has duplicate raw property names",
                )
                try fields.forEach { try validateGeneratedDataType($0.dataType, visitedTypeIDs: &visitedTypeIDs) }

            case let .stringEnum(typeName, values, _, _, supportGarbage):
                let caseNames = values.map(\.name.kotlinEnumCaseName) + (supportGarbage ? ["Garbage"] : [])
                try validateUnique(caseNames, reason: "enum \(typeName) has duplicate case names")
                let rawValues = values.map(\.rawName) + (supportGarbage ? ["__garbage__"] : [])
                try validateUnique(rawValues, reason: "enum \(typeName) has duplicate raw values")

            case let .intEnum(typeName, values, _, _):
                let caseNames = values.map { value in
                    if let name = value.name, !name.isEmpty {
                        return name.kotlinEnumCaseName
                    }
                    return value.rawValue.description.kotlinEnumCaseName
                }
                try validateUnique(caseNames, reason: "enum \(typeName) has duplicate case names")
                try validateUnique(values.map(\.rawValue), reason: "enum \(typeName) has duplicate raw values")

            case let .double(value):
                guard value?.isFinite != false else {
                    throw KotlinAndroidGeneratorError.invalidPackage(reason: "double initial value must be finite")
                }

            case let .dynamicObject(typeName, objectTypePropertyName, objectDataPropertyName, alternateObjectDataPropertyName, objectTypes, supportGarbage, _, _, extraProperties):
                let typeNames = objectTypes.map(\.objectTypeName.kotlinTypeName) + (supportGarbage ? ["Garbage"] : [])
                try validateUnique(typeNames, reason: "dynamic object \(typeName) has duplicate subtype names")
                let rawTypeNames = objectTypes.map(\.objectTypeRawName) + (supportGarbage ? ["__garbage__"] : [])
                try validateUnique(rawTypeNames, reason: "dynamic object \(typeName) has duplicate subtype raw names")
                let extraFields = extraProperties
                let payloadFields = ["payload"] + extraProperties.map(\.propertyName.kotlinPropertyName)
                try validateUnique(payloadFields, reason: "dynamic object \(typeName) has duplicate payload property names")
                let reservedRawNames = [objectTypePropertyName, objectDataPropertyName, alternateObjectDataPropertyName]
                try validateUnique(reservedRawNames, reason: "dynamic object \(typeName) has duplicate reserved raw property names")
                let extraRawNames = extraProperties.map(\.rawName)
                try validateUnique(extraRawNames, reason: "dynamic object \(typeName) has duplicate extra raw property names")
                let reservedExtraRawNames = Set(extraRawNames).intersection(reservedRawNames)
                guard reservedExtraRawNames.isEmpty else {
                    throw KotlinAndroidGeneratorError.invalidPackage(
                        reason: "dynamic object \(typeName) has extra raw property names that collide with reserved names: \(reservedExtraRawNames.sorted())",
                    )
                }
                let reservedPropertyNames = Set(reservedRawNames.map(\.kotlinPropertyName))
                let reservedExtraPropertyNames = Set(extraProperties.map(\.propertyName.kotlinPropertyName)).intersection(reservedPropertyNames)
                guard reservedExtraPropertyNames.isEmpty else {
                    throw KotlinAndroidGeneratorError.invalidPackage(
                        reason: "dynamic object \(typeName) has extra property names that collide with reserved names: \(reservedExtraPropertyNames.sorted())",
                    )
                }
                if objectDataPropertyName == "__self__" {
                    let reservedNames = Set([objectTypePropertyName] + extraRawNames)
                    for objectType in objectTypes {
                        let rawNames = objectRawNames(in: objectType.objectType)
                        let collisions = Set(rawNames).intersection(reservedNames)
                        guard collisions.isEmpty else {
                            throw KotlinAndroidGeneratorError.invalidPackage(
                                reason: "dynamic object \(typeName) has self-encoded property names that collide with reserved names: \(collisions.sorted())",
                            )
                        }
                    }
                }
                try objectTypes.forEach { try validateGeneratedDataType($0.objectType, visitedTypeIDs: &visitedTypeIDs) }
                try extraFields.forEach { try validateGeneratedDataType($0.dataType, visitedTypeIDs: &visitedTypeIDs) }

            case let .array(type),
                 let .keyedByString(type, _):
                try validateGeneratedDataType(type, visitedTypeIDs: &visitedTypeIDs)

            case let .genericReference(_, types):
                try types.forEach { try validateGeneratedDataType($0, visitedTypeIDs: &visitedTypeIDs) }

            case let .reference(_, _, _, _, dataType):
                if let dataType {
                    try validateGeneratedDataType(dataType, visitedTypeIDs: &visitedTypeIDs)
                }

            default:
                break
        }
    }

    private func validateGeneratedFilePaths(_ files: [KotlinAndroidGeneratedTextFile]) throws {
        try validateUnique(files.map(\.relativePath), reason: "has duplicate generated file paths")
    }

    private func objectRawNames(in dataType: ApiTypeSchema) -> [String] {
        switch dataType {
            case let .object(_, properties, _, _, _, _):
                properties.map(\.rawName)
            case let .reference(_, _, _, _, dataType):
                dataType.map(objectRawNames(in:)) ?? []
            default:
                []
        }
    }

    private func validateUnique(_ values: [some Comparable & Hashable], reason: String) throws {
        let duplicates = duplicateValues(values)
        guard duplicates.isEmpty else {
            throw KotlinAndroidGeneratorError.invalidPackage(reason: "\(reason): \(duplicates.sorted())")
        }
    }

    private func duplicateValues<T: Hashable>(_ values: [T]) -> Set<T> {
        var seen: Set<T> = []
        var duplicates: Set<T> = []
        for value in values {
            guard seen.insert(value).inserted else {
                duplicates.insert(value)
                continue
            }
        }
        return duplicates
    }

    private func validate(operation: ApiOperation) throws {
        let parameters = operation.expandedParameters
        let propertyNames = parameters.map(\.propertyName.kotlinPropertyName)
        guard Set(propertyNames).count == propertyNames.count else {
            throw invalidOperation(operation, "has duplicate parameter property names")
        }

        let wireNames = parameters.map { parameter in
            let wireName = parameter.location == .header
                ? parameter.rawName.lowercased()
                : parameter.rawName
            return "\(parameter.location.rawValue):\(wireName)"
        }
        guard Set(wireNames).count == wireNames.count else {
            throw invalidOperation(operation, "has duplicate parameter wire names")
        }

        let generatedNameCollisions = Set(propertyNames).intersection(kotlinGeneratedRequestMemberNames(operation: operation))
        guard generatedNameCollisions.isEmpty else {
            throw invalidOperation(
                operation,
                "has parameter names that collide with generated request members: \(generatedNameCollisions.sorted())",
            )
        }

        if parameters.contains(where: { $0.location == .cookie }),
           parameters.contains(where: { $0.location == .header && $0.rawName.caseInsensitiveCompare("Cookie") == .orderedSame }) {
            throw invalidOperation(operation, "cannot combine Cookie header parameters with cookie parameters")
        }

        try parameters.forEach { try validate(parameter: $0, operation: operation) }
        try validateMultipartParts(operation)
        try validatePath(operation: operation, parameters: parameters)
    }

    private func validate(parameter: ApiParameter, operation: ApiOperation) throws {
        switch parameter.dataType {
            case let .stringEnumArray(type, _):
                if parameter.location == .path {
                    throw invalidOperation(operation, "has enum array path parameter")
                }
                guard validateStringEnum(type: type) else {
                    throw invalidOperation(operation, "has invalid enum parameter type")
                }
            case let .stringEnumValue(type, _):
                guard validateStringEnum(type: type) else {
                    throw invalidOperation(operation, "has invalid enum parameter type")
                }
            case let .intEnumArray(type, _):
                if parameter.location == .path {
                    throw invalidOperation(operation, "has enum array path parameter")
                }
                guard validateIntEnum(type: type) else {
                    throw invalidOperation(operation, "has invalid enum parameter type")
                }
            case let .intEnumValue(type, _):
                guard validateIntEnum(type: type) else {
                    throw invalidOperation(operation, "has invalid enum parameter type")
                }
            default:
                break
        }

        guard validateEnumDefault(parameter.dataType) else {
            throw invalidOperation(operation, "has invalid enum parameter default")
        }
    }

    private func validateStringEnum(type: ApiTypeSchema) -> Bool {
        switch type {
            case .stringEnum:
                true
            case let .reference(typeName, _, _, _, dataType):
                options.mapping(for: typeName) != nil || (dataType.map(validateStringEnum(type:)) ?? true)
            default:
                false
        }
    }

    private func validateIntEnum(type: ApiTypeSchema) -> Bool {
        switch type {
            case .intEnum:
                true
            case let .reference(typeName, _, _, _, dataType):
                options.mapping(for: typeName) != nil || (dataType.map(validateIntEnum(type:)) ?? true)
            default:
                false
        }
    }

    private func validateEnumDefault(_ dataType: ApiParameter.DataType) -> Bool {
        switch dataType {
            case let .stringEnumValue(type, value):
                guard let value else {
                    return true
                }
                if hasMappedType(type) {
                    return true
                }
                return stringEnumRawNames(type: type)?.contains(value) ?? false
            case let .stringEnumArray(type, values):
                guard let values else {
                    return true
                }
                if hasMappedType(type) {
                    return true
                }
                guard let rawNames = stringEnumRawNames(type: type) else {
                    return false
                }
                return values.allSatisfy(rawNames.contains)
            case let .intEnumValue(type, value):
                guard let value else {
                    return true
                }
                if hasMappedType(type) {
                    return true
                }
                return intEnumRawValues(type: type)?.contains(value) ?? false
            case let .intEnumArray(type, values):
                guard let values else {
                    return true
                }
                if hasMappedType(type) {
                    return true
                }
                guard let rawValues = intEnumRawValues(type: type) else {
                    return false
                }
                return values.allSatisfy(rawValues.contains)
            default:
                return true
        }
    }

    private func hasMappedType(_ dataType: ApiTypeSchema) -> Bool {
        switch dataType {
            case let .reference(typeName, _, _, _, dataType):
                options.mapping(for: typeName) != nil || dataType.map(hasMappedType) == true
            default:
                dataType.typeName.map { options.mapping(for: $0) != nil } ?? false
        }
    }

    private func stringEnumRawNames(type: ApiTypeSchema) -> Set<String>? {
        switch type {
            case let .stringEnum(_, values, _, _, _):
                Set(values.map(\.rawName))
            case let .reference(_, _, _, _, dataType):
                dataType.flatMap { stringEnumRawNames(type: $0) }
            default:
                nil
        }
    }

    private func intEnumRawValues(type: ApiTypeSchema) -> Set<Int>? {
        switch type {
            case let .intEnum(_, values, _, _):
                Set(values.map(\.rawValue))
            case let .reference(_, _, _, _, dataType):
                dataType.flatMap { intEnumRawValues(type: $0) }
            default:
                nil
        }
    }

    private func validateMultipartParts(_ operation: ApiOperation) throws {
        guard case let .multiPart(parts) = operation.request else {
            return
        }
        guard !parts.isEmpty else {
            throw invalidOperation(operation, "has no multipart part names")
        }
        guard !parts.contains(where: \.isEmpty) else {
            throw invalidOperation(operation, "has empty multipart part names")
        }
        let setterNames = parts.map { "with\($0.capitalCased)" }
        guard Set(setterNames).count == setterNames.count else {
            throw invalidOperation(operation, "has multipart part names that generate duplicate setters")
        }
    }

    private func kotlinGeneratedRequestMemberNames(operation: ApiOperation) -> Set<String> {
        var names: Set = [
            "headers",
            "queryParameters",
            "requestPath",
            "toApiRequest",
            "request",
            "adaptedRequest",
            "client"
        ]
        if requestRequiresProgress(operation.request) {
            names.insert("progress")
        }
        if KotlinAndroidOperationEmitter(operation: operation, options: options).hasPagedResultsResponse {
            names.insert("currentPage")
        }
        if operation.path.isRuntime {
            names.insert("requestUrl")
        }
        if operation.request.hasKotlinAndroidBody {
            names.insert("body")
        }
        if case let .multiPart(parts) = operation.request {
            names.formUnion(parts.map { "with\($0.capitalCased)" })
        }
        return names
    }

    private func validatePath(operation: ApiOperation, parameters: [ApiParameter]) throws {
        switch operation.path {
            case let .relative(path):
                try validatePathPlaceholders(
                    path: path,
                    operation: operation,
                    parameters: parameters,
                    allowedRange: pathComponentRange(inRelativePath: path),
                )
                let replacedPath = pathReplacingParameters(path: path, parameters: parameters)
                let effectivePath = replacedPath.starts(with: "/") ? replacedPath : "/\(replacedPath)"
                guard URL(string: "https://localhost.com\(effectivePath)") != nil else {
                    throw invalidOperation(operation, "has invalid relative url: \(path)")
                }
            case let .absolute(path):
                try validatePathPlaceholders(
                    path: path,
                    operation: operation,
                    parameters: parameters,
                    allowedRange: pathComponentRange(inAbsolutePath: path),
                )
                let replacedPath = pathReplacingParameters(path: path, parameters: parameters)
                guard let url = URL(string: replacedPath),
                      url.scheme?.isEmpty == false,
                      url.host?.isEmpty == false else {
                    throw invalidOperation(operation, "has invalid absolute url: \(path)")
                }
            case .runtime:
                guard parameters.allSatisfy({ $0.location != .path }) else {
                    throw invalidOperation(operation, "uses runtime url with path parameters")
                }
        }
    }

    private func pathReplacingParameters(path: String, parameters: [ApiParameter]) -> String {
        parameters.filter { $0.location == .path }.reduce(path) { partialPath, parameter in
            partialPath.replacingOccurrences(of: "{\(parameter.rawName)}", with: "value")
        }
    }

    private func validatePathPlaceholders(
        path: String,
        operation: ApiOperation,
        parameters: [ApiParameter],
        allowedRange: Range<String.Index>,
    ) throws {
        let placeholders = try pathPlaceholders(in: path, operation: operation)
        guard placeholders.allSatisfy({
            allowedRange.lowerBound <= $0.range.lowerBound && $0.range.upperBound <= allowedRange.upperBound
        }) else {
            throw invalidOperation(operation, "has path parameters that do not match url placeholders")
        }
        let pathParameters = parameters.filter { $0.location == .path }
        guard pathParameters.allSatisfy(\.isRequired) else {
            throw invalidOperation(operation, "has optional path parameters")
        }

        let pathParameterNames = pathParameters.map(\.rawName)
        let placeholderNames = placeholders.map(\.name)
        guard Set(placeholderNames) == Set(pathParameterNames),
              placeholderNames.count == Set(placeholderNames).count,
              pathParameterNames.count == Set(pathParameterNames).count else {
            throw invalidOperation(operation, "has path parameters that do not match url placeholders")
        }
    }

    private func pathPlaceholders(in path: String, operation: ApiOperation) throws -> [(name: String, range: Range<String.Index>)] {
        var placeholders: [(name: String, range: Range<String.Index>)] = []
        var current: String?
        var startIndex: String.Index?

        for index in path.indices {
            let character = path[index]
            if character == "{" {
                guard current == nil else {
                    throw invalidOperation(operation, "has malformed path placeholders")
                }
                current = ""
                startIndex = index
            } else if character == "}" {
                guard let value = current, !value.isEmpty, let placeholderStartIndex = startIndex else {
                    throw invalidOperation(operation, "has malformed path placeholders")
                }
                placeholders.append((value, placeholderStartIndex ..< path.index(after: index)))
                current = nil
                startIndex = nil
            } else if current != nil {
                current?.append(character)
            }
        }

        if current != nil {
            throw invalidOperation(operation, "has malformed path placeholders")
        }

        return placeholders
    }

    private func pathComponentRange(inRelativePath path: String) -> Range<String.Index> {
        path.startIndex ..< firstPathBoundary(in: path, from: path.startIndex)
    }

    private func pathComponentRange(inAbsolutePath path: String) -> Range<String.Index> {
        guard let schemeRange = path.range(of: "://") else {
            return path.startIndex ..< path.startIndex
        }
        let authorityStart = schemeRange.upperBound
        let delimiters: [(index: String.Index, startsPath: Bool)] = [
            path[authorityStart...].firstIndex(of: "/").map { (index: $0, startsPath: true) },
            path[authorityStart...].firstIndex(of: "?").map { (index: $0, startsPath: false) },
            path[authorityStart...].firstIndex(of: "#").map { (index: $0, startsPath: false) }
        ]
        .compactMap(\.self)
        .sorted { $0.index < $1.index }

        guard let firstDelimiter = delimiters.first else {
            return path.endIndex ..< path.endIndex
        }
        guard firstDelimiter.startsPath else {
            return firstDelimiter.index ..< firstDelimiter.index
        }
        return firstDelimiter.index ..< firstPathBoundary(in: path, from: firstDelimiter.index)
    }

    private func firstPathBoundary(in path: String, from start: String.Index) -> String.Index {
        [path[start...].firstIndex(of: "?"), path[start...].firstIndex(of: "#")]
            .compactMap(\.self)
            .min() ?? path.endIndex
    }

    private func invalidOperation(_ operation: ApiOperation, _ reason: String) -> KotlinAndroidGeneratorError {
        .invalidOperation(operationName: operation.name, reason: reason)
    }

    private func gradleFiles() -> [KotlinAndroidGeneratedTextFile] {
        KotlinAndroidGradleProjectEmitter(options: options).generatedFiles()
    }

    private func modelFile(
        sourceBasePath: String,
        packageName: String,
        dataType: ApiTypeSchema,
        excludedNestedTypeIDs: Set<UUID>,
    ) -> KotlinAndroidGeneratedTextFile? {
        guard let typeName = dataType.typeName,
              options.mapping(for: typeName) == nil else {
            return nil
        }
        let emitter = KotlinAndroidModelEmitter(
            dataType: dataType,
            options: options,
            excludedNestedTypeIDs: excludedNestedTypeIDs,
        )
        guard let declaration = emitter.declaration else {
            return nil
        }
        var imports = emitter.imports
            .union(localTypeImports(for: dataType, currentPackage: packageName, excludingTypeName: typeName))
        if dataType.needsKotlinAndroidIdentifiableImport {
            imports.formUnion(runtimeImports(["Identifiable"], currentPackage: packageName))
        }
        if dataType.needsKotlinAndroidByteArrayBase64SerializerImport {
            imports.formUnion(runtimeImports(["ByteArrayBase64Serializer"], currentPackage: packageName))
        }
        let contents = KotlinAndroidFileEmitter.render(
            packageName: packageName,
            imports: Array(imports),
            body: declaration,
        )
        return KotlinAndroidGeneratedTextFile(relativePath: "\(sourceBasePath)/\(typeName.kotlinTypeName).kt", contents: contents)
    }

    private func sourceFile(sourceBasePath: String, name: String, node: any Node) -> KotlinAndroidGeneratedTextFile {
        KotlinAndroidGeneratedTextFile(relativePath: "\(sourceBasePath)/\(name)", contents: node.toString())
    }

    private func managed(_ content: String, commentPrefix: String = "//") -> String {
        "\(commentPrefix) Generated code. Do not edit.\n\(content)\n"
    }

    private var sourceRoot: String {
        options.layout == .standaloneProject
            ? "\(options.gradle.moduleName)/src/main/kotlin"
            : "src/main/kotlin"
    }

    private func sourcePath(packageName: String) -> String {
        "\(sourceRoot)/\(packageName.packagePath)"
    }

    private func removeStaleManagedKotlinAndroidSources(keeping generatedRelativePaths: Set<String>) throws {
        let sourceRootURL = url(forRelativePath: sourceRoot, in: package.targetDirUrl)
        guard let enumerator = FileManager.default.enumerator(
            at: sourceRootURL,
            includingPropertiesForKeys: [.isRegularFileKey],
        ) else {
            return
        }

        let basePath = package.targetDirUrl.resolvingSymlinksInPath().standardizedFileURL.path
        for case let fileURL as URL in enumerator where fileURL.pathExtension == "kt" {
            let resolvedRoot = package.targetDirUrl.resolvingSymlinksInPath().standardizedFileURL.path
            guard fileURL.resolvingSymlinksInPath().standardizedFileURL.path.hasPrefix(resolvedRoot + "/") else {
                throw KotlinAndroidGeneratedTextFileError.invalidRelativePath(fileURL.path)
            }
            let filePath = fileURL.resolvingSymlinksInPath().standardizedFileURL.path
            guard filePath.hasPrefix("\(basePath)/") else {
                continue
            }
            let relativePath = String(filePath.dropFirst(basePath.count + 1))
            guard !generatedRelativePaths.contains(relativePath),
                  let contents = try? String(contentsOf: fileURL, encoding: .utf8),
                  contents.hasPrefix(KotlinAndroidGeneratedTextFile.managedHeader) else {
                continue
            }
            try FileManager.default.removeItem(at: fileURL)
        }
    }

    private func url(forRelativePath relativePath: String, in baseURL: URL) -> URL {
        relativePath.split(separator: "/").reduce(baseURL) { partialURL, component in
            partialURL.appendingPathComponent(String(component))
        }
    }

    private func packageName(module: ApiModule? = nil, definition: ApiService? = nil) -> String {
        var segments = [options.basePackage]
        if let module, !module.name.isEmpty {
            segments.append(module.name.kotlinPackageSegment)
        }
        if let definition {
            segments.append(definition.name.kotlinPackageSegment)
        }
        return segments.joined(separator: ".")
    }

    private func aggregateImports(_ modules: [ApiModule]) -> [String] {
        var imports = Set(modules.flatMap { module in
            module.definitions.flatMap { definition in
                let packageName = packageName(module: module, definition: definition)
                return [
                    "\(packageName).\(definition.kotlinApiTypeName(moduleName: module.name))",
                    "\(packageName).\(definition.kotlinApiServiceTypeName(moduleName: module.name))"
                ]
            }
        })
        imports.formUnion(runtimeImports(["ApiError", "RestClient"], currentPackage: options.basePackage))
        imports.insert("kotlinx.coroutines.flow.MutableSharedFlow")
        imports.insert("kotlinx.coroutines.flow.SharedFlow")
        return Array(imports)
    }

    private func koinImports(_ modules: [ApiModule]) -> [String] {
        Array(Set(modules.flatMap { module in
            module.definitions.flatMap { definition in
                let packageName = packageName(module: module, definition: definition)
                return [
                    "\(packageName).\(definition.kotlinApiTypeName(moduleName: module.name))",
                    "\(packageName).\(definition.kotlinApiServiceTypeName(moduleName: module.name))"
                ]
            }
        }))
    }

    private func serviceImports(module: ApiModule, definition: ApiService) -> [String] {
        let currentPackage = packageName(module: module, definition: definition)
        var imports: Set<String> = []
        imports.formUnion(runtimeImports(["ApiOperationResult", "ApiResponse", "ApiResponseType", "RestClient"], currentPackage: currentPackage))
        if definition.operations.contains(where: { requestRequiresProgress($0.request) }) {
            imports.formUnion(runtimeImports(["ApiProgress"], currentPackage: currentPackage))
        }
        if definition.operations.contains(where: { KotlinAndroidOperationEmitter(operation: $0, options: options).hasPagedResultsResponse }) {
            imports.formUnion(runtimeImports(["ApiError", "ApiRequest", "ApiRequestConvertible", "ApiRequestPath"], currentPackage: currentPackage))
        }
        if !definition.operations.isEmpty {
            imports.insert("kotlinx.serialization.serializer")
        }
        for operation in definition.operations {
            imports.formUnion(operationImports(operation, currentPackage: currentPackage))
            if let responseType = operation.response.dataType {
                imports.formUnion(responseType.kotlinTypeImports(options: options))
                imports.formUnion(localTypeImports(for: responseType, currentPackage: currentPackage))
            }
        }
        return Array(imports)
    }

    private func operationImports(_ operation: ApiOperation, currentPackage: String) -> [String] {
        var imports: Set<String> = []
        imports.formUnion(operation.extraImports.map(\.name).filter(\.isValidKotlinAndroidImport))
        imports.formUnion(runtimeImports(["ApiRequest", "ApiRequestConvertible", "ApiRequestPath"], currentPackage: currentPackage))
        if operation.expandedParameters.contains(where: { $0.location == .path }) {
            imports.formUnion(runtimeImports(["toApiPathSegment"], currentPackage: currentPackage))
        }
        if operation.expandedParameters.contains(where: { $0.location == .query || $0.location == .header || $0.location == .cookie }) {
            imports.formUnion(runtimeImports(["toApiFormValue"], currentPackage: currentPackage))
        }
        if operation.expandedParameters.contains(where: { $0.location == .cookie }) {
            imports.formUnion(runtimeImports(["toCookieHeader"], currentPackage: currentPackage))
        }
        switch operation.request {
            case let .json(type) where type != nil:
                imports.formUnion(runtimeImports(["apiBodySerializer"], currentPackage: currentPackage))
            case .file:
                imports.formUnion(runtimeImports(["ApiUploadSource"], currentPackage: currentPackage))
            case .multiPart:
                imports.formUnion(runtimeImports(["MultipartBody"], currentPackage: currentPackage))
            default:
                break
        }
        for parameter in operation.expandedParameters {
            imports.formUnion(parameter.dataType.kotlinOperationImports(options: options))
            imports.formUnion(localTypeImports(for: parameter.dataType, currentPackage: currentPackage))
        }
        if let requestType = operation.request.dataType {
            imports.formUnion(requestType.kotlinTypeImports(options: options))
            imports.formUnion(localTypeImports(for: requestType, currentPackage: currentPackage))
        }
        return Array(imports)
    }

    private func requestRequiresProgress(_ request: ApiRequestBody) -> Bool {
        switch request {
            case .file,
                 .binary,
                 .multiPart:
                true
            default:
                false
        }
    }

    private func runtimeImports(_ names: [String], currentPackage: String) -> Set<String> {
        guard currentPackage != options.basePackage else {
            return []
        }
        return Set(names.map { "\(options.basePackage).\($0)" })
    }

    private func localTypeImports(for dataType: ApiTypeSchema?, currentPackage: String, excludingTypeName: String? = nil) -> Set<String> {
        guard let dataType else {
            return []
        }
        switch dataType {
            case let .array(type):
                return localTypeImports(for: type, currentPackage: currentPackage, excludingTypeName: excludingTypeName)
            case let .keyedByString(type, _):
                return localTypeImports(for: type, currentPackage: currentPackage, excludingTypeName: excludingTypeName)
            case let .genericReference(typeName, types):
                var imports = types
                    .map { localTypeImports(for: $0, currentPackage: currentPackage, excludingTypeName: excludingTypeName) }
                    .reduce(Set<String>()) { $0.union($1) }
                imports.formUnion(mappedTypeImports(apiTypeName: typeName, currentPackage: currentPackage, excludingTypeName: excludingTypeName))
                return imports
            case let .reference(typeName, _, imports, uuid, dataType):
                if options.mapping(for: typeName) != nil {
                    return mappedTypeImports(apiTypeName: typeName, currentPackage: currentPackage, excludingTypeName: excludingTypeName)
                }
                if let dataType {
                    return localTypeImports(for: dataType, currentPackage: currentPackage, excludingTypeName: excludingTypeName)
                }
                var localImports = Set(imports.map(\.name))
                localImports.formUnion(mappedTypeImports(apiTypeName: typeName, currentPackage: currentPackage, excludingTypeName: excludingTypeName))
                localImports.formUnion(declaredTypeImport(typeName: typeName, uuid: uuid, currentPackage: currentPackage, excludingTypeName: excludingTypeName))
                return localImports
            case let .object(typeName, properties, _, _, _, uuid):
                if options.mapping(for: typeName) != nil {
                    return mappedTypeImports(apiTypeName: typeName, currentPackage: currentPackage, excludingTypeName: excludingTypeName)
                }
                var imports = declaredTypeImport(typeName: typeName, uuid: uuid, currentPackage: currentPackage, excludingTypeName: excludingTypeName)
                imports.formUnion(
                    properties
                        .filter(\.publishedAsField)
                        .map { localTypeImports(for: $0.dataType, currentPackage: currentPackage, excludingTypeName: excludingTypeName) }
                        .reduce(Set<String>()) { $0.union($1) },
                )
                return imports
            case let .stringEnum(typeName, _, _, uuid, _),
                 let .intEnum(typeName, _, _, uuid):
                if options.mapping(for: typeName) != nil {
                    return mappedTypeImports(apiTypeName: typeName, currentPackage: currentPackage, excludingTypeName: excludingTypeName)
                }
                return declaredTypeImport(typeName: typeName, uuid: uuid, currentPackage: currentPackage, excludingTypeName: excludingTypeName)
            case let .dynamicObject(typeName, _, _, _, objectTypes, _, _, uuid, extraProperties):
                if options.mapping(for: typeName) != nil {
                    return mappedTypeImports(apiTypeName: typeName, currentPackage: currentPackage, excludingTypeName: excludingTypeName)
                }
                var imports = declaredTypeImport(typeName: typeName, uuid: uuid, currentPackage: currentPackage, excludingTypeName: excludingTypeName)
                imports.formUnion(
                    objectTypes
                        .map { localTypeImports(for: $0.objectType, currentPackage: currentPackage, excludingTypeName: excludingTypeName) }
                        .reduce(Set<String>()) { $0.union($1) },
                )
                imports.formUnion(
                    extraProperties
                        .map { localTypeImports(for: $0.dataType, currentPackage: currentPackage, excludingTypeName: excludingTypeName) }
                        .reduce(Set<String>()) { $0.union($1) },
                )
                return imports
            default:
                return []
        }
    }

    private func localTypeImports(for dataType: ApiParameter.DataType, currentPackage: String, excludingTypeName: String? = nil) -> Set<String> {
        switch dataType {
            case let .stringEnumValue(type, _),
                 let .stringEnumArray(type, _),
                 let .intEnumValue(type, _),
                 let .intEnumArray(type, _):
                localTypeImports(for: type, currentPackage: currentPackage, excludingTypeName: excludingTypeName)
            default:
                []
        }
    }

    private func mappedTypeImports(apiTypeName: String, currentPackage: String, excludingTypeName: String?) -> Set<String> {
        guard let mapping = options.mapping(for: apiTypeName) else {
            return []
        }
        if !mapping.imports.isEmpty {
            return Set(mapping.imports)
        }
        guard apiTypeName != excludingTypeName,
              defaultRuntimeMappedTypeNames.contains(apiTypeName),
              currentPackage != options.basePackage else {
            return []
        }
        return ["\(options.basePackage).\(mapping.kotlinType)"]
    }

    private func declaredTypeImport(typeName: String, uuid: UUID, currentPackage: String, excludingTypeName: String?) -> Set<String> {
        guard typeName != excludingTypeName,
              let packageName = declaredTypePackagesByID[uuid],
              packageName != currentPackage else {
            return []
        }
        return ["\(packageName).\(typeName.kotlinTypeName)"]
    }

    private func makeDeclaredTypePackagesByID() -> [UUID: String] {
        var packages: [UUID: String] = [:]
        func register(_ dataTypes: [ApiTypeSchema], packageName: String) {
            for dataType in dataTypes {
                if let typeName = dataType.typeName,
                   options.mapping(for: typeName) != nil {
                    continue
                }
                if let uuid = dataType.declaredKotlinAndroidTypeID {
                    packages[uuid] = packages[uuid] ?? packageName
                }
            }
        }

        register(package.commonReferences + package.references, packageName: options.basePackage)
        for module in package.referencedModules + package.modules {
            let modulePackage = packageName(module: module)
            register(module.references, packageName: "\(modulePackage).shared")
            for definition in module.definitions {
                register(definition.referencedTypes + definition.operationDeclaredTypes, packageName: "\(packageName(module: module, definition: definition)).models")
            }
        }
        return packages
    }

    private var topLevelModelTypeIDs: Set<UUID> {
        Set(declaredTypePackagesByID.keys)
    }

    private var defaultRuntimeMappedTypeNames: Set<String> {
        ["DateInterval", "LocalizedData", "PagedResults", "PatchableValue"]
    }

    private func unresolvedExternalTypeNames() -> [String] {
        let allTypes = package.references
            + package.modules.flatMap(\.allKotlinAndroidUsedDataTypes)
        return Set(allTypes.flatMap { $0.externalTypeNames(options: options) }).sorted()
    }

    private func allOperations() -> [ApiOperation] {
        package.modules
            .flatMap(\.definitions)
            .flatMap(\.operations)
    }
}

private extension KotlinAndroidEditorConfigEmitter {
    func fileWithManagedHeader() -> KotlinAndroidGeneratedTextFile {
        KotlinAndroidGeneratedTextFile(relativePath: ".editorconfig", contents: "# Generated code. Do not edit.\n\(render())")
    }
}

private extension String {
    var packagePath: String {
        replacingOccurrences(of: ".", with: "/")
    }

    var isValidKotlinAndroidPackage: Bool {
        let segments = split(separator: ".", omittingEmptySubsequences: false).map(String.init)
        return !segments.isEmpty && segments.allSatisfy { segment in
            guard !segment.isKotlinHardKeyword else {
                return false
            }
            guard let first = segment.first, first.isLetter || first == "_" else {
                return false
            }
            return segment.allSatisfy { $0.isLetter || $0.isNumber || $0 == "_" }
        }
    }

    var isValidKotlinAndroidImport: Bool {
        let importAndAlias = components(separatedBy: " as ")
        guard importAndAlias.count <= 2 else {
            return false
        }
        if importAndAlias.count == 2 {
            guard importAndAlias[1].isValidKotlinAndroidIdentifierSegment else {
                return false
            }
        }

        var segments = importAndAlias[0].split(separator: ".", omittingEmptySubsequences: false).map(String.init)
        if segments.last == "*" {
            segments.removeLast()
        }
        return segments.count > 1 && segments.allSatisfy(\.isValidKotlinAndroidIdentifierSegment)
    }

    var isValidKotlinAndroidIdentifierSegment: Bool {
        guard let first, first.isLetter || first == "_" else {
            return false
        }
        return allSatisfy { $0.isLetter || $0.isNumber || $0 == "_" }
    }

    var isValidGradleModuleName: Bool {
        guard let first, first.isLetter || first.isNumber || first == "_" else {
            return false
        }
        return allSatisfy { $0.isLetter || $0.isNumber || $0 == "_" || $0 == "-" }
    }
}

private extension Int {
    var isHttpBodylessStatus: Bool {
        (100 ..< 200).contains(self) || self == 204 || self == 205 || self == 304
    }
}

private extension ApiModule {
    var allKotlinAndroidUsedDataTypes: [ApiTypeSchema] {
        references + definitions.flatMap(\.allKotlinAndroidUsedDataTypes)
    }

    var allKotlinAndroidDataTypes: [ApiTypeSchema] {
        references + definitions.flatMap(\.allKotlinAndroidDataTypes)
    }
}

private extension ApiService {
    var allKotlinAndroidUsedDataTypes: [ApiTypeSchema] {
        referencedTypes + operations.flatMap(\.usedKotlinAndroidDataTypes)
    }

    var allKotlinAndroidDataTypes: [ApiTypeSchema] {
        referencedTypes + operationDeclaredTypes
    }

    var operationDeclaredTypes: [ApiTypeSchema] {
        operations.flatMap(\.declaredKotlinAndroidDataTypes)
    }
}

private extension ApiOperation {
    var usedKotlinAndroidDataTypes: [ApiTypeSchema] {
        [request.dataType, response.dataType].compactMap(\.self)
            + parameters.flatMap(\.usedKotlinAndroidDataTypes)
    }

    var declaredKotlinAndroidDataTypes: [ApiTypeSchema] {
        [request.dataType, response.dataType].compactMap(\.self).flatMap(\.declaredKotlinAndroidDataTypes)
            + parameters.flatMap(\.declaredKotlinAndroidDataTypes)
    }
}

private extension ApiRequestBody {
    var hasKotlinAndroidBody: Bool {
        switch self {
            case .none:
                false
            case let .json(type):
                type != nil
            case .binary,
                 .file,
                 .multiPart:
                true
        }
    }
}

private extension ApiParameter {
    var usedKotlinAndroidDataTypes: [ApiTypeSchema] {
        switch dataType {
            case let .stringEnumValue(type, _),
                 let .stringEnumArray(type, _),
                 let .intEnumValue(type, _),
                 let .intEnumArray(type, _):
                [type]
            default:
                []
        }
    }

    var declaredKotlinAndroidDataTypes: [ApiTypeSchema] {
        switch dataType {
            case let .stringEnumValue(type, _),
                 let .stringEnumArray(type, _),
                 let .intEnumValue(type, _),
                 let .intEnumArray(type, _):
                type.declaredKotlinAndroidDataTypes
            default:
                []
        }
    }
}

private extension ApiTypeSchema {
    var isKotlinAndroidReferenceable: Bool {
        switch self {
            case .object,
                 .stringEnum,
                 .intEnum,
                 .dynamicObject:
                true
            default:
                false
        }
    }

    var declaredKotlinAndroidDataTypes: [ApiTypeSchema] {
        switch self {
            case .object,
                 .stringEnum,
                 .intEnum,
                 .dynamicObject:
                [self]
            case let .array(type),
                 let .keyedByString(type, _):
                type.declaredKotlinAndroidDataTypes
            case let .reference(_, _, _, _, dataType):
                dataType?.declaredKotlinAndroidDataTypes ?? []
            case let .genericReference(_, types):
                types.flatMap(\.declaredKotlinAndroidDataTypes)
            default:
                []
        }
    }

    var needsKotlinAndroidIdentifiableImport: Bool {
        switch self {
            case let .object(_, properties, protocols, _, _, _):
                let fields = properties.filter(\.publishedAsField)
                return protocols.contains("Identifiable")
                    && fields.contains { $0.propertyName.kotlinPropertyName == "id" }
                    || fields.contains { $0.dataType.needsKotlinAndroidIdentifiableImport }
            case let .dynamicObject(_, _, _, _, objectTypes, _, _, _, _):
                return objectTypes.allSatisfy(\.objectType.supportsKotlinAndroidDynamicObjectIdentifiable)
                    || objectTypes.contains { $0.objectType.needsKotlinAndroidIdentifiableImport }
            case .stringEnum,
                 .intEnum:
                return true
            default:
                return false
        }
    }

    private var supportsKotlinAndroidDynamicObjectIdentifiable: Bool {
        switch self {
            case let .object(_, _, protocols, _, _, _):
                protocols.contains("Identifiable")
            case let .reference(_, _, _, _, dataType):
                dataType?.supportsKotlinAndroidDynamicObjectIdentifiable ?? false
            case .stringEnum,
                 .intEnum:
                true
            default:
                false
        }
    }

    func externalTypeNames(options: KotlinAndroidGeneratorOptions) -> [String] {
        switch self {
            case let .reference(typeName, _, _, _, dataType):
                if options.mapping(for: typeName) != nil {
                    return []
                }
                if let dataType {
                    return dataType.externalTypeNames(options: options)
                }
                return [typeName]
            case let .genericReference(typeName, types):
                let current = options.mapping(for: typeName) == nil ? [typeName] : []
                return current + types.flatMap { $0.externalTypeNames(options: options) }
            case let .array(type),
                 let .keyedByString(type, _):
                return type.externalTypeNames(options: options)
            case let .object(typeName, properties, _, _, _, _):
                if options.mapping(for: typeName) != nil {
                    return []
                }
                return properties
                    .filter(\.publishedAsField)
                    .flatMap { $0.dataType.externalTypeNames(options: options) }
            case let .dynamicObject(typeName, _, _, _, objectTypes, _, _, _, extraProperties):
                if options.mapping(for: typeName) != nil {
                    return []
                }
                return objectTypes.flatMap { $0.objectType.externalTypeNames(options: options) }
                    + extraProperties
                    .flatMap { $0.dataType.externalTypeNames(options: options) }
            default:
                return []
        }
    }
}
