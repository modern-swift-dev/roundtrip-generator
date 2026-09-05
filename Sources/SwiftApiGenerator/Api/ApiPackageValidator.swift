import Foundation
import GeneratorModels

public struct ApiPackageValidator {
    public let package: ApiPackage

    public init(package: ApiPackage) {
        self.package = package
    }

    public func validate() throws {
        // Validate Data-Type Unicity
        try validatePackageLevel()
        try validateGeneratedModuleNames()
        for module in package.modules {
            try validateModuleLevel(module: module)

            for api in module.definitions {
                try validateApiLevel(module: module, api: api)

                for operation in api.operations {
                    try validateOperationLevel(module: module, api: api, operation: operation)
                }
            }
        }

        // Check for non referenceable
        let globalReferences = package.commonReferences + package.references

        for reference in globalReferences {
            try ApiTypeSchemaValidator(dataType: reference).validate()
        }

        // perform on all sub definitions
        for module in package.referencedModules + package.modules {
            try ApiModuleValidator(module: module)
                .validate(globalTypes: globalReferences)
        }
    }

    private func validateGeneratedModuleNames() throws {
        let modulesWithDefinitions = (package.referencedModules + package.modules).filter { !$0.definitions.isEmpty }
        let moduleTypes = modulesWithDefinitions.map(\.swiftApiModuleTypeName)
        if Set(moduleTypes).count != moduleTypes.count {
            throw ApiValidationError.failed("Duplicate generated ApiModule types found for package \(package.name): \(moduleTypes)")
        }

        let moduleProperties = modulesWithDefinitions.map(\.swiftModulePropertyName)
        if Set(moduleProperties).count != moduleProperties.count {
            throw ApiValidationError.failed("Duplicate generated ApiModule properties found for package \(package.name): \(moduleProperties)")
        }
    }

    @discardableResult private func validatePackageLevel() throws -> Set<UUID> {
        let allDataTypes: [ApiTypeSchema] = package.commonReferences + package.references
        guard allDataTypes.allSatisfy(\.isReferenceable) else {
            throw ApiValidationError.failed("Package \(package.name) references are not all referenceable: \(allDataTypes.filter { !$0.isReferenceable }.map(\.typeName))")
        }

        if allDataTypes.hasDuplicates {
            throw ApiValidationError.failed("Duplicate ApiTypeSchemas found for package \(package.name): \(allDataTypes.map { ApiTypeSchemaGenerator(dataType: $0).swiftTypeDeclaration })")
        }

        if allDataTypes.hasDuplicateDeclarations {
            throw ApiValidationError.failed("Duplicate ApiTypeSchemas found for package \(package.name): \(allDataTypes.map { ApiTypeSchemaGenerator(dataType: $0).swiftTypeDeclaration })")
        }

        return Set(allDataTypes.compactMap(\.uuid))
    }

    @discardableResult private func validateModuleLevel(module: ApiModule) throws -> Set<UUID> {
        let allDataTypes: [ApiTypeSchema] = module.references
        if allDataTypes.hasDuplicates {
            throw ApiValidationError.failed("Duplicate ApiTypeSchemas found for module \(module.name): \(allDataTypes.map { ApiTypeSchemaGenerator(dataType: $0).swiftTypeDeclaration })")
        }

        if allDataTypes.hasDuplicateDeclarations {
            throw ApiValidationError.failed("Duplicate ApiTypeSchemas found for module \(module.name): \(allDataTypes.map { ApiTypeSchemaGenerator(dataType: $0).swiftTypeDeclaration })")
        }

        return Set(allDataTypes.compactMap(\.uuid))
    }

    @discardableResult private func validateApiLevel(module: ApiModule, api: ApiService) throws -> Set<UUID> {
        let allDataTypes: [ApiTypeSchema] = api.referencedTypes
        if allDataTypes.hasDuplicates {
            throw ApiValidationError
                .failed("Duplicate ApiTypeSchemas found for service \(api.name) in module \(module.name): \(allDataTypes.map { ApiTypeSchemaGenerator(dataType: $0).swiftTypeDeclaration })")
        }

        if allDataTypes.hasDuplicateDeclarations {
            throw ApiValidationError
                .failed("Duplicate ApiTypeSchemas found for service \(api.name) in module \(module.name): \(allDataTypes.map { ApiTypeSchemaGenerator(dataType: $0).swiftTypeDeclaration })")
        }
        return Set(allDataTypes.compactMap(\.uuid))
    }

    private func validateOperationLevel(module: ApiModule, api: ApiService, operation: ApiOperation) throws {
        let allDataTypes: [ApiTypeSchema] = operation.allDataTypes
        let declaredDataTypes = allDataTypes.filter {
            ApiTypeSchemaGenerator(dataType: $0).getSwiftClass(parentClassName: nil, outputWithExtension: false) != nil
        }
        if declaredDataTypes.hasDuplicates {
            throw ApiValidationError
                .failed(
                    "Duplicate ApiTypeSchemas found for operation \(operation.name) in module \(module.name), and service \(api.name): \(declaredDataTypes.map { ApiTypeSchemaGenerator(dataType: $0).swiftTypeDeclaration })",
                )
        }
        if declaredDataTypes.hasDuplicateDeclarations {
            throw ApiValidationError
                .failed(
                    "Duplicate ApiTypeSchemas found for operation \(operation.name) in module \(module.name), and service \(api.name): \(declaredDataTypes.map { ApiTypeSchemaGenerator(dataType: $0).swiftTypeDeclaration })",
                )
        }
    }
}
