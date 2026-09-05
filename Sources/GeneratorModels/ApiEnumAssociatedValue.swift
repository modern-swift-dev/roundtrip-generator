import Foundation

/// A associative enum case value
public struct ApiEnumAssociatedValue: Sendable {
    /// The name of the field
    public var name: String

    /// The raw name of the field
    public var rawName: String

    /// The data-type
    public var dataType: ApiTypeSchema

    /// Is Required?
    public var required: Bool = true
}
