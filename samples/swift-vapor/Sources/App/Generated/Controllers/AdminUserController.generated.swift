// Generated code. Do not edit.
import Foundation
import Vapor

public struct AdminUserController: Sendable {
    private let service: any AdminUserService
    private let security: any GeneratedSecurityMiddleware

    public init(service: any AdminUserService, security: any GeneratedSecurityMiddleware) {
        self.service = service
        self.security = security
    }

    public func register(routes: RoutesBuilder) throws {
        routes.on(.POST, .constant("user"), use: create)
        routes.on(.PUT, .constant("user"), .parameter("user_id"), use: update)
        routes.on(.PATCH, .constant("user"), .parameter("user_id"), use: patch)
        routes.on(.DELETE, .constant("user"), .parameter("user_id"), use: delete)
        routes.on(.GET, .constant("user"), use: list)
        routes.on(.GET, .constant("user"), .parameter("user_id"), use: get)
    }

    private func create(req: Request) async throws -> Response {
        let securityRequest = GeneratedSecurityRequest(request: req, operationID: "Admin.User.Create")
        _ = securityRequest
        let body = try req.content.decode(AdminUserUser.self)
        let serviceRequest = AdminUserCreateOperationRequest(
            body: body,
        )
        let serviceResponse = try await service.create(serviceRequest)
        return try GeneratedResponseEncoder.json(serviceResponse, validStatusCodes: [200, 201])
    }

    private func update(req: Request) async throws -> Response {
        let securityRequest = GeneratedSecurityRequest(request: req, operationID: "Admin.User.Update")
        _ = securityRequest
        let userId = try GeneratedRequestValueParser.required(req.parameters.get("user_id"), name: "user_id", as: Int64.self)
        let body = try req.content.decode(AdminUserUser.self)
        let serviceRequest = AdminUserUpdateOperationRequest(
            userId: userId,
            body: body,
        )
        let serviceResponse = try await service.update(serviceRequest)
        return try GeneratedResponseEncoder.json(serviceResponse, validStatusCodes: [200])
    }

    private func patch(req: Request) async throws -> Response {
        let securityRequest = GeneratedSecurityRequest(request: req, operationID: "Admin.User.Patch")
        _ = securityRequest
        let userId = try GeneratedRequestValueParser.required(req.parameters.get("user_id"), name: "user_id", as: Int64.self)
        let body = try req.content.decode(AdminUserPatchedUser.self)
        let serviceRequest = AdminUserPatchOperationRequest(
            userId: userId,
            body: body,
        )
        let serviceResponse = try await service.patch(serviceRequest)
        return try GeneratedResponseEncoder.json(serviceResponse, validStatusCodes: [200])
    }

    private func delete(req: Request) async throws -> Response {
        let securityRequest = GeneratedSecurityRequest(request: req, operationID: "Admin.User.Delete")
        _ = securityRequest
        let userId = try GeneratedRequestValueParser.required(req.parameters.get("user_id"), name: "user_id", as: Int64.self)
        let serviceRequest = AdminUserDeleteOperationRequest(
            userId: userId,
        )
        let serviceResponse = try await service.delete(serviceRequest)
        return try GeneratedResponseEncoder.empty(serviceResponse, validStatusCodes: [200, 204, 205])
    }

    private func list(req: Request) async throws -> Response {
        let securityRequest = GeneratedSecurityRequest(request: req, operationID: "Admin.User.List")
        _ = securityRequest
        let text = GeneratedRequestValueParser.optionalString(req.query[String.self, at: "text"])
        let serviceRequest = AdminUserListOperationRequest(
            text: text,
        )
        let serviceResponse = try await service.list(serviceRequest)
        return try GeneratedResponseEncoder.json(serviceResponse, validStatusCodes: [200])
    }

    private func get(req: Request) async throws -> Response {
        let securityRequest = GeneratedSecurityRequest(request: req, operationID: "Admin.User.Get")
        _ = securityRequest
        let userId = try GeneratedRequestValueParser.required(req.parameters.get("user_id"), name: "user_id", as: Int64.self)
        let serviceRequest = AdminUserGetOperationRequest(
            userId: userId,
        )
        let serviceResponse = try await service.get(serviceRequest)
        return try GeneratedResponseEncoder.json(serviceResponse, validStatusCodes: [200])
    }
}
