import Foundation

public enum KotlinGradleRepository: Sendable, Equatable {
    case gradlePluginPortal
    case mavenCentral
    case google
    case maven(url: String)
    case custom(String)

    func render() -> String {
        switch self {
            case .gradlePluginPortal:
                "gradlePluginPortal()"
            case .mavenCentral:
                "mavenCentral()"
            case .google:
                "google()"
            case let .maven(url):
                "maven(url = uri(\(kotlinGradleStringLiteral(url))))"
            case let .custom(statement):
                statement
        }
    }
}

public enum KotlinGradleRepositoriesMode: Sendable, Equatable {
    case failOnProjectRepos
    case preferSettings
    case preferProject

    var expression: String {
        switch self {
            case .failOnProjectRepos:
                "RepositoriesMode.FAIL_ON_PROJECT_REPOS"
            case .preferSettings:
                "RepositoriesMode.PREFER_SETTINGS"
            case .preferProject:
                "RepositoriesMode.PREFER_PROJECT"
        }
    }
}

public enum KotlinGradlePlugin: Sendable, Equatable {
    case kotlin(module: String, version: String?, apply: Bool?)
    case id(String, version: String?, apply: Bool?)

    public static func kotlinJvm(version: String? = nil, apply: Bool? = nil) -> KotlinGradlePlugin {
        .kotlin(module: "jvm", version: version, apply: apply)
    }

    public static func ktlint(version: String? = nil, apply: Bool? = nil) -> KotlinGradlePlugin {
        .id("org.jlleitschuh.gradle.ktlint", version: version, apply: apply)
    }

    func render() -> String {
        let base: String
        let version: String?
        let apply: Bool?

        switch self {
            case let .kotlin(module, pluginVersion, shouldApply):
                base = "kotlin(\(kotlinGradleStringLiteral(module)))"
                version = pluginVersion
                apply = shouldApply
            case let .id(pluginID, pluginVersion, shouldApply):
                base = "id(\(kotlinGradleStringLiteral(pluginID)))"
                version = pluginVersion
                apply = shouldApply
        }

        var parts = [base]
        if let version {
            parts.append("version \(kotlinGradleStringLiteral(version))")
        }
        if let apply {
            parts.append("apply \(apply ? "true" : "false")")
        }
        return parts.joined(separator: " ")
    }
}

public struct KotlinGradleDependency: Sendable, Equatable {
    public let configuration: String
    public let notation: String

    public init(configuration: String, notation: String) {
        self.configuration = configuration
        self.notation = notation
    }

    public static func implementation(_ notation: String) -> KotlinGradleDependency {
        KotlinGradleDependency(configuration: "implementation", notation: notation)
    }

    public static func testImplementation(_ notation: String) -> KotlinGradleDependency {
        KotlinGradleDependency(configuration: "testImplementation", notation: notation)
    }

    func render() -> String {
        "\(configuration)(\(kotlinGradleStringLiteral(notation)))"
    }
}

public struct KotlinGradleProperty: Sendable, Equatable {
    public let key: String
    public let value: String

    public init(_ key: String, _ value: String) {
        self.key = key
        self.value = value
    }

    func render() -> String {
        "\(key)=\(value)"
    }
}

public struct KotlinGradleSettingsEmitter: Sendable, Equatable {
    public let projectName: String
    public let pluginRepositories: [KotlinGradleRepository]
    public let dependencyRepositories: [KotlinGradleRepository]
    public let repositoriesMode: KotlinGradleRepositoriesMode

    public init(
        projectName: String,
        pluginRepositories: [KotlinGradleRepository] = [.gradlePluginPortal, .mavenCentral, .google],
        dependencyRepositories: [KotlinGradleRepository] = [.mavenCentral],
        repositoriesMode: KotlinGradleRepositoriesMode = .failOnProjectRepos
    ) {
        self.projectName = projectName
        self.pluginRepositories = pluginRepositories
        self.dependencyRepositories = dependencyRepositories
        self.repositoriesMode = repositoriesMode
    }

