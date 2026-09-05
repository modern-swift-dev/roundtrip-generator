import SwiftApiGenerator
import SwiftSyntax
import SwiftSyntaxBuilder

enum SwiftVaporSyntax {
    static func sourceFile(imports: [String], declarations: [DeclSyntax]) -> SourceFileSyntax {
        SourceFileSyntax {
            for line in imports {
                SwiftGeneratedSyntax.parse("Vapor import") { try ImportDeclSyntax("\(raw: line)") }
            }
            for declaration in declarations {
                declaration.with(\.leadingTrivia, .newlines(2) + declaration.leadingTrivia)
            }
        }
        .with(\.leadingTrivia, .lineComment(SwiftVaporGeneratedTextFile.managedHeader) + .newline)
    }
}
