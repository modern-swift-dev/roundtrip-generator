// Generated code. Do not edit.
import Foundation
import Vapor

public struct AdminRoleController: Sendable {
    private let service: any AdminRoleService
    private let security: any GeneratedSecurityMiddleware

    public init(service: any AdminRoleService, security: any GeneratedSecurityMiddleware) {
        self.service = service
        self.security = security
    }

    public func register(routes: RoutesBuilder) throws {
        routes.on(.POST, .constant("role"), use: create)
        routes.on(.PUT, .constant("role"), .parameter("role_id"), use: update)
        routes.on(.PATCH, .constant("role"), .parameter("role_id"), use: patch)
        routes.on(.DELETE, .constant("role"), .parameter("role_id"), use: delete)
        routes.on(.GET, .constant("role"), use: list)
        routes.on(.GET, .constant("role"), .parameter("role_id"), use: get)
    }

    private func create(req: Request) async throws -> Response {
        let securityRequest = GeneratedSecurityRequest(request: req, operationID: "Admin.Role.Create")
        _ = securityRequest
        let body = try req.content.decode(AdminRoleRole.self)
        let serviceRequest = AdminRoleCreateOperationRequest(
            body: body
        )
        let serviceResponse = try await service.create(serviceRequest)
        return try GeneratedResponseEncoder.json(serviceResponse, validStatusCodes: [200, 201])
    }

    private func update(req: Request) async throws -> Response {
        let securityRequest = GeneratedSecurityRequest(request: req, operationID: "Admin.Role.Update")
        _ = securityRequest
        let roleId = try GeneratedRequestValueParser.required(req.parameters.get("role_id"), name: "role_id", as: Int64.self)
        let body = try req.content.decode(AdminRoleRole.self)
        let serviceRequest = AdminRoleUpdateOperationRequest(
            roleId: roleId,
            body: body
        )
        let serviceResponse = try await service.update(serviceRequest)
        return try GeneratedResponseEncoder.json(serviceResponse, validStatusCodes: [200])
    }

    private func patch(req: Request) async throws -> Response {
        let securityRequest = GeneratedSecurityRequest(request: req, operationID: "Admin.Role.Patch")
        _ = securityRequest
        let roleId = try GeneratedRequestValueParser.required(req.parameters.get("role_id"), name: "role_id", as: Int64.self)
        let body = try req.content.decode(AdminRolePatchedRole.self)
        let serviceRequest = AdminRolePatchOperationRequest(
            roleId: roleId,
            body: body
        )
        let serviceResponse = try await service.patch(serviceRequest)
        return try GeneratedResponseEncoder.json(serviceResponse, validStatusCodes: [200])
    }

    private func delete(req: Request) async throws -> Response {
        let securityRequest = GeneratedSecurityRequest(request: req, operationID: "Admin.Role.Delete")
        _ = securityRequest
        let roleId = try GeneratedRequestValueParser.required(req.parameters.get("role_id"), name: "role_id", as: Int64.self)
        let serviceRequest = AdminRoleDeleteOperationRequest(
            roleId: roleId
        )
        let serviceResponse = try await service.delete(serviceRequest)
        return try GeneratedResponseEncoder.empty(serviceResponse, validStatusCodes: [200, 204, 205])
    }

    private func list(req: Request) async throws -> Response {
        let securityRequest = GeneratedSecurityRequest(request: req, operationID: "Admin.Role.List")
        _ = securityRequest
        let text = GeneratedRequestValueParser.optionalString(req.query[String.self, at: "text"])
        let serviceRequest = AdminRoleListOperationRequest(
            text: text
        )
        let serviceResponse = try await service.list(serviceRequest)
        return try GeneratedResponseEncoder.json(serviceResponse, validStatusCodes: [200])
    }

    private func get(req: Request) async throws -> Response {
        let securityRequest = GeneratedSecurityRequest(request: req, operationID: "Admin.Role.Get")
        _ = securityRequest
        let roleId = try GeneratedRequestValueParser.required(req.parameters.get("role_id"), name: "role_id", as: Int64.self)
        let serviceRequest = AdminRoleGetOperationRequest(
            roleId: roleId
        )
        let serviceResponse = try await service.get(serviceRequest)
        return try GeneratedResponseEncoder.json(serviceResponse, validStatusCodes: [200])
    }
}
