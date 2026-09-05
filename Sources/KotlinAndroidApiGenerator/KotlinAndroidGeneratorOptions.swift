import Foundation

public struct KotlinAndroidGeneratorOptions: Sendable, Equatable {
    public let layout: KotlinAndroidProjectLayout
    public let basePackage: String
    public let typeMappings: [KotlinAndroidTypeMapping]
    public let gradle: KotlinAndroidGradleOptions
    public let generateRuntime: Bool
    public let generateKoinModule: Bool
    public let generateMocks: Bool

    public static func standaloneProject(basePackage: String = "com.example.api", gradle: KotlinAndroidGradleOptions = .init()) -> Self {
        Self(basePackage: basePackage, gradle: gradle)
    }

    /// Generates sources into an existing module root. The host supplies Gradle configuration and dependencies.
    public static func existingProject(basePackage: String = "com.example.api", generateKoinModule: Bool = false) -> Self {
        Self(basePackage: basePackage, generateKoinModule: generateKoinModule, layout: .existingProject)
    }

    public init(
        basePackage: String = "com.example.api",
        typeMappings: [KotlinAndroidTypeMapping] = KotlinAndroidTypeMapping.defaultMappings,
        gradle: KotlinAndroidGradleOptions = .init(),
        generateRuntime: Bool = true,
        generateKoinModule: Bool = false,
        generateMocks: Bool = false,
        layout: KotlinAndroidProjectLayout = .standaloneProject,
    ) {
        self.layout = layout
        self.basePackage = basePackage
        self.typeMappings = typeMappings
        self.gradle = gradle
        self.generateRuntime = generateRuntime
        self.generateKoinModule = generateKoinModule
        self.generateMocks = generateMocks
    }

    /// Adds a mapping while preserving existing mappings, replacing any mapping for the same API type.
    public func mapping(_ mapping: KotlinAndroidTypeMapping) -> Self {
        Self(
            basePackage: basePackage,
            typeMappings: typeMappings.filter { $0.apiTypeName != mapping.apiTypeName } + [mapping],
            gradle: gradle,
            generateRuntime: generateRuntime,
            generateKoinModule: generateKoinModule,
            generateMocks: generateMocks,
            layout: layout,
        )
    }

    public func mapping(for apiTypeName: String) -> KotlinAndroidTypeMapping? {
        typeMappings.first { $0.apiTypeName == apiTypeName }
    }
}

public struct KotlinAndroidTypeMapping: Sendable, Equatable {
    public let apiTypeName: String
    public let kotlinType: String
    public let imports: [String]

    public init(apiTypeName: String, kotlinType: String, imports: [String] = []) {
        self.apiTypeName = apiTypeName
        self.kotlinType = kotlinType
        self.imports = imports
    }

    public static let defaultMappings: [KotlinAndroidTypeMapping] = [
        .init(apiTypeName: "DateInterval", kotlinType: "DateInterval"),
        .init(apiTypeName: "LocalizedData", kotlinType: "LocalizedData"),
        .init(apiTypeName: "PagedResults", kotlinType: "PagedResults"),
        .init(apiTypeName: "PatchableValue", kotlinType: "PatchableValue")
    ]
}

public struct KotlinAndroidGradleOptions: Sendable, Equatable {
    public let projectName: String
    public let moduleName: String
    public let namespace: String?
    public let group: String
    public let version: String
    public let artifactId: String
    public let kotlinVersion: String
    public let androidGradlePluginVersion: String
    public let retrofitVersion: String
    public let okHttpVersion: String
    public let koinVersion: String
    public let kotlinxSerializationVersion: String
    public let kotlinxDateTimeVersion: String
    public let kotlinxCoroutinesVersion: String
    public let robolectricVersion: String
    public let junitVersion: String
    public let desugarJdkLibsVersion: String
    public let ktlintGradlePluginVersion: String
    public let ktlintVersion: String
    public let compileSdk: Int
    public let minSdk: Int
    public let jvmToolchain: Int
    public let ktlintCodeStyle: KotlinAndroidKtlintCodeStyle
    public let overwritePolicy: KotlinAndroidGeneratedFileOverwritePolicy

    public init(
        projectName: String = "generated-api",
        moduleName: String = "generated-api",
        namespace: String? = nil,
        group: String = "com.example",
        version: String = "1.0.0",
        artifactId: String = "generated-api",
        kotlinVersion: String = "2.4.0",
        androidGradlePluginVersion: String = "9.2.1",
        retrofitVersion: String = "3.0.0",
        okHttpVersion: String = "4.12.0",
        koinVersion: String = "4.2.2",
        kotlinxSerializationVersion: String = "1.11.0",
        kotlinxDateTimeVersion: String = "0.8.0",
        kotlinxCoroutinesVersion: String = "1.11.0",
        robolectricVersion: String = "4.16.1",
        junitVersion: String = "4.13.2",
        desugarJdkLibsVersion: String = "2.1.5",
        ktlintGradlePluginVersion: String = "14.2.0",
        ktlintVersion: String = "1.7.1",
        compileSdk: Int = 36,
        minSdk: Int = 23,
        jvmToolchain: Int = 21,
        ktlintCodeStyle: KotlinAndroidKtlintCodeStyle = .ktlintOfficial,
        overwritePolicy: KotlinAndroidGeneratedFileOverwritePolicy = .replaceManagedFiles,
    ) {
        self.projectName = projectName
        self.moduleName = moduleName
        self.namespace = namespace
        self.group = group
        self.version = version
        self.artifactId = artifactId
        self.kotlinVersion = kotlinVersion
        self.androidGradlePluginVersion = androidGradlePluginVersion
        self.retrofitVersion = retrofitVersion
        self.okHttpVersion = okHttpVersion
        self.koinVersion = koinVersion
        self.kotlinxSerializationVersion = kotlinxSerializationVersion
        self.kotlinxDateTimeVersion = kotlinxDateTimeVersion
        self.kotlinxCoroutinesVersion = kotlinxCoroutinesVersion
        self.robolectricVersion = robolectricVersion
        self.junitVersion = junitVersion
        self.desugarJdkLibsVersion = desugarJdkLibsVersion
        self.ktlintGradlePluginVersion = ktlintGradlePluginVersion
        self.ktlintVersion = ktlintVersion
        self.compileSdk = compileSdk
        self.minSdk = minSdk
        self.jvmToolchain = jvmToolchain
        self.ktlintCodeStyle = ktlintCodeStyle
        self.overwritePolicy = overwritePolicy
    }
}

public enum KotlinAndroidGeneratedFileOverwritePolicy: Sendable, Equatable {
    case replaceManagedFiles
    case neverOverwriteExisting
}

/// Controls whether generation owns project scaffolding or only generated sources.
public enum KotlinAndroidProjectLayout: Sendable, Equatable {
    case standaloneProject
    case existingProject
}
