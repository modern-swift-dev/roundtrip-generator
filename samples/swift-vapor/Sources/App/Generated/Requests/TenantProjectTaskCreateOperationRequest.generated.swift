// Generated code. Do not edit.
import Foundation
import Vapor

public struct TenantProjectTaskCreateOperationRequest: Sendable {
    public var tenantId: String
    public var projectId: String
    public var body: TenantProjectTaskTask

    public init(tenantId: String, projectId: String, body: TenantProjectTaskTask) {
        self.tenantId = tenantId
        self.projectId = projectId
        self.body = body
    }
}
