import Foundation
import GeneratorBuilder
import GeneratorModels
import SwiftSyntax
import SwiftSyntaxBuilder

struct SwiftIntEnum: BodyNode {

    var extensionName: String?
    var visibility: SwiftVisibility = .public
    var name: String
    var values: [(name: String, raw: String)]

    init(
        extensionName: String? = nil,
        visibility: SwiftVisibility = .public,
        name: String,
        values: [(name: String, raw: String)]
    ) {
        self.extensionName = extensionName
        self.visibility = visibility
        self.name = name
        self.values = values
    }

    var body: any Node {
        SwiftSyntaxNode(SourceFileSyntax {
            declaration
        })
    }

    var declaration: DeclSyntax {
        if let extensionName {
            return DeclSyntax(
                SwiftGeneratedSyntax.parse("int enum extension") {
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
            SwiftGeneratedSyntax.parse("int enum") {
                try EnumDeclSyntax(
                    """
                    \(raw: generatedComment)\(raw: visibilityPrefix)enum \(raw: name): Int, Codable, CaseIterable, Sendable, Identifiable
                    """
                ) {
                    for pair in values {
                        if pair.name != pair.raw {
                            SwiftGeneratedSyntax.parse("int enum case") {
                                try EnumCaseDeclSyntax("case \(raw: pair.name) = \(raw: pair.raw)")
                            }
                        } else {
                            SwiftGeneratedSyntax.parse("int enum case") {
                                try EnumCaseDeclSyntax("case \(raw: pair.name)")
                            }
                        }
                    }

                    try VariableDeclSyntax("public var id: Int { rawValue }")
                }
            }
        )
    }
}

extension SwiftIntEnum {
    static func intEnumCaseName(_ selectedCase: (name: String?, rawValue: Int)) -> String {
        if let name = selectedCase.name, !name.isEmpty {
            name.swiftEnumValueDeclaration
        } else {
            selectedCase.rawValue.swiftEnumValueDeclaration
        }
    }
}
