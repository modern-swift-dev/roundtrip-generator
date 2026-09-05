import Foundation

/// An associative enum case
public struct ApiEnumCase: Sendable {
    /// The name of the `case`.
    public var name: String

    /// The raw name of the `case`
    public var rawName: String

    /// The values of this case
    public var values: [ApiEnumAssociatedValue]
}
