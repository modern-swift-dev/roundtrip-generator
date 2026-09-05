public enum KotlinAndroidKtlintCodeStyle: String, Sendable {
    case ktlintOfficial = "ktlint_official"
    case intellijIdea = "intellij_idea"
    case androidStudio = "android_studio"
}

public struct KotlinAndroidEditorConfigProperty: Sendable, Equatable {
    public let key: String
    public let value: String

    public init(_ key: String, _ value: String) {
        self.key = key
        self.value = value
    }

    func render() -> String {
        "\(key) = \(value)"
    }
}

public struct KotlinAndroidKtlintRuleOverride: Sendable, Equatable {
    public let ruleSet: String
    public let ruleName: String
    public let isEnabled: Bool

    public init(ruleSet: String = "standard", ruleName: String, isEnabled: Bool) {
        self.ruleSet = ruleSet
        self.ruleName = ruleName
        self.isEnabled = isEnabled
    }

    var property: KotlinAndroidEditorConfigProperty {
        KotlinAndroidEditorConfigProperty(
            "ktlint_\(ruleSet)_\(ruleName)",
            isEnabled ? "enabled" : "disabled",
        )
    }
}

public struct KotlinAndroidEditorConfigSection: Sendable, Equatable {
    public let pattern: String?
    public let properties: [KotlinAndroidEditorConfigProperty]

    public init(pattern: String?, properties: [KotlinAndroidEditorConfigProperty]) {
        self.pattern = pattern
        self.properties = properties
    }

    func render() -> String {
        let propertyLines = properties.map { $0.render() }
        guard let pattern else {
            return propertyLines.joined(separator: "\n")
        }
        return (["[\(pattern)]"] + propertyLines).joined(separator: "\n")
    }
}

public struct KotlinAndroidEditorConfigEmitter: Sendable, Equatable {
    public let sections: [KotlinAndroidEditorConfigSection]

    public init(sections: [KotlinAndroidEditorConfigSection] = KotlinAndroidEditorConfigEmitter.defaultSections()) {
        self.sections = sections
    }

    public static func defaultSections(
        maxLineLength: Int = 120,
        ktlintCodeStyle: KotlinAndroidKtlintCodeStyle = .ktlintOfficial,
        ktlintRuleOverrides: [KotlinAndroidKtlintRuleOverride] = [],
        extraKotlinAndroidProperties: [KotlinAndroidEditorConfigProperty] = [],
    ) -> [KotlinAndroidEditorConfigSection] {
        [
            KotlinAndroidEditorConfigSection(
                pattern: nil,
                properties: [
                    KotlinAndroidEditorConfigProperty("root", "true")
                ],
            ),
            KotlinAndroidEditorConfigSection(
                pattern: "*",
                properties: [
                    KotlinAndroidEditorConfigProperty("charset", "utf-8"),
                    KotlinAndroidEditorConfigProperty("end_of_line", "lf"),
                    KotlinAndroidEditorConfigProperty("insert_final_newline", "true"),
                    KotlinAndroidEditorConfigProperty("trim_trailing_whitespace", "true")
                ],
            ),
            KotlinAndroidEditorConfigSection(
                pattern: "*.{kt,kts}",
                properties: [
                    KotlinAndroidEditorConfigProperty("indent_style", "space"),
                    KotlinAndroidEditorConfigProperty("indent_size", "4"),
                    KotlinAndroidEditorConfigProperty("continuation_indent_size", "4"),
                    KotlinAndroidEditorConfigProperty("max_line_length", "\(maxLineLength)"),
                    KotlinAndroidEditorConfigProperty("ij_kotlin_code_style_defaults", "KOTLIN_OFFICIAL"),
                    KotlinAndroidEditorConfigProperty("ktlint_code_style", ktlintCodeStyle.rawValue)
                ] + ktlintRuleOverrides.map(\.property) + extraKotlinAndroidProperties,
            )
        ]
    }

    public func render() -> String {
        sections
            .map { $0.render() }
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n") + "\n"
    }

    public func file() -> KotlinAndroidGeneratedTextFile {
        KotlinAndroidGeneratedTextFile(relativePath: ".editorconfig", contents: "# Generated code. Do not edit.\n\(render())")
    }
}
