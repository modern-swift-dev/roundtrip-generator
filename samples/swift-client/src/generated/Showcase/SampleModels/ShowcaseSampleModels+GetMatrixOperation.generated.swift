import Combine
import Foundation
import RoundTrip
import RoundTripREST
import UniformTypeIdentifiers

/// ☠️☠️☠️ This is generated code, modify at your own risk
public extension ShowcaseSampleModelsApi {
    struct GetMatrixOperation: Sendable {
        public struct Request: URLRequestConvertible, Equatable, Sendable {
            public let matrixId: String
            public var visible: Bool
            public var visibility: ShowcaseApi.SampleVisibility
            public var scores: [SampleScore]?
            public var traceId: String?
            public var sampleSession: String?
            public var apiKey: String?
            public var requestPath: String {
                let pathSegmentAllowedCharacters = CharacterSet.urlPathAllowed.subtracting(CharacterSet(charactersIn: "/"))
                var path = "/showcase/matrix/{matrix_id}"
                path = path.replacingOccurrences(
                    of: "{matrix_id}",
                    with: String(matrixId).addingPercentEncoding(withAllowedCharacters: pathSegmentAllowedCharacters) ?? String(matrixId),
                )
                return path
            }

            public var httpHeaders: [String: String] {
                var values: [String: String] = [:]
                if let __api0TraceIdValue = traceId {
                    values["X-Trace-Id"] = __api0TraceIdValue
                }
                if let __api1ApiKeyValue = apiKey {
                    values["Authorization"] = __api1ApiKeyValue
                }
                let cookieAllowedCharacters = CharacterSet.urlQueryAllowed.subtracting(CharacterSet(charactersIn: ";,= "))
                let cookieValues = httpCookies
                let cookies = cookieValues.keys.sorted().compactMap { name -> String? in
                    guard let encodedName = name.addingPercentEncoding(withAllowedCharacters: cookieAllowedCharacters),
                          let encodedValue = cookieValues[name]?.formEncodableValue().addingPercentEncoding(withAllowedCharacters: cookieAllowedCharacters) else {
                        return nil
                    }
                    return "\(encodedName)=\(encodedValue)"
                }.joined(separator: "; ")
                if !cookies.isEmpty {
                    values["Cookie"] = cookies
                }
                return values
            }

            public var httpCookies: [String: any FormEncodable] {
                var values: [String: any FormEncodable] = [:]
                if let __api0SampleSessionValue = sampleSession {
                    values["sample_session"] = __api0SampleSessionValue
                }
                return values
            }

            public var queryParameters: [String: any FormEncodable] {
                var values: [String: any FormEncodable] = [:]
                let __api0VisibleValue = visible
                values["visible"] = String(describing: __api0VisibleValue)
                let __api1VisibilityValue = visibility
                values["visibility"] = __api1VisibilityValue.rawValue
                if let __api2ScoresValue = scores, !__api2ScoresValue.isEmpty {
                    values["scores"] = __api2ScoresValue.map {
                        $0.rawValue.formEncodableValue()
                    }.joined(separator: ",")
                }
                return values
            }

            public init(
                matrixId: String,
                visible: Bool = true,
                visibility: ShowcaseApi.SampleVisibility = .public,
                scores: [SampleScore]? = [.high],
                traceId: String? = nil,
                sampleSession: String? = nil,
                apiKey: String? = nil
            ) {
                self.matrixId = matrixId
                self.visible = visible
                self.visibility = visibility
                self.scores = scores
                self.traceId = traceId
                self.sampleSession = sampleSession
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

        public typealias Response = PrimitiveMatrix
    }
}
