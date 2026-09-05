import Combine
import Foundation
import RoundTrip
import RoundTripREST

/// ☠️☠️☠️ This is generated code, modify at your own risk
public extension TenantProjectTaskApi {
    struct IdTask: Codable, Sendable {
        public var id: UUID
        public init(id: UUID) {
            self.id = id
        }

        public enum CodingKeys: String, CodingKey {
            case id
        }
    }
}
