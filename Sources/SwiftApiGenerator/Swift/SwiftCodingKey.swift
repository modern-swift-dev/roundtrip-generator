import Foundation
import GeneratorBuilder
import GeneratorModels
import SwiftSyntax
import SwiftSyntaxBuilder

struct SwiftCodingKey: Codable, BodyNode {
    /// The name of the property
    var name: String

    /// The raw name
    var rawName: String

    var body: any Node {
        SwiftSyntaxNode(declaration)
    }

    var declaration: SourceFileSyntax {
        SourceFileSyntax {
            SwiftGeneratedSyntax.parse("coding key") {
                if name != rawName {
                    try EnumCaseDeclSyntax("case \(raw: name) = \(raw: rawName.debugDescription)")
                } else {
                    try EnumCaseDeclSyntax("case \(raw: name)")
                }
            }
        }
    }
}

struct SwiftCodingKeys: BodyNode {
    /// The type name of the coding keys
    var typeName: String

    /// The visibility
    let visibility: SwiftVisibility

    /// The Values
    let values: [SwiftCodingKey]

    init(typeName: String = "CodingKeys", visibility: SwiftVisibility = .public, values: [SwiftCodingKey]) {
        self.typeName = typeName
        self.visibility = visibility
        self.values = values
    }

    var body: any Node {
        SwiftSyntaxNode(declaration)
    }

    var declaration: DeclSyntax {
        SwiftGeneratedSyntax.parse("coding keys") {
            try DeclSyntax(
                EnumDeclSyntax("\(raw: visibility.rawValue) enum \(raw: typeName): String, CodingKey") {
                    for value in values {
                        value.caseDeclaration
                    }
                },
            )
        }
    }
}

private extension SwiftCodingKey {
    var caseDeclaration: EnumCaseDeclSyntax {
        if name != rawName {
            SwiftGeneratedSyntax.parse("coding key case") {
                try EnumCaseDeclSyntax("case \(raw: name) = \(raw: rawName.debugDescription)")
            }
        } else {
            SwiftGeneratedSyntax.parse("coding key case") {
                try EnumCaseDeclSyntax("case \(raw: name)")
            }
        }
    }
}
