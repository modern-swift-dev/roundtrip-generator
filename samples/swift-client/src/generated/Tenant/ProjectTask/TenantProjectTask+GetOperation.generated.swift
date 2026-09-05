import Combine
import Foundation
import RoundTrip
import RoundTripREST

/// ☠️☠️☠️ This is generated code, modify at your own risk
public extension TenantProjectTaskApi {
    struct GetOperation: Sendable {
        public struct Request: URLRequestConvertible, Equatable, Sendable {
            public let tenantId: String
            public var projectId: String
            public var taskId: String
            public var requestPath: String {
                let pathSegmentAllowedCharacters = CharacterSet.urlPathAllowed.subtracting(CharacterSet(charactersIn: "/"))
                var path = "/project/{project_id}/task/{task_id}"
                path = path.replacingOccurrences(
                    of: "{project_id}",
                    with: String(self.projectId).addingPercentEncoding(withAllowedCharacters: pathSegmentAllowedCharacters) ?? String(self.projectId)
                )
                path = path.replacingOccurrences(
                    of: "{task_id}",
                    with: String(self.taskId).addingPercentEncoding(withAllowedCharacters: pathSegmentAllowedCharacters) ?? String(self.taskId)
                )
                return path
            }

            public var httpHeaders: [String: String] {
                var values: [String: String] = [:]
                let __api0TenantIdValue = self.tenantId
                values["X-Tenant-Id"] = __api0TenantIdValue

                return values
            }

            public init(tenantId: String, projectId: String, taskId: String) {
                self.tenantId = tenantId
                self.projectId = projectId
                self.taskId = taskId
            }

            public func buildRequest(baseUrl: URL?, encoder _: JSONEncoder) throws -> URLRequest {
                guard let baseUrl else {
                    throw ApiError.invalidURL
                }
                var request = try URLRequest(
                    baseUrl: baseUrl,
                    path: requestPath,
                    queryParams: nil
                )
                request.httpMethod = "GET"
                let httpHeaders = self.httpHeaders
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

        public typealias Response = IdentifiedTask
    }
}
