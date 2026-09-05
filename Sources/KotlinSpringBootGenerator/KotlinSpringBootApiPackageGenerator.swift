import Foundation
import GeneratorBuilder
import GeneratorModels

public enum KotlinSpringBootGeneratorError: Error, LocalizedError, Equatable {
    case invalidBasePackage(String)
    case invalidApplicationName(String)
    case invalidProjectName(String)
    case invalidPackage(reason: String)
    case unresolvedExternalType(String)
    case invalidOperation(operationName: String, reason: String)

    public var errorDescription: String? {
        switch self {
            case let .invalidBasePackage(value):
                "Invalid Kotlin Spring Boot base package: \(value)"
            case let .invalidApplicationName(value):
                "Invalid Kotlin Spring Boot application name: \(value)"
            case let .invalidProjectName(value):
                "Invalid Kotlin Spring Boot Gradle project name: \(value)"
            case let .invalidPackage(reason):
                "Invalid Kotlin Spring Boot package: \(reason)"
            case let .unresolvedExternalType(value):
                "Missing Kotlin Spring Boot type mapping for external type: \(value)"
            case let .invalidOperation(operationName, reason):
                "Kotlin Spring Boot operation \(operationName) \(reason)"
        }
    }
}

public struct KotlinSpringBootApiPackageGenerator {
    public let package: ApiPackage
    public let options: KotlinSpringBootGeneratorOptions

    // The package and options are immutable; build lookup tables once, not per reference.
    private var declaredTypePackagesByID: [UUID: String] = [:]
    private var declaredTypePackagesByName: [String: String] = [:]
    private var knownSpringBootDataTypesByName: [String: ApiTypeSchema] = [:]

    public init(package: ApiPackage, options: KotlinSpringBootGeneratorOptions = .init()) {
        self.package = package
        self.options = options
        self.declaredTypePackagesByID = makeDeclaredTypePackagesByID()
        self.declaredTypePackagesByName = makeDeclaredTypePackagesByName()
        self.knownSpringBootDataTypesByName = makeKnownSpringBootDataTypesByName()
    }

    public func write() throws {
        let files = try generatedFiles()
        for file in files {
            try file.write(to: package.targetDirUrl.resolvingSymlinksInPath().standardizedFileURL, overwritePolicy: options.overwritePolicy)
        }
        if options.overwritePolicy == .replaceManagedFiles {
            try removeStaleManagedKotlinSources(keeping: Set(files.map(\.relativePath)))
        }
    }

    public func generatedFiles() throws -> [KotlinSpringBootGeneratedTextFile] {
        try validate()

        var files = options.layout == .standaloneProject ? gradleFiles() : []
        let sourceBasePath = sourcePath(packageName: options.basePackage)
        var generatedModelIDs: Set<UUID> = []
        let excludedNestedTypeIDs = topLevelModelTypeIDs
        let suppliedTypeIDs = commonReferenceTypeIDs.union(referencedModuleTypeIDs)

        func appendModelFile(sourceBasePath: String, packageName: String, dataType: ApiTypeSchema) {
            if let uuid = dataType.declaredKotlinSpringBootTypeID,
               suppliedTypeIDs.contains(uuid) || generatedModelIDs.contains(uuid) {
                return
            }
            guard let file = modelFile(
                sourceBasePath: sourceBasePath,
                packageName: packageName,
                dataType: dataType,
                excludedNestedTypeIDs: excludedNestedTypeIDs
            ) else {
                return
            }
            if let uuid = dataType.declaredKotlinSpringBootTypeID {
                generatedModelIDs.insert(uuid)
            }
            files.append(file)
        }

        if options.layout == .standaloneProject, options.generateApplication {
            files.append(applicationFile(sourceBasePath: sourceBasePath))
        }
        if options.generateRuntime {
            files.append(KotlinSpringBootRuntimeEmitter().file(packageName: options.basePackage))
        }

        for dataType in package.references {
            appendModelFile(
                sourceBasePath: sourceBasePath, packageName: options.basePackage, dataType: dataType
            )
        }

        for module in package.modules {
            let modulePackage = packageName(module: module)
            for dataType in module.references {
                appendModelFile(
                    sourceBasePath: sourcePath(packageName: "\(modulePackage).shared"),
                    packageName: "\(modulePackage).shared",
                    dataType: dataType
                )
            }

            for definition in module.definitions {
                let definitionPackage = packageName(module: module, definition: definition)
                let modelPackage = "\(definitionPackage).models"
                for dataType in definition.referencedTypes + definition.springBootOperationDeclaredTypes {
                    appendModelFile(
                        sourceBasePath: sourcePath(packageName: modelPackage),
                        packageName: modelPackage,
                        dataType: dataType
                    )
                }

                let emitter = KotlinSpringBootOperationEmitter(
                    module: module,
                    definition: definition,
                    options: options,
                    packageName: definitionPackage,
                    importsProvider: { dataType, currentPackage in
                        localTypeImports(for: dataType, currentPackage: currentPackage)
                    },
                    parameterImportsProvider: { dataType, currentPackage in
                        localTypeImports(for: dataType, currentPackage: currentPackage)
                    }
                )
                files.append(contentsOf: emitter.requestFiles())
                files.append(emitter.serviceFile())
                files.append(emitter.controllerFile())
            }
        }

        try validateGeneratedFilePaths(files)
        return files
    }

    private func validate() throws {
        guard options.basePackage.isValidKotlinSpringBootPackage else {
            throw KotlinSpringBootGeneratorError.invalidBasePackage(options.basePackage)
        }
        guard options.layout == .existingProject || options.applicationName.isValidKotlinSpringBootIdentifier else {
            throw KotlinSpringBootGeneratorError.invalidApplicationName(options.applicationName)
        }
        guard options.layout == .existingProject || options.gradle.projectName.isValidKotlinSpringBootProjectName else {
            throw KotlinSpringBootGeneratorError.invalidProjectName(options.gradle.projectName)
        }
        try validateGeneratedNames()
        try validateGeneratedDataTypes()
        for operation in allSpringBootRoutableOperations() {
            try validate(operation: operation)
        }
        for typeName in unresolvedExternalTypeNames() {
            throw KotlinSpringBootGeneratorError.unresolvedExternalType(typeName)
        }
    }

