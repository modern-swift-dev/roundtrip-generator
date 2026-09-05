import Foundation
import GeneratorBuilder
import SwiftBasicFormat
import SwiftSyntax

struct SwiftSyntaxNode: Node {
    let syntax: any SyntaxProtocol

    init(_ syntax: any SyntaxProtocol) {
        self.syntax = syntax
    }

    func toString() -> String {
        syntax.formatted().description
    }
}
