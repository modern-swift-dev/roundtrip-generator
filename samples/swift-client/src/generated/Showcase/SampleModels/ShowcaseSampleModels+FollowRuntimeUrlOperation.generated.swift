import Combine
import Foundation
import RoundTrip
import RoundTripREST

/// ☠️☠️☠️ This is generated code, modify at your own risk
public extension ShowcaseSampleModelsApi {
    struct FollowRuntimeUrlOperation: Sendable {
        public struct Request: URLRequestConvertible, Equatable, Sendable {
            public var apiKey: String?
            public var requestPath: URL
            public var httpHeaders: [String: String] {
                var values: [String: String] = [:]
                if let __api0ApiKeyValue = self.apiKey {
                    values["Authorization"] = __api0ApiKeyValue
                }

                return values
            }

            public init(requestPath: URL, apiKey: String? = nil) {
                self.requestPath = requestPath
                self.apiKey = apiKey
            }

            public func buildRequest(baseUrl: URL?, encoder _: JSONEncoder) throws -> URLRequest {
                var request = try URLRequest(url: requestPath, queryParams: nil)
                request.httpMethod = "GET"
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
        }

        public typealias Response = PagedResults<PrimitiveMatrix>
    }
}
