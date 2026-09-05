import Combine
import Foundation
import RoundTrip
import RoundTripREST

/// ☠️☠️☠️ This is generated code, modify at your own risk
public struct LocalizedNamedObject: Codable, Sendable, Equatable, Hashable {
    public var id: Int64
    public var name: LocalizedData<String>
    public init(id: Int64, name: LocalizedData<String>) {
        self.id = id
        self.name = name
    }

    public enum CodingKeys: String, CodingKey {
        case id
        case name
    }

    public static func == (lhs: LocalizedNamedObject, rhs: LocalizedNamedObject) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
