// Generated code. Do not edit.
import Foundation
import Vapor

public struct AdminGroupIdentifiedGroup: Codable, Sendable, Identifiable {
    public var id: Int64
    public var name: String
    public var creationDate: Date
    public var lastUpdateDate: Date

    public init(id: Int64, name: String, creationDate: Date, lastUpdateDate: Date) {
        self.id = id
        self.name = name
        self.creationDate = creationDate
        self.lastUpdateDate = lastUpdateDate
    }

    public enum CodingKeys: String, CodingKey {
        case id
        case name
        case creationDate = "creation_date"
        case lastUpdateDate = "last_update_date"
    }
}
