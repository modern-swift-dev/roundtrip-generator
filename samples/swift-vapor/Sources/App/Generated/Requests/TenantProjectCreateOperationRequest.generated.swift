// Generated code. Do not edit.
import Foundation
import Vapor

public struct TenantProjectCreateOperationRequest: Sendable {
    public var tenantId: String
    public var body: TenantProjectProject

    public init(tenantId: String, body: TenantProjectProject) {
        self.tenantId = tenantId
        self.body = body
    }
}
