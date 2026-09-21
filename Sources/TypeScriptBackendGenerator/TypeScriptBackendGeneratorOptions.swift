import Foundation

public enum TypeScriptBackendProjectLayout: Sendable, Equatable {
    case standaloneProject
    case existingProject
}

public enum TypeScriptBackendGeneratedFileOverwritePolicy: Sendable, Equatable {
    case neverOverwriteExisting
    case replaceManagedFiles
}

public struct TypeScriptBackendGeneratorOptions: Sendable, Equatable {
    public let layout: TypeScriptBackendProjectLayout
    public let packageName: String
    public let packageVersion: String
    public let sourceDirectory: String
    public let overwritePolicy: TypeScriptBackendGeneratedFileOverwritePolicy

    public init(
        packageName: String = "generated-backend",
        packageVersion: String = "1.0.0",
        sourceDirectory: String = "src/generated",
        overwritePolicy: TypeScriptBackendGeneratedFileOverwritePolicy = .replaceManagedFiles,
        layout: TypeScriptBackendProjectLayout = .standaloneProject,
    ) {
        self.layout = layout
        self.packageName = packageName
        self.packageVersion = packageVersion
        self.sourceDirectory = sourceDirectory
        self.overwritePolicy = overwritePolicy
    }

    public static func standaloneProject(
        packageName: String = "generated-backend",
        sourceDirectory: String = "src/generated",
    ) -> Self {
        Self(packageName: packageName, sourceDirectory: sourceDirectory)
    }

    public static func existingProject(sourceDirectory: String = "src/generated") -> Self {
        Self(sourceDirectory: sourceDirectory, layout: .existingProject)
    }
}
