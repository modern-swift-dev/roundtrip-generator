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

        /// Custom Encoding Method for `PatchableValue` fields
        public func encode(to encoder: any Encoder) throws {
            var codingContainer = encoder.container(keyedBy: Self.CodingKeys.self)
            if !self.name.isUnmodified {
                try codingContainer.encode(self.name, forKey: .name)
            }
            if !self.status.isUnmodified {
                try codingContainer.encode(self.status, forKey: .status)
            }
            if !self.owners.isUnmodified {
                try codingContainer.encode(self.owners, forKey: .owners)
            }
            if !self.labels.isUnmodified {
                try codingContainer.encode(self.labels, forKey: .labels)
            }
        }

        public init(from decoder: any Decoder) throws {
            let codingContainer = try decoder.container(keyedBy: Self.CodingKeys.self)
            if codingContainer.contains(.name) {
                if try codingContainer.decodeNil(forKey: .name) {
                    self.name = .deleted
                } else {
                    self.name = try codingContainer.decode(PatchableValue<String>.self, forKey: .name)
                }
            } else {
                self.name = .unmodified
            }
            if codingContainer.contains(.status) {
                if try codingContainer.decodeNil(forKey: .status) {
                    self.status = .deleted
                } else {
                    self.status = try codingContainer.decode(PatchableValue<TenantApi.TenantStatus>.self, forKey: .status)
                }
            } else {
                self.status = .unmodified
            }
            if codingContainer.contains(.owners) {
                if try codingContainer.decodeNil(forKey: .owners) {
                    self.owners = .deleted
                } else {
                    self.owners = try codingContainer.decode(PatchableValue<[NamedObject]>.self, forKey: .owners)
                }
            } else {
                self.owners = .unmodified
            }
            if codingContainer.contains(.labels) {
                if try codingContainer.decodeNil(forKey: .labels) {
                    self.labels = .deleted
                } else {
                    self.labels = try codingContainer.decode(PatchableValue<[String: String?]>.self, forKey: .labels)
                }
            } else {
                self.labels = .unmodified
            }
        }

        /// Reset all patchable fields to `unmodified`
        public mutating func resetPatchableFields() {
            self.name = .unmodified
            self.status = .unmodified
            self.owners = .unmodified
            self.labels = .unmodified
        }

        public func isUnmodified() -> Bool {
            self.name.isUnmodified &&
                self.status.isUnmodified &&
                self.owners.isUnmodified &&
                self.labels.isUnmodified
        }
    }
}
