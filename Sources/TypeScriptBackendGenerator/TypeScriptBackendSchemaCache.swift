/// Collects the Zod schemas a generated file parses with at request time, so each is built once per process.
final class TypeScriptBackendSchemaCache {
    private var names: [String: String] = [:]
    private var declarations: [String] = []

    /// Returns an expression that evaluates to the shared instance of `schemaExpression`.
    func reference(to schemaExpression: String) -> String {
        if let name = names[schemaExpression] {
            return "\(name)()"
        }
        let name = "generatedSchema\(declarations.count + 1)"
        names[schemaExpression] = name
        declarations.append("const \(name) = lazySchema(() => \(schemaExpression));")
        return "\(name)()"
    }

    func source() -> String {
        declarations.joined(separator: "\n")
    }
}
