import Combine
import Foundation
import RoundTrip
import RoundTripREST

/// ☠️☠️☠️ This is generated code, modify at your own risk
public extension AdminGroupApi {
    struct Group: Codable, Sendable {
        public var name: String
        public init(name: String) {
            self.name = name
        }

        public enum CodingKeys: String, CodingKey {
            case name
        }
    }
}
