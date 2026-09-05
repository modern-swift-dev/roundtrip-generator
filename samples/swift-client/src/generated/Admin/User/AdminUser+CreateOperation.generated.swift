import Combine
import Foundation
import RoundTrip
import RoundTripREST

/// ☠️☠️☠️ This is generated code, modify at your own risk
public extension AdminUserApi {
    struct CreateOperation: Sendable {
        public struct Request: URLRequestConvertible, Sendable {
            public var body: User
            public var requestPath: String {
                "/user"
            }

            public init(body: User) {
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
                request.accept(mimeType: "application/json")

                request.contentType(mimeType: "application/json")
                try request.codableBody(body, encoder: encoder)
                return request
            }
        }

        public typealias Response = IdUser
    }
}
