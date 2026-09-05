import Combine
import Foundation
import RoundTrip
import RoundTripREST

/// ☠️☠️☠️ This is generated code, modify at your own risk
public extension AdminRoleApi {
    struct ListOperation: Sendable {
        public struct Request: URLRequestConvertible, Equatable, Sendable {
            public var text: String?
            public var requestPath: String {
                "/role"
            }

            public var queryParameters: [String: any FormEncodable] {
                var values: [String: any FormEncodable] = [:]
                if let __api0TextValue = self.text {
                    values["text"] = __api0TextValue
                }
                return values
            }

            public init(text: String? = nil) {
                self.text = text
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
                request.httpMethod = "GET"
                request.accept(mimeType: "application/json")

                return request
            }
        }

        public typealias Response = PagedResults<IdentifiedRole>
    }
}