    public func render() -> String {
        [
            pluginManagementBlock(),
            dependencyResolutionManagementBlock(),
            "rootProject.name = \(kotlinGradleStringLiteral(projectName))"
        ]
        .filter { !$0.isEmpty }
        .joined(separator: "\n\n") + "\n"
    }

    public func file() -> KotlinGeneratedTextFile {
        KotlinGeneratedTextFile(
            relativePath: "settings.gradle.kts",
            contents: "\(KotlinGeneratedTextFile.managedHeader)\n\(render())"
        )
    }

    private func pluginManagementBlock() -> String {
        guard !pluginRepositories.isEmpty else {
            return ""
        }

        return """
        pluginManagement {
            repositories {
        \(indentedGradleLines(pluginRepositories.map { $0.render() }, level: 2))
            }
        }
        """
    }

    private func dependencyResolutionManagementBlock() -> String {
        guard !dependencyRepositories.isEmpty else {
            return ""
        }

        return """
        dependencyResolutionManagement {
            repositoriesMode.set(\(repositoriesMode.expression))
            repositories {
        \(indentedGradleLines(dependencyRepositories.map { $0.render() }, level: 2))
            }
        }
        """
    }
}

public struct KotlinGradleBuildFileEmitter: Sendable, Equatable {
    public let plugins: [KotlinGradlePlugin]
    public let group: String?
    public let version: String?
    public let repositories: [KotlinGradleRepository]
    public let jvmToolchain: Int?
    public let dependencies: [KotlinGradleDependency]
    public let ktlintVersion: String?
    public let extraBlocks: [String]

    public init(
        plugins: [KotlinGradlePlugin],
        group: String? = nil,
        version: String? = nil,
        repositories: [KotlinGradleRepository] = [.mavenCentral],
        jvmToolchain: Int? = 21,
        dependencies: [KotlinGradleDependency] = [],
        ktlintVersion: String? = nil,
        extraBlocks: [String] = []
    ) {
        self.plugins = plugins
        self.group = group
        self.version = version
        self.repositories = repositories
        self.jvmToolchain = jvmToolchain
        self.dependencies = dependencies
        self.ktlintVersion = ktlintVersion
        self.extraBlocks = extraBlocks
    }

    public func render() -> String {
        (
            [
                pluginsBlock(),
                coordinatesBlock(),
                repositoriesBlock(),
                kotlinBlock(),
                dependenciesBlock(),
                ktlintBlock()
            ] + extraBlocks.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        )
        .filter { !$0.isEmpty }
        .joined(separator: "\n\n") + "\n"
    }

    public func file() -> KotlinGeneratedTextFile {
        KotlinGeneratedTextFile(
            relativePath: "build.gradle.kts",
            contents: "\(KotlinGeneratedTextFile.managedHeader)\n\(render())"
        )
    }

    private func pluginsBlock() -> String {
        guard !plugins.isEmpty else {
            return ""
        }

        return """
        plugins {
        \(indentedGradleLines(plugins.map { $0.render() }))
        }
        """
    }

    private func coordinatesBlock() -> String {
        var lines: [String] = []
        if let group {
            lines.append("group = \(kotlinGradleStringLiteral(group))")
        }
        if let version {
            lines.append("version = \(kotlinGradleStringLiteral(version))")
        }
        return lines.joined(separator: "\n")
    }

    private func repositoriesBlock() -> String {
        guard !repositories.isEmpty else {
            return ""
        }

        return """
        repositories {
        \(indentedGradleLines(repositories.map { $0.render() }))
        }
        """
    }

    private func kotlinBlock() -> String {
        guard let jvmToolchain else {
            return ""
        }

        return """
        kotlin {
            jvmToolchain(\(jvmToolchain))
        }
        """
    }

