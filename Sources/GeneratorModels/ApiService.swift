import Foundation

/// A named group of ``ApiOperation`` values that generates one API service.
public struct ApiService: Sendable {

    /// The name of the definition. Ex: `Users`
    public let name: String

    /// The operations generated for this definition.
    public let operations: [ApiOperation]

    /// Data types generated as part of this definition.
    ///
    /// These types are scoped to this API definition, not generated globally.
    public let referencedTypes: [ApiTypeSchema]

    /// The initializer
    /// - parameter name: The name of the `ApiService`
    /// - parameter operations: The list of `ApiOperation` values for the definition.
    /// - parameter references: The data types generated for the definition.
    ///
    /// > The definition name is used to derive file names, directory names, and generated type names.
    ///
    public init(name: String, operations: [ApiOperation], references: [ApiTypeSchema] = []) {
        self.name = name
        self.operations = operations
        referencedTypes = references
    }

}
