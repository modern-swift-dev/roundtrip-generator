import Foundation
import GeneratorBuilder
import GeneratorModels
import SwiftSyntax
import SwiftSyntaxBuilder

class SwiftClass: BodyNode {
    var extensionName: String?
    var visibility: SwiftVisibility = .public
    var name: String
    var protocols: [String] = []
    var classAnnotations: [String] = []
    var properties: [SwiftProperty]
    var codingKeys: [SwiftCodingKey] = []
    var equatableProperties: [String] = []
    var hashableProperties: [String] = []
    var initDefinition: SwiftInit
    var innerTypes: [DeclSyntax] = []
    var isValueType: Bool = true
    var includeSendable: Bool = true

    var patchableProperties: [SwiftProperty] {
        properties.filter(\.isPatchableValue)
    }

    init(
        extensionName: String? = nil,
        visibility: SwiftVisibility = .public,
        name: String,
        classAnnotations: [String] = [],
        protocols: [String] = [],
        properties: [SwiftProperty],
        innerTypes: [DeclSyntax] = [],
        isValueType: Bool = true,
        includeSendable: Bool = true,
    ) {
        self.extensionName = extensionName
        self.visibility = visibility
        self.name = name
        self.isValueType = isValueType
        self.includeSendable = includeSendable
        self.protocols = []
        self.classAnnotations = classAnnotations
        self.properties = properties
        initDefinition = .init(visibility: visibility, properties: properties)
        codingKeys = properties.codingKeys
        self.innerTypes = innerTypes
        equatableProperties = properties.filter { $0.equatable || $0.hashable }.map(\.name)
        hashableProperties = properties.filter(\.hashable).map(\.name)

        let defaultProtocols = isValueType && includeSendable ? ["Codable", "Sendable"] : ["Codable"]
        var effectiveProtocols = Set<String>()
        if !equatableProperties.isEmpty {
            effectiveProtocols.insert("Equatable")
        }

        if !hashableProperties.isEmpty {
            effectiveProtocols.insert("Hashable")
        }

        for proto in protocols {
            effectiveProtocols.insert(proto)
        }

        for proto in defaultProtocols + Array(effectiveProtocols).sorted() where !self.protocols.contains(proto) {
            self.protocols.append(proto)
        }
    }

    var body: any Node {
        SwiftSyntaxNode(declaration)
    }

    var declaration: DeclSyntax {
        let declaration = typeDeclaration
        if let extensionName {
            let extensionDecl = SwiftGeneratedSyntax.parse("class extension") {
                try ExtensionDeclSyntax(
                    """
                    // ☠️☠️☠️ This is generated code, modify at your own risk
                    \(raw: visibility.rawValue) extension \(raw: extensionName)
                    """,
                ) {
                    declaration
                }
            }
            return DeclSyntax(extensionDecl)
        }

        return declaration.with(\.leadingTrivia, .lineComment("// ☠️☠️☠️ This is generated code, modify at your own risk\n"))
    }

    private var typeDeclaration: DeclSyntax {
        let annotationSource = classAnnotations.map { "@\($0)" }.joined(separator: "\n")
        let declarationPrefix = extensionName == nil ? "\(visibility.rawValue) " : ""
        let typeKeyword = isValueType ? "struct" : "class"
        let inheritance = protocols.isEmpty ? "" : ": \(protocols.joined(separator: ", "))"
        let headerPrefix = annotationSource.isEmpty ? "" : "\(annotationSource)\n"
        let header = "\(headerPrefix)\(declarationPrefix)\(typeKeyword) \(name)\(inheritance)"

        return SwiftGeneratedSyntax.parse("class") {
            if isValueType {
                try DeclSyntax(
                    StructDeclSyntax("\(raw: header)") {
                        memberDeclarations
                    },
                )
            } else {
                try DeclSyntax(
                    ClassDeclSyntax("\(raw: header)") {
                        memberDeclarations
                    },
                )
            }
        }
    }

    private var memberDeclarations: [DeclSyntax] {
        var members: [DeclSyntax] = []

        if !properties.isEmpty {
            members += properties.map(\.declaration)
        }

        members.append(initDefinition.declaration)

        if protocols.contains("Codable"), !properties.isEmpty {
            members.append(SwiftCodingKeys(visibility: visibility, values: properties.codingKeys).declaration)
        }

        if !equatableProperties.isEmpty || protocols.contains("Equatable") || protocols.contains("Hashable") {
            members.append(DeclSyntax(equatableDeclaration))
        }

        if !hashableProperties.isEmpty || protocols.contains("Hashable") {
            members.append(DeclSyntax(hashableDeclaration))
        }

        if !innerTypes.isEmpty {
            members += innerTypes
        }

        if !patchableProperties.isEmpty {
            members += patchableDeclarations
        }

        return members
    }

