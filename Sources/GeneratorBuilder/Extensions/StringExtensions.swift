import Foundation

public extension String {
    var uppercasingFirst: String {
        prefix(1).uppercased() + dropFirst()
    }

    var lowercasingFirst: String {
        prefix(1).lowercased() + dropFirst()
    }

    func endingWith(_ value: String) -> Bool {
        let range = range(of: value, options: .backwards)
        return range?.upperBound == endIndex
    }

    var camelized: String {
        guard !isEmpty else {
            return ""
        }

        let parts = components(separatedBy: CharacterSet.alphanumerics.inverted)
        let first = (parts.first ?? "").lowercasingFirst
        let rest = parts.dropFirst().map { String($0).uppercasingFirst }
        return ([first] + rest).joined(separator: "")
    }

    var capitalCased: String {
        guard !isEmpty else {
            return ""
        }

        let parts = components(separatedBy: CharacterSet.alphanumerics.inverted)
        let first = (parts.first ?? "").uppercasingFirst
        let rest = parts.dropFirst().map { String($0).uppercasingFirst }

        return ([first] + rest).joined(separator: "")
    }

    func prepad(_ nbTab: UInt = 1) -> String {
        var prefix = ""
        for _ in 0 ..< nbTab {
            prefix += "    "
        }

        var result = ""
        var isFirstLine = true
        enumerateLines { value, _ in
            if !isFirstLine {
                result += "\n"
            }
            result += prefix
            result += value
            isFirstLine = false
        }
        return result
    }

    /// Return true if the string is a number
    var isNumber: Bool {
        !isEmpty && rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
    }

}

public extension String {
    private static let swiftKeywords: Set<String> = [
        "Any", "Protocol", "Self", "Type", "actor", "any", "as", "associatedtype", "async",
        "await", "break", "case", "catch", "class", "continue", "default", "defer", "deinit",
        "do", "dynamic", "else", "enum", "extension", "fallthrough", "false", "fileprivate",
        "for", "func", "guard", "if", "import", "in", "indirect", "init", "inout", "internal",
        "is", "isolated", "let", "nil", "nonisolated", "operator", "optional", "private",
        "protocol", "public", "repeat", "required", "rethrows", "return", "self", "some",
        "static", "struct", "subscript", "super", "switch", "throw", "throws", "true", "try",
        "typealias", "unowned", "var", "weak", "where", "while"
    ]

    var swiftIdentifier: String {
        if isEmpty {
            return "_value"
        }
        if Self.swiftKeywords.contains(self) {
            return "`\(self)`"
        }
        return self
    }

    private var swiftIdentifierWithValidLeadingCharacter: String {
        if first?.isNumber == true {
            return "_\(self)"
        }
        return self
    }

    var swiftPropertyName: String {
        camelized.swiftIdentifierWithValidLeadingCharacter.swiftIdentifier
    }

    /// Return a safe string value for an enum, if the value is a number
    var swiftEnumValueDeclaration: String {
        camelized.swiftIdentifierWithValidLeadingCharacter.swiftIdentifier
    }

    var swiftTypeName: String {
        capitalCased.swiftIdentifierWithValidLeadingCharacter.swiftIdentifier
    }

    var swiftStringLiteral: String {
        debugDescription
    }
}
