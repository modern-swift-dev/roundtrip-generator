// Generated code. Do not edit.
import Foundation
import Vapor

public protocol ShowcaseTransportService: Sendable {
    func uploadMultipart(_ request: ShowcaseTransportUploadMultipartOperationRequest) async throws -> GeneratedResponse<ShowcaseTransportUploadReceipt>
    func uploadFile(_ request: ShowcaseTransportUploadFileOperationRequest) async throws -> GeneratedResponse<ShowcaseTransportUploadReceipt>
    func uploadBinary(_ request: ShowcaseTransportUploadBinaryOperationRequest) async throws -> GeneratedResponse<Data>
    func deleteWithBody(_ request: ShowcaseTransportDeleteWithBodyOperationRequest) async throws -> GeneratedResponse<ShowcaseTransportUploadReceipt>
}

public struct NotImplementedShowcaseTransportService: ShowcaseTransportService {
    public init() {}

    public func uploadMultipart(_: ShowcaseTransportUploadMultipartOperationRequest) async throws -> GeneratedResponse<ShowcaseTransportUploadReceipt> {
        throw Abort(.notImplemented)
    }

    public func uploadFile(_: ShowcaseTransportUploadFileOperationRequest) async throws -> GeneratedResponse<ShowcaseTransportUploadReceipt> {
        throw Abort(.notImplemented)
    }

    public func uploadBinary(_: ShowcaseTransportUploadBinaryOperationRequest) async throws -> GeneratedResponse<Data> {
        throw Abort(.notImplemented)
    }

    public func deleteWithBody(_: ShowcaseTransportDeleteWithBodyOperationRequest) async throws -> GeneratedResponse<ShowcaseTransportUploadReceipt> {
        throw Abort(.notImplemented)
    }
}
