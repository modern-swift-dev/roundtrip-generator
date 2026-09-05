// Generated code. Do not edit.
import Foundation
import Vapor

public struct AdminRolePatchedRole: Codable, Sendable {
    public var name: PatchableValue<String>

    public init(name: PatchableValue<String> = .unmodified) {
        self.name = name
    }

    public enum CodingKeys: String, CodingKey {
        case name
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodePatchable(PatchableValue<String>.self, forKey: .name)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodePatchable(name, forKey: .name)
    }
}
