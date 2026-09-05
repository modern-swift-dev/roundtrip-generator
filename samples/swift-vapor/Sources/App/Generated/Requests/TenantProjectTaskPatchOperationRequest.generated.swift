// Generated code. Do not edit.
import Foundation
import Vapor

public struct TenantProjectTaskPatchOperationRequest: Sendable {
    public var tenantId: String
    public var projectId: String
    public var taskId: String
    public var body: TenantProjectTaskPatchedTask

    public init(tenantId: String, projectId: String, taskId: String, body: TenantProjectTaskPatchedTask) {
        self.tenantId = tenantId
        self.projectId = projectId
        self.taskId = taskId
        self.body = body
    }
}
