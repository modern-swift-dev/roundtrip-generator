import Combine
import Foundation
import RoundTrip
import RoundTripREST

/// ☠️☠️☠️ This is generated code, modify at your own risk
public extension TenantProjectTaskApi {
    struct Task: Codable, Sendable {
        public var title: String
        public var details: String?
        public var dueAt: Date?
        public var done: Bool
        public init(title: String, details: String? = nil, dueAt: Date? = nil, done: Bool = false) {
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
    }
}
