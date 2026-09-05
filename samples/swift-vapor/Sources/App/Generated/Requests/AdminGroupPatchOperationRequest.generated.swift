// Generated code. Do not edit.
import Foundation
import Vapor

public struct AdminGroupPatchOperationRequest: Sendable {
    public var groupId: Int64
    public var body: AdminGroupPatchedGroup

    public init(groupId: Int64, body: AdminGroupPatchedGroup) {
        self.groupId = groupId
        self.body = body
    }
}
