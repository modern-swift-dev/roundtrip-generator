import Foundation

struct KotlinAndroidProperty: Hashable {
    var mutable: Bool
    var name: String
    var typeName: KotlinAndroidTypeName
    var nullable: Bool
    var defaultValue: String?
    var annotations: [String]
    var modifiers: [String]
    var additionalImports: Set<String>

    init(
        mutable: Bool = false,
        name: String,
        typeName: KotlinAndroidTypeName,
        nullable: Bool = false,
        defaultValue: String? = nil,
        annotations: [String] = [],
        modifiers: [String] = [],
        additionalImports: Set<String> = []
    ) {
        self.mutable = mutable
        self.name = name
        self.typeName = typeName
        self.nullable = nullable
        self.defaultValue = defaultValue
        self.annotations = annotations
        self.modifiers = modifiers
        self.additionalImports = additionalImports
    }

    var imports: Set<String> {
        typeName.imports.union(additionalImports)
    }

    var declaration: String {
        let keyword = mutable ? "var" : "val"
        let typeDeclaration = nullable ? typeName.nullable.declaration : typeName.declaration
        let defaultDeclaration = defaultValue.map { " = \($0)" } ?? ""
        let modifierDeclaration = modifiers.isEmpty ? "" : "\(modifiers.joined(separator: " ")) "
        let propertyDeclaration = "\(modifierDeclaration)\(keyword) \(name): \(typeDeclaration)\(defaultDeclaration)"

        if annotations.isEmpty {
            return propertyDeclaration
        }

        return (annotations + [propertyDeclaration]).joined(separator: "\n")
    }

    var isDirectByteArray: Bool {
        typeName.declaration == "ByteArray"
    }

    var hashCodeExpression: String {
        if isDirectByteArray {
            return nullable ? "(\(name)?.contentHashCode() ?: 0)" : "\(name).contentHashCode()"
        }
        return nullable ? "(\(name)?.hashCode() ?: 0)" : "\(name).hashCode()"
    }

    func byteArrayEqualityExpression(otherPrefix: String, otherValueName: String) -> String {
        if !nullable {
            return "if (!\(name).contentEquals(\(otherPrefix).\(name))) return false"
        }
        return """
        val \(otherValueName) = \(otherPrefix).\(name)
        if (\(name) == null) {
            if (\(otherValueName) != null) return false
        } else if (\(otherValueName) == null || !\(name).contentEquals(\(otherValueName))) return false
        """
    }
}
