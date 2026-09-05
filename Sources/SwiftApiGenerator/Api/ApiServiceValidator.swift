import Foundation
import GeneratorModels

struct ApiServiceValidator {
    let definition: ApiService

    /// Minimal validation
    func validate(globalTypes: [ApiTypeSchema] = [], moduleName: String? = nil) throws {
        // Check for non referenceable
        guard definition.referencedTypes.allSatisfy(\.isReferenceable) else {
            throw ApiValidationError.failed("ApiService \(definition.name) references are not all referenceable: \(definition.referencedTypes.filter { !$0.isReferenceable }.map(\.typeName))")
        }

        // Check for non referenceable
        for referencedType in definition.referencedTypes {
            try ApiTypeSchemaValidator(dataType: referencedType).validate()
        }

        // Check for duplicates!
        let typeNames = definition.referencedTypes.compactMap(\.typeName)
        let typeNameSet = Set(typeNames)
        if typeNameSet.count != typeNames.count {
            throw ApiValidationError.failed("ApiService \(definition.name) contains duplicated referenced types")
        }

        // Check for non existing references!
        let operationReferences = definition.operations.flatMap { operation in
            operation.allReferences.map { (operation: operation.typeName, reference: $0) }
        }
        let scopedTypes = definition.referencedTypes + globalTypes
        let scopedUUIDs = Set(scopedTypes.compactMap(\.uuid))
        let scopedNames = Set(scopedTypes.compactMap(\.typeName))
        let missingReferences = operationReferences.filter { entry in
            let reference = entry.reference
            if let uuid = reference.referenceUUID {
                if scopedUUIDs.contains(uuid) {
                    return false
                }
                if reference.resolvedReferenceDataType != nil {
                    return true
                }
            }
            if let uuid = reference.uuid {
                return !scopedUUIDs.contains(uuid)
            }
            guard let name = reference.typeName else {
                return false
            }
            return !typeNameSet.contains(name) && !scopedNames.contains(name)
        }
        if !missingReferences.isEmpty {
            let scope = moduleName.map { "Module \($0), " } ?? ""
            let details = missingReferences.map { entry in
                let name = entry.reference.typeName ?? "<unnamed>"
                let mismatch = scopedNames.contains(name)
                    ? " A type with this name is registered but has a different UUID; reuse the same ApiTypeSchema value when creating .asRef and registering it."
                    : ""
                return "\(scope)ApiService \(definition.name), operation \(entry.operation): missing reference \(name). Register the type in ApiService.references, ApiModule.references, or ApiPackage.references; use ApiPackage.commonReferences for types supplied by another package.\(mismatch)"
            }
            throw ApiValidationError.failed(details.joined(separator: "\n"))
        }

        // Check for duplicates!
        let opNames = definition.operations.map(\.typeName)
        if Set(opNames).count != opNames.count {
            throw ApiValidationError.failed("ApiService \(definition.name) contains duplicated operations: \(opNames)")
        }

        // Validate at the operation level
        for operation in definition.operations {
            try ApiOperationValidator(operation: operation).validate()
        }
    }
}

private extension ApiTypeSchema {
    var resolvedReferenceDataType: ApiTypeSchema? {
        switch self {
            case let .reference(_, _, _, _, dataType):
                dataType
            default:
                nil
        }
    }
}
