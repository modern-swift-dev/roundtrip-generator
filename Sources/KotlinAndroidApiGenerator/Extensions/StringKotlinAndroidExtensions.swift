import Foundation
import GeneratorBuilder

extension String {
    private static let kotlinHardKeywords: Set<String> = [
        "as", "break", "class", "continue", "do", "else", "false", "for",
        "fun", "if", "in", "interface", "is", "null", "object", "package",
        "return", "super", "this", "throw", "true", "try", "typealias",
        "typeof", "val", "var", "when", "while"
    ]

    private static let kotlinSoftKeywords: Set<String> = [
        "by", "catch", "constructor", "delegate", "dynamic", "field", "file",
        "finally", "get", "import", "init", "param", "property", "receiver",
        "set", "setparam", "where"
    ]

    private var removingSwiftIdentifierEscapes: String {
        if hasPrefix("`"), hasSuffix("`"), count > 1 {
            return String(dropFirst().dropLast())
        }
        return self
    }

    private var kotlinIdentifierWithValidLeadingCharacter: String {
        guard let first else {
            return "_value"
        }
        if first == "_" || first.isLetter {
            return self
        }
        return "_\(self)"
    }

    var isKotlinHardKeyword: Bool {
        Self.kotlinHardKeywords.contains(self)
    }

    var kotlinIdentifier: String {
        if isEmpty {
            return "_value"
        }
        if Self.kotlinHardKeywords.contains(self) || Self.kotlinSoftKeywords.contains(self) {
            return "`\(self)`"
        }
        return self
    }

    var kotlinPropertyName: String {
        removingSwiftIdentifierEscapes
            .camelized
            .kotlinIdentifierWithValidLeadingCharacter
            .kotlinIdentifier
    }

    var kotlinEnumCaseName: String {
        removingSwiftIdentifierEscapes
            .capitalCased
            .kotlinIdentifierWithValidLeadingCharacter
            .kotlinIdentifier
    }

    var kotlinTypeName: String {
        removingSwiftIdentifierEscapes
            .capitalCased
            .kotlinIdentifierWithValidLeadingCharacter
            .kotlinIdentifier
    }

    var kotlinTypeReferenceName: String {
        let parts = removingSwiftIdentifierEscapes.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count > 1, let last = parts.last else {
            return kotlinTypeName
        }

        let prefix = parts.dropLast().map(String.init).joined(separator: ".")
        return "\(prefix).\(String(last).kotlinTypeName)"
    }

    var kotlinStringLiteral: String {
        var result = "\""
        for scalar in unicodeScalars {
            switch scalar.value {
                case 0x08:
                    result += "\\b"
                case 0x09:
                    result += "\\t"
                case 0x0A:
                    result += "\\n"
                case 0x0C:
                    result += "\\u000c"
                case 0x0D:
                    result += "\\r"
                case 0x22:
                    result += "\\\""
                case 0x24:
                    result += "\\$"
                case 0x5C:
                    result += "\\\\"
                case 0x00 ... 0x1F:
                    let hex = String(scalar.value, radix: 16, uppercase: false)
                    result += "\\u\(String(repeating: "0", count: max(0, 4 - hex.count)))\(hex)"
                default:
                    result.unicodeScalars.append(scalar)
            }
        }
        result += "\""
        return result
    }

    var kotlinPackageSegment: String {
        camelized
            .replacingOccurrences(of: "`", with: "")
            .lowercased()
            .kotlinIdentifierWithValidLeadingCharacter
            .kotlinIdentifier
            .replacingOccurrences(of: "`", with: "_")
    }
}
