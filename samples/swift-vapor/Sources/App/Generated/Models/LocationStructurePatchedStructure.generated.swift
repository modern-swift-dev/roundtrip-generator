// Generated code. Do not edit.
import Foundation
import Vapor

public struct LocationStructurePatchedStructure: Codable, Sendable {
    public var name: PatchableValue<String>
    public var type: PatchableValue<StructureType>

    public init(name: PatchableValue<String> = .unmodified, type: PatchableValue<StructureType> = .unmodified) {
        self.name = name
        self.type = type
    }

    public enum CodingKeys: String, CodingKey {
        case name
        case type
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodePatchable(PatchableValue<String>.self, forKey: .name)
        type = try container.decodePatchable(PatchableValue<StructureType>.self, forKey: .type)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodePatchable(name, forKey: .name)
        try container.encodePatchable(type, forKey: .type)
    }
}