    private func validateGeneratedNames() throws {
        try validateUnique(
            aggregateModules.map { packageName(module: $0) },
            reason: "has duplicate module package names"
        )

        for module in aggregateModules {
            try validateUnique(
                module.definitions.map { $0.kotlinSpringBootServiceTypeName(moduleName: module.name) },
                reason: "module \(module.name) has duplicate service type names"
            )
            try validateUnique(
                module.definitions.map { $0.kotlinSpringBootControllerTypeName(moduleName: module.name) },
                reason: "module \(module.name) has duplicate controller type names"
            )
            try validateUnique(
                module.definitions.map { packageName(module: module, definition: $0) },
                reason: "module \(module.name) has duplicate definition package names"
            )
        }

        for module in package.modules {
            for definition in module.definitions {
                let operations = definition.springBootRoutableOperations
                try validateUnique(
                    operations.map {
                        $0.kotlinSpringBootRequestTypeName(
                            moduleName: module.name, definitionName: definition.name
                        )
                    },
                    reason: "definition \(definition.name) has duplicate request type names"
                )
                try validateUnique(
                    operations.map(\.kotlinSpringBootMethodName),
                    reason: "definition \(definition.name) has duplicate method names"
                )
            }
        }
    }

    private func validateGeneratedDataTypes() throws {
        var visitedTypeIDs: Set<UUID> = []
        let packageReferences = package.commonReferences + package.references
        guard packageReferences.allSatisfy(\.isKotlinSpringBootReferenceable) else {
            let invalidTypes = packageReferences
                .filter { !$0.isKotlinSpringBootReferenceable }
                .map(springBootValidationTypeName)
            throw KotlinSpringBootGeneratorError.invalidPackage(reason: "package references are not all referenceable: \(invalidTypes)")
        }
        for module in package.modules {
            guard module.references.allSatisfy(\.isKotlinSpringBootReferenceable) else {
                let invalidTypes = module.references
                    .filter { !$0.isKotlinSpringBootReferenceable }
                    .map(springBootValidationTypeName)
                throw KotlinSpringBootGeneratorError.invalidPackage(
                    reason: "module \(module.name) references are not all referenceable: \(invalidTypes)"
                )
            }
            for definition in module.definitions {
                guard definition.referencedTypes.allSatisfy(\.isKotlinSpringBootReferenceable) else {
                    let invalidTypes = definition.referencedTypes
                        .filter { !$0.isKotlinSpringBootReferenceable }
                        .map(springBootValidationTypeName)
                    throw KotlinSpringBootGeneratorError.invalidPackage(
                        reason: "definition \(definition.name) references are not all referenceable: \(invalidTypes)"
                    )
                }
            }
        }
        for dataType in packageReferences + package.modules.flatMap(\.allSpringBootDataTypes) {
            try validateGeneratedDataType(dataType, visitedTypeIDs: &visitedTypeIDs)
        }
    }

