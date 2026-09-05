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
            if !title.isUnmodified {
                try codingContainer.encode(title, forKey: .title)
            }
            if !details.isUnmodified {
                try codingContainer.encode(details, forKey: .details)
            }
            if !dueAt.isUnmodified {
                try codingContainer.encode(dueAt, forKey: .dueAt)
            }
            if !done.isUnmodified {
                try codingContainer.encode(done, forKey: .done)
            }
        }

        public init(from decoder: any Decoder) throws {
            let codingContainer = try decoder.container(keyedBy: Self.CodingKeys.self)
            if codingContainer.contains(.title) {
                if try codingContainer.decodeNil(forKey: .title) {
                    title = .deleted
                } else {
                    title = try codingContainer.decode(PatchableValue<String>.self, forKey: .title)
                }
            } else {
                title = .unmodified
            }
            if codingContainer.contains(.details) {
                if try codingContainer.decodeNil(forKey: .details) {
                    details = .deleted
                } else {
                    details = try codingContainer.decode(PatchableValue<String>.self, forKey: .details)
                }
            } else {
                details = .unmodified
            }
            if codingContainer.contains(.dueAt) {
                if try codingContainer.decodeNil(forKey: .dueAt) {
                    dueAt = .deleted
                } else {
                    dueAt = try codingContainer.decode(PatchableValue<Date>.self, forKey: .dueAt)
                }
            } else {
                dueAt = .unmodified
            }
            if codingContainer.contains(.done) {
                if try codingContainer.decodeNil(forKey: .done) {
                    done = .deleted
                } else {
                    done = try codingContainer.decode(PatchableValue<Bool>.self, forKey: .done)
                }
            } else {
                done = .unmodified
            }
        }

        /// Reset all patchable fields to `unmodified`
        public mutating func resetPatchableFields() {
            title = .unmodified
            details = .unmodified
            dueAt = .unmodified
            done = .unmodified
        }

        public func isUnmodified() -> Bool {
            title.isUnmodified &&
                details.isUnmodified &&
                dueAt.isUnmodified &&
                done.isUnmodified
        }
    }
}
