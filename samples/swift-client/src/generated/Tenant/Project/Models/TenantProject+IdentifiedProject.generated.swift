import Combine
import Foundation
import RoundTrip
import RoundTripREST

/// ☠️☠️☠️ This is generated code, modify at your own risk
public extension TenantProjectApi {
    struct IdentifiedProject: Codable, Sendable, Identifiable {
        public var id: UUID
        public var name: String
        public var status: TenantApi.TenantStatus
        public var owners: [NamedObject]
        public var labels: [String: String?]
        public var creationDate: Date
        public var lastUpdateDate: Date
        public init(id: UUID, name: String, status: TenantApi.TenantStatus, owners: [NamedObject], labels: [String: String?], creationDate: Date, lastUpdateDate: Date) {
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
}
