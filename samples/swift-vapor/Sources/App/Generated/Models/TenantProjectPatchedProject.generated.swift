// Generated code. Do not edit.
import Foundation
import Vapor

public struct TenantProjectPatchedProject: Codable, Sendable {
    public var name: PatchableValue<String>
    public var status: PatchableValue<TenantStatus>
    public var owners: PatchableValue<[NamedObject]>
    public var labels: PatchableValue<[String: String?]>

    public init(
        name: PatchableValue<String> = .unmodified,
        status: PatchableValue<TenantStatus> = .unmodified,
        owners: PatchableValue<[NamedObject]> = .unmodified,
        labels: PatchableValue<[String: String?]> = .unmodified
    ) {
        self.name = name
        self.status = status
        self.owners = owners
        self.labels = labels
    }

    public enum CodingKeys: String, CodingKey {
        case name
        case status
        case owners
        case labels
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decodePatchable(PatchableValue<String>.self, forKey: .name)
        self.status = try container.decodePatchable(PatchableValue<TenantStatus>.self, forKey: .status)
        self.owners = try container.decodePatchable(PatchableValue<[NamedObject]>.self, forKey: .owners)
        self.labels = try container.decodePatchable(PatchableValue<[String: String?]>.self, forKey: .labels)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodePatchable(self.name, forKey: .name)
        try container.encodePatchable(self.status, forKey: .status)
        try container.encodePatchable(self.owners, forKey: .owners)
        try container.encodePatchable(self.labels, forKey: .labels)
    }
}
