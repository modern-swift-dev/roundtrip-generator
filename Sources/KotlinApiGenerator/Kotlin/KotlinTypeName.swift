import Foundation

struct KotlinTypeName: Hashable {
    var declaration: String
    var imports: Set<String>

    init(_ declaration: String, imports: Set<String> = []) {
        self.declaration = declaration
        self.imports = imports
    }

    var nullable: KotlinTypeName {
        if declaration.hasSuffix("?") {
            return self
        }
        return .init("\(declaration)?", imports: imports)
    }
}
