// Generated code. Do not edit.
import Foundation
import Vapor

public struct AdminUserUpdateOperationRequest: Sendable {
    public var userId: Int64
    public var body: AdminUserUser

    public init(userId: Int64, body: AdminUserUser) {
        self.userId = userId
        self.body = body
    }
}
