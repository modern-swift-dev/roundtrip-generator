// Generated code. Do not edit.
import Foundation
import Vapor

public struct TenantProjectTaskGetOperationRequest: Sendable {
    public var tenantId: String
    public var projectId: String
    public var taskId: String

    public init(tenantId: String, projectId: String, taskId: String) {
        self.tenantId = tenantId
        self.projectId = projectId
        self.taskId = taskId
    }
}
