// Generated code. Do not edit.
import Foundation
import Vapor

public struct TenantProjectListOperationRequest: Sendable {
    public var tenantId: String
    public var status: [TenantStatus]
    public var includeArchived: Bool

    public init(tenantId: String, status: [TenantStatus], includeArchived: Bool) {
        self.tenantId = tenantId
        self.status = status
        self.includeArchived = includeArchived
    }
}
