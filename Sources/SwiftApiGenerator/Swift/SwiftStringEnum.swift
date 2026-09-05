import Foundation
import GeneratorBuilder
import GeneratorModels
import SwiftSyntax
import SwiftSyntaxBuilder

struct SwiftStringEnum: BodyNode {

    var extensionName: String?
    var visibility: SwiftVisibility = .public
    var name: String
    var values: [(name: String, raw: String)]
    var supportGarbage: Bool

    init(
        extensionName: String? = nil,
        visibility: SwiftVisibility = .public,
        name: String,
        values: [(name: String, raw: String)],
        supportGarbage: Bool
    ) {
        self.extensionName = extensionName
        self.visibility = visibility
        self.name = name
        self.values = values

        if supportGarbage {
            self.values.insert((name: "garbage", raw: "__garbage__"), at: 0)
        }

        self.supportGarbage = supportGarbage
    }

    var body: any Node {
        SwiftSyntaxNode(SourceFileSyntax {
            declaration
        })
    }

    var declaration: DeclSyntax {
        if let extensionName {
            return DeclSyntax(
                SwiftGeneratedSyntax.parse("string enum extension") {
                    try ExtensionDeclSyntax(
                        """
                        // ☠️☠️☠️ This is generated code, modify at your own risk
                        \(raw: visibility.rawValue) extension \(raw: extensionName)
                        """
                    ) {
                        enumDeclaration(includeVisibility: false, includeGeneratedComment: false)
                    }
                }
            )
        }

        return enumDeclaration(includeVisibility: true, includeGeneratedComment: true)
    }

    func enumDeclaration(includeVisibility: Bool, includeGeneratedComment: Bool) -> DeclSyntax {
        let visibilityPrefix = includeVisibility ? "\(visibility.rawValue) " : ""
        let generatedComment = includeGeneratedComment ? "// ☠️☠️☠️ This is generated code, modify at your own risk\n" : ""

        return DeclSyntax(
            SwiftGeneratedSyntax.parse("string enum") {
                try EnumDeclSyntax(
                    """
                    \(raw: generatedComment)\(raw: visibilityPrefix)enum \(raw: name): String, Codable, CaseIterable, Sendable, Identifiable
                    """
                ) {
                    for pair in values {
                        if pair.name != pair.raw {
                            SwiftGeneratedSyntax.parse("string enum case") {
                                try EnumCaseDeclSyntax("case \(raw: pair.name) = \(raw: pair.raw.debugDescription)")
                            }
                        } else {
                            SwiftGeneratedSyntax.parse("string enum case") {
                                try EnumCaseDeclSyntax("case \(raw: pair.name)")
                            }
                        }
                    }

                    try VariableDeclSyntax("public var id: String { rawValue }")

                    if supportGarbage {
                        try FunctionDeclSyntax(
                            """
                            public func encode(to encoder: any Encoder) throws {
                                var container = encoder.singleValueContainer()
                                try container.encode(rawValue)
                            }
                            """
                        )

                        try InitializerDeclSyntax(
                            """
                            public init(from decoder: any Decoder) throws {
                                do {
                                    let container = try decoder.singleValueContainer()
                                    let rawValue = try container.decode(String.self)
                                    self = .init(rawValue: rawValue) ?? .garbage
                                }
                                catch {
                                    self = .garbage
                                }
                            }
                            """
                        )
                    }
                }
            }
        )
    }
}
