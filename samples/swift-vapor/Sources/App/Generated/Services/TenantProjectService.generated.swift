// Generated code. Do not edit.
import Foundation
import Vapor

public protocol TenantProjectService: Sendable {
    func create(_ request: TenantProjectCreateOperationRequest) async throws -> GeneratedResponse<TenantProjectIdProject>
    func update(_ request: TenantProjectUpdateOperationRequest) async throws -> GeneratedResponse<TenantProjectIdProject>
    func delete(_ request: TenantProjectDeleteOperationRequest) async throws -> GeneratedResponse<Void>
    func list(_ request: TenantProjectListOperationRequest) async throws -> GeneratedResponse<[TenantProjectIdentifiedProject]>
    func get(_ request: TenantProjectGetOperationRequest) async throws -> GeneratedResponse<TenantProjectIdentifiedProject>
    func archive(_ request: TenantProjectArchiveOperationRequest) async throws -> GeneratedResponse<IdObject>
}

public struct NotImplementedTenantProjectService: TenantProjectService {
    public init() {}

    public func create(_: TenantProjectCreateOperationRequest) async throws -> GeneratedResponse<TenantProjectIdProject> {
        throw Abort(.notImplemented)
    }

    public func update(_: TenantProjectUpdateOperationRequest) async throws -> GeneratedResponse<TenantProjectIdProject> {
        throw Abort(.notImplemented)
    }

    public func delete(_: TenantProjectDeleteOperationRequest) async throws -> GeneratedResponse<Void> {
        throw Abort(.notImplemented)
    }

    public func list(_: TenantProjectListOperationRequest) async throws -> GeneratedResponse<[TenantProjectIdentifiedProject]> {
        throw Abort(.notImplemented)
    }

    public func get(_: TenantProjectGetOperationRequest) async throws -> GeneratedResponse<TenantProjectIdentifiedProject> {
        throw Abort(.notImplemented)
    }

    public func archive(_: TenantProjectArchiveOperationRequest) async throws -> GeneratedResponse<IdObject> {
        throw Abort(.notImplemented)
    }
}
