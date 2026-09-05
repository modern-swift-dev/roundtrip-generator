import Foundation

/// Composes a collection of one schema type, preserving declaration order.
///
/// Use individual values, reusable arrays, conditionals, and loops in schema
/// closures. Each closure accepts only its declared element type.
@resultBuilder
public enum ApiCollectionBuilder<Element> {
    public static func buildExpression(_ expression: Element) -> [Element] { [expression] }
    public static func buildExpression(_ expression: [Element]) -> [Element] { expression }
    public static func buildBlock(_ components: [Element]...) -> [Element] { components.flatMap { $0 } }
    public static func buildOptional(_ component: [Element]?) -> [Element] { component ?? [] }
    public static func buildEither(first component: [Element]) -> [Element] { component }
    public static func buildEither(second component: [Element]) -> [Element] { component }
    public static func buildArray(_ components: [[Element]]) -> [Element] { components.flatMap { $0 } }
    public static func buildLimitedAvailability(_ component: [Element]) -> [Element] { component }
}

public extension ApiTypeSchema {
    /// Declares an object using a typed collection of properties.
    static func object(
        typeName: String,
        protocols: [String] = [],
        imports: [ApiImport] = [],
        isValueType: Bool = true,
        uuid: UUID = .init(),
        @ApiCollectionBuilder<ApiModelProperty> properties: () -> [ApiModelProperty]
    ) -> ApiTypeSchema {
        .object(typeName: typeName, properties: properties(), protocols: protocols, imports: imports, isValueType: isValueType, uuid: uuid)
    }

    /// Declares an object with a concise name and a typed property collection.
    static func object(
        _ typeName: String,
        protocols: [String] = [],
        imports: [ApiImport] = [],
        isValueType: Bool = true,
        uuid: UUID = .init(),
        @ApiCollectionBuilder<ApiModelProperty> properties: () -> [ApiModelProperty]
    ) -> ApiTypeSchema {
        .object(typeName: typeName, protocols: protocols, imports: imports, isValueType: isValueType, uuid: uuid, properties: properties)
    }
}

public extension ApiService {
    /// Declares a service using a typed collection of operations.
    init(name: String, references: [ApiTypeSchema] = [], @ApiCollectionBuilder<ApiOperation> operations: () -> [ApiOperation]) {
        self.init(name: name, operations: operations(), references: references)
    }
}

public extension ApiModule {
    /// Declares a module using a typed collection of API definitions.
    init(name: String, references: [ApiTypeSchema] = [], @ApiCollectionBuilder<ApiService> definitions: () -> [ApiService]) {
        self.init(name: name, definitions: definitions(), references: references)
    }
}

public extension ApiPackage {
    /// Declares a package using a typed collection of modules.
    init(
        name: String,
        targetDirUrl: URL,
        referencedModules: [ApiModule] = [],
        references: [ApiTypeSchema] = [],
        commonReferences: [ApiTypeSchema] = [],
        imports: [ApiImport] = [],
        generateApiModules: Bool = true,
        @ApiCollectionBuilder<ApiModule> modules: () -> [ApiModule]
    ) {
        self.init(name: name, targetDirUrl: targetDirUrl, modules: modules(), referencedModules: referencedModules, references: references, commonReferences: commonReferences, imports: imports, generateApiModules: generateApiModules)
    }
}

public extension ApiRestResourceGroup {
    /// Declares a group using a typed collection of REST resources.
    convenience init(
        name: String = "",
        references: [ApiTypeSchema] = [],
        parameters: [ApiParameter] = [],
        @ApiCollectionBuilder<ApiRestResource> resources: () -> [ApiRestResource]
    ) {
        self.init(name: name, references: references, parameters: parameters, resources: resources())
    }
}
