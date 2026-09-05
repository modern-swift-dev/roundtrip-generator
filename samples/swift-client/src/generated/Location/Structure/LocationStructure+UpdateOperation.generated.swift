import Combine
import Foundation
import RoundTrip
import RoundTripREST

/// ☠️☠️☠️ This is generated code, modify at your own risk
public extension LocationStructureApi {
    struct UpdateOperation: Sendable {
        public struct Request: URLRequestConvertible, Sendable {
            public var structureId: Int64
            public var body: Structure
            public var requestPath: String {
                let pathSegmentAllowedCharacters = CharacterSet.urlPathAllowed.subtracting(CharacterSet(charactersIn: "/"))
                var path = "/structure/{structure_id}"
                path = path.replacingOccurrences(
                    of: "{structure_id}",
                    with: String(structureId).addingPercentEncoding(withAllowedCharacters: pathSegmentAllowedCharacters) ?? String(structureId),
                )
                return path
            }

            public init(structureId: Int64, body: Structure) {
                self.structureId = structureId
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

        public typealias Response = IdStructure
    }
}
