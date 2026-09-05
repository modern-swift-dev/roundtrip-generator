// Generated code. Do not edit.
import Foundation
import Vapor

public struct AdminRolePatchOperationRequest: Sendable {
    public var roleId: Int64
    public var body: AdminRolePatchedRole

    public init(roleId: Int64, body: AdminRolePatchedRole) {
        self.roleId = roleId
        self.body = body
    }
}
