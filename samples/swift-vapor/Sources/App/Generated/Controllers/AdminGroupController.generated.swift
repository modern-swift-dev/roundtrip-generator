// Generated code. Do not edit.
import Foundation
import Vapor

public struct AdminGroupController: Sendable {
    private let service: any AdminGroupService
    private let security: any GeneratedSecurityMiddleware

    public init(service: any AdminGroupService, security: any GeneratedSecurityMiddleware) {
        self.service = service
        self.security = security
    }

    public func register(routes: RoutesBuilder) throws {
        routes.on(.POST, .constant("group"), use: create)
        routes.on(.PUT, .constant("group"), .parameter("group_id"), use: update)
        routes.on(.PATCH, .constant("group"), .parameter("group_id"), use: patch)
        routes.on(.DELETE, .constant("group"), .parameter("group_id"), use: delete)
        routes.on(.GET, .constant("group"), use: list)
        routes.on(.GET, .constant("group"), .parameter("group_id"), use: get)
    }

    private func create(req: Request) async throws -> Response {
        let securityRequest = GeneratedSecurityRequest(request: req, operationID: "Admin.Group.Create")
        _ = securityRequest
        let body = try req.content.decode(AdminGroupGroup.self)
        let serviceRequest = AdminGroupCreateOperationRequest(
            body: body,
        )
        let serviceResponse = try await service.create(serviceRequest)
        return try GeneratedResponseEncoder.json(serviceResponse, validStatusCodes: [200, 201])
    }

    private func update(req: Request) async throws -> Response {
        let securityRequest = GeneratedSecurityRequest(request: req, operationID: "Admin.Group.Update")
        _ = securityRequest
        let groupId = try GeneratedRequestValueParser.required(req.parameters.get("group_id"), name: "group_id", as: Int64.self)
        let body = try req.content.decode(AdminGroupGroup.self)
        let serviceRequest = AdminGroupUpdateOperationRequest(
            groupId: groupId,
            body: body,
        )
        let serviceResponse = try await service.update(serviceRequest)
        return try GeneratedResponseEncoder.json(serviceResponse, validStatusCodes: [200])
    }

    private func patch(req: Request) async throws -> Response {
        let securityRequest = GeneratedSecurityRequest(request: req, operationID: "Admin.Group.Patch")
        _ = securityRequest
        let groupId = try GeneratedRequestValueParser.required(req.parameters.get("group_id"), name: "group_id", as: Int64.self)
        let body = try req.content.decode(AdminGroupPatchedGroup.self)
        let serviceRequest = AdminGroupPatchOperationRequest(
            groupId: groupId,
            body: body,
        )
        let serviceResponse = try await service.patch(serviceRequest)
        return try GeneratedResponseEncoder.json(serviceResponse, validStatusCodes: [200])
    }

    private func delete(req: Request) async throws -> Response {
        let securityRequest = GeneratedSecurityRequest(request: req, operationID: "Admin.Group.Delete")
        _ = securityRequest
        let groupId = try GeneratedRequestValueParser.required(req.parameters.get("group_id"), name: "group_id", as: Int64.self)
        let serviceRequest = AdminGroupDeleteOperationRequest(
            groupId: groupId,
        )
        let serviceResponse = try await service.delete(serviceRequest)
        return try GeneratedResponseEncoder.empty(serviceResponse, validStatusCodes: [200, 204, 205])
    }

    private func list(req: Request) async throws -> Response {
        let securityRequest = GeneratedSecurityRequest(request: req, operationID: "Admin.Group.List")
        _ = securityRequest
        let text = GeneratedRequestValueParser.optionalString(req.query[String.self, at: "text"])
        let serviceRequest = AdminGroupListOperationRequest(
            text: text,
        )
        let serviceResponse = try await service.list(serviceRequest)
        return try GeneratedResponseEncoder.json(serviceResponse, validStatusCodes: [200])
    }

    private func get(req: Request) async throws -> Response {
        let securityRequest = GeneratedSecurityRequest(request: req, operationID: "Admin.Group.Get")
        _ = securityRequest
        let groupId = try GeneratedRequestValueParser.required(req.parameters.get("group_id"), name: "group_id", as: Int64.self)
        let serviceRequest = AdminGroupGetOperationRequest(
            groupId: groupId,
        )
        let serviceResponse = try await service.get(serviceRequest)
        return try GeneratedResponseEncoder.json(serviceResponse, validStatusCodes: [200])
    }
}