    private func dependenciesBlock() -> String {
        guard !dependencies.isEmpty else {
            return ""
        }

        return """
        dependencies {
        \(indentedGradleLines(dependencies.map { $0.render() }))
        }
        """
    }

    private func ktlintBlock() -> String {
        guard let ktlintVersion else {
            return ""
        }

        return """
        ktlint {
            version.set(\(kotlinGradleStringLiteral(ktlintVersion)))
        }
        """
    }
}

public struct KotlinGradlePropertiesEmitter: Sendable, Equatable {
    public let properties: [KotlinGradleProperty]

    public init(
        properties: [KotlinGradleProperty] = [
            KotlinGradleProperty("org.gradle.jvmargs", "-Xmx2g -Dfile.encoding=UTF-8"),
            KotlinGradleProperty("kotlin.code.style", "official")
        ]
    ) {
        self.properties = properties
    }

    public func render() -> String {
        properties.map { $0.render() }.joined(separator: "\n") + "\n"
    }

    public func file() -> KotlinGeneratedTextFile {
        KotlinGeneratedTextFile(
            relativePath: "gradle.properties",
            contents: "# Generated code. Do not edit.\n\(render())"
        )
    }
}

public struct KotlinGradleProjectEmitter: Sendable, Equatable {
    public let settings: KotlinGradleSettingsEmitter
    public let buildFile: KotlinGradleBuildFileEmitter
    public let gradleProperties: KotlinGradlePropertiesEmitter
    public let editorConfig: KotlinEditorConfigEmitter?

    public init(
        projectName: String,
        kotlinPluginVersion: String,
        ktlintGradlePluginVersion: String,
        group: String? = nil,
        version: String? = nil,
        ktlintVersion: String? = nil,
        jvmToolchain: Int? = 21,
        dependencies: [KotlinGradleDependency] = [],
        editorConfig: KotlinEditorConfigEmitter? = KotlinEditorConfigEmitter()
    ) {
        settings = KotlinGradleSettingsEmitter(projectName: projectName)
        buildFile = KotlinGradleBuildFileEmitter(
            plugins: [
                .kotlinJvm(version: kotlinPluginVersion),
                .ktlint(version: ktlintGradlePluginVersion)
            ],
            group: group,
            version: version,
            jvmToolchain: jvmToolchain,
            dependencies: dependencies,
            ktlintVersion: ktlintVersion
        )
        gradleProperties = KotlinGradlePropertiesEmitter()
        self.editorConfig = editorConfig
    }

    public init(
        settings: KotlinGradleSettingsEmitter,
        buildFile: KotlinGradleBuildFileEmitter,
        gradleProperties: KotlinGradlePropertiesEmitter = KotlinGradlePropertiesEmitter(),
        editorConfig: KotlinEditorConfigEmitter? = KotlinEditorConfigEmitter()
    ) {
        self.settings = settings
        self.buildFile = buildFile
        self.gradleProperties = gradleProperties
        self.editorConfig = editorConfig
    }

    public func files() -> [KotlinGeneratedTextFile] {
        var files = [
            settings.file(),
            buildFile.file(),
            gradleProperties.file()
        ]

        if let editorConfig {
            files.append(editorConfig.file())
        }

        return files
    }

    public func write(to directoryURL: URL) throws {
        for file in files() {
            try file.write(to: directoryURL)
        }
    }
}

private func indentedGradleLines(_ lines: [String], level: Int = 1) -> String {
    let indentation = String(repeating: "    ", count: level)
    return lines.map { "\(indentation)\($0)" }.joined(separator: "\n")
}

private func kotlinGradleStringLiteral(_ value: String) -> String {
    var result = "\""
    for character in value {
        switch character {
            case "\\":
                result += "\\\\"
            case "\"":
                result += "\\\""
            case "\n":
                result += "\\n"
            case "\r":
                result += "\\r"
            case "\t":
                result += "\\t"
            case "$":
                result += "\\$"
            default:
                result.append(character)
        }
    }
    result += "\""
    return result
}
