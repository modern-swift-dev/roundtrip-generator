import Combine
import Foundation
import RoundTrip
import RoundTripREST

/// ☠️☠️☠️ This is generated code, modify at your own risk
public extension TenantProjectApi {
    struct PatchedProject: Codable, Sendable {
        public var name: PatchableValue<String>
        public var status: PatchableValue<TenantApi.TenantStatus>
        public var owners: PatchableValue<[NamedObject]>
        public var labels: PatchableValue<[String: String?]>
        public init(
            name: PatchableValue<String> = .unmodified,
            status: PatchableValue<TenantApi.TenantStatus> = .unmodified,
            owners: PatchableValue<[NamedObject]> = .unmodified,
            labels: PatchableValue<[String: String?]> = .unmodified,
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

        /// Custom Encoding Method for `PatchableValue` fields
        public func encode(to encoder: any Encoder) throws {
            var codingContainer = encoder.container(keyedBy: Self.CodingKeys.self)
            if !name.isUnmodified {
                try codingContainer.encode(name, forKey: .name)
            }
            if !status.isUnmodified {
                try codingContainer.encode(status, forKey: .status)
            }
            if !owners.isUnmodified {
                try codingContainer.encode(owners, forKey: .owners)
            }
            if !labels.isUnmodified {
                try codingContainer.encode(labels, forKey: .labels)
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
            if codingContainer.contains(.status) {
                if try codingContainer.decodeNil(forKey: .status) {
                    status = .deleted
                } else {
                    status = try codingContainer.decode(PatchableValue<TenantApi.TenantStatus>.self, forKey: .status)
                }
            } else {
                status = .unmodified
            }
            if codingContainer.contains(.owners) {
                if try codingContainer.decodeNil(forKey: .owners) {
                    owners = .deleted
                } else {
                    owners = try codingContainer.decode(PatchableValue<[NamedObject]>.self, forKey: .owners)
                }
            } else {
                owners = .unmodified
            }
            if codingContainer.contains(.labels) {
                if try codingContainer.decodeNil(forKey: .labels) {
                    labels = .deleted
                } else {
                    labels = try codingContainer.decode(PatchableValue<[String: String?]>.self, forKey: .labels)
                }
            } else {
                labels = .unmodified
            }
        }

        /// Reset all patchable fields to `unmodified`
        public mutating func resetPatchableFields() {
            name = .unmodified
            status = .unmodified
            owners = .unmodified
            labels = .unmodified
        }

        public func isUnmodified() -> Bool {
            name.isUnmodified &&
                status.isUnmodified &&
                owners.isUnmodified &&
                labels.isUnmodified
        }
    }
}
