// Generated code. Do not edit.
import Foundation
import Vapor

public struct TenantProjectIdentifiedProject: Codable, Sendable, Identifiable {
    public var id: UUID
    public var name: String
    public var status: TenantStatus
    public var owners: [NamedObject]
    public var labels: [String: String?]
    public var creationDate: Date
    public var lastUpdateDate: Date

    public init(id: UUID, name: String, status: TenantStatus, owners: [NamedObject], labels: [String: String?], creationDate: Date, lastUpdateDate: Date) {
        self.id = id
        self.name = name
        self.status = status
        self.owners = owners
        self.labels = labels
        self.creationDate = creationDate
        self.lastUpdateDate = lastUpdateDate
    }

    public enum CodingKeys: String, CodingKey {
        case id
        case name
        case status
        case owners
        case labels
        case creationDate = "creation_date"
        case lastUpdateDate = "last_update_date"
    }
}
