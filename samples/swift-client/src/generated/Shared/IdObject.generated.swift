import Combine
import Foundation
import RoundTrip
import RoundTripREST

/// ☠️☠️☠️ This is generated code, modify at your own risk
public struct IdObject: Codable, Sendable, Equatable, Hashable {
    public var id: Int64
    public init(id: Int64) {
        self.id = id
    }

    public enum CodingKeys: String, CodingKey {
        case id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
