import Combine
import Foundation
import RoundTrip
import RoundTripREST

// ☠️☠️☠️ This is generated code, modify at your own risk
// sourcery: AutoMockable
public protocol TenantProjectApiAsyncAwaitProtocol: Sendable {
    func create(
        request: TenantProjectApi.CreateOperation.Request
    ) async throws -> ApiOperationResult<TenantProjectApi.CreateOperation.Response>
    func update(
        request: TenantProjectApi.UpdateOperation.Request
    ) async throws -> ApiOperationResult<TenantProjectApi.UpdateOperation.Response>
    func delete(
        request: TenantProjectApi.DeleteOperation.Request
    ) async throws -> ApiResponse
    func list(
        request: TenantProjectApi.ListOperation.Request
    ) async throws -> ApiOperationResult<TenantProjectApi.ListOperation.Response>
    func get(
        request: TenantProjectApi.GetOperation.Request
    ) async throws -> ApiOperationResult<TenantProjectApi.GetOperation.Response>
    func archive(
        request: TenantProjectApi.ArchiveOperation.Request
    ) async throws -> ApiOperationResult<TenantProjectApi.ArchiveOperation.Response>
}

/// ☠️☠️☠️ This is generated code, modify at your own risk
public final class TenantProjectApi: TenantProjectApiAsyncAwaitProtocol, Sendable {
    private let client: any RestClientProtocol
    public init(client: any RestClientProtocol) {
        self.client = client
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

    public func archive(request: ArchiveOperation.Request) async throws -> ApiOperationResult<ArchiveOperation.Response> {
        var adaptedRequest = request
        if adaptedRequest.apiKey.isEmpty {
            adaptedRequest.apiKey = try await client.requireApiKey()
        }
        return try await client.execute(
            request: adaptedRequest,
            validStatusCode: [200, 202]
        )
    }
}
