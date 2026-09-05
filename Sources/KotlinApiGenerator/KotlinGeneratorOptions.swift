import Foundation

public struct KotlinGeneratorOptions: Sendable, Equatable {
    public let layout: KotlinProjectLayout
    public let basePackage: String
    public let typeMappings: [KotlinTypeMapping]
    public let gradle: KotlinGradleOptions
    public let generateRuntime: Bool
    public let generateKoinModule: Bool

    public static func standaloneProject(basePackage: String = "com.example.api", gradle: KotlinGradleOptions = .init()) -> Self {
        Self(basePackage: basePackage, gradle: gradle)
    }

    /// Generates sources into an existing module root. The host supplies Gradle configuration and dependencies.
    public static func existingProject(basePackage: String = "com.example.api", generateKoinModule: Bool = false) -> Self {
        Self(basePackage: basePackage, generateKoinModule: generateKoinModule, layout: .existingProject)
    }

    public init(
        basePackage: String = "com.example.api",
        typeMappings: [KotlinTypeMapping] = KotlinTypeMapping.defaultMappings,
        gradle: KotlinGradleOptions = .init(),
        generateRuntime: Bool = true,
        generateKoinModule: Bool = true,
        layout: KotlinProjectLayout = .standaloneProject,
    ) {
        self.layout = layout
        self.basePackage = basePackage
        self.typeMappings = typeMappings
        self.gradle = gradle
        self.generateRuntime = generateRuntime
        self.generateKoinModule = generateKoinModule
    }

    /// Adds a mapping while preserving existing mappings, replacing any mapping for the same API type.
    public func mapping(_ mapping: KotlinTypeMapping) -> Self {
        Self(
            basePackage: basePackage,
            typeMappings: typeMappings.filter { $0.apiTypeName != mapping.apiTypeName } + [mapping],
            gradle: gradle,
            generateRuntime: generateRuntime,
            generateKoinModule: generateKoinModule,
            layout: layout,
        )
    }

    public func mapping(for apiTypeName: String) -> KotlinTypeMapping? {
        typeMappings.first { $0.apiTypeName == apiTypeName }
    }
}

public struct KotlinTypeMapping: Sendable, Equatable {
    public let apiTypeName: String
    public let kotlinType: String
    public let imports: [String]

    public init(apiTypeName: String, kotlinType: String, imports: [String] = []) {
        self.apiTypeName = apiTypeName
        self.kotlinType = kotlinType
        self.imports = imports
    }

    public static let defaultMappings: [KotlinTypeMapping] = [
        .init(apiTypeName: "DateInterval", kotlinType: "DateInterval"),
        .init(apiTypeName: "LocalizedData", kotlinType: "LocalizedData"),
        .init(apiTypeName: "PagedResults", kotlinType: "PagedResults"),
        .init(apiTypeName: "PatchableValue", kotlinType: "PatchableValue")
    ]
}

public struct KotlinGradleOptions: Sendable, Equatable {
    public let projectName: String
    public let moduleName: String
    public let namespace: String?
    public let group: String
    public let version: String
    public let artifactId: String
    public let kotlinVersion: String
    public let androidGradlePluginVersion: String
    public let ktorVersion: String
    public let koinVersion: String
    public let kotlinxSerializationVersion: String
    public let kotlinxDateTimeVersion: String
    public let kotlinxCoroutinesVersion: String
    public let nativeCoroutinesVersion: String
    public let ktlintGradlePluginVersion: String
    public let ktlintVersion: String
    public let compileSdk: Int
    public let minSdk: Int
    public let jvmToolchain: Int
    public let ktlintCodeStyle: KotlinKtlintCodeStyle
    public let overwritePolicy: KotlinGeneratedFileOverwritePolicy

    public init(
        projectName: String = "generated-api",
        moduleName: String = "generated-api",
        namespace: String? = nil,
        group: String = "com.example",
        version: String = "1.0.0",
        artifactId: String = "generated-api",
        kotlinVersion: String = "2.4.0",
        androidGradlePluginVersion: String = "9.2.1",
        ktorVersion: String = "3.5.0",
        koinVersion: String = "4.2.2",
        kotlinxSerializationVersion: String = "1.11.0",
        kotlinxDateTimeVersion: String = "0.8.0",
        kotlinxCoroutinesVersion: String = "1.11.0",
        nativeCoroutinesVersion: String = "1.0.4",
        ktlintGradlePluginVersion: String = "14.2.0",
        ktlintVersion: String = "1.7.1",
        compileSdk: Int = 36,
        minSdk: Int = 23,
        jvmToolchain: Int = 21,
        ktlintCodeStyle: KotlinKtlintCodeStyle = .ktlintOfficial,
        overwritePolicy: KotlinGeneratedFileOverwritePolicy = .replaceManagedFiles,
    ) {
        self.projectName = projectName
        self.moduleName = moduleName
        self.namespace = namespace
        self.group = group
        self.version = version
        self.artifactId = artifactId
        self.kotlinVersion = kotlinVersion
        self.androidGradlePluginVersion = androidGradlePluginVersion
        self.ktorVersion = ktorVersion
        self.koinVersion = koinVersion
        self.kotlinxSerializationVersion = kotlinxSerializationVersion
        self.kotlinxDateTimeVersion = kotlinxDateTimeVersion
        self.kotlinxCoroutinesVersion = kotlinxCoroutinesVersion
        self.nativeCoroutinesVersion = nativeCoroutinesVersion
        self.ktlintGradlePluginVersion = ktlintGradlePluginVersion
        self.ktlintVersion = ktlintVersion
        self.compileSdk = compileSdk
        self.minSdk = minSdk
        self.jvmToolchain = jvmToolchain
        self.ktlintCodeStyle = ktlintCodeStyle
        self.overwritePolicy = overwritePolicy
    }
}

public enum KotlinGeneratedFileOverwritePolicy: Sendable, Equatable {
    case replaceManagedFiles
    case neverOverwriteExisting
}

/// Controls whether generation owns project scaffolding or only generated sources.
public enum KotlinProjectLayout: Sendable, Equatable {
    case standaloneProject
    case existingProject
}
