import Combine
import Foundation
import RoundTrip
import RoundTripREST

// ☠️☠️☠️ This is generated code, modify at your own risk
// sourcery: AutoMockable
public protocol AdminRoleApiAsyncAwaitProtocol: Sendable {
    func create(
        request: AdminRoleApi.CreateOperation.Request
    ) async throws -> ApiOperationResult<AdminRoleApi.CreateOperation.Response>
    func update(
        request: AdminRoleApi.UpdateOperation.Request
    ) async throws -> ApiOperationResult<AdminRoleApi.UpdateOperation.Response>
    func patch(
        request: AdminRoleApi.PatchOperation.Request
    ) async throws -> ApiOperationResult<AdminRoleApi.PatchOperation.Response>
    func delete(
        request: AdminRoleApi.DeleteOperation.Request
    ) async throws -> ApiResponse
    func list(
        request: AdminRoleApi.ListOperation.Request
    ) async throws -> ApiOperationResult<AdminRoleApi.ListOperation.Response>
    func get(
        request: AdminRoleApi.GetOperation.Request
    ) async throws -> ApiOperationResult<AdminRoleApi.GetOperation.Response>
    func getNextPage(
        _ currentPage: AdminRoleApi.ListOperation.Response,
        request: AdminRoleApi.ListOperation.Request
    ) async throws -> ApiOperationResult<AdminRoleApi.ListOperation.Response>
}

/// ☠️☠️☠️ This is generated code, modify at your own risk
public final class AdminRoleApi: AdminRoleApiAsyncAwaitProtocol, Sendable {
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
        request: ListOperation.Request
    ) async throws -> ApiOperationResult<ListOperation.Response> {
        guard let next = currentPage.next else {
            throw ApiError.invalidURL
        }
        return try await client.execute(
            request: NextPageRequest(requestPath: next, httpHeaders: [:]),
            validStatusCode: [200]
        )
    }

    public func create(request: CreateOperation.Request) async throws -> ApiOperationResult<CreateOperation.Response> {
        try await client.execute(
            request: request,
            validStatusCode: [200, 201]
        )
    }

    public func update(request: UpdateOperation.Request) async throws -> ApiOperationResult<UpdateOperation.Response> {
        try await client.execute(
            request: request,
            validStatusCode: [200]
        )
    }

    public func patch(request: PatchOperation.Request) async throws -> ApiOperationResult<PatchOperation.Response> {
        try await client.execute(
            request: request,
            validStatusCode: [200]
        )
    }

    public func delete(request: DeleteOperation.Request) async throws -> ApiResponse {
        try await client.execute(
            request: request,
            validStatusCode: [200, 204, 205]
        )
    }

    public func list(request: ListOperation.Request) async throws -> ApiOperationResult<ListOperation.Response> {
        try await client.execute(
            request: request,
            validStatusCode: [200]
        )
    }

    public func get(request: GetOperation.Request) async throws -> ApiOperationResult<GetOperation.Response> {
        try await client.execute(
            request: request,
            validStatusCode: [200]
        )
    }
}
