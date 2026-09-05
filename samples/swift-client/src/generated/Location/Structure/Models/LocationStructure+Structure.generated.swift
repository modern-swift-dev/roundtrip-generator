import Combine
import Foundation
import RoundTrip
import RoundTripREST

/// ☠️☠️☠️ This is generated code, modify at your own risk
public extension LocationStructureApi {
    struct Structure: Codable, Sendable {
        public var name: String
        public var type: StructureType
        public init(name: String, type: StructureType) {
            self.name = name
            self.type = type
        }

        public enum CodingKeys: String, CodingKey {
            case name
            case type
        }
    }
}
