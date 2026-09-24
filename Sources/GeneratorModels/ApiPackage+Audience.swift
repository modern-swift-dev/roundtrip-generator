import Foundation

public extension ApiPackage {
    /// Removes backend-only operations and models reachable exclusively from them.
    /// Independently declared models and dependencies shared with client operations remain.
    var clientAudiencePackage: ApiPackage {
        let allModules = modules + referencedModules
        let operations = allModules.flatMap(\.definitions).flatMap(\.operations)
        guard operations.contains(where: { $0.audience == .backendOnly }) else {
            return self
        }
        let declarations = references + commonReferences + allModules.flatMap { module in
            module.references + module.definitions.flatMap(\.referencedTypes)
        }
        let catalog = Dictionary(declarations.compactMap { type in type.uuid.map { ($0, type) } }, uniquingKeysWith: { first, _ in first })
        let backendDefinitions = allModules.flatMap(\.definitions).filter { !$0.operations.isEmpty && $0.operations.allSatisfy { $0.audience == .backendOnly } }
        let backendTypes = audienceTypeIDs(operations.filter { $0.audience == .backendOnly }.flatMap(\.audienceDataTypes) + backendDefinitions.flatMap(\.referencedTypes), catalog: catalog)
        let standalone = declarations.filter { type in type.uuid.map { !backendTypes.contains($0) } ?? true }
        let clientTypes = audienceTypeIDs(operations.filter { $0.audience == .all }.flatMap(\.audienceDataTypes) + standalone, catalog: catalog)
        let excluded = backendTypes.subtracting(clientTypes)
        func keep(_ type: ApiTypeSchema) -> Bool {
            type.uuid.map { !excluded.contains($0) } ?? true
        }
        func project(_ module: ApiModule) -> ApiModule? {
            let definitions = module.definitions.compactMap { definition -> ApiService? in
                if !definition.operations.isEmpty && definition.operations.allSatisfy({ $0.audience == .backendOnly }) {
                    return nil
                }
                let visible = definition.operations.filter { $0.audience == .all }
                let types = definition.referencedTypes.filter(keep)
                guard !visible.isEmpty || !types.isEmpty else {
                    return nil
                }
                return ApiService(name: definition.name, operations: visible, references: types)
            }
            var existingIDs = Set((references + commonReferences + module.references + definitions.flatMap(\.referencedTypes)).compactMap(\.uuid))
            let promoted = module.definitions.filter { !$0.operations.isEmpty && $0.operations.allSatisfy { $0.audience == .backendOnly } }
                .flatMap(\.referencedTypes).filter { type in
                    guard keep(type) else {
                        return false
                    }
                    return type.uuid.map { existingIDs.insert($0).inserted } ?? true
                }
            let types = module.references.filter(keep) + promoted
            guard !definitions.isEmpty || !types.isEmpty else {
                return nil
            }
            return ApiModule(name: module.name, definitions: definitions, references: types)
        }
        return ApiPackage(
            name: name,
            targetDirUrl: targetDirUrl,
            modules: modules.compactMap(project),
            referencedModules: referencedModules.compactMap(project),
            references: references.filter(keep),
            commonReferences: commonReferences.filter(keep),
            imports: imports,
            generateApiModules: generateApiModules,
        )
    }
}

private extension ApiOperation {
    var audienceDataTypes: [ApiTypeSchema] {
        [request.dataType, response.dataType].compactMap(\.self)
            + successResponses.compactMap(\.response.dataType)
            + publicErrors.compactMap(\.response.dataType)
            + parameters.compactMap { parameter in
                switch parameter.dataType {
                    case let .stringEnumValue(type, _),
                         let .stringEnumArray(type, _),
                         let .intEnumValue(type, _),
                         let .intEnumArray(type, _): type
                    default: nil
                }
            }
    }
}

private func audienceTypeIDs(_ roots: [ApiTypeSchema], catalog: [UUID: ApiTypeSchema]) -> Set<UUID> {
    var visited: Set<UUID> = []
    func visit(_ type: ApiTypeSchema) {
        if let id = type.uuid, !visited.insert(id).inserted {
            return
        }
        switch type {
            case let .reference(_, _, _, id, embedded):
                if let definition = embedded ?? catalog[id] {
                    visit(definition)
                } else {
                    visited.insert(id)
                }
            case let .object(_, properties, _, _, _, _):
                properties.forEach { visit($0.dataType) }
            case let .dynamicObject(_, _, _, _, types, _, _, _, properties):
                types.forEach { visit($0.objectType) }
                properties.forEach { visit($0.dataType) }
            case let .array(element),
                 let .keyedByString(element, _):
                visit(element)
            case let .genericReference(_, arguments):
                arguments.forEach(visit)
            default: break
        }
    }
    roots.forEach(visit)
    return visited
}
