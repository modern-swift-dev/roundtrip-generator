import Foundation
import GeneratorBuilder
import GeneratorModels
import SwiftSyntax
import SwiftSyntaxBuilder

struct SwiftImport: BodyNode, ExpressibleByStringLiteral {
    var annotation: String?
    var name: String

    init(stringLiteral value: String) {
        annotation = nil
        name = value
    }

    init(
        name: String,
        annotation: String? = nil
    ) {
        self.annotation = annotation
        self.name = name

    }

    var body: any Node {
        let source = SourceFileSyntax {
            declaration
        }

        return SwiftSyntaxNode(source)
    }

    var declaration: DeclSyntax {
        DeclSyntax(importDeclaration)
    }

    var importDeclaration: ImportDeclSyntax {
        SwiftGeneratedSyntax.parse("import") {
            try ImportDeclSyntax("\(raw: annotation.map { "@\($0) " } ?? "")import \(raw: name)")
        }
    }
}
