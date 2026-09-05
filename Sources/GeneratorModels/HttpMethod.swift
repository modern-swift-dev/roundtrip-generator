import Foundation

/// The supported Http Methods for the API Generator
public enum HttpMethod: String, Sendable {
    /// The Http Method `POST`
    case post

    /// The Http Method `GET`
    case get

    /// The Http Method `PATCH`
    case patch

    /// The Http Method `PUT`
    case put

    /// The Http Method `DELETE`
    case delete

    public var httpMethod: String {
        rawValue.uppercased()
    }
}
