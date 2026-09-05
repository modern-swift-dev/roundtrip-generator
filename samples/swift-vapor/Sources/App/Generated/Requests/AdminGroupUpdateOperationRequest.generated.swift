// Generated code. Do not edit.
import Foundation
import Vapor

public struct AdminGroupUpdateOperationRequest: Sendable {
    public var groupId: Int64
    public var body: AdminGroupGroup

    public init(groupId: Int64, body: AdminGroupGroup) {
        self.groupId = groupId
        self.body = body
    }
}
