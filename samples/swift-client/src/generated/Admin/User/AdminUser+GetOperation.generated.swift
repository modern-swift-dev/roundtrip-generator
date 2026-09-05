import Combine
import Foundation
import RoundTrip
import RoundTripREST

/// ☠️☠️☠️ This is generated code, modify at your own risk
public extension AdminUserApi {
    struct GetOperation: Sendable {
        public struct Request: URLRequestConvertible, Equatable, Sendable {
            public var userId: Int64
            public var requestPath: String {
                let pathSegmentAllowedCharacters = CharacterSet.urlPathAllowed.subtracting(CharacterSet(charactersIn: "/"))
                var path = "/user/{user_id}"
                path = path.replacingOccurrences(
                    of: "{user_id}",
                    with: String(userId).addingPercentEncoding(withAllowedCharacters: pathSegmentAllowedCharacters) ?? String(userId),
                )
                return path
            }

            public init(userId: Int64) {
                self.userId = userId
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
                request.httpMethod = "GET"
                request.accept(mimeType: "application/json")

                return request
            }
        }

        public typealias Response = IdentifiedUser
    }
}
