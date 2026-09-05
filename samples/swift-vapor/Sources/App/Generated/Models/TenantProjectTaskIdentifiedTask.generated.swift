// Generated code. Do not edit.
import Foundation
import Vapor

public struct TenantProjectTaskIdentifiedTask: Codable, Sendable, Identifiable {
    public var id: UUID
    public var title: String
    public var details: String?
    public var dueAt: Date?
    public var done: Bool
    public var creationDate: Date
    public var lastUpdateDate: Date

    public init(id: UUID, title: String, details: String? = nil, dueAt: Date? = nil, done: Bool = false, creationDate: Date, lastUpdateDate: Date) {
        self.id = id
        self.title = title
        self.details = details
        self.dueAt = dueAt
        self.done = done
        self.creationDate = creationDate
        self.lastUpdateDate = lastUpdateDate
    }

    public enum CodingKeys: String, CodingKey {
        case id
        case title
        case details
        case dueAt = "due_at"
        case done
        case creationDate = "creation_date"
        case lastUpdateDate = "last_update_date"
    }
}
