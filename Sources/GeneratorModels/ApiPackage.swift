import Foundation

/// `ApiPackage` is the top-level construct for an API definition, declaring
/// modules, generated shared data types, parent-package data types, and imports.
///
/// Target-specific generators decide whether to emit project scaffolding.
/// Swift client generation emits source files; the consuming project owns its manifest.
public struct ApiPackage: Sendable {

    /// The package name.
    public let name: String

    /// The list of modules to generate.
    public let modules: [ApiModule]

    /// Modules from parent packages whose generated types can be referenced.
    public let referencedModules: [ApiModule]

    /// Shared data types generated at the package root.
    public let references: [ApiTypeSchema]

    /// Shared data types supplied by parent packages.
    public let commonReferences: [ApiTypeSchema]

    /// The directory where generated REST code is written.
    ///
    /// > A file URL is required.
    public let targetDirUrl: URL

    /// Imports added to generated files.
    ///
    /// > Add imports required by generated code, such as external package modules.
    public let imports: [ApiImport]

    /// Controls generation of the package-level API modules container.
    public let generateApiModules: Bool

    /// Initializer
    ///
    /// - parameter name: The package name. Ex: `Api`
    /// - parameter targetDirUrl: The target directory `URL` for code generation.
    /// - parameter modules: The list of modules for the package.
    /// - parameter referencedModules: The list of referenced modules for the package.
    /// - parameter references: Shared data types generated at the package root.
    /// - parameter commonReferences: Shared data types supplied by parent packages.
    /// - parameter imports: Imports added to generated files. Ex: `["Foundation"]`
    /// - parameter generateApiModules: Whether to generate the package-level API modules container.
    public init(
        name: String,
        targetDirUrl: URL,
        modules: [ApiModule],
        referencedModules: [ApiModule] = [],
        references: [ApiTypeSchema] = [],
        commonReferences: [ApiTypeSchema] = [],
        imports: [ApiImport] = [],
        generateApiModules: Bool = true
    ) {
        self.name = name
        self.referencedModules = referencedModules
        self.modules = modules
        self.references = references
        self.targetDirUrl = targetDirUrl
        self.commonReferences = commonReferences
        self.imports = imports
        self.generateApiModules = generateApiModules
    }

    /// Returns the same API contract configured for another output directory.
    /// Model identities and reference scopes are preserved.
    public func output(to directory: URL) -> ApiPackage {
        ApiPackage(
            name: name,
            targetDirUrl: directory,
            modules: modules,
            referencedModules: referencedModules,
            references: references,
            commonReferences: commonReferences,
            imports: imports,
            generateApiModules: generateApiModules
        )
    }

}

public extension ApiOperation {
    class predefined {}
}

public extension ApiTypeSchema {
    class predefined {}
}

public extension ApiModelProperty {
    class predefined {}
}

public extension ApiParameter {
    class predefined {

        /// Required `Authorization` HTTP header for secured API calls.
        public static let apiKey: ApiParameter = .header("Authorization", .string(""), propertyName: "apiKey")

        /// Optional `Authorization` HTTP header for optionally secured API calls.
        public static let optionalApiKey: ApiParameter = .header("Authorization", .string(), propertyName: "apiKey").optional

    }
}
