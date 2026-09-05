import Combine
import Foundation
import RoundTrip
import RoundTripREST

/// ☠️☠️☠️ This is generated code, modify at your own risk
public extension AdminRoleApi {
    struct UpdateOperation: Sendable {
        public struct Request: URLRequestConvertible, Sendable {
            public var roleId: Int64
            public var body: Role
            public var requestPath: String {
                let pathSegmentAllowedCharacters = CharacterSet.urlPathAllowed.subtracting(CharacterSet(charactersIn: "/"))
                var path = "/role/{role_id}"
                path = path.replacingOccurrences(
                    of: "{role_id}",
                    with: String(roleId).addingPercentEncoding(withAllowedCharacters: pathSegmentAllowedCharacters) ?? String(roleId),
                )
                return path
            }

            public init(roleId: Int64, body: Role) {
                self.roleId = roleId
                self.body = body
            }

            public func buildRequest(baseUrl: URL?, encoder: JSONEncoder) throws -> URLRequest {
                guard let baseUrl else {
                    throw ApiError.invalidURL
                }
                var request = try URLRequest(
                    baseUrl: baseUrl,
                    path: requestPath,
                    queryParams: nil,
                )
                request.httpMethod = "PUT"
                request.accept(mimeType: "application/json")

                request.contentType(mimeType: "application/json")
                try request.codableBody(body, encoder: encoder)
                return request
            }
        }

        public typealias Response = IdRole
    }
}
