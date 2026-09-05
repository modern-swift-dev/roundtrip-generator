import Foundation

struct KotlinAndroidTypeName: Hashable {
    var declaration: String
    var imports: Set<String>

    init(_ declaration: String, imports: Set<String> = []) {
        self.declaration = declaration
        self.imports = imports
    }

    var nullable: KotlinAndroidTypeName {
        if declaration.hasSuffix("?") {
            return self
        }
        return .init("\(declaration)?", imports: imports)
    }
}
