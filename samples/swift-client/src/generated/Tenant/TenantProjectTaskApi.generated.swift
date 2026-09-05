import Combine
import Foundation
import RoundTrip
import RoundTripREST

// ☠️☠️☠️ This is generated code, modify at your own risk
// sourcery: AutoMockable
public protocol TenantProjectTaskApiAsyncAwaitProtocol: Sendable {
    func create(
        request: TenantProjectTaskApi.CreateOperation.Request,
    ) async throws -> ApiOperationResult<TenantProjectTaskApi.CreateOperation.Response>
    func patch(
        request: TenantProjectTaskApi.PatchOperation.Request,
    ) async throws -> ApiOperationResult<TenantProjectTaskApi.PatchOperation.Response>
    func list(
        request: TenantProjectTaskApi.ListOperation.Request,
    ) async throws -> ApiOperationResult<TenantProjectTaskApi.ListOperation.Response>
    func get(
        request: TenantProjectTaskApi.GetOperation.Request,
    ) async throws -> ApiOperationResult<TenantProjectTaskApi.GetOperation.Response>
    func complete(
        request: TenantProjectTaskApi.CompleteOperation.Request,
    ) async throws -> ApiOperationResult<TenantProjectTaskApi.CompleteOperation.Response>
    func getNextPage(
        _ currentPage: TenantProjectTaskApi.ListOperation.Response,
        request: TenantProjectTaskApi.ListOperation.Request,
    ) async throws -> ApiOperationResult<TenantProjectTaskApi.ListOperation.Response>
}

/// ☠️☠️☠️ This is generated code, modify at your own risk
public final class TenantProjectTaskApi: TenantProjectTaskApiAsyncAwaitProtocol, Sendable {
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
        _ currentPage: ListOperation.Response,
        request: ListOperation.Request,
    ) async throws -> ApiOperationResult<ListOperation.Response> {
        guard let next = currentPage.next else {
            throw ApiError.invalidURL
        }
        return try await client.execute(
            request: NextPageRequest(requestPath: next, httpHeaders: request.httpHeaders),
            validStatusCode: [200],
        )
    }

    public func create(request: CreateOperation.Request) async throws -> ApiOperationResult<CreateOperation.Response> {
        try await client.execute(
            request: request,
            validStatusCode: [200, 201],
        )
    }

    public func patch(request: PatchOperation.Request) async throws -> ApiOperationResult<PatchOperation.Response> {
        try await client.execute(
            request: request,
            validStatusCode: [200],
        )
    }

    public func list(request: ListOperation.Request) async throws -> ApiOperationResult<ListOperation.Response> {
        try await client.execute(
            request: request,
            validStatusCode: [200],
        )
    }

    public func get(request: GetOperation.Request) async throws -> ApiOperationResult<GetOperation.Response> {
        try await client.execute(
            request: request,
            validStatusCode: [200],
        )
    }

    public func complete(request: CompleteOperation.Request) async throws -> ApiOperationResult<CompleteOperation.Response> {
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
