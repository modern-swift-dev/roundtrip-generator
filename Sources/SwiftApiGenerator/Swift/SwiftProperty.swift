import Foundation
import GeneratorBuilder
import GeneratorModels
import SwiftSyntax
import SwiftSyntaxBuilder

struct SwiftProperty: Codable {
    /// The visibility
    var visibility: SwiftVisibility

    /// The mutability modifier
    var mutable: Bool

    /// The name of the property
    var name: String

    /// The data-type
    var dataType: String

    /// The nullability
    var nullable: Bool

    /// The default value
    var defaultValue: String?

    /// The raw name of the property, for coding keys
    var rawName: String?

    /// Is Equatable
    var equatable: Bool = true

    /// Is Hashable
    var hashable: Bool = false

    init(
        visibility: SwiftVisibility = .public,
        mutable: Bool = true,
        name: String,
        dataType: String,
        nullable: Bool = false,
        defaultValue: String? = nil,
        rawName: String? = nil,
        equatable: Bool = true,
        hashable: Bool = false,
    ) {
        self.visibility = visibility
        self.mutable = mutable
        self.name = name
        self.dataType = dataType
        self.nullable = nullable
        self.defaultValue = defaultValue
        self.rawName = rawName
        self.equatable = equatable
        self.hashable = hashable
    }

    var bodyDeclaration: any Node {
        SwiftSyntaxNode(declaration)
    }

    var declaration: DeclSyntax {
        DeclSyntax(variableDeclaration)
    }

    var variableDeclaration: VariableDeclSyntax {
        let type = effectiveNullable ? "\(dataType)?" : dataType
        let keyword = mutable ? "var" : "let"
        if let defaultValue, !mutable {
            return SwiftGeneratedSyntax.parse("property") {
                try VariableDeclSyntax("\(raw: visibility.rawValue) \(raw: keyword) \(raw: name): \(raw: type) = \(raw: defaultValue)")
            }
        } else {
            return SwiftGeneratedSyntax.parse("property") {
                try VariableDeclSyntax("\(raw: visibility.rawValue) \(raw: keyword) \(raw: name): \(raw: type)")
            }
        }
    }

    var initDeclaration: any Node {
        SwiftSyntaxNode(initParameter)
    }

    var initParameter: FunctionParameterSyntax {
        let type = effectiveNullable ? "\(dataType)?" : dataType
        return SwiftGeneratedSyntax.parse("function parameter") {
            if let defaultValue {
                FunctionParameterSyntax("\(raw: name): \(raw: type) = \(raw: defaultValue)")
            } else {
                FunctionParameterSyntax("\(raw: name): \(raw: type)")
            }
        }
    }
}

extension SwiftProperty {
    var isPatchableValue: Bool {
        dataType == "PatchableValue" || dataType.hasPrefix("PatchableValue<")
    }

    var effectiveNullable: Bool {
        nullable && !isPatchableValue
    }

    /// The coding key
    var codingKey: SwiftCodingKey {
        .init(name: name, rawName: rawName ?? name)
    }
}

extension [SwiftProperty] {
    var codingKeys: [SwiftCodingKey] {
        map(\.codingKey)
    }
}
