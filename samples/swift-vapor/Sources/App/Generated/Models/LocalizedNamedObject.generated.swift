// Generated code. Do not edit.
import Foundation
import Vapor

public struct LocalizedNamedObject: Codable, Sendable, Equatable, Hashable {
    public var id: Int64
    public var name: LocalizedData<String>

    public init(id: Int64, name: LocalizedData<String>) {
        self.id = id
        self.name = name
    }

    public static func == (lhs: LocalizedNamedObject, rhs: LocalizedNamedObject) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}
