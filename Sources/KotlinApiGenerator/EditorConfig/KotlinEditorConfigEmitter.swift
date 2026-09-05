public enum KotlinKtlintCodeStyle: String, Sendable {
    case ktlintOfficial = "ktlint_official"
    case intellijIdea = "intellij_idea"
    case androidStudio = "android_studio"
}

public struct KotlinEditorConfigProperty: Sendable, Equatable {
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

public struct KotlinKtlintRuleOverride: Sendable, Equatable {
    public let ruleSet: String
    public let ruleName: String
    public let isEnabled: Bool

    public init(ruleSet: String = "standard", ruleName: String, isEnabled: Bool) {
        self.ruleSet = ruleSet
        self.ruleName = ruleName
        self.isEnabled = isEnabled
    }

    var property: KotlinEditorConfigProperty {
        KotlinEditorConfigProperty(
            "ktlint_\(ruleSet)_\(ruleName)",
            isEnabled ? "enabled" : "disabled"
        )
    }
}

public struct KotlinEditorConfigSection: Sendable, Equatable {
    public let pattern: String?
    public let properties: [KotlinEditorConfigProperty]

    public init(pattern: String?, properties: [KotlinEditorConfigProperty]) {
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

public struct KotlinEditorConfigEmitter: Sendable, Equatable {
    public let sections: [KotlinEditorConfigSection]

    public init(sections: [KotlinEditorConfigSection] = KotlinEditorConfigEmitter.defaultSections()) {
        self.sections = sections
    }

    public static func defaultSections(
        maxLineLength: Int = 120,
        ktlintCodeStyle: KotlinKtlintCodeStyle = .ktlintOfficial,
        ktlintRuleOverrides: [KotlinKtlintRuleOverride] = [],
        extraKotlinProperties: [KotlinEditorConfigProperty] = []
    ) -> [KotlinEditorConfigSection] {
        [
            KotlinEditorConfigSection(
                pattern: nil,
                properties: [
                    KotlinEditorConfigProperty("root", "true")
                ]
            ),
            KotlinEditorConfigSection(
                pattern: "*",
                properties: [
                    KotlinEditorConfigProperty("charset", "utf-8"),
                    KotlinEditorConfigProperty("end_of_line", "lf"),
                    KotlinEditorConfigProperty("insert_final_newline", "true"),
                    KotlinEditorConfigProperty("trim_trailing_whitespace", "true")
                ]
            ),
            KotlinEditorConfigSection(
                pattern: "*.{kt,kts}",
                properties: [
                    KotlinEditorConfigProperty("indent_style", "space"),
                    KotlinEditorConfigProperty("indent_size", "4"),
                    KotlinEditorConfigProperty("continuation_indent_size", "4"),
                    KotlinEditorConfigProperty("max_line_length", "\(maxLineLength)"),
                    KotlinEditorConfigProperty("ij_kotlin_code_style_defaults", "KOTLIN_OFFICIAL"),
                    KotlinEditorConfigProperty("ktlint_code_style", ktlintCodeStyle.rawValue)
                ] + ktlintRuleOverrides.map(\.property) + extraKotlinProperties
            )
        ]
    }

    public func render() -> String {
        sections
            .map { $0.render() }
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n") + "\n"
    }

    public func file() -> KotlinGeneratedTextFile {
        KotlinGeneratedTextFile(relativePath: ".editorconfig", contents: "# Generated code. Do not edit.\n\(render())")
    }
}
