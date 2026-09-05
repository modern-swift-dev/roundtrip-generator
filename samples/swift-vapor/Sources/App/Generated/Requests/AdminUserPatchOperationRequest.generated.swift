// Generated code. Do not edit.
import Foundation
import Vapor

public struct AdminUserPatchOperationRequest: Sendable {
    public var userId: Int64
    public var body: AdminUserPatchedUser

    public init(userId: Int64, body: AdminUserPatchedUser) {
        self.userId = userId
        self.body = body
    }
}
