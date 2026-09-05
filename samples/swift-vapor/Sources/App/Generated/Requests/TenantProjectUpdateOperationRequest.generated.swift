// Generated code. Do not edit.
import Foundation
import Vapor

public struct TenantProjectUpdateOperationRequest: Sendable {
    public var tenantId: String
    public var projectId: String
    public var body: TenantProjectProject

    public init(tenantId: String, projectId: String, body: TenantProjectProject) {
        self.tenantId = tenantId
        self.projectId = projectId
        self.body = body
    }
}
