// Generated code. Do not edit.
import Foundation
import Vapor

public struct TenantProjectTaskController: Sendable {
    private let service: any TenantProjectTaskService
    private let security: any GeneratedSecurityMiddleware

    public init(service: any TenantProjectTaskService, security: any GeneratedSecurityMiddleware) {
        self.service = service
        self.security = security
    }

    public func register(routes: RoutesBuilder) throws {
        routes.on(.POST, .constant("project"), .parameter("project_id"), .constant("task"), use: create)
        routes.on(.PATCH, .constant("project"), .parameter("project_id"), .constant("task"), .parameter("task_id"), use: patch)
        routes.on(.GET, .constant("project"), .parameter("project_id"), .constant("task"), use: list)
        routes.on(.GET, .constant("project"), .parameter("project_id"), .constant("task"), .parameter("task_id"), use: get)
        routes.on(.PATCH, .constant("project"), .parameter("project_id"), .constant("task"), .parameter("task_id"), .constant("complete"), use: complete)
    }

    private func create(req: Request) async throws -> Response {
        let securityRequest = GeneratedSecurityRequest(request: req, operationID: "Tenant.ProjectTask.Create")
        _ = securityRequest
        let tenantId = try GeneratedRequestValueParser.requiredString(req.headers.first(name: "X-Tenant-Id"), name: "X-Tenant-Id")
        let projectId = try GeneratedRequestValueParser.requiredString(req.parameters.get("project_id"), name: "project_id")
        let body = try req.content.decode(TenantProjectTaskTask.self)
        let serviceRequest = TenantProjectTaskCreateOperationRequest(
            tenantId: tenantId,
            projectId: projectId,
            body: body,
        )
        let serviceResponse = try await service.create(serviceRequest)
        return try GeneratedResponseEncoder.json(serviceResponse, validStatusCodes: [200, 201])
    }

    private func patch(req: Request) async throws -> Response {
        let securityRequest = GeneratedSecurityRequest(request: req, operationID: "Tenant.ProjectTask.Patch")
        _ = securityRequest
        let tenantId = try GeneratedRequestValueParser.requiredString(req.headers.first(name: "X-Tenant-Id"), name: "X-Tenant-Id")
        let projectId = try GeneratedRequestValueParser.requiredString(req.parameters.get("project_id"), name: "project_id")
        let taskId = try GeneratedRequestValueParser.requiredString(req.parameters.get("task_id"), name: "task_id")
        let body = try req.content.decode(TenantProjectTaskPatchedTask.self)
        let serviceRequest = TenantProjectTaskPatchOperationRequest(
            tenantId: tenantId,
            projectId: projectId,
            taskId: taskId,
            body: body,
        )
        let serviceResponse = try await service.patch(serviceRequest)
        return try GeneratedResponseEncoder.json(serviceResponse, validStatusCodes: [200])
    }

    private func list(req: Request) async throws -> Response {
        let securityRequest = GeneratedSecurityRequest(request: req, operationID: "Tenant.ProjectTask.List")
        _ = securityRequest
        let tenantId = try GeneratedRequestValueParser.requiredString(req.headers.first(name: "X-Tenant-Id"), name: "X-Tenant-Id")
        let projectId = try GeneratedRequestValueParser.requiredString(req.parameters.get("project_id"), name: "project_id")
        let done = try GeneratedRequestValueParser.optional(req.query[String.self, at: "done"], name: "done", as: Bool.self)
        let serviceRequest = TenantProjectTaskListOperationRequest(
            tenantId: tenantId,
            projectId: projectId,
            done: done,
        )
        let serviceResponse = try await service.list(serviceRequest)
        return try GeneratedResponseEncoder.json(serviceResponse, validStatusCodes: [200])
    }

    private func get(req: Request) async throws -> Response {
        let securityRequest = GeneratedSecurityRequest(request: req, operationID: "Tenant.ProjectTask.Get")
        _ = securityRequest
        let tenantId = try GeneratedRequestValueParser.requiredString(req.headers.first(name: "X-Tenant-Id"), name: "X-Tenant-Id")
        let projectId = try GeneratedRequestValueParser.requiredString(req.parameters.get("project_id"), name: "project_id")
        let taskId = try GeneratedRequestValueParser.requiredString(req.parameters.get("task_id"), name: "task_id")
        let serviceRequest = TenantProjectTaskGetOperationRequest(
            tenantId: tenantId,
            projectId: projectId,
            taskId: taskId,
        )
        let serviceResponse = try await service.get(serviceRequest)
        return try GeneratedResponseEncoder.json(serviceResponse, validStatusCodes: [200])
    }

    private func complete(req: Request) async throws -> Response {
        let securityRequest = GeneratedSecurityRequest(request: req, operationID: "Tenant.ProjectTask.Complete")
        try await security.authorizeOptional(securityRequest)
        let tenantId = try GeneratedRequestValueParser.requiredString(req.headers.first(name: "X-Tenant-Id"), name: "X-Tenant-Id")
        let projectId = try GeneratedRequestValueParser.requiredString(req.parameters.get("project_id"), name: "project_id")
        let taskId = try GeneratedRequestValueParser.requiredString(req.parameters.get("task_id"), name: "task_id")
        let notify = try (GeneratedRequestValueParser.optional(req.query[String.self, at: "notify"], name: "notify", as: Bool.self)) ?? true
        let apiKey = GeneratedRequestValueParser.optionalString(req.headers.first(name: "Authorization"))
        let body = try req.content.decode(TenantProjectTaskCompleteTaskRequest.self)
        let serviceRequest = TenantProjectTaskCompleteOperationRequest(
            tenantId: tenantId,
            projectId: projectId,
            taskId: taskId,
            notify: notify,
            apiKey: apiKey,
            body: body,
        )
        let serviceResponse = try await service.complete(serviceRequest)
        return try GeneratedResponseEncoder.json(serviceResponse, validStatusCodes: [200])
    }
}
