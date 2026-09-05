import Foundation

/// `ApiRequestBody` allows you to configure the `request` body of your http request.
public enum ApiRequestBody: Sendable {

    /// `none`, meaning that the request has no body property. Usually for `GET` or `DELETE` request
    case none

    /// `binary`, meaning that the data sent is binary,
    ///
    /// - parameter mimeType: The mime-type of the body. Defaults to `application/octet-stream`
    case binary(mimeType: String = "application/octet-stream")

    /// `file`, meaning that the data sent is binary, but loaded from a file URL
    case file

    /// `multipart`, meaning that the data uploaded is multiple parts. You can have as many parts as you need,
    /// but the caller is responsible for setting the right part with the right payload.
    case multiPart([String])

    /// `json` meaning that the data-type is plain old JSON codable
    ///
    /// - parameter dataType: The ApiTypeSchema.
    case json(ApiTypeSchema?)

    public var dataType: ApiTypeSchema? {
        switch self {
            case let .json(type):
                type
            case .file:
                .url(nil)
            default:
                nil
        }
    }

    public var mimeType: String? {
        switch self {
            case let .binary(mimeType):
                mimeType
            case .json:
                "application/json"
            default:
                nil
        }
    }

}
