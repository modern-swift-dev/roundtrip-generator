import Combine
import Foundation
import RoundTrip
import RoundTripREST

/// ☠️☠️☠️ This is generated code, modify at your own risk
public extension AdminRoleApi {
    struct DeleteOperation: Sendable {
        public struct Request: URLRequestConvertible, Equatable, Sendable {
            public var roleId: Int64
            public var requestPath: String {
                let pathSegmentAllowedCharacters = CharacterSet.urlPathAllowed.subtracting(CharacterSet(charactersIn: "/"))
                var path = "/role/{role_id}"
                path = path.replacingOccurrences(
                    of: "{role_id}",
                    with: String(roleId).addingPercentEncoding(withAllowedCharacters: pathSegmentAllowedCharacters) ?? String(roleId),
                )
                return path
            }

            public init(roleId: Int64) {
                self.roleId = roleId
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
                request.httpMethod = "DELETE"
                request.accept(mimeType: "*/*")

                return request
            }
        }
    }
}
