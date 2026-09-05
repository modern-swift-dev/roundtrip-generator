// Generated code. Do not edit.
import Foundation
import Vapor

public protocol AdminRoleService: Sendable {
    func create(_ request: AdminRoleCreateOperationRequest) async throws -> GeneratedResponse<AdminRoleIdRole>
    func update(_ request: AdminRoleUpdateOperationRequest) async throws -> GeneratedResponse<AdminRoleIdRole>
    func patch(_ request: AdminRolePatchOperationRequest) async throws -> GeneratedResponse<AdminRoleIdRole>
    func delete(_ request: AdminRoleDeleteOperationRequest) async throws -> GeneratedResponse<Void>
    func list(_ request: AdminRoleListOperationRequest) async throws -> GeneratedResponse<PagedResults<AdminRoleIdentifiedRole>>
    func get(_ request: AdminRoleGetOperationRequest) async throws -> GeneratedResponse<AdminRoleIdentifiedRole>
}

public struct NotImplementedAdminRoleService: AdminRoleService {
    public init() {}

    public func create(_: AdminRoleCreateOperationRequest) async throws -> GeneratedResponse<AdminRoleIdRole> {
        throw Abort(.notImplemented)
    }

    public func update(_: AdminRoleUpdateOperationRequest) async throws -> GeneratedResponse<AdminRoleIdRole> {
        throw Abort(.notImplemented)
    }

    public func patch(_: AdminRolePatchOperationRequest) async throws -> GeneratedResponse<AdminRoleIdRole> {
        throw Abort(.notImplemented)
    }

    public func delete(_: AdminRoleDeleteOperationRequest) async throws -> GeneratedResponse<Void> {
        throw Abort(.notImplemented)
    }

    public func list(_: AdminRoleListOperationRequest) async throws -> GeneratedResponse<PagedResults<AdminRoleIdentifiedRole>> {
        throw Abort(.notImplemented)
    }

    public func get(_: AdminRoleGetOperationRequest) async throws -> GeneratedResponse<AdminRoleIdentifiedRole> {
        throw Abort(.notImplemented)
    }
}
