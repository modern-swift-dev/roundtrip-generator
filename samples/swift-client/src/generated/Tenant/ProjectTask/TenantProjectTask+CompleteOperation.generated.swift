import Combine
import Foundation
import RoundTrip
import RoundTripREST

/// ☠️☠️☠️ This is generated code, modify at your own risk
public extension TenantProjectTaskApi {
    struct CompleteOperation: Sendable {
        public struct Request: URLRequestConvertible, Sendable {
            public let tenantId: String
            public var projectId: String
            public var taskId: String
            public var notify: Bool?
            public var apiKey: String?
            public var body: CompleteTaskRequest
            public var requestPath: String {
                let pathSegmentAllowedCharacters = CharacterSet.urlPathAllowed.subtracting(CharacterSet(charactersIn: "/"))
                var path = "/project/{project_id}/task/{task_id}/complete"
                path = path.replacingOccurrences(
                    of: "{project_id}",
                    with: String(projectId).addingPercentEncoding(withAllowedCharacters: pathSegmentAllowedCharacters) ?? String(projectId),
                )
                path = path.replacingOccurrences(
                    of: "{task_id}",
                    with: String(taskId).addingPercentEncoding(withAllowedCharacters: pathSegmentAllowedCharacters) ?? String(taskId),
                )
                return path
            }

            public var httpHeaders: [String: String] {
                var values: [String: String] = [:]
                let __api0TenantIdValue = tenantId
                values["X-Tenant-Id"] = __api0TenantIdValue
                if let __api1ApiKeyValue = apiKey {
                    values["Authorization"] = __api1ApiKeyValue
                }

                return values
            }

            public var queryParameters: [String: any FormEncodable] {
                var values: [String: any FormEncodable] = [:]
                if let __api0NotifyValue = notify {
                    values["notify"] = String(describing: __api0NotifyValue)
                }
                return values
            }

            public init(tenantId: String, projectId: String, taskId: String, notify: Bool? = true, apiKey: String? = nil, body: CompleteTaskRequest) {
                self.tenantId = tenantId
                self.projectId = projectId
                self.taskId = taskId
                self.notify = notify
                self.apiKey = apiKey
                self.body = body
            }

            public func buildRequest(baseUrl: URL?, encoder: JSONEncoder) throws -> URLRequest {
                guard let baseUrl else {
                    throw ApiError.invalidURL
                }
                var request = try URLRequest(
                    baseUrl: baseUrl,
                    path: requestPath,
                    queryParams: queryParameters,
                )
                request.httpMethod = "PATCH"
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
                request.contentType(mimeType: "application/json")
                try request.codableBody(body, encoder: encoder)
                return request
            }
        }

        /// ☠️☠️☠️ This is generated code, modify at your own risk
        public struct CompleteTaskRequest: Codable, Sendable {
            public var completedAt: Date
            public init(completedAt: Date) {
                self.completedAt = completedAt
            }

            public enum CodingKeys: String, CodingKey {
                case completedAt = "completed_at"
            }
        }

        public typealias Response = IdObject
    }
}
