import Combine
import Foundation
import RoundTrip
import RoundTripREST

/// ☠️☠️☠️ This is generated code, modify at your own risk
public extension LocationStructureApi {
    struct PatchedStructure: Codable, Sendable {
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

        /// Custom Encoding Method for `PatchableValue` fields
        public func encode(to encoder: any Encoder) throws {
            var codingContainer = encoder.container(keyedBy: Self.CodingKeys.self)
            if !name.isUnmodified {
                try codingContainer.encode(name, forKey: .name)
            }
            if !type.isUnmodified {
                try codingContainer.encode(type, forKey: .type)
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
            if codingContainer.contains(.type) {
                if try codingContainer.decodeNil(forKey: .type) {
                    type = .deleted
                } else {
                    type = try codingContainer.decode(PatchableValue<StructureType>.self, forKey: .type)
                }
            } else {
                type = .unmodified
            }
        }

        /// Reset all patchable fields to `unmodified`
        public mutating func resetPatchableFields() {
            name = .unmodified
            type = .unmodified
        }

        public func isUnmodified() -> Bool {
            name.isUnmodified &&
                type.isUnmodified
        }
    }
}
