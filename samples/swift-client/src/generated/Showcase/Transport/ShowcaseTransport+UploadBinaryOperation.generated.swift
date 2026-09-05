import Combine
import Foundation
import RoundTrip
import RoundTripREST

/// ☠️☠️☠️ This is generated code, modify at your own risk
public extension ShowcaseTransportApi {
    struct UploadBinaryOperation: Sendable {
        public struct Request: URLRequestConvertible, Equatable, Sendable {
            public var contentMd5: String?
            public var apiKey: String
            public var body: Data
            public var requestPath: String {
                "/showcase/uploads/binary"
            }

            public var httpHeaders: [String: String] {
                var values: [String: String] = [:]
                if let __api0ContentMd5Value = self.contentMd5 {
                    values["Content-MD5"] = __api0ContentMd5Value
                }
                let __api1ApiKeyValue = self.apiKey
                values["Authorization"] = __api1ApiKeyValue

                return values
            }

            public init(contentMd5: String? = nil, apiKey: String = "", body: Data) {
                self.contentMd5 = contentMd5
                self.apiKey = apiKey
                self.body = body
            }

            public func buildRequest(baseUrl: URL?, encoder: JSONEncoder) throws -> URLRequest {
                guard let baseUrl else {
                    throw ApiError.invalidURL
                }
                var request = try URLRequest(
                    baseUrl: baseUrl,
                    path: requestPath,
                    queryParams: nil
                )
                request.httpMethod = "POST"
                let httpHeaders = self.httpHeaders
                let hasExplicitAccept = httpHeaders.keys.contains {
                    $0.lowercased() == "accept"
                }
                if !hasExplicitAccept {
                    request.accept(mimeType: "application/zip")
                }
                for (key, value) in httpHeaders {
                    request.addHeader(value, name: key)
                }
                request.contentType(mimeType: "application/octet-stream")
                request.httpBody = body
                return request
            }
        }
    }
}
