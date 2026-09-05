// Generated code. Do not edit.
import Foundation
import Vapor

public struct TenantProjectArchiveOperationRequest: Sendable {
    public var tenantId: String
    public var projectId: String
    public var cascade: Bool
    public var apiKey: String

    public init(tenantId: String, projectId: String, cascade: Bool, apiKey: String) {
        self.tenantId = tenantId
        self.projectId = projectId
        self.cascade = cascade
        self.apiKey = apiKey
    }
}