    private var patchableDeclarations: [DeclSyntax] {
        let patchableList = patchableProperties
        let encodeStatements = properties.map { property in
            if property.isPatchableValue {
                """
                if !self.\(property.name).isUnmodified {
                    try codingContainer.encode(self.\(property.name), forKey: .\(property.name))
                }
                """
            } else if property.nullable {
                "try codingContainer.encodeIfPresent(self.\(property.name), forKey: .\(property.name))"
            } else {
                "try codingContainer.encode(self.\(property.name), forKey: .\(property.name))"
            }
        }.joined(separator: "\n")

        let decodeStatements = properties.map { property in
            if property.isPatchableValue {
                """
                if codingContainer.contains(.\(property.name)) {
                    if try codingContainer.decodeNil(forKey: .\(property.name)) {
                        self.\(property.name) = .deleted
                    } else {
                        self.\(property.name) = try codingContainer.decode(\(property.dataType).self, forKey: .\(property.name))
                    }
                } else {
                    self.\(property.name) = .unmodified
                }
                """
            } else if property.nullable {
                "self.\(property.name) = try codingContainer.decodeIfPresent(\(property.dataType).self, forKey: .\(property.name))"
            } else {
                "self.\(property.name) = try codingContainer.decode(\(property.dataType).self, forKey: .\(property.name))"
            }
        }.joined(separator: "\n")

        let resetStatements = patchableList.map { "self.\($0.name) = .unmodified" }.joined(separator: "\n")
        let isUnmodifiedValues = patchableList.map { "self.\($0.name).isUnmodified" }.joined(separator: " &&\n")

        let decoderInitPrefix = isValueType ? "public" : "public required"
        let resetMutatingPrefix = isValueType ? "mutating " : ""

        return SwiftGeneratedSyntax.parse("class patchable coding") {
            try [
                DeclSyntax(
                    FunctionDeclSyntax(
                        """
                        /// Custom Encoding Method for `PatchableValue` fields
                        public func encode(to encoder: any Encoder) throws {
                            var codingContainer = encoder.container(keyedBy: Self.CodingKeys.self)
                        \(raw: encodeStatements.prepad(1))
                        }
                        """,
                    ),
                ),
                DeclSyntax(
                    InitializerDeclSyntax(
                        """
                        \(raw: decoderInitPrefix) init(from decoder: any Decoder) throws {
                            let codingContainer = try decoder.container(keyedBy: Self.CodingKeys.self)
                        \(raw: decodeStatements.prepad(1))
                        }
                        """,
                    ),
                ),
                DeclSyntax(
                    FunctionDeclSyntax(
                        """
                        /// Reset all patchable fields to `unmodified`
                        public \(raw: resetMutatingPrefix)func resetPatchableFields() {
                        \(raw: resetStatements.prepad(1))
                        }
                        """,
                    ),
                ),
                DeclSyntax(
                    FunctionDeclSyntax(
                        """
                        public func isUnmodified() -> Bool {
                            return \(raw: isUnmodifiedValues)
                        }
                        """,
                    ),
                )
            ]
        }
    }

    private var equatableDeclaration: FunctionDeclSyntax {
        let comparison = if usesIdentityEquality {
            "lhs === rhs"
        } else if equatableProperties.isEmpty {
            "true"
        } else {
            equatableProperties.map { "lhs.\($0) == rhs.\($0)" }.joined(separator: " &&\n")
        }
        return SwiftGeneratedSyntax.parse("class equatable member") {
            try FunctionDeclSyntax(
                """
                \(raw: visibility.rawValue) static func == (lhs: \(raw: name), rhs: \(raw: name)) -> Bool {
                \(raw: comparison.prepad(1))
                }
                """,
            )
        }
    }

    private var hashableDeclaration: FunctionDeclSyntax {
        let hashes = if usesIdentityHash {
            "hasher.combine(ObjectIdentifier(self))"
        } else if hashableProperties.isEmpty {
            "hasher.combine(0)"
        } else {
            hashableProperties.map { "hasher.combine(self.\($0))" }.joined(separator: "\n")
        }
        return SwiftGeneratedSyntax.parse("class hashable member") {
            try FunctionDeclSyntax(
                """
                \(raw: visibility.rawValue) func hash(into hasher: inout Hasher) {
                \(raw: hashes.prepad(1))
                }
                """,
            )
        }
    }

    private var usesIdentityEquality: Bool {
        !isValueType && (equatableProperties.isEmpty || usesIdentityHash)
    }

    private var usesIdentityHash: Bool {
        !isValueType && protocols.contains("Hashable") && hashableProperties.isEmpty
    }
}
