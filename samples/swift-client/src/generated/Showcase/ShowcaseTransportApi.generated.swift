import Combine
import Foundation
import RoundTrip
import RoundTripREST

// ☠️☠️☠️ This is generated code, modify at your own risk
// sourcery: AutoMockable
public protocol ShowcaseTransportApiAsyncAwaitProtocol: Sendable {
    func uploadMultipart(
        request: ShowcaseTransportApi.UploadMultipartOperation.Request, progress: Progress?
    ) async throws -> ApiOperationResult<ShowcaseTransportApi.UploadMultipartOperation.Response>
    func uploadFile(
        request: ShowcaseTransportApi.UploadFileOperation.Request, progress: Progress?
    ) async throws -> ApiOperationResult<ShowcaseTransportApi.UploadFileOperation.Response>
    func uploadBinary(
        request: ShowcaseTransportApi.UploadBinaryOperation.Request
    ) async throws -> ApiResponse
    func deleteWithBody(
        request: ShowcaseTransportApi.DeleteWithBodyOperation.Request
    ) async throws -> ApiOperationResult<ShowcaseTransportApi.DeleteWithBodyOperation.Response>
}

/// ☠️☠️☠️ This is generated code, modify at your own risk
public final class ShowcaseTransportApi: ShowcaseTransportApiAsyncAwaitProtocol, Sendable {
    private let client: any RestClientProtocol
    public init(client: any RestClientProtocol) {
        self.client = client
    }

    public func uploadMultipart(request: UploadMultipartOperation.Request, progress: Progress?) async throws -> ApiOperationResult<UploadMultipartOperation.Response> {
        var adaptedRequest = request
        if adaptedRequest.apiKey.isEmpty {
            adaptedRequest.apiKey = try await client.requireApiKey()
        }
        return try await client.postMultipart(
            request: adaptedRequest,
            progress: progress,
            validStatusCode: [200, 201]
        )
    }

    public func uploadFile(request: UploadFileOperation.Request, progress: Progress?) async throws -> ApiOperationResult<UploadFileOperation.Response> {
        var adaptedRequest = request
        if adaptedRequest.apiKey.isEmpty {
            adaptedRequest.apiKey = try await client.requireApiKey()
        }
        return try await client.upload(
            request: adaptedRequest,
            fileUrl: request.body,
            progress: progress,
            validStatusCode: [200, 201]
        )
    }

    public func uploadBinary(request: UploadBinaryOperation.Request) async throws -> ApiResponse {
        var adaptedRequest = request
        if adaptedRequest.apiKey.isEmpty {
            adaptedRequest.apiKey = try await client.requireApiKey()
        }
        return try await client.execute(
            request: adaptedRequest,
            validStatusCode: [200, 202]
        )
    }

    public func deleteWithBody(request: DeleteWithBodyOperation.Request) async throws -> ApiOperationResult<DeleteWithBodyOperation.Response> {
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
