import Foundation
import GeneratorBuilder

struct KotlinDataClass: Node {
    var name: String
    var properties: [KotlinProperty]
    var annotations: [String]
    var interfaces: [String]
    var nestedDeclarations: [String]
    var isDataClass: Bool
    var includeGeneratedComment: Bool
    var additionalImports: Set<String>

    init(
        name: String,
        properties: [KotlinProperty],
        annotations: [String] = [],
        interfaces: [String] = [],
        nestedDeclarations: [String] = [],
        isDataClass: Bool = true,
        includeGeneratedComment: Bool = true,
        additionalImports: Set<String> = []
    ) {
        self.name = name
        self.properties = properties
        self.annotations = annotations
        self.interfaces = interfaces
        self.nestedDeclarations = nestedDeclarations
        self.isDataClass = isDataClass
        self.includeGeneratedComment = includeGeneratedComment
        self.additionalImports = additionalImports
    }

    var imports: Set<String> {
        properties.reduce(additionalImports) { imports, property in
            imports.union(property.imports)
        }
    }

    func toString() -> String {
        var header: [any Node] = []
        if includeGeneratedComment {
            header.append("// Generated code. Modify at your own risk.")
        }
        header.append(contentsOf: annotations)

        let inheritance = interfaces.isEmpty ? "" : " : \(interfaces.joined(separator: ", "))"

        let declaration: String
        if properties.isEmpty {
            declaration = "class \(name)\(inheritance)"
        } else {
            let classKeyword = isDataClass ? "data class" : "class"
            let propertyNodes: [any Node] = properties.map { property in
                property.declaration.appendingCommaToLastLine()
            }
            declaration = Block {
                "\(classKeyword) \(name)("
                Indentation {
                    NodeList(propertyNodes)
                }
                ")\(inheritance)"
            }.toString()
        }

        let members = nestedDeclarations + byteArrayEqualityMembers()
        let body = if members.isEmpty {
            declaration
        } else {
            Block {
                "\(declaration) {"
                Indentation {
                    NodeList(members.map { $0 as any Node })
                }
                "}"
            }
            .toString()
        }

        return Block {
            NodeList(header)
            body
        }
        .toString()
    }

    private func byteArrayEqualityMembers() -> [String] {
        guard isDataClass, properties.contains(where: \.isDirectByteArray) else {
            return []
        }
        return [
            kotlinEqualsFunction(className: name, properties: properties),
            kotlinHashCodeFunction(properties: properties)
        ]
    }
}

private func kotlinEqualsFunction(className: String, properties: [KotlinProperty]) -> String {
    Block {
        "override fun equals(other: Any?): Boolean {"
        Indentation {
            "if (this === other) return true"
            "if (other !is \(className)) return false"
            for (index, property) in properties.enumerated() {
                if property.isDirectByteArray {
                    property.byteArrayEqualityExpression(
                        otherPrefix: "other",
                        otherValueName: "otherByteArray\(index)"
                    )
                } else {
                    "if (\(property.name) != other.\(property.name)) return false"
                }
            }
            "return true"
        }
        "}"
    }
    .toString()
}

private func kotlinHashCodeFunction(properties: [KotlinProperty]) -> String {
    guard let firstProperty = properties.first else {
        return "override fun hashCode(): Int = 0"
    }
    let remainingProperties = properties.dropFirst()
    return Block {
        "override fun hashCode(): Int {"
        Indentation {
            "var result = \(firstProperty.hashCodeExpression)"
            for property in remainingProperties {
                "result = 31 * result + \(property.hashCodeExpression)"
            }
            "return result"
        }
        "}"
    }
    .toString()
}

struct KotlinEnumCase: Hashable {
    var name: String
    var arguments: [String]
    var annotations: [String]

    init(
        name: String,
        arguments: [String] = [],
        annotations: [String] = []
    ) {
        self.name = name
        self.arguments = arguments
        self.annotations = annotations
    }

    var declaration: String {
        let argumentDeclaration = arguments.isEmpty ? "" : "(\(arguments.joined(separator: ", ")))"
        let caseDeclaration = "\(name)\(argumentDeclaration)"

        if annotations.isEmpty {
            return caseDeclaration
        }

        return (annotations + [caseDeclaration]).joined(separator: "\n")
    }
}

struct KotlinEnumClass: Node {
    var name: String
    var cases: [KotlinEnumCase]
    var rawValuePropertyName: String?
    var rawValueType: KotlinTypeName?
    var annotations: [String]
    var interfaces: [String]
    var functions: [String]
    var includeGeneratedComment: Bool
    var additionalImports: Set<String>

    init(
        name: String,
        cases: [KotlinEnumCase],
        rawValuePropertyName: String? = nil,
        rawValueType: KotlinTypeName? = nil,
        annotations: [String] = [],
        interfaces: [String] = [],
        functions: [String] = [],
        includeGeneratedComment: Bool = true,
        additionalImports: Set<String> = []
    ) {
        self.name = name
        self.cases = cases
        self.rawValuePropertyName = rawValuePropertyName
        self.rawValueType = rawValueType
        self.annotations = annotations
        self.interfaces = interfaces
        self.functions = functions
        self.includeGeneratedComment = includeGeneratedComment
        self.additionalImports = additionalImports
    }

    var imports: Set<String> {
        additionalImports.union(rawValueType?.imports ?? [])
    }

    func toString() -> String {
        var header: [any Node] = []
        if includeGeneratedComment {
            header.append("// Generated code. Modify at your own risk.")
        }
        header.append(contentsOf: annotations)

        let constructorDeclaration = if let rawValuePropertyName, let rawValueType {
            "(\n    val \(rawValuePropertyName): \(rawValueType.declaration),\n)"
        } else {
            ""
        }

        var bodyLines: [any Node] = []
        for (index, item) in cases.enumerated() {
            bodyLines.append(item.declaration.prepad(1).appendingCommaToLastLine())
            if index < cases.count - 1 {
                bodyLines.append(NewLine())
            }
        }
        if !functions.isEmpty {
            bodyLines.append("    ;")
            bodyLines.append(NewLine())
            bodyLines.append(contentsOf: functions.map { $0.prepad(1) as any Node })
        }

        return Block {
            NodeList(header)
            let inheritance = interfaces.isEmpty ? "" : " : \(interfaces.joined(separator: ", "))"
            "enum class \(name)\(constructorDeclaration)\(inheritance) {"
            NodeList(bodyLines)
            "}"
        }
        .toString()
    }
}

private extension String {
    func appendingCommaToLastLine() -> String {
        var lines = components(separatedBy: "\n")
        guard let last = lines.indices.last else {
            return self
        }
        lines[last] += ","
        return lines.joined(separator: "\n")
    }
}
