// Generated code. Do not edit.
import Foundation
import Vapor

public protocol AdminUserService: Sendable {
    func create(_ request: AdminUserCreateOperationRequest) async throws -> GeneratedResponse<AdminUserIdUser>
    func update(_ request: AdminUserUpdateOperationRequest) async throws -> GeneratedResponse<AdminUserIdUser>
    func patch(_ request: AdminUserPatchOperationRequest) async throws -> GeneratedResponse<AdminUserIdUser>
    func delete(_ request: AdminUserDeleteOperationRequest) async throws -> GeneratedResponse<Void>
    func list(_ request: AdminUserListOperationRequest) async throws -> GeneratedResponse<PagedResults<AdminUserIdentifiedUser>>
    func get(_ request: AdminUserGetOperationRequest) async throws -> GeneratedResponse<AdminUserIdentifiedUser>
}

public struct NotImplementedAdminUserService: AdminUserService {
    public init() {}

    public func create(_: AdminUserCreateOperationRequest) async throws -> GeneratedResponse<AdminUserIdUser> {
        throw Abort(.notImplemented)
    }

    public func update(_: AdminUserUpdateOperationRequest) async throws -> GeneratedResponse<AdminUserIdUser> {
        throw Abort(.notImplemented)
    }

    public func patch(_: AdminUserPatchOperationRequest) async throws -> GeneratedResponse<AdminUserIdUser> {
        throw Abort(.notImplemented)
    }

    public func delete(_: AdminUserDeleteOperationRequest) async throws -> GeneratedResponse<Void> {
        throw Abort(.notImplemented)
    }

    public func list(_: AdminUserListOperationRequest) async throws -> GeneratedResponse<PagedResults<AdminUserIdentifiedUser>> {
        throw Abort(.notImplemented)
    }

    public func get(_: AdminUserGetOperationRequest) async throws -> GeneratedResponse<AdminUserIdentifiedUser> {
        throw Abort(.notImplemented)
    }
}
