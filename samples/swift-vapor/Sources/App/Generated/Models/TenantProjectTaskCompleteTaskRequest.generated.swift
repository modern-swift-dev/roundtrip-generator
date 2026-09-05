// Generated code. Do not edit.
import Foundation
import Vapor

public struct TenantProjectTaskCompleteTaskRequest: Codable, Sendable {
    public var completedAt: Date

    public init(completedAt: Date) {
        self.completedAt = completedAt
    }

    public enum CodingKeys: String, CodingKey {
        case completedAt = "completed_at"
    }
}
