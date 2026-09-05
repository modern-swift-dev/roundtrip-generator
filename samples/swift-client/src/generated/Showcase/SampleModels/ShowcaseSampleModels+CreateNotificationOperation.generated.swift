import Combine
import Foundation
import RoundTrip
import RoundTripREST

/// ☠️☠️☠️ This is generated code, modify at your own risk
public extension ShowcaseSampleModelsApi {
    struct CreateNotificationOperation: Sendable {
        public struct Request: URLRequestConvertible, Sendable {
            public var idempotencyKey: String?
            public var apiKey: String
            public var body: NotificationEnvelope
            public var requestPath: String {
                "/showcase/notifications"
            }

            public var httpHeaders: [String: String] {
                var values: [String: String] = [:]
                if let __api0IdempotencyKeyValue = idempotencyKey {
                    values["Idempotency-Key"] = __api0IdempotencyKeyValue
                }
                let __api1ApiKeyValue = apiKey
                values["Authorization"] = __api1ApiKeyValue

                return values
            }

            public init(idempotencyKey: String? = nil, apiKey: String = "", body: NotificationEnvelope) {
                self.idempotencyKey = idempotencyKey
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
                    queryParams: nil,
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
                request.contentType(mimeType: "application/json")
                try request.codableBody(body, encoder: encoder)
                return request
            }
        }

        public typealias Response = NotificationEnvelope
    }
}
