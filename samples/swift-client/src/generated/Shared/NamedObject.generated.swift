import Combine
import Foundation
import RoundTrip
import RoundTripREST

/// ☠️☠️☠️ This is generated code, modify at your own risk
public struct NamedObject: Codable, Sendable, Equatable, Hashable {
    public var id: Int64
    public var name: String
    public init(id: Int64, name: String) {
        self.id = id
        self.name = name
    }

    public enum CodingKeys: String, CodingKey {
        case id
        case name
    }

    public static func == (lhs: NamedObject, rhs: NamedObject) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
