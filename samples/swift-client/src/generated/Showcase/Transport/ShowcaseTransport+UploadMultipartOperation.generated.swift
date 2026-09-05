import Combine
import Foundation
import RoundTrip
import RoundTripREST

/// ☠️☠️☠️ This is generated code, modify at your own risk
public extension ShowcaseTransportApi {
    struct UploadMultipartOperation: Sendable {
        public struct Request: URLRequestConvertible, MultipartBodyConvertible, Sendable {
            public var compress: Bool?
            public var apiKey: String
            public private(set) var body: [String: MultipartBody.Part] = [:]
            public mutating func setBodyPartFile(part: MultipartBody.Part) {
                body["file"] = part
            }

            public mutating func setBodyPartMetadata(part: MultipartBody.Part) {
                body["metadata"] = part
            }

            public var requestPath: String {
                "/showcase/uploads/multipart"
            }

            public var httpHeaders: [String: String] {
                var values: [String: String] = [:]
                let __api0ApiKeyValue = self.apiKey
                values["Authorization"] = __api0ApiKeyValue

                return values
            }

            public var queryParameters: [String: any FormEncodable] {
                var values: [String: any FormEncodable] = [:]
                if let __api0CompressValue = self.compress {
                    values["compress"] = String(describing: __api0CompressValue)
                }
                return values
            }

            public init(compress: Bool? = false, apiKey: String = "") {
                self.compress = compress
                self.apiKey = apiKey
            }

            public func buildRequest(baseUrl: URL?, encoder _: JSONEncoder) throws -> URLRequest {
                guard let baseUrl else {
                    throw ApiError.invalidURL
                }
                var request = try URLRequest(
                    baseUrl: baseUrl,
                    path: requestPath,
                    queryParams: queryParameters
                )
                request.httpMethod = "POST"
                let httpHeaders = self.httpHeaders
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

            public func multiPartBody(encoder _: JSONEncoder) throws -> MultipartBody {
                guard let builder = try MultipartBody.Builder() else {
                    throw ApiError.requestEncodingFailed
                }
                guard body["file"] != nil else {
                    throw ApiError.requestEncodingFailed
                }
                guard body["metadata"] != nil else {
                    throw ApiError.requestEncodingFailed
                }
                for (name, part) in body {
                    builder.addPart(name: name, part: part)
                }
                return try builder.build()
            }
        }

        public typealias Response = UploadReceipt
    }
}
