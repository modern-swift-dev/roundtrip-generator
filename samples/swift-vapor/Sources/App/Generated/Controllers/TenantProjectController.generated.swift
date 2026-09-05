// Generated code. Do not edit.
import Foundation
import Vapor

public struct TenantProjectController: Sendable {
    private let service: any TenantProjectService
    private let security: any GeneratedSecurityMiddleware

    public init(service: any TenantProjectService, security: any GeneratedSecurityMiddleware) {
        self.service = service
        self.security = security
    }

    public func register(routes: RoutesBuilder) throws {
        routes.on(.POST, .constant("project"), use: create)
        routes.on(.PUT, .constant("project"), .parameter("project_id"), use: update)
        routes.on(.DELETE, .constant("project"), .parameter("project_id"), use: delete)
        routes.on(.GET, .constant("project"), use: list)
        routes.on(.GET, .constant("project"), .parameter("project_id"), use: get)
        routes.on(.POST, .constant("project"), .parameter("project_id"), .constant("archive"), use: archive)
    }

    private func create(req: Request) async throws -> Response {
        let securityRequest = GeneratedSecurityRequest(request: req, operationID: "Tenant.Project.Create")
        _ = securityRequest
        let tenantId = try GeneratedRequestValueParser.requiredString(req.headers.first(name: "X-Tenant-Id"), name: "X-Tenant-Id")
        let body = try req.content.decode(TenantProjectProject.self)
        let serviceRequest = TenantProjectCreateOperationRequest(
            tenantId: tenantId,
            body: body
        )
        let serviceResponse = try await service.create(serviceRequest)
        return try GeneratedResponseEncoder.json(serviceResponse, validStatusCodes: [200, 201])
    }

    private func update(req: Request) async throws -> Response {
        let securityRequest = GeneratedSecurityRequest(request: req, operationID: "Tenant.Project.Update")
        _ = securityRequest
        let tenantId = try GeneratedRequestValueParser.requiredString(req.headers.first(name: "X-Tenant-Id"), name: "X-Tenant-Id")
        let projectId = try GeneratedRequestValueParser.requiredString(req.parameters.get("project_id"), name: "project_id")
        let body = try req.content.decode(TenantProjectProject.self)
        let serviceRequest = TenantProjectUpdateOperationRequest(
            tenantId: tenantId,
            projectId: projectId,
            body: body
        )
        let serviceResponse = try await service.update(serviceRequest)
        return try GeneratedResponseEncoder.json(serviceResponse, validStatusCodes: [200])
    }

    private func delete(req: Request) async throws -> Response {
        let securityRequest = GeneratedSecurityRequest(request: req, operationID: "Tenant.Project.Delete")
        _ = securityRequest
        let tenantId = try GeneratedRequestValueParser.requiredString(req.headers.first(name: "X-Tenant-Id"), name: "X-Tenant-Id")
        let projectId = try GeneratedRequestValueParser.requiredString(req.parameters.get("project_id"), name: "project_id")
        let serviceRequest = TenantProjectDeleteOperationRequest(
            tenantId: tenantId,
            projectId: projectId
        )
        let serviceResponse = try await service.delete(serviceRequest)
        return try GeneratedResponseEncoder.empty(serviceResponse, validStatusCodes: [200, 204, 205])
    }

    private func list(req: Request) async throws -> Response {
        let securityRequest = GeneratedSecurityRequest(request: req, operationID: "Tenant.Project.List")
        _ = securityRequest
        let tenantId = try GeneratedRequestValueParser.requiredString(req.headers.first(name: "X-Tenant-Id"), name: "X-Tenant-Id")
        let status = (try GeneratedRequestValueParser.optionalStringRawEnumArray(req.query[String.self, at: "status"], name: "status", as: TenantStatus.self)) ?? [.active]
        let includeArchived = (try GeneratedRequestValueParser.optional(req.query[String.self, at: "include_archived"], name: "include_archived", as: Bool.self)) ?? false
        let serviceRequest = TenantProjectListOperationRequest(
            tenantId: tenantId,
            status: status,
            includeArchived: includeArchived
        )
        let serviceResponse = try await service.list(serviceRequest)
        return try GeneratedResponseEncoder.json(serviceResponse, validStatusCodes: [200])
    }

    private func get(req: Request) async throws -> Response {
        let securityRequest = GeneratedSecurityRequest(request: req, operationID: "Tenant.Project.Get")
        _ = securityRequest
        let tenantId = try GeneratedRequestValueParser.requiredString(req.headers.first(name: "X-Tenant-Id"), name: "X-Tenant-Id")
        let projectId = try GeneratedRequestValueParser.requiredString(req.parameters.get("project_id"), name: "project_id")
        let serviceRequest = TenantProjectGetOperationRequest(
            tenantId: tenantId,
            projectId: projectId
        )
        let serviceResponse = try await service.get(serviceRequest)
        return try GeneratedResponseEncoder.json(serviceResponse, validStatusCodes: [200])
    }

    private func archive(req: Request) async throws -> Response {
        let securityRequest = GeneratedSecurityRequest(request: req, operationID: "Tenant.Project.Archive")
        try await security.requireAuthorization(securityRequest)
        let tenantId = try GeneratedRequestValueParser.requiredString(req.headers.first(name: "X-Tenant-Id"), name: "X-Tenant-Id")
        let projectId = try GeneratedRequestValueParser.requiredString(req.parameters.get("project_id"), name: "project_id")
        let cascade = (try GeneratedRequestValueParser.optional(req.query[String.self, at: "cascade"], name: "cascade", as: Bool.self)) ?? false
        let apiKey = try GeneratedRequestValueParser.requiredString(req.headers.first(name: "Authorization"), name: "Authorization")
        let serviceRequest = TenantProjectArchiveOperationRequest(
            tenantId: tenantId,
            projectId: projectId,
            cascade: cascade,
            apiKey: apiKey
        )
        let serviceResponse = try await service.archive(serviceRequest)
        return try GeneratedResponseEncoder.json(serviceResponse, validStatusCodes: [200, 202])
    }
}
