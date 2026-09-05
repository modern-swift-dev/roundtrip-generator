// Generated code. Do not edit.
import Foundation
import Vapor

public struct TenantProjectTaskListOperationRequest: Sendable {
    public var tenantId: String
    public var projectId: String
    public var done: Bool?

    public init(tenantId: String, projectId: String, done: Bool?) {
        self.tenantId = tenantId
        self.projectId = projectId
        self.done = done
    }
}
