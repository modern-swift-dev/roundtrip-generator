import Foundation

/// Defines whether generated operations include an `Authorization` header parameter.
///
/// > Security here only controls generated request parameters. Runtime storage and
/// > transport of credentials remain the app's responsibility.
public enum ApiAuthorizationHeaderPolicy: Sendable {
    /// No generated `Authorization` HTTP header.
    case unsecured

    /// Adds a required `Authorization` HTTP header parameter named `apiKey`.
    case secured

    /// Adds an optional `Authorization` HTTP header parameter named `apiKey`.
    case optional

    func append(to: inout [ApiParameter]) {
        switch self {
            case .unsecured:
                break
            case .secured:
                to.append(.predefined.apiKey)
            case .optional:
                to.append(.predefined.optionalApiKey)
        }
    }
}
