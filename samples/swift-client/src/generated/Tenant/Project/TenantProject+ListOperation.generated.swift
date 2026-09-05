import Combine
import Foundation
import RoundTrip
import RoundTripREST

/// ☠️☠️☠️ This is generated code, modify at your own risk
public extension TenantProjectApi {
    struct ListOperation: Sendable {
        public struct Request: URLRequestConvertible, Equatable, Sendable {
            public let tenantId: String
            public var status: [TenantApi.TenantStatus]?
            public var includeArchived: Bool?
            public var requestPath: String {
                "/project"
            }

            public var httpHeaders: [String: String] {
                var values: [String: String] = [:]
                let __api0TenantIdValue = tenantId
                values["X-Tenant-Id"] = __api0TenantIdValue

                return values
            }

            public var queryParameters: [String: any FormEncodable] {
                var values: [String: any FormEncodable] = [:]
                if let __api0StatusValue = status, !__api0StatusValue.isEmpty {
                    values["status"] = __api0StatusValue.map {
                        $0.rawValue.formEncodableValue()
                    }.joined(separator: ",")
                }
                if let __api1IncludeArchivedValue = includeArchived {
                    values["include_archived"] = String(describing: __api1IncludeArchivedValue)
                }
                return values
            }

            public init(tenantId: String, status: [TenantApi.TenantStatus]? = [.active], includeArchived: Bool? = false) {
                self.tenantId = tenantId
                self.status = status
                self.includeArchived = includeArchived
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
                request.httpMethod = "GET"
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

        public typealias Response = [IdentifiedProject]
    }
}