    private func validateGeneratedDataType(_ dataType: ApiTypeSchema, visitedTypeIDs: inout Set<UUID>) throws {
        if let typeName = dataType.typeName,
           options.mapping(for: typeName) != nil {
            return
        }
        if let uuid = dataType.declaredKotlinSpringBootTypeID,
           !visitedTypeIDs.insert(uuid).inserted {
            return
        }

        switch dataType {
            case let .object(typeName, properties, _, _, _, _):
                let fields = properties.filter(\.publishedAsField)
                try validateUnique(
                    properties.map(\.propertyName.kotlinSpringBootPropertyName),
                    reason: "model \(typeName) has duplicate property names"
                )
                try validateUnique(
                    properties.map(\.rawName),
                    reason: "model \(typeName) has duplicate raw property names"
                )
                try fields.forEach { try validateGeneratedDataType($0.dataType, visitedTypeIDs: &visitedTypeIDs) }

            case let .stringEnum(typeName, values, _, _, supportGarbage):
                let caseNames = values.map(\.name.kotlinSpringBootEnumCaseName) + (supportGarbage ? ["Garbage"] : [])
                try validateUnique(caseNames, reason: "enum \(typeName) has duplicate case names")
                let rawValues = values.map(\.rawName) + (supportGarbage ? ["__garbage__"] : [])
                try validateUnique(rawValues, reason: "enum \(typeName) has duplicate raw values")

            case let .intEnum(typeName, values, _, _):
                let caseNames = values.map { value in
                    if let name = value.name, !name.isEmpty {
                        return name.kotlinSpringBootEnumCaseName
                    }
                    return value.rawValue.description.kotlinSpringBootEnumCaseName
                }
                try validateUnique(caseNames, reason: "enum \(typeName) has duplicate case names")
                try validateUnique(values.map(\.rawValue), reason: "enum \(typeName) has duplicate raw values")

            case let .double(value):
                guard value?.isFinite != false else {
                    throw KotlinSpringBootGeneratorError.invalidPackage(reason: "double initial value must be finite")
                }

            case let .dynamicObject(
            typeName, objectTypePropertyName, objectDataPropertyName, alternateObjectDataPropertyName, objectTypes, supportGarbage, _, _, extraProperties
        ):
                let typeNames = objectTypes.map(\.objectTypeName.kotlinSpringBootTypeName) + (supportGarbage ? ["Garbage"] : [])
                try validateUnique(typeNames, reason: "dynamic object \(typeName) has duplicate subtype names")
                let rawTypeNames = objectTypes.map(\.objectTypeRawName) + (supportGarbage ? ["__garbage__"] : [])
                try validateUnique(rawTypeNames, reason: "dynamic object \(typeName) has duplicate subtype raw names")
                let extraFields = extraProperties
                let payloadFields = ["payload"] + extraProperties.map(\.propertyName.kotlinSpringBootPropertyName)
                try validateUnique(payloadFields, reason: "dynamic object \(typeName) has duplicate payload property names")
                let reservedRawNames = [objectTypePropertyName, objectDataPropertyName, alternateObjectDataPropertyName]
                try validateUnique(reservedRawNames, reason: "dynamic object \(typeName) has duplicate reserved raw property names")
                let extraRawNames = extraProperties.map(\.rawName)
                try validateUnique(extraRawNames, reason: "dynamic object \(typeName) has duplicate extra raw property names")
                let reservedExtraRawNames = Set(extraRawNames).intersection(reservedRawNames)
                guard reservedExtraRawNames.isEmpty else {
                    throw KotlinSpringBootGeneratorError.invalidPackage(
                        reason: "dynamic object \(typeName) has extra raw property names that collide with reserved names: \(reservedExtraRawNames.sorted())"
                    )
                }
                let reservedPropertyNames = Set(reservedRawNames.map(\.kotlinSpringBootPropertyName))
                let reservedExtraPropertyNames = Set(extraProperties.map(\.propertyName.kotlinSpringBootPropertyName)).intersection(reservedPropertyNames)
                guard reservedExtraPropertyNames.isEmpty else {
                    throw KotlinSpringBootGeneratorError.invalidPackage(
                        reason: "dynamic object \(typeName) has extra property names that collide with reserved names: \(reservedExtraPropertyNames.sorted())"
                    )
                }
                if objectDataPropertyName == "__self__" {
                    let reservedNames = Set([objectTypePropertyName] + extraRawNames)
                    for objectType in objectTypes {
                        let rawNames = objectRawNames(in: objectType.objectType)
                        let collisions = Set(rawNames).intersection(reservedNames)
                        guard collisions.isEmpty else {
                            throw KotlinSpringBootGeneratorError.invalidPackage(
                                reason: "dynamic object \(typeName) has self-encoded property names that collide with reserved names: \(collisions.sorted())"
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

    private func validateGeneratedFilePaths(_ files: [KotlinSpringBootGeneratedTextFile]) throws {
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
            throw KotlinSpringBootGeneratorError.invalidPackage(reason: "\(reason): \(duplicates.sorted())")
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
        try validateParameters(operation)
        try validateAcceptableStatuses(operation)
        try validateGeneratedRequestMemberCollisions(operation)
        try validateMultipartParts(operation)

        guard case let .relative(path) = operation.path else {
            return
        }
        try validatePathPlaceholders(path: path, operation: operation, parameters: operation.expandedParameters)
        try validateNoSpringWildcardPathComponents(path: path, operation: operation)
    }

    private func validateParameters(_ operation: ApiOperation) throws {
        let parameters = operation.expandedParameters
        let propertyNames = parameters.map(\.propertyName.kotlinSpringBootPropertyName)
        guard Set(propertyNames).count == propertyNames.count else {
            throw invalidOperation(operation, "has duplicate parameter property names")
        }
        let controllerParameterCollisions = Set(propertyNames).intersection(springBootGeneratedControllerParameterNames)
        guard controllerParameterCollisions.isEmpty else {
            throw invalidOperation(
                operation,
                "has parameter names that collide with generated controller parameters: \(controllerParameterCollisions.sorted())"
            )
        }

        let wireNames = parameters.map { parameter in
            let wireName =
                parameter.location == .header
                    ? parameter.rawName.lowercased()
                    : parameter.rawName
            return "\(parameter.location.rawValue):\(wireName)"
        }
        guard Set(wireNames).count == wireNames.count else {
            throw invalidOperation(operation, "has duplicate parameter wire names")
        }

        if parameters.contains(where: { $0.location == .cookie }),
           parameters.contains(where: {
               $0.location == .header && $0.rawName.caseInsensitiveCompare("Cookie") == .orderedSame
           }) {
            throw invalidOperation(operation, "cannot combine Cookie header parameters with cookie parameters")
        }

        for parameter in parameters {
            try validate(parameter: parameter, operation: operation)
        }
    }

    private func validate(parameter: ApiParameter, operation: ApiOperation) throws {
        switch parameter.dataType {
            case let .stringEnumArray(type, _):
                guard parameter.location != .path else {
                    throw invalidOperation(operation, "has enum array path parameters")
                }
                guard isValidStringEnumType(type) else {
                    throw invalidOperation(operation, "has invalid enum parameter type")
                }
            case let .stringEnumValue(type, _):
                guard isValidStringEnumType(type) else {
                    throw invalidOperation(operation, "has invalid enum parameter type")
                }
            case let .intEnumArray(type, _):
                guard parameter.location != .path else {
                    throw invalidOperation(operation, "has enum array path parameters")
                }
                guard isValidIntEnumType(type) else {
                    throw invalidOperation(operation, "has invalid enum parameter type")
                }
            case let .intEnumValue(type, _):
                guard isValidIntEnumType(type) else {
                    throw invalidOperation(operation, "has invalid enum parameter type")
                }
            default:
                return
        }

        try validateEnumDefaults(parameter.dataType, operation: operation)
    }

    private func isValidStringEnumType(_ type: ApiTypeSchema) -> Bool {
        switch type {
            case .stringEnum:
                true
            case let .reference(typeName, _, _, _, dataType):
                if let dataType {
                    isValidStringEnumType(dataType)
                } else if let knownType = knownSpringBootDataTypesByName[typeName] {
                    isValidStringEnumType(knownType)
                } else {
                    true
                }
            default:
                false
        }
    }

    private func isValidIntEnumType(_ type: ApiTypeSchema) -> Bool {
        switch type {
            case .intEnum:
                true
            case let .reference(typeName, _, _, _, dataType):
                if let dataType {
                    isValidIntEnumType(dataType)
                } else if let knownType = knownSpringBootDataTypesByName[typeName] {
                    isValidIntEnumType(knownType)
                } else {
                    true
                }
            default:
                false
        }
    }

    private func validateEnumDefaults(
        _ parameterType: ApiParameter.DataType,
        operation: ApiOperation
    ) throws {
        switch parameterType {
            case let .stringEnumValue(type, defaultValue):
                guard let defaultValue else {
                    return
                }
                guard let rawNames = stringEnumRawNames(type),
                      rawNames.contains(defaultValue) else {
                    if isMappedExternalType(type) {
                        return
                    }
                    throw invalidOperation(operation, "has invalid enum parameter default value")
                }
            case let .stringEnumArray(type, defaultValues):
                guard let defaultValues else {
                    return
                }
                guard let rawNames = stringEnumRawNames(type) else {
                    if isMappedExternalType(type) {
                        return
                    }
                    throw invalidOperation(operation, "has invalid enum parameter default value")
                }
                guard defaultValues.allSatisfy(rawNames.contains) else {
                    throw invalidOperation(operation, "has invalid enum parameter default value")
                }
            case let .intEnumValue(type, defaultValue):
                guard let defaultValue else {
                    return
                }
                guard let rawValues = intEnumRawValues(type),
                      rawValues.contains(defaultValue) else {
                    if isMappedExternalType(type) {
                        return
                    }
                    throw invalidOperation(operation, "has invalid enum parameter default value")
                }
            case let .intEnumArray(type, defaultValues):
                guard let defaultValues else {
                    return
                }
                guard let rawValues = intEnumRawValues(type) else {
                    if isMappedExternalType(type) {
                        return
                    }
                    throw invalidOperation(operation, "has invalid enum parameter default value")
                }
                guard defaultValues.allSatisfy(rawValues.contains) else {
                    throw invalidOperation(operation, "has invalid enum parameter default value")
                }
            default:
                return
        }
    }

    private func stringEnumRawNames(_ type: ApiTypeSchema) -> Set<String>? {
        switch type {
            case let .stringEnum(_, values, _, _, _):
                return Set(values.map(\.rawName))
            case let .reference(typeName, _, _, _, dataType):
                if let dataType {
                    return stringEnumRawNames(dataType)
                }
                return knownSpringBootDataTypesByName[typeName].flatMap(stringEnumRawNames)
            default:
                return nil
        }
    }

    private func intEnumRawValues(_ type: ApiTypeSchema) -> Set<Int>? {
        switch type {
            case let .intEnum(_, values, _, _):
                return Set(values.map(\.rawValue))
            case let .reference(typeName, _, _, _, dataType):
                if let dataType {
                    return intEnumRawValues(dataType)
                }
                return knownSpringBootDataTypesByName[typeName].flatMap(intEnumRawValues)
            default:
                return nil
        }
    }

    private func isMappedExternalType(_ type: ApiTypeSchema) -> Bool {
        guard let typeName = type.typeName else {
            return false
        }
        return options.mapping(for: typeName) != nil
    }

    private func validateAcceptableStatuses(_ operation: ApiOperation) throws {
        guard !operation.acceptableStatuses.isEmpty else {
            throw invalidOperation(operation, "must have at least one acceptable status")
        }

        if case .json(nil) = operation.response {
            throw invalidOperation(operation, "has a typed response without a data type")
        }

        if let statusCode = operation.acceptableStatuses.first(where: { !(100 ... 599).contains($0) }) {
            throw invalidOperation(operation, "has invalid acceptable status \(statusCode)")
        }

        if operation.response.dataType != nil {
            let statusesWithBody = operation.acceptableStatuses.filter { !$0.isHttpBodylessStatus }
            guard !statusesWithBody.isEmpty else {
                throw invalidOperation(
                    operation,
                    "has a typed response but no acceptable status can carry a response body"
                )
            }
        }
    }

    private func validateGeneratedRequestMemberCollisions(_ operation: ApiOperation) throws {
        let parameterNames = Set(operation.expandedParameters.map(\.propertyName.kotlinSpringBootPropertyName))
        let collisions = parameterNames.intersection(springBootGeneratedRequestMemberNames(operation))
        guard collisions.isEmpty else {
            throw invalidOperation(
                operation,
                "has parameter names that collide with generated request members: \(collisions.sorted())"
            )
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
        guard Set(parts).count == parts.count else {
            throw invalidOperation(operation, "has duplicate multipart part names")
        }
        let parameterNames = parts.map(\.kotlinSpringBootPropertyName)
        guard Set(parameterNames).count == parameterNames.count else {
            throw invalidOperation(operation, "has multipart part names that generate duplicate parameters")
        }
        let controllerParameterCollisions = Set(parameterNames).intersection(springBootGeneratedControllerParameterNames)
        guard controllerParameterCollisions.isEmpty else {
            throw invalidOperation(
                operation,
                "has multipart part names that collide with generated controller parameters: \(controllerParameterCollisions.sorted())"
            )
        }
        let operationParameterNames = Set(operation.expandedParameters.map(\.propertyName.kotlinSpringBootPropertyName))
        let collisions = Set(parameterNames).intersection(operationParameterNames)
        guard collisions.isEmpty else {
            throw invalidOperation(
                operation,
                "has multipart part names that collide with generated parameters: \(collisions.sorted())"
            )
        }
    }

    private func springBootGeneratedRequestMemberNames(_ operation: ApiOperation) -> Set<String> {
        if operation.request.hasSpringBootBody {
            return ["body"]
        }
        return []
    }

    private var springBootGeneratedControllerParameterNames: Set<String> {
        ["servletRequest"]
    }

    private func validatePathPlaceholders(
        path: String,
        operation: ApiOperation,
        parameters: [ApiParameter]
    ) throws {
        let placeholders = try pathPlaceholders(in: path, operation: operation)
        let allowedRange = pathComponentRange(inRelativePath: path)
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

    private func validateNoSpringWildcardPathComponents(path: String, operation: ApiOperation) throws {
        let pathComponent = path[pathComponentRange(inRelativePath: path)]
        let components = pathComponent.split(separator: "/").map(String.init)
        guard !components.contains("*"), !components.contains("**") else {
            throw invalidOperation(operation, "has Spring wildcard path components")
        }
    }

    private func pathPlaceholders(
        in path: String,
        operation: ApiOperation
    ) throws -> [(name: String, range: Range<String.Index>)] {
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
        let end = firstPathBoundary(in: path, from: path.startIndex)
        return path.startIndex ..< end
    }

    private func firstPathBoundary(in path: String, from start: String.Index) -> String.Index {
        let queryIndex = path[start...].firstIndex(of: "?")
        let fragmentIndex = path[start...].firstIndex(of: "#")
        return [queryIndex, fragmentIndex].compactMap(\.self).min() ?? path.endIndex
    }

    private func invalidOperation(
        _ operation: ApiOperation,
        _ reason: String
    ) -> KotlinSpringBootGeneratorError {
        .invalidOperation(operationName: operation.name, reason: reason)
    }

    private func gradleFiles() -> [KotlinSpringBootGeneratedTextFile] {
        let gradle = options.gradle
        return [
            KotlinSpringBootGeneratedTextFile(
                relativePath: "settings.gradle.kts",
                contents: managed(
                    """
                    pluginManagement {
                        repositories {
                            mavenCentral()
                            gradlePluginPortal()
                        }
                    }

                    dependencyResolutionManagement {
                        repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
                        repositories {
                            mavenCentral()
                        }
                    }

                    rootProject.name = \(gradle.projectName.kotlinSpringBootStringLiteral)
                    """
                )
            ),
            KotlinSpringBootGeneratedTextFile(
                relativePath: "build.gradle.kts",
                contents: managed(
                    """
                    plugins {
                        alias(libs.plugins.spring.boot)
                        alias(libs.plugins.spring.dependency.management)
                        alias(libs.plugins.kotlin.jvm)
                        alias(libs.plugins.kotlin.plugin.spring)
                        alias(libs.plugins.kotlin.plugin.serialization)
                        alias(libs.plugins.ktlint)
                    }

                    group = \(gradle.group.kotlinSpringBootStringLiteral)
                    version = \(gradle.version.kotlinSpringBootStringLiteral)

                    kotlin {
                        jvmToolchain(\(gradle.jvmToolchain))

                        compilerOptions {
                            optIn.add("kotlin.time.ExperimentalTime")
                        }
                    }

                    dependencies {
                        implementation(libs.spring.boot.starter.web)
                        implementation(libs.kotlin.reflect)
                        implementation(libs.kotlinx.datetime)
                        implementation(libs.kotlinx.coroutines.reactor)
                        implementation(libs.kotlinx.serialization.json)
                        testImplementation(libs.spring.boot.starter.test)
                    }

                    tasks.withType<Test> {
                        useJUnitPlatform()
                    }

                    ktlint {
                        version.set(\(gradle.ktlintVersion.kotlinSpringBootStringLiteral))
                        filter {
                            exclude("src/**")
                        }
                    }

                    val generatedSourceSetKtlintTasks =
                        tasks.matching { task ->
                            task.name.contains("SourceSet") && task.name.contains("ktlint", ignoreCase = true)
                        }
                    generatedSourceSetKtlintTasks.configureEach {
                        enabled = false
                    }
                    """
                )
            ),
            KotlinSpringBootGeneratedTextFile(
                relativePath: "gradle/libs.versions.toml",
                contents: managed(
                    """
                    [versions]
                    springBoot = "\(gradle.springBootVersion)"
                    kotlin = "\(gradle.kotlinVersion)"
                    springDependencyManagement = "\(gradle.dependencyManagementVersion)"
                    kotlinxSerialization = "\(gradle.kotlinxSerializationVersion)"
                    kotlinxDateTime = "\(gradle.kotlinxDateTimeVersion)"
                    ktlintGradle = "\(gradle.ktlintGradlePluginVersion)"

                    [libraries]
                    spring-boot-starter-web = { module = "org.springframework.boot:spring-boot-starter-web" }
                    spring-boot-starter-test = { module = "org.springframework.boot:spring-boot-starter-test" }
                    kotlin-reflect = { module = "org.jetbrains.kotlin:kotlin-reflect" }
                    kotlinx-datetime = { module = "org.jetbrains.kotlinx:kotlinx-datetime", version.ref = "kotlinxDateTime" }
                    kotlinx-coroutines-reactor = { module = "org.jetbrains.kotlinx:kotlinx-coroutines-reactor" }
                    kotlinx-serialization-json = { module = "org.jetbrains.kotlinx:kotlinx-serialization-json", version.ref = "kotlinxSerialization" }

                    [plugins]
                    spring-boot = { id = "org.springframework.boot", version.ref = "springBoot" }
                    spring-dependency-management = { id = "io.spring.dependency-management", version.ref = "springDependencyManagement" }
                    kotlin-jvm = { id = "org.jetbrains.kotlin.jvm", version.ref = "kotlin" }
                    kotlin-plugin-spring = { id = "org.jetbrains.kotlin.plugin.spring", version.ref = "kotlin" }
                    kotlin-plugin-serialization = { id = "org.jetbrains.kotlin.plugin.serialization", version.ref = "kotlin" }
                    ktlint = { id = "org.jlleitschuh.gradle.ktlint", version.ref = "ktlintGradle" }
                    """, commentPrefix: "#"
                )
            ),
            KotlinSpringBootGeneratedTextFile(
                relativePath: "gradle.properties",
                contents: managed(
                    """
                    org.gradle.jvmargs=-Xmx2g -Dfile.encoding=UTF-8
                    kotlin.code.style=official
                    """, commentPrefix: "#"
                )
            ),
            editorConfigFile()
        ]
    }

    private func applicationFile(sourceBasePath: String) -> KotlinSpringBootGeneratedTextFile {
        let applicationTypeName = options.applicationName.kotlinSpringBootTypeName
        return KotlinSpringBootGeneratedTextFile(
            relativePath: "\(sourceBasePath)/\(applicationTypeName).kt",
            contents: KotlinSpringBootFileEmitter.render(
                packageName: options.basePackage,
                imports: [
                    "org.springframework.boot.autoconfigure.SpringBootApplication",
                    "org.springframework.boot.runApplication"
                ],
                body: """
                @SpringBootApplication
                class \(applicationTypeName)

                fun main(args: Array<String>) {
                    runApplication<\(applicationTypeName)>(*args)
                }
                """
            )
        )
    }

    private func modelFile(
        sourceBasePath: String,
        packageName: String,
        dataType: ApiTypeSchema,
        excludedNestedTypeIDs: Set<UUID>
    ) -> KotlinSpringBootGeneratedTextFile? {
        guard let typeName = dataType.typeName,
              options.mapping(for: typeName) == nil else {
            return nil
        }
        let emitter = KotlinSpringBootModelEmitter(
            dataType: dataType,
            options: options,
            excludedNestedTypeIDs: excludedNestedTypeIDs
        )
        guard let declaration = emitter.declaration else {
            return nil
        }
        var imports = emitter.imports
            .union(
                localTypeImports(for: dataType, currentPackage: packageName, excludingTypeName: typeName)
            )
        if dataType.needsKotlinSpringBootIdentifiableImport {
            if packageName != options.basePackage {
                imports.insert("\(options.basePackage).Identifiable")
            }
        }
        let contents = KotlinSpringBootFileEmitter.render(
            packageName: packageName,
            imports: Array(imports),
            body: declaration
        )
        return KotlinSpringBootGeneratedTextFile(
            relativePath: "\(sourceBasePath)/\(typeName.kotlinSpringBootTypeName).kt", contents: contents
        )
    }

    private func sourcePath(packageName: String) -> String {
        "src/main/kotlin/\(packageName.kotlinSpringBootPackagePath)"
    }

    private func managed(_ content: String, commentPrefix: String = "//") -> String {
        "\(commentPrefix) Generated code. Do not edit.\n\(content)\n"
    }

    private func editorConfigFile() -> KotlinSpringBootGeneratedTextFile {
        KotlinSpringBootGeneratedTextFile(
            relativePath: ".editorconfig",
            contents: """
            # Generated code. Do not edit.
            root = true

            [*.{kt,kts}]
            indent_style = space
            indent_size = 4
            ktlint_code_style = \(options.gradle.ktlintCodeStyle.rawValue)
            """
        )
    }

    private func packageName(module: ApiModule? = nil, definition: ApiService? = nil) -> String {
        var segments = [options.basePackage]
        if let module, !module.name.isEmpty {
            segments.append(module.name.kotlinSpringBootPackageSegment)
        }
        if let definition {
            segments.append(definition.name.kotlinSpringBootPackageSegment)
        }
        return segments.joined(separator: ".")
    }

    private func localTypeImports(
        for dataType: ApiTypeSchema?, currentPackage: String, excludingTypeName: String? = nil
    ) -> Set<String> {
        guard let dataType else {
            return []
        }
        switch dataType {
            case let .array(type):
                return localTypeImports(
                    for: type, currentPackage: currentPackage, excludingTypeName: excludingTypeName
                )
            case let .keyedByString(type, _):
                return localTypeImports(
                    for: type, currentPackage: currentPackage, excludingTypeName: excludingTypeName
                )
            case let .genericReference(typeName, types):
                var imports =
                    types
                        .map {
                            localTypeImports(
                                for: $0, currentPackage: currentPackage, excludingTypeName: excludingTypeName
                            )
                        }
                        .reduce(Set<String>()) { $0.union($1) }
                imports.formUnion(
                    mappedTypeImports(
                        apiTypeName: typeName, currentPackage: currentPackage,
                        excludingTypeName: excludingTypeName
                    )
                )
                return imports
            case let .reference(typeName, _, imports, uuid, dataType):
                if let dataType {
                    return localTypeImports(
                        for: dataType, currentPackage: currentPackage, excludingTypeName: excludingTypeName
                    )
                }
                if options.mapping(for: typeName) != nil {
                    return mappedTypeImports(
                        apiTypeName: typeName, currentPackage: currentPackage,
                        excludingTypeName: excludingTypeName
                    )
                }
                var localImports = Set(imports.map(\.name))
                localImports.formUnion(
                    mappedTypeImports(
                        apiTypeName: typeName, currentPackage: currentPackage,
                        excludingTypeName: excludingTypeName
                    )
                )
                localImports.formUnion(
                    declaredTypeImport(
                        typeName: typeName, uuid: uuid, currentPackage: currentPackage,
                        excludingTypeName: excludingTypeName
                    )
                )
                return localImports
            case let .object(typeName, properties, _, _, _, uuid):
                if options.mapping(for: typeName) != nil {
                    return mappedTypeImports(
                        apiTypeName: typeName, currentPackage: currentPackage,
                        excludingTypeName: excludingTypeName
                    )
                }
                var imports = declaredTypeImport(
                    typeName: typeName, uuid: uuid, currentPackage: currentPackage,
                    excludingTypeName: excludingTypeName
                )
                imports.formUnion(
                    properties
                        .filter(\.publishedAsField)
                        .map {
                            localTypeImports(
                                for: $0.dataType, currentPackage: currentPackage, excludingTypeName: excludingTypeName
                            )
                        }
                        .reduce(Set<String>()) { $0.union($1) }
                )
                return imports
            case let .stringEnum(typeName, _, _, uuid, _),
                 let .intEnum(typeName, _, _, uuid):
                if options.mapping(for: typeName) != nil {
                    return mappedTypeImports(
                        apiTypeName: typeName, currentPackage: currentPackage,
                        excludingTypeName: excludingTypeName
                    )
                }
                return declaredTypeImport(
                    typeName: typeName, uuid: uuid, currentPackage: currentPackage,
                    excludingTypeName: excludingTypeName
                )
            case let .dynamicObject(
            typeName, _, _, _, objectTypes, _, _, uuid, extraProperties
        ):
                if options.mapping(for: typeName) != nil {
                    return mappedTypeImports(
                        apiTypeName: typeName, currentPackage: currentPackage,
                        excludingTypeName: excludingTypeName
                    )
                }
                var imports = declaredTypeImport(
                    typeName: typeName, uuid: uuid, currentPackage: currentPackage,
                    excludingTypeName: excludingTypeName
                )
                imports.formUnion(
                    objectTypes
                        .map {
                            localTypeImports(
                                for: $0.objectType, currentPackage: currentPackage,
                                excludingTypeName: excludingTypeName
                            )
                        }
                        .reduce(Set<String>()) { $0.union($1) }
                )
                imports.formUnion(
                    extraProperties
                        .map {
                            localTypeImports(
                                for: $0.dataType, currentPackage: currentPackage, excludingTypeName: excludingTypeName
                            )
                        }
                        .reduce(Set<String>()) { $0.union($1) }
                )
                return imports
            default:
                return []
        }
    }

    private func localTypeImports(
        for dataType: ApiParameter.DataType, currentPackage: String, excludingTypeName: String? = nil
    ) -> Set<String> {
        switch dataType {
            case let .stringEnumValue(type, _),
                 let .stringEnumArray(type, _),
                 let .intEnumValue(type, _),
                 let .intEnumArray(type, _):
                localTypeImports(
                    for: type, currentPackage: currentPackage, excludingTypeName: excludingTypeName
                )
            default:
                []
        }
    }

    private func mappedTypeImports(
        apiTypeName: String, currentPackage: String, excludingTypeName: String?
    ) -> Set<String> {
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

    private func declaredTypeImport(
        typeName: String, uuid: UUID, currentPackage: String, excludingTypeName: String?
    ) -> Set<String> {
        guard typeName != excludingTypeName,
              let packageName = declaredTypePackagesByID[uuid] ?? declaredTypePackagesByName[typeName],
              packageName != currentPackage else {
            return []
        }
        return ["\(packageName).\(typeName.kotlinSpringBootTypeName)"]
    }

    private func makeDeclaredTypePackagesByID() -> [UUID: String] {
        var packages: [UUID: String] = [:]
        func register(_ dataTypes: [ApiTypeSchema], packageName: String) {
            for dataType in dataTypes {
                if let typeName = dataType.typeName,
                   options.mapping(for: typeName) != nil {
                    continue
                }
                if let uuid = dataType.declaredKotlinSpringBootTypeID {
                    packages[uuid] = packages[uuid] ?? packageName
                }
            }
        }

        register(package.commonReferences + package.references, packageName: options.basePackage)
        for module in aggregateModules {
            let modulePackage = packageName(module: module)
            register(module.references, packageName: "\(modulePackage).shared")
            for definition in module.definitions {
                register(
                    definition.referencedTypes + definition.springBootOperationDeclaredTypes,
                    packageName: "\(packageName(module: module, definition: definition)).models"
                )
            }
        }
        return packages
    }

    private func makeDeclaredTypePackagesByName() -> [String: String] {
        var packages: [String: String] = [:]
        func register(_ dataTypes: [ApiTypeSchema], packageName: String) {
            for dataType in dataTypes {
                guard let typeName = dataType.typeName,
                      options.mapping(for: typeName) == nil else {
                    continue
                }
                packages[typeName] = packages[typeName] ?? packageName
            }
        }

        register(package.commonReferences + package.references, packageName: options.basePackage)
        for module in aggregateModules {
            let modulePackage = packageName(module: module)
            register(module.references, packageName: "\(modulePackage).shared")
            for definition in module.definitions {
                register(
                    definition.referencedTypes + definition.springBootOperationDeclaredTypes,
                    packageName: "\(packageName(module: module, definition: definition)).models"
                )
            }
        }
        return packages
    }

    private var topLevelModelTypeIDs: Set<UUID> {
        Set(declaredTypePackagesByID.keys)
    }

    private var commonReferenceTypeIDs: Set<UUID> {
        Set(package.commonReferences.compactMap(\.declaredKotlinSpringBootTypeID))
    }

    private var referencedModuleTypeIDs: Set<UUID> {
        Set(package.referencedModules.flatMap(\.allSpringBootDataTypes).compactMap(\.declaredKotlinSpringBootTypeID))
    }

    private func springBootValidationTypeName(_ dataType: ApiTypeSchema) -> String {
        switch dataType {
            case let .array(type):
                "[\(springBootValidationTypeName(type))]"
            case let .keyedByString(type, isOptional):
                "[String: \(springBootValidationTypeName(type))\(isOptional ? "?" : "")]"
            default:
                dataType.kotlinSpringBootTypeName(options: options).declaration
        }
    }

    private var defaultRuntimeMappedTypeNames: Set<String> {
        ["DateInterval", "LocalizedData", "PagedResults", "PatchableValue"]
    }

    private func unresolvedExternalTypeNames() -> [String] {
        let allTypes =
            package.references
                + package.modules.flatMap(\.allSpringBootUsedDataTypes)
        let externalTypeNames = Set(allTypes.flatMap { $0.externalSpringBootTypeNames(options: options) })
        return externalTypeNames.subtracting(knownSpringBootTypeNames).sorted()
    }

    private var knownSpringBootTypeNames: Set<String> {
        Set(knownSpringBootDataTypesByName.keys)
    }

    private func makeKnownSpringBootDataTypesByName() -> [String: ApiTypeSchema] {
        var dataTypes: [String: ApiTypeSchema] = [:]
        func register(_ values: [ApiTypeSchema]) {
            for dataType in values {
                guard let typeName = dataType.typeName else {
                    continue
                }
                dataTypes[typeName] = dataTypes[typeName] ?? dataType
            }
        }

        register(package.commonReferences + package.references)
        for module in aggregateModules {
            register(module.references)
            for definition in module.definitions {
                register(definition.referencedTypes + definition.springBootOperationDeclaredTypes)
            }
        }
        return dataTypes
    }

    private func allSpringBootRoutableOperations() -> [ApiOperation] {
        package.modules
            .flatMap(\.definitions)
            .flatMap(\.springBootRoutableOperations)
    }

    private var aggregateModules: [ApiModule] {
        package.referencedModules + package.modules
    }

    private func removeStaleManagedKotlinSources(keeping generatedRelativePaths: Set<String>) throws {
        let sourceRootURL = url(forRelativePath: "src/main/kotlin", in: package.targetDirUrl)
        guard let enumerator = FileManager.default.enumerator(
            at: sourceRootURL,
            includingPropertiesForKeys: [.isRegularFileKey]
        ) else {
            return
        }

        let basePath = package.targetDirUrl.resolvingSymlinksInPath().standardizedFileURL.path
        for case let fileURL as URL in enumerator where fileURL.pathExtension == "kt" {
            let filePath = fileURL.resolvingSymlinksInPath().standardizedFileURL.path
            guard filePath.hasPrefix("\(basePath)/") else {
                continue
            }
            let relativePath = String(filePath.dropFirst(basePath.count + 1))
            guard !generatedRelativePaths.contains(relativePath),
                  let contents = try? String(contentsOf: fileURL, encoding: .utf8),
                  contents.hasPrefix(KotlinSpringBootGeneratedTextFile.managedHeader) else {
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
}

private extension ApiModule {
    var allSpringBootUsedDataTypes: [ApiTypeSchema] {
        references + definitions.flatMap(\.allSpringBootUsedDataTypes)
    }

    var allSpringBootDataTypes: [ApiTypeSchema] {
        references + definitions.flatMap(\.allSpringBootDataTypes)
    }
}

private extension ApiService {
    var allSpringBootUsedDataTypes: [ApiTypeSchema] {
        referencedTypes + springBootRoutableOperations.flatMap(\.usedSpringBootDataTypes)
    }

    var allSpringBootDataTypes: [ApiTypeSchema] {
        referencedTypes + springBootOperationDeclaredTypes
    }

    var springBootOperationDeclaredTypes: [ApiTypeSchema] {
        springBootRoutableOperations.flatMap(\.declaredSpringBootDataTypes)
    }

    var springBootRoutableOperations: [ApiOperation] {
        operations.filter(\.isSpringBootRoutable)
    }
}

private extension ApiOperation {
    var isSpringBootRoutable: Bool {
        switch path {
            case .relative:
                true
            case .absolute,
                 .runtime:
                false
        }
    }

    var usedSpringBootDataTypes: [ApiTypeSchema] {
        [request.dataType, response.dataType].compactMap(\.self)
            + parameters.flatMap(\.usedSpringBootDataTypes)
    }

    var declaredSpringBootDataTypes: [ApiTypeSchema] {
        [request.dataType, response.dataType].compactMap(\.self).flatMap(\.declaredSpringBootDataTypes)
            + parameters.flatMap(\.declaredSpringBootDataTypes)
    }
}

private extension ApiRequestBody {
    var hasSpringBootBody: Bool {
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

private extension Int {
    var isHttpBodylessStatus: Bool {
        (100 ..< 200).contains(self) || self == 204 || self == 205 || self == 304
    }
}

private extension ApiParameter {
    var usedSpringBootDataTypes: [ApiTypeSchema] {
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

    var declaredSpringBootDataTypes: [ApiTypeSchema] {
        switch dataType {
            case let .stringEnumValue(type, _),
                 let .stringEnumArray(type, _),
                 let .intEnumValue(type, _),
                 let .intEnumArray(type, _):
                type.declaredSpringBootDataTypes
            default:
                []
        }
    }
}

private extension ApiTypeSchema {
    var isKotlinSpringBootReferenceable: Bool {
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

    var declaredSpringBootDataTypes: [ApiTypeSchema] {
        switch self {
            case .object,
                 .stringEnum,
                 .intEnum,
                 .dynamicObject:
                [self]
            case let .array(type),
                 let .keyedByString(type, _):
                type.declaredSpringBootDataTypes
            case let .reference(_, _, _, _, dataType):
                dataType?.declaredSpringBootDataTypes ?? []
            case let .genericReference(_, types):
                types.flatMap(\.declaredSpringBootDataTypes)
            default:
                []
        }
    }

    var needsKotlinSpringBootIdentifiableImport: Bool {
        switch self {
            case let .object(_, properties, protocols, _, _, _):
                let fields = properties.filter(\.publishedAsField)
                return protocols.contains("Identifiable")
                    && fields.contains { $0.propertyName.kotlinSpringBootPropertyName == "id" }
                    || fields.contains { $0.dataType.needsKotlinSpringBootIdentifiableImport }
            case let .dynamicObject(_, _, _, _, objectTypes, _, _, _, _):
                return objectTypes.allSatisfy(\.objectType.supportsKotlinSpringBootDynamicObjectIdentifiable)
                    || objectTypes.contains { $0.objectType.needsKotlinSpringBootIdentifiableImport }
            case .stringEnum,
                 .intEnum:
                return true
            default:
                return false
        }
    }

    private var supportsKotlinSpringBootDynamicObjectIdentifiable: Bool {
        switch self {
            case let .object(_, _, protocols, _, _, _):
                protocols.contains("Identifiable")
            case let .reference(_, _, _, _, dataType):
                dataType?.supportsKotlinSpringBootDynamicObjectIdentifiable ?? false
            case .stringEnum,
                 .intEnum:
                true
            default:
                false
        }
    }

    func externalSpringBootTypeNames(options: KotlinSpringBootGeneratorOptions)
        -> [String] {
        switch self {
            case let .reference(typeName, _, _, _, dataType):
                if options.mapping(for: typeName) != nil {
                    return []
                }
                if let dataType {
                    return dataType.externalSpringBootTypeNames(options: options)
                }
                return [typeName]
            case let .genericReference(typeName, types):
                let current = options.mapping(for: typeName) == nil ? [typeName] : []
                return current + types.flatMap { $0.externalSpringBootTypeNames(options: options) }
            case let .array(type),
                 let .keyedByString(type, _):
                return type.externalSpringBootTypeNames(options: options)
            case let .object(typeName, properties, _, _, _, _):
                if options.mapping(for: typeName) != nil {
                    return []
                }
                return properties.filter(\.publishedAsField).flatMap {
                    $0.dataType.externalSpringBootTypeNames(options: options)
                }
            case let .dynamicObject(typeName, _, _, _, objectTypes, _, _, _, extraProperties):
                if options.mapping(for: typeName) != nil {
                    return []
                }
                return objectTypes.flatMap { $0.objectType.externalSpringBootTypeNames(options: options) }
                    + extraProperties.flatMap {
                        $0.dataType.externalSpringBootTypeNames(options: options)
                    }
            default:
                return []
        }
    }
}
