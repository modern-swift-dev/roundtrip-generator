import Foundation

public struct KotlinSpringBootGeneratorOptions: Sendable, Equatable {
    public let layout: KotlinSpringBootProjectLayout
    public let basePackage: String
    public let applicationName: String
    public let typeMappings: [KotlinSpringBootTypeMapping]
    public let gradle: KotlinSpringBootGradleOptions
    public let generateApplication: Bool
    public let generateRuntime: Bool
    public let overwritePolicy: KotlinSpringBootGeneratedFileOverwritePolicy

    public static func standaloneProject(basePackage: String = "com.example.api", applicationName: String = "GeneratedApiApplication", gradle: KotlinSpringBootGradleOptions = .init()) -> Self {
        Self(basePackage: basePackage, applicationName: applicationName, gradle: gradle)
    }

    /// Generates sources into an existing project root. The host supplies the application and Gradle dependencies.
    public static func existingProject(basePackage: String = "com.example.api") -> Self {
        Self(basePackage: basePackage, generateApplication: false, layout: .existingProject)
    }

    public init(
        basePackage: String = "com.example.api",
        applicationName: String = "GeneratedApiApplication",
        typeMappings: [KotlinSpringBootTypeMapping] = KotlinSpringBootTypeMapping.defaultMappings,
        gradle: KotlinSpringBootGradleOptions = .init(),
        generateApplication: Bool = true,
        generateRuntime: Bool = true,
        overwritePolicy: KotlinSpringBootGeneratedFileOverwritePolicy = .replaceManagedFiles,
        layout: KotlinSpringBootProjectLayout = .standaloneProject
    ) {
        self.layout = layout
        self.basePackage = basePackage
        self.applicationName = applicationName
        self.typeMappings = typeMappings
        self.gradle = gradle
        self.generateApplication = generateApplication
        self.generateRuntime = generateRuntime
        self.overwritePolicy = overwritePolicy
    }

    /// Adds a mapping while preserving existing mappings, replacing any mapping for the same API type.
    public func mapping(_ mapping: KotlinSpringBootTypeMapping) -> Self {
        Self(
            basePackage: basePackage,
            applicationName: applicationName,
            typeMappings: typeMappings.filter { $0.apiTypeName != mapping.apiTypeName } + [mapping],
            gradle: gradle,
            generateApplication: generateApplication,
            generateRuntime: generateRuntime,
            overwritePolicy: overwritePolicy,
            layout: layout
        )
    }

    func mapping(for apiTypeName: String) -> KotlinSpringBootTypeMapping? {
        typeMappings.first { $0.apiTypeName == apiTypeName }
    }
}

public struct KotlinSpringBootTypeMapping: Sendable, Equatable {
    public let apiTypeName: String
    public let kotlinType: String
    public let imports: [String]

    public init(apiTypeName: String, kotlinType: String, imports: [String] = []) {
        self.apiTypeName = apiTypeName
        self.kotlinType = kotlinType
        self.imports = imports
    }

    public static let defaultMappings: [KotlinSpringBootTypeMapping] = [
        .init(apiTypeName: "DateInterval", kotlinType: "DateInterval"),
        .init(apiTypeName: "LocalizedData", kotlinType: "LocalizedData"),
        .init(apiTypeName: "PagedResults", kotlinType: "PagedResults"),
        .init(apiTypeName: "PatchableValue", kotlinType: "PatchableValue")
    ]
}

public struct KotlinSpringBootGradleOptions: Sendable, Equatable {
    public let projectName: String
    public let group: String
    public let version: String
    public let springBootVersion: String
    public let kotlinVersion: String
    public let dependencyManagementVersion: String
    public let kotlinxSerializationVersion: String
    public let kotlinxDateTimeVersion: String
    public let ktlintGradlePluginVersion: String
    public let ktlintVersion: String
    public let jvmToolchain: Int
    public let ktlintCodeStyle: KotlinSpringBootKtlintCodeStyle

    public init(
        projectName: String = "generated-api",
        group: String = "com.example",
        version: String = "1.0.0",
        springBootVersion: String = "4.1.0",
        kotlinVersion: String = "2.4.0",
        dependencyManagementVersion: String = "1.1.7",
        kotlinxSerializationVersion: String = "1.11.0",
        kotlinxDateTimeVersion: String = "0.8.0",
        ktlintGradlePluginVersion: String = "14.2.0",
        ktlintVersion: String = "1.7.1",
        jvmToolchain: Int = 21,
        ktlintCodeStyle: KotlinSpringBootKtlintCodeStyle = .ktlintOfficial
    ) {
        self.projectName = projectName
        self.group = group
        self.version = version
        self.springBootVersion = springBootVersion
        self.kotlinVersion = kotlinVersion
        self.dependencyManagementVersion = dependencyManagementVersion
        self.kotlinxSerializationVersion = kotlinxSerializationVersion
        self.kotlinxDateTimeVersion = kotlinxDateTimeVersion
        self.ktlintGradlePluginVersion = ktlintGradlePluginVersion
        self.ktlintVersion = ktlintVersion
        self.jvmToolchain = jvmToolchain
        self.ktlintCodeStyle = ktlintCodeStyle
    }
}

public enum KotlinSpringBootKtlintCodeStyle: String, Sendable, Equatable {
    case ktlintOfficial = "ktlint_official"
    case intellijIdea = "intellij_idea"
}

public enum KotlinSpringBootGeneratedFileOverwritePolicy: Sendable, Equatable {
    case replaceManagedFiles
    case neverOverwriteExisting
}

/// Controls whether generation owns project scaffolding or only generated sources.
public enum KotlinSpringBootProjectLayout: Sendable, Equatable {
    case standaloneProject
    case existingProject
}
