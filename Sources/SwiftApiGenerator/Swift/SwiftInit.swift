import Foundation
import GeneratorBuilder
import GeneratorModels
import SwiftBasicFormat
import SwiftSyntax
import SwiftSyntaxBuilder

struct SwiftInit: Codable, BodyNode {

    /// The Visibility modifier
    var visibility: SwiftVisibility

    /// The properties to assign in the init
    var properties: [SwiftProperty]

    init(
        visibility: SwiftVisibility,
        properties: [SwiftProperty]
    ) {
        self.visibility = visibility

        // Filter out properties which have a default value, and are not mutable. They are not initialized by the init method
        self.properties = properties.filter {
            if $0.defaultValue != nil, !$0.mutable {
                return false
            }
            return true
        }
    }

    var body: any Node {
        SwiftSyntaxNode(declaration)
    }

    var declaration: DeclSyntax {
        DeclSyntax(initializerDeclaration)
    }

    var initializerDeclaration: InitializerDeclSyntax {
        let parameters = properties
            .map { $0.initParameter.formatted().description }
            .joined(separator: ", ")

        let assignments = properties
            .map { "self.\($0.name) = \($0.name)" }
            .joined(separator: "\n")

        return SwiftGeneratedSyntax.parse("initializer") {
            if properties.isEmpty {
                try InitializerDeclSyntax("\(raw: visibility.rawValue) init() {}")
            } else {
                try InitializerDeclSyntax(
                    """
                    \(raw: visibility.rawValue) init(\(raw: parameters)) {
                    \(raw: assignments)
                    }
                    """
                )
            }
        }
    }
}
