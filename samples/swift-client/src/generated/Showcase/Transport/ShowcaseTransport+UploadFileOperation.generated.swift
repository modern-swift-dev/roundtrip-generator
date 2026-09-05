import Combine
import Foundation
import RoundTrip
import RoundTripREST

/// ☠️☠️☠️ This is generated code, modify at your own risk
public extension ShowcaseTransportApi {
    struct UploadFileOperation: Sendable {
        public struct Request: URLRequestConvertible, Equatable, Sendable {
            public var apiKey: String
            public var body: URL
            public var requestPath: String {
                "/showcase/uploads/file"
            }

            public var httpHeaders: [String: String] {
                var values: [String: String] = [:]
                let __api0ApiKeyValue = apiKey
                values["Authorization"] = __api0ApiKeyValue

                return values
            }

            public init(apiKey: String = "", body: URL) {
                self.apiKey = apiKey
                self.body = body
            }

            public func buildRequest(baseUrl: URL?, encoder _: JSONEncoder) throws -> URLRequest {
                guard let baseUrl else {
                    throw ApiError.invalidURL
                }
                var request = try URLRequest(
                    baseUrl: baseUrl,
                    path: requestPath,
                    queryParams: nil,
                )
                request.httpMethod = "POST"
                let httpHeaders = httpHeaders
                let hasExplicitAccept = httpHeaders.keys.contains {
                    $0.lowercased() == "accept"
                }
                if !hasExplicitAccept {
                    request.accept(mimeType: "application/json")
                }
                for (key, value) in httpHeaders {
                    request.addHeader(value, name: key)
                }

                return request
            }
        }

        public typealias Response = UploadReceipt
    }
}
