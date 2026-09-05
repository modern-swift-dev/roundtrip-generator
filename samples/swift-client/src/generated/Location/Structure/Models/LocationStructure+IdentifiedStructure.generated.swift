import Combine
import Foundation
import RoundTrip
import RoundTripREST

/// ☠️☠️☠️ This is generated code, modify at your own risk
public extension LocationStructureApi {
    struct IdentifiedStructure: Codable, Sendable, Identifiable {
        public var id: Int64
        public var name: String
        public var type: StructureType
        public var creationDate: Date
        public var lastUpdateDate: Date
        public init(id: Int64, name: String, type: StructureType, creationDate: Date, lastUpdateDate: Date) {
            self.id = id
            self.name = name
            self.type = type
            self.creationDate = creationDate
            self.lastUpdateDate = lastUpdateDate
        }

        public enum CodingKeys: String, CodingKey {
            case id
            case name
            case type
            case creationDate = "creation_date"
            case lastUpdateDate = "last_update_date"
        }
    }
}
