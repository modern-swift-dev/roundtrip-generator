import Combine
import Foundation
import RoundTrip
import RoundTripREST

/// ☠️☠️☠️ This is generated code, modify at your own risk
public extension LocationStructureApi {
    struct IdStructure: Codable, Sendable {
        public var id: Int64
        public init(id: Int64) {
            self.id = id
        }

        public enum CodingKeys: String, CodingKey {
            case id
        }
    }
}
