import Combine
import Foundation
import RoundTrip
import RoundTripREST

/// ☠️☠️☠️ This is generated code, modify at your own risk
public extension LocationStructureApi {
    struct GetOperation: Sendable {
        public struct Request: URLRequestConvertible, Equatable, Sendable {
            public var structureId: Int64
            public var requestPath: String {
                let pathSegmentAllowedCharacters = CharacterSet.urlPathAllowed.subtracting(CharacterSet(charactersIn: "/"))
                var path = "/structure/{structure_id}"
                path = path.replacingOccurrences(
                    of: "{structure_id}",
                    with: String(structureId).addingPercentEncoding(withAllowedCharacters: pathSegmentAllowedCharacters) ?? String(structureId),
                )
                return path
            }

            public init(structureId: Int64) {
                self.structureId = structureId
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

        public typealias Response = IdentifiedStructure
    }
}
