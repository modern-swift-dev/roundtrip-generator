import Combine
import Foundation
import RoundTrip
import RoundTripREST

// ☠️☠️☠️ This is generated code, modify at your own risk
// sourcery: AutoMockable
public protocol ShowcaseSampleModelsApiAsyncAwaitProtocol: Sendable {
    func getMatrix(
        request: ShowcaseSampleModelsApi.GetMatrixOperation.Request,
    ) async throws -> ApiOperationResult<ShowcaseSampleModelsApi.GetMatrixOperation.Response>
    func createNotification(
        request: ShowcaseSampleModelsApi.CreateNotificationOperation.Request,
    ) async throws -> ApiOperationResult<ShowcaseSampleModelsApi.CreateNotificationOperation.Response>
    func followRuntimeUrl(
        request: ShowcaseSampleModelsApi.FollowRuntimeUrlOperation.Request,
    ) async throws -> ApiOperationResult<ShowcaseSampleModelsApi.FollowRuntimeUrlOperation.Response>
    func getNextPage(
        _ currentPage: ShowcaseSampleModelsApi.FollowRuntimeUrlOperation.Response,
        request: ShowcaseSampleModelsApi.FollowRuntimeUrlOperation.Request,
    ) async throws -> ApiOperationResult<ShowcaseSampleModelsApi.FollowRuntimeUrlOperation.Response>
}

/// ☠️☠️☠️ This is generated code, modify at your own risk
public final class ShowcaseSampleModelsApi: ShowcaseSampleModelsApiAsyncAwaitProtocol, Sendable {
    private let client: any RestClientProtocol
    public init(client: any RestClientProtocol) {
        self.client = client
    }

    private struct NextPageRequest: URLRequestConvertible, Sendable {
        let requestPath: URL
        let httpHeaders: [String: String]

        func buildRequest(baseUrl _: URL?, encoder _: JSONEncoder) throws -> URLRequest {
            var request = try URLRequest(url: requestPath, queryParams: nil)
            request.httpMethod = "GET"
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

    public func getNextPage(
        _ currentPage: FollowRuntimeUrlOperation.Response,
        request: FollowRuntimeUrlOperation.Request,
    ) async throws -> ApiOperationResult<FollowRuntimeUrlOperation.Response> {
        var adaptedRequest = request
        if adaptedRequest.apiKey?.isEmpty != false {
            adaptedRequest.apiKey = await client.apiKey()
        }
        guard let next = currentPage.next else {
            throw ApiError.invalidURL
        }
        return try await client.execute(
            request: NextPageRequest(requestPath: next, httpHeaders: adaptedRequest.httpHeaders),
            validStatusCode: [200],
        )
    }

    public func getMatrix(request: GetMatrixOperation.Request) async throws -> ApiOperationResult<GetMatrixOperation.Response> {
        var adaptedRequest = request
        if adaptedRequest.apiKey?.isEmpty != false {
            adaptedRequest.apiKey = await client.apiKey()
        }
        return try await client.execute(
            request: adaptedRequest,
            validStatusCode: [200],
        )
    }

    public func createNotification(request: CreateNotificationOperation.Request) async throws -> ApiOperationResult<CreateNotificationOperation.Response> {
        var adaptedRequest = request
        if adaptedRequest.apiKey.isEmpty {
            adaptedRequest.apiKey = try await client.requireApiKey()
        }
        return try await client.execute(
            request: adaptedRequest,
            validStatusCode: [200, 201, 202],
        )
    }

    public func followRuntimeUrl(request: FollowRuntimeUrlOperation.Request) async throws -> ApiOperationResult<FollowRuntimeUrlOperation.Response> {
        var adaptedRequest = request
        if adaptedRequest.apiKey?.isEmpty != false {
            adaptedRequest.apiKey = await client.apiKey()
        }
        return try await client.execute(
            request: adaptedRequest,
            validStatusCode: [200],
        )
    }
}
