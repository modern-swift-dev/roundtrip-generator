// Generated code. Do not edit.
import Foundation
import Vapor

public struct IdObject: Codable, Sendable, Equatable, Hashable {
    public var id: Int64

    public init(id: Int64) {
        self.id = id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}
