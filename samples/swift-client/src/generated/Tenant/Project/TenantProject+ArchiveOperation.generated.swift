import Combine
import Foundation
import RoundTrip
import RoundTripREST

/// ☠️☠️☠️ This is generated code, modify at your own risk
public extension TenantProjectApi {
    struct ArchiveOperation: Sendable {
        public struct Request: URLRequestConvertible, Sendable {
            public let tenantId: String
            public var projectId: String
            public var cascade: Bool?
            public var apiKey: String
            public var requestPath: String {
                let pathSegmentAllowedCharacters = CharacterSet.urlPathAllowed.subtracting(CharacterSet(charactersIn: "/"))
                var path = "/project/{project_id}/archive"
                path = path.replacingOccurrences(
                    of: "{project_id}",
                    with: String(projectId).addingPercentEncoding(withAllowedCharacters: pathSegmentAllowedCharacters) ?? String(projectId),
                )
                return path
            }

            public var httpHeaders: [String: String] {
                var values: [String: String] = [:]
                let __api0TenantIdValue = tenantId
                values["X-Tenant-Id"] = __api0TenantIdValue
                let __api1ApiKeyValue = apiKey
                values["Authorization"] = __api1ApiKeyValue

                return values
            }

            public var queryParameters: [String: any FormEncodable] {
                var values: [String: any FormEncodable] = [:]
                if let __api0CascadeValue = cascade {
                    values["cascade"] = String(describing: __api0CascadeValue)
                }
                return values
            }

            public init(tenantId: String, projectId: String, cascade: Bool? = false, apiKey: String = "") {
                self.tenantId = tenantId
                self.projectId = projectId
                self.cascade = cascade
                self.apiKey = apiKey
            }

            public func buildRequest(baseUrl: URL?, encoder _: JSONEncoder) throws -> URLRequest {
                guard let baseUrl else {
                    throw ApiError.invalidURL
                }
                var request = try URLRequest(
                    baseUrl: baseUrl,
                    path: requestPath,
                    queryParams: queryParameters,
                )
                request.httpMethod = "POST"
                let httpHeaders = httpHeaders
                let hasExplicitAccept = httpHeaders.keys.contains {
                    $0.lowercased() == "accept"
                }
                if !hasExplicitAccept {
                    request.accept(mimeType: "application/json")
                }
                for (key, value) in httpHeaders {
                    request.addHeader(value, name: key)
                }

                return request
            }
        }

        public typealias Response = IdObject
    }
}
