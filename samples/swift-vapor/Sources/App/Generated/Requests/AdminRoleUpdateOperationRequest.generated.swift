// Generated code. Do not edit.
import Foundation
import Vapor

public struct AdminRoleUpdateOperationRequest: Sendable {
    public var roleId: Int64
    public var body: AdminRoleRole

    public init(roleId: Int64, body: AdminRoleRole) {
        self.roleId = roleId
        self.body = body
    }
}
