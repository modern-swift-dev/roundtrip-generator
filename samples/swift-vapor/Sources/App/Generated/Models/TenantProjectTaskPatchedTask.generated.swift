// Generated code. Do not edit.
import Foundation
import Vapor

public struct TenantProjectTaskPatchedTask: Codable, Sendable {
    public var title: PatchableValue<String>
    public var details: PatchableValue<String>
    public var dueAt: PatchableValue<Date>
    public var done: PatchableValue<Bool>

    public init(title: PatchableValue<String> = .unmodified, details: PatchableValue<String> = .unmodified, dueAt: PatchableValue<Date> = .unmodified, done: PatchableValue<Bool> = .unmodified) {
        self.title = title
        self.details = details
        self.dueAt = dueAt
        self.done = done
    }

    public enum CodingKeys: String, CodingKey {
        case title
        case details
        case dueAt = "due_at"
        case done
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.title = try container.decodePatchable(PatchableValue<String>.self, forKey: .title)
        self.details = try container.decodePatchable(PatchableValue<String>.self, forKey: .details)
        self.dueAt = try container.decodePatchable(PatchableValue<Date>.self, forKey: .dueAt)
        self.done = try container.decodePatchable(PatchableValue<Bool>.self, forKey: .done)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodePatchable(self.title, forKey: .title)
        try container.encodePatchable(self.details, forKey: .details)
        try container.encodePatchable(self.dueAt, forKey: .dueAt)
        try container.encodePatchable(self.done, forKey: .done)
    }
}
