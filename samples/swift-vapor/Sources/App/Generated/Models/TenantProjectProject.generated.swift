// Generated code. Do not edit.
import Foundation
import Vapor

public struct TenantProjectProject: Codable, Sendable {
    public var name: String
    public var status: TenantStatus
    public var owners: [NamedObject]
    public var labels: [String: String?]

    public init(name: String, status: TenantStatus, owners: [NamedObject], labels: [String: String?]) {
        self.name = name
        self.status = status
        self.owners = owners
        self.labels = labels
    }
}
