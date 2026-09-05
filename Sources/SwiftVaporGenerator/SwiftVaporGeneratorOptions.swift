import Foundation

public struct SwiftVaporGeneratorOptions: Sendable, Equatable {
    public let layout: SwiftVaporProjectLayout
    public let appName: String
    public let moduleName: String
    public let swiftToolsVersion: String
    public let vaporVersion: String
    public let additionalPackageDependencies: [String]
    public let additionalTargetDependencies: [String]
    public let overwritePolicy: SwiftVaporGeneratedFileOverwritePolicy
    public let generatePackage: Bool
    public let generateRunTarget: Bool
    public let generateDockerfile: Bool

    public static func standaloneProject(appName: String = "GeneratedApi", moduleName: String = "App") -> Self {
        Self(appName: appName, moduleName: moduleName)
    }

    /// Generates route and model sources. The host configures Vapor and registers the generated routes.
    public static func existingProject(moduleName: String = "App") -> Self {
        Self(moduleName: moduleName, generatePackage: false, generateRunTarget: false, generateDockerfile: false, layout: .existingProject)
    }

    public init(
        appName: String = "GeneratedApi",
        moduleName: String = "App",
        swiftToolsVersion: String = "6.0",
        vaporVersion: String = "4.121.4",
        additionalPackageDependencies: [String] = [],
        additionalTargetDependencies: [String] = [],
        overwritePolicy: SwiftVaporGeneratedFileOverwritePolicy = .replaceManagedFiles,
        generatePackage: Bool = true,
        generateRunTarget: Bool = true,
        generateDockerfile: Bool = true,
        layout: SwiftVaporProjectLayout = .standaloneProject
    ) {
        self.layout = layout
        self.appName = appName
        self.moduleName = moduleName
        self.swiftToolsVersion = swiftToolsVersion
        self.vaporVersion = vaporVersion
        self.additionalPackageDependencies = additionalPackageDependencies
        self.additionalTargetDependencies = additionalTargetDependencies
        self.overwritePolicy = overwritePolicy
        self.generatePackage = generatePackage
        self.generateRunTarget = generateRunTarget
        self.generateDockerfile = generateDockerfile
    }
}

public enum SwiftVaporGeneratedFileOverwritePolicy: Sendable, Equatable {
    case replaceManagedFiles
    case neverOverwriteExisting
}

/// Controls whether generation owns project scaffolding or only generated sources.
public enum SwiftVaporProjectLayout: Sendable, Equatable {
    case standaloneProject
    case existingProject
}
