import Combine
import Foundation
import RoundTrip
import RoundTripREST

/// ☠️☠️☠️ This is generated code, modify at your own risk
public extension AdminUserApi {
    struct UpdateOperation: Sendable {
        public struct Request: URLRequestConvertible, Sendable {
            public var userId: Int64
            public var body: User
            public var requestPath: String {
                let pathSegmentAllowedCharacters = CharacterSet.urlPathAllowed.subtracting(CharacterSet(charactersIn: "/"))
                var path = "/user/{user_id}"
                path = path.replacingOccurrences(
                    of: "{user_id}",
                    with: String(self.userId).addingPercentEncoding(withAllowedCharacters: pathSegmentAllowedCharacters) ?? String(self.userId)
                )
                return path
            }

            public init(userId: Int64, body: User) {
                self.userId = userId
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
                request.httpMethod = "PUT"
                request.accept(mimeType: "application/json")

                request.contentType(mimeType: "application/json")
                try request.codableBody(body, encoder: encoder)
                return request
            }
        }

        public typealias Response = IdUser
    }
}
