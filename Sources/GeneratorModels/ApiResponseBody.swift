import Foundation

/// `ApiResponseBody` allows you to configure the `response` body of your http response.
public enum ApiResponseBody: Sendable {

    /// `none`, meaning that the response has no body.
    case none

    /// `binary`, meaning that the data received is binary, and of expected mime-type
    ///
    /// - parameter mimeType: The mime-type of the body.
    case binary(mimeType: String)

    /// `json` meaning that the data-type is plain old JSON codable
    ///
    /// - parameter dataType: The ApiTypeSchema.
    case json(ApiTypeSchema?)

    public var dataType: ApiTypeSchema? {
        switch self {
            case let .json(type):
                type
            default:
                nil
        }
    }

    public var mimeType: String {
        switch self {
            case let .binary(mimeType):
                mimeType
            case .json:
                "application/json"
            default:
                "*/*"
        }
    }
}
