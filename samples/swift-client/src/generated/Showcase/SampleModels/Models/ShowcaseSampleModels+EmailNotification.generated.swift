import Combine
import Foundation
import RoundTrip
import RoundTripREST

/// ☠️☠️☠️ This is generated code, modify at your own risk
public extension ShowcaseSampleModelsApi {
    struct EmailNotification: Codable, Sendable, Equatable, Hashable, Identifiable {
        public var id: UUID
        public var subject: String
        public var body: String
        public var recipients: [String]
        public init(id: UUID, subject: String, body: String, recipients: [String]) {
            self.id = id
            self.subject = subject
            self.body = body
            self.recipients = recipients
        }

        public enum CodingKeys: String, CodingKey {
            case id
            case subject
            case body
            case recipients
        }

        public static func == (lhs: EmailNotification, rhs: EmailNotification) -> Bool {
            lhs.id == rhs.id
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }
}
