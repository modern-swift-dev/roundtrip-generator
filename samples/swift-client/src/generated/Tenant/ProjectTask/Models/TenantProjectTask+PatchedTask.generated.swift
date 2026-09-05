import Combine
import Foundation
import RoundTrip
import RoundTripREST

/// ☠️☠️☠️ This is generated code, modify at your own risk
public extension TenantProjectTaskApi {
    struct PatchedTask: Codable, Sendable {
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

        /// Custom Encoding Method for `PatchableValue` fields
        public func encode(to encoder: any Encoder) throws {
            var codingContainer = encoder.container(keyedBy: Self.CodingKeys.self)
            if !self.title.isUnmodified {
                try codingContainer.encode(self.title, forKey: .title)
            }
            if !self.details.isUnmodified {
                try codingContainer.encode(self.details, forKey: .details)
            }
            if !self.dueAt.isUnmodified {
                try codingContainer.encode(self.dueAt, forKey: .dueAt)
            }
            if !self.done.isUnmodified {
                try codingContainer.encode(self.done, forKey: .done)
            }
        }

        public init(from decoder: any Decoder) throws {
            let codingContainer = try decoder.container(keyedBy: Self.CodingKeys.self)
            if codingContainer.contains(.title) {
                if try codingContainer.decodeNil(forKey: .title) {
                    self.title = .deleted
                } else {
                    self.title = try codingContainer.decode(PatchableValue<String>.self, forKey: .title)
                }
            } else {
                self.title = .unmodified
            }
            if codingContainer.contains(.details) {
                if try codingContainer.decodeNil(forKey: .details) {
                    self.details = .deleted
                } else {
                    self.details = try codingContainer.decode(PatchableValue<String>.self, forKey: .details)
                }
            } else {
                self.details = .unmodified
            }
            if codingContainer.contains(.dueAt) {
                if try codingContainer.decodeNil(forKey: .dueAt) {
                    self.dueAt = .deleted
                } else {
                    self.dueAt = try codingContainer.decode(PatchableValue<Date>.self, forKey: .dueAt)
                }
            } else {
                self.dueAt = .unmodified
            }
            if codingContainer.contains(.done) {
                if try codingContainer.decodeNil(forKey: .done) {
                    self.done = .deleted
                } else {
                    self.done = try codingContainer.decode(PatchableValue<Bool>.self, forKey: .done)
                }
            } else {
                self.done = .unmodified
            }
        }

        /// Reset all patchable fields to `unmodified`
        public mutating func resetPatchableFields() {
            self.title = .unmodified
            self.details = .unmodified
            self.dueAt = .unmodified
            self.done = .unmodified
        }

        public func isUnmodified() -> Bool {
            self.title.isUnmodified &&
                self.details.isUnmodified &&
                self.dueAt.isUnmodified &&
                self.done.isUnmodified
        }
    }
}
