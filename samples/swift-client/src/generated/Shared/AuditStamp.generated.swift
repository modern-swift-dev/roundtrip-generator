import Combine
import Foundation
import RoundTrip
import RoundTripREST

/// ☠️☠️☠️ This is generated code, modify at your own risk
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
