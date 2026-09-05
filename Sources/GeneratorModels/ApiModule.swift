import Foundation

public struct ApiModule: Sendable {
    /// The name of the module
    ///
    /// > The `name` is used to generate the directory structure, and prefix the api definitions generated code (ensuring uniqueness).
    public let name: String

    /// The API definitions generated in this module.
    ///
    /// > Definitions are generally mapped closely to their back-end service equivalents.
    public let definitions: [ApiService]

    /// Data types available to every definition in this module.
    ///
    /// > Module references are generated for this module and are not available to other modules unless also declared there.
    public var references: [ApiTypeSchema] = []

    public init(name: String, definitions: [ApiService], references: [ApiTypeSchema] = []) {
        self.name = name
        self.definitions = definitions
        self.references = references
    }
}
