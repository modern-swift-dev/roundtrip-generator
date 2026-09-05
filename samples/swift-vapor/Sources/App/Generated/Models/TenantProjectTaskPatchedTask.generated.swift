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
        title = try container.decodePatchable(PatchableValue<String>.self, forKey: .title)
        details = try container.decodePatchable(PatchableValue<String>.self, forKey: .details)
        dueAt = try container.decodePatchable(PatchableValue<Date>.self, forKey: .dueAt)
        done = try container.decodePatchable(PatchableValue<Bool>.self, forKey: .done)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodePatchable(title, forKey: .title)
        try container.encodePatchable(details, forKey: .details)
        try container.encodePatchable(dueAt, forKey: .dueAt)
        try container.encodePatchable(done, forKey: .done)
    }
}
