// Generated code. Do not edit.
import Foundation
import Vapor

public struct AuditStamp: Codable, Sendable {
    public var createdBy: UUID
    public var createdAt: Date
    public var updatedAt: Date?

    public init(createdBy: UUID, createdAt: Date, updatedAt: Date? = nil) {
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public enum CodingKeys: String, CodingKey {
        case createdBy = "created_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
