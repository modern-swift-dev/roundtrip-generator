import Combine
import Foundation
import RoundTrip
import RoundTripREST

/// ☠️☠️☠️ This is generated code, modify at your own risk
public extension AdminGroupApi {
    struct GetOperation: Sendable {
        public struct Request: URLRequestConvertible, Equatable, Sendable {
            public var groupId: Int64
            public var requestPath: String {
                let pathSegmentAllowedCharacters = CharacterSet.urlPathAllowed.subtracting(CharacterSet(charactersIn: "/"))
                var path = "/group/{group_id}"
                path = path.replacingOccurrences(
                    of: "{group_id}",
                    with: String(groupId).addingPercentEncoding(withAllowedCharacters: pathSegmentAllowedCharacters) ?? String(groupId),
                )
                return path
            }

            public init(groupId: Int64) {
                self.groupId = groupId
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

        public typealias Response = IdentifiedGroup
    }
}
