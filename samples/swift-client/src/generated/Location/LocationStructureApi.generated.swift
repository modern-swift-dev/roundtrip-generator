import Combine
import Foundation
import RoundTrip
import RoundTripREST

// ☠️☠️☠️ This is generated code, modify at your own risk
// sourcery: AutoMockable
public protocol LocationStructureApiAsyncAwaitProtocol: Sendable {
    func create(
        request: LocationStructureApi.CreateOperation.Request
    ) async throws -> ApiOperationResult<LocationStructureApi.CreateOperation.Response>
    func update(
        request: LocationStructureApi.UpdateOperation.Request
    ) async throws -> ApiOperationResult<LocationStructureApi.UpdateOperation.Response>
    func patch(
        request: LocationStructureApi.PatchOperation.Request
    ) async throws -> ApiOperationResult<LocationStructureApi.PatchOperation.Response>
    func delete(
        request: LocationStructureApi.DeleteOperation.Request
    ) async throws -> ApiResponse
    func list(
        request: LocationStructureApi.ListOperation.Request
    ) async throws -> ApiOperationResult<LocationStructureApi.ListOperation.Response>
    func get(
        request: LocationStructureApi.GetOperation.Request
    ) async throws -> ApiOperationResult<LocationStructureApi.GetOperation.Response>
    func getNextPage(
        _ currentPage: LocationStructureApi.ListOperation.Response,
        request: LocationStructureApi.ListOperation.Request
    ) async throws -> ApiOperationResult<LocationStructureApi.ListOperation.Response>
}

/// ☠️☠️☠️ This is generated code, modify at your own risk
public final class LocationStructureApi: LocationStructureApiAsyncAwaitProtocol, Sendable {
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
