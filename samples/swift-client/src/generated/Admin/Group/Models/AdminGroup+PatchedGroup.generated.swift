import Combine
import Foundation
import RoundTrip
import RoundTripREST

/// ☠️☠️☠️ This is generated code, modify at your own risk
public extension AdminGroupApi {
    struct PatchedGroup: Codable, Sendable {
        public var name: PatchableValue<String>
        public init(name: PatchableValue<String> = .unmodified) {
            self.name = name
        }

        public enum CodingKeys: String, CodingKey {
            case name
        }

        /// Custom Encoding Method for `PatchableValue` fields
        public func encode(to encoder: any Encoder) throws {
            var codingContainer = encoder.container(keyedBy: Self.CodingKeys.self)
            if !name.isUnmodified {
                try codingContainer.encode(name, forKey: .name)
            }
        }

        public init(from decoder: any Decoder) throws {
            let codingContainer = try decoder.container(keyedBy: Self.CodingKeys.self)
            if codingContainer.contains(.name) {
                if try codingContainer.decodeNil(forKey: .name) {
                    name = .deleted
                } else {
                    name = try codingContainer.decode(PatchableValue<String>.self, forKey: .name)
                }
            } else {
                name = .unmodified
            }
        }

        /// Reset all patchable fields to `unmodified`
        public mutating func resetPatchableFields() {
            name = .unmodified
        }

        public func isUnmodified() -> Bool {
            name.isUnmodified
        }
    }
}
