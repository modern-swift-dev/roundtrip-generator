// Generated code. Do not edit.
import Foundation
import Vapor

public protocol AdminGroupService: Sendable {
    func create(_ request: AdminGroupCreateOperationRequest) async throws -> GeneratedResponse<AdminGroupIdGroup>
    func update(_ request: AdminGroupUpdateOperationRequest) async throws -> GeneratedResponse<AdminGroupIdGroup>
    func patch(_ request: AdminGroupPatchOperationRequest) async throws -> GeneratedResponse<AdminGroupIdGroup>
    func delete(_ request: AdminGroupDeleteOperationRequest) async throws -> GeneratedResponse<Void>
    func list(_ request: AdminGroupListOperationRequest) async throws -> GeneratedResponse<PagedResults<AdminGroupIdentifiedGroup>>
    func get(_ request: AdminGroupGetOperationRequest) async throws -> GeneratedResponse<AdminGroupIdentifiedGroup>
}

public struct NotImplementedAdminGroupService: AdminGroupService {
    public init() {}

    public func create(_: AdminGroupCreateOperationRequest) async throws -> GeneratedResponse<AdminGroupIdGroup> {
        throw Abort(.notImplemented)
    }

    public func update(_: AdminGroupUpdateOperationRequest) async throws -> GeneratedResponse<AdminGroupIdGroup> {
        throw Abort(.notImplemented)
    }

    public func patch(_: AdminGroupPatchOperationRequest) async throws -> GeneratedResponse<AdminGroupIdGroup> {
        throw Abort(.notImplemented)
    }

    public func delete(_: AdminGroupDeleteOperationRequest) async throws -> GeneratedResponse<Void> {
        throw Abort(.notImplemented)
    }

    public func list(_: AdminGroupListOperationRequest) async throws -> GeneratedResponse<PagedResults<AdminGroupIdentifiedGroup>> {
        throw Abort(.notImplemented)
    }

    public func get(_: AdminGroupGetOperationRequest) async throws -> GeneratedResponse<AdminGroupIdentifiedGroup> {
        throw Abort(.notImplemented)
    }
}
