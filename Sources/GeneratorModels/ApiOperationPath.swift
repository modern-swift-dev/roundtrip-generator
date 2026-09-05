import Foundation

/// Defines how a generated operation gets its URL.
public enum ApiOperationPath: Sendable {
    /// A path relative to the generated client's base URL.
    ///
    /// - parameter path: The rest of the path. Ex: `/users/`
    case relative(String)

    /// A fully known URL string.
    case absolute(String)

    /// A URL supplied at runtime rather than generated from a fixed path.
    case runtime

    public var isRuntime: Bool {
        switch self {
            case .runtime:
                true
            default:
                false
        }
    }
}
