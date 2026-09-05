// Generated code. Do not edit.
import Foundation
import Vapor

public struct TenantProjectTaskCompleteOperationRequest: Sendable {
    public var tenantId: String
    public var projectId: String
    public var taskId: String
    public var notify: Bool
    public var apiKey: String?
    public var body: TenantProjectTaskCompleteTaskRequest

    public init(tenantId: String, projectId: String, taskId: String, notify: Bool, apiKey: String?, body: TenantProjectTaskCompleteTaskRequest) {
        self.tenantId = tenantId
        self.projectId = projectId
        self.taskId = taskId
        self.notify = notify
        self.apiKey = apiKey
        self.body = body
    }
}
