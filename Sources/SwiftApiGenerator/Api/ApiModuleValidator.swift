import Foundation
import GeneratorModels

struct ApiModuleValidator {
    let module: ApiModule

    /// Validate the global types
    func validate(globalTypes: [ApiTypeSchema]) throws {
        // Check for non referenceable
        guard module.references.allSatisfy(\.isReferenceable) else {
            throw ApiValidationError.failed("Top Label Global Types references are not all referenceable: \(module.references.filter { !$0.isReferenceable }.map(\.typeName))")
        }

        // Check for non referenceable
        for reference in module.references {
            try ApiTypeSchemaValidator(dataType: reference).validate()
        }

        // perform on all sub definitions
        let allReferences = module.references + globalTypes

        // Check for duplicates
        let defNames = module.definitions.map { $0.swiftApiTypeName(moduleName: module.name) }
        if Set(defNames).count != defNames.count {
            throw ApiValidationError.failed("Duplicate ApiService found: \(defNames)")
        }

        for definition in module.definitions {
            try ApiServiceValidator(definition: definition).validate(globalTypes: allReferences, moduleName: module.name)
        }
    }
}
