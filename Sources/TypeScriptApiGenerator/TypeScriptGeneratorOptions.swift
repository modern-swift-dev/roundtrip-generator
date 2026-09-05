import Foundation

public struct TypeScriptGeneratorOptions: Sendable, Equatable {
    public let layout: TypeScriptProjectLayout
    public let packageName: String
    public let packageVersion: String
    public let sourceDirectory: String
    public let typeMappings: [TypeScriptTypeMapping]
    public let generateRuntime: Bool
    public let flavor: TypeScriptGeneratorFlavor
    public let overwritePolicy: TypeScriptGeneratedFileOverwritePolicy

    public static func standaloneProject(packageName: String = "generated-api", sourceDirectory: String = "src/generated", flavor: TypeScriptGeneratorFlavor = .plain) -> Self {
        Self(packageName: packageName, sourceDirectory: sourceDirectory, flavor: flavor)
    }

    /// Generates sources only. The host supplies TypeScript configuration and any flavor dependencies.
    public static func existingProject(sourceDirectory: String = "src/generated", flavor: TypeScriptGeneratorFlavor = .plain) -> Self {
        Self(sourceDirectory: sourceDirectory, flavor: flavor, layout: .existingProject)
    }

    public init(
        packageName: String = "generated-api",
        packageVersion: String = "1.0.0",
        sourceDirectory: String = "src/generated",
        typeMappings: [TypeScriptTypeMapping] = TypeScriptTypeMapping.defaultMappings,
        generateRuntime: Bool = true,
        flavor: TypeScriptGeneratorFlavor = .plain,
        overwritePolicy: TypeScriptGeneratedFileOverwritePolicy = .replaceManagedFiles,
        layout: TypeScriptProjectLayout = .standaloneProject
    ) {
        self.layout = layout
        self.packageName = packageName
        self.packageVersion = packageVersion
        self.sourceDirectory = sourceDirectory
        self.typeMappings = typeMappings
        self.generateRuntime = generateRuntime
        self.flavor = flavor
        self.overwritePolicy = overwritePolicy
    }

    /// Adds a mapping while preserving existing mappings, replacing any mapping for the same API type.
    public func mapping(_ mapping: TypeScriptTypeMapping) -> Self {
        Self(
            packageName: packageName,
            packageVersion: packageVersion,
            sourceDirectory: sourceDirectory,
            typeMappings: typeMappings.filter { $0.apiTypeName != mapping.apiTypeName } + [mapping],
            generateRuntime: generateRuntime,
            flavor: flavor,
            overwritePolicy: overwritePolicy,
            layout: layout
        )
    }

    public func mapping(for apiTypeName: String) -> TypeScriptTypeMapping? {
        typeMappings.first { $0.apiTypeName == apiTypeName }
    }
}

public enum TypeScriptGeneratorFlavor: Sendable, Equatable {
    case plain
    case tanStackQuery
}

public struct TypeScriptTypeMapping: Sendable, Equatable {
    public let apiTypeName: String
    public let typeScriptType: String
    public let imports: [String]

    public init(apiTypeName: String, typeScriptType: String, imports: [String] = []) {
        self.apiTypeName = apiTypeName
        self.typeScriptType = typeScriptType
        self.imports = imports
    }

    public static let defaultMappings: [TypeScriptTypeMapping] = [
        .init(apiTypeName: "DateInterval", typeScriptType: "DateInterval"),
        .init(apiTypeName: "LocalizedData", typeScriptType: "LocalizedData"),
        .init(apiTypeName: "PagedResults", typeScriptType: "PagedResults"),
        .init(apiTypeName: "PatchableValue", typeScriptType: "PatchableValue")
    ]
}

public enum TypeScriptGeneratedFileOverwritePolicy: Sendable, Equatable {
    case replaceManagedFiles
    case neverOverwriteExisting
}

/// Controls whether generation owns project scaffolding or only generated sources.
public enum TypeScriptProjectLayout: Sendable, Equatable {
    case standaloneProject
    case existingProject
}
