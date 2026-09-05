import Combine
import Foundation
import RoundTrip
import RoundTripREST

/// ☠️☠️☠️ This is generated code, modify at your own risk
public extension AdminGroupApi {
    struct PatchOperation: Sendable {
        public struct Request: URLRequestConvertible, Sendable {
            public var groupId: Int64
            public var body: PatchedGroup
            public var requestPath: String {
                let pathSegmentAllowedCharacters = CharacterSet.urlPathAllowed.subtracting(CharacterSet(charactersIn: "/"))
                var path = "/group/{group_id}"
                path = path.replacingOccurrences(
                    of: "{group_id}",
                    with: String(self.groupId).addingPercentEncoding(withAllowedCharacters: pathSegmentAllowedCharacters) ?? String(self.groupId)
                )
                return path
            }

            public init(groupId: Int64, body: PatchedGroup) {
                self.groupId = groupId
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
                request.httpMethod = "PATCH"
                request.accept(mimeType: "application/json")

                request.contentType(mimeType: "application/json")
                try request.codableBody(body, encoder: encoder)
                return request
            }
        }

        public typealias Response = IdGroup
    }
}
