// Generated code. Do not edit.
import Foundation
import Vapor

public protocol TenantProjectTaskService: Sendable {
    func create(_ request: TenantProjectTaskCreateOperationRequest) async throws -> GeneratedResponse<TenantProjectTaskIdTask>
    func patch(_ request: TenantProjectTaskPatchOperationRequest) async throws -> GeneratedResponse<TenantProjectTaskIdTask>
    func list(_ request: TenantProjectTaskListOperationRequest) async throws -> GeneratedResponse<PagedResults<TenantProjectTaskIdentifiedTask>>
    func get(_ request: TenantProjectTaskGetOperationRequest) async throws -> GeneratedResponse<TenantProjectTaskIdentifiedTask>
    func complete(_ request: TenantProjectTaskCompleteOperationRequest) async throws -> GeneratedResponse<IdObject>
}

public struct NotImplementedTenantProjectTaskService: TenantProjectTaskService {
    public init() {}

    public func create(_: TenantProjectTaskCreateOperationRequest) async throws -> GeneratedResponse<TenantProjectTaskIdTask> {
        throw Abort(.notImplemented)
    }

    public func patch(_: TenantProjectTaskPatchOperationRequest) async throws -> GeneratedResponse<TenantProjectTaskIdTask> {
        throw Abort(.notImplemented)
    }

    public func list(_: TenantProjectTaskListOperationRequest) async throws -> GeneratedResponse<PagedResults<TenantProjectTaskIdentifiedTask>> {
        throw Abort(.notImplemented)
    }

    public func get(_: TenantProjectTaskGetOperationRequest) async throws -> GeneratedResponse<TenantProjectTaskIdentifiedTask> {
        throw Abort(.notImplemented)
    }

    public func complete(_: TenantProjectTaskCompleteOperationRequest) async throws -> GeneratedResponse<IdObject> {
        throw Abort(.notImplemented)
    }
}
