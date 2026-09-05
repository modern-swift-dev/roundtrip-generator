import Combine
import Foundation
import RoundTrip
import RoundTripREST

/// ☠️☠️☠️ This is generated code, modify at your own risk
public extension TenantProjectApi {
    struct Project: Codable, Sendable {
        public var name: String
        public var status: TenantApi.TenantStatus
        public var owners: [NamedObject]
        public var labels: [String: String?]
        public init(name: String, status: TenantApi.TenantStatus, owners: [NamedObject], labels: [String: String?]) {
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
    }
}
