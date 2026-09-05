import Combine
import Foundation
import RoundTrip
import RoundTripREST

/// ☠️☠️☠️ This is generated code, modify at your own risk
public extension ShowcaseSampleModelsApi {
    struct PushNotification: Codable, Sendable, Equatable, Hashable, Identifiable {
        public var id: UUID
        public var title: String
        public var body: String
        public var customData: [String: String?]
        public init(id: UUID, title: String, body: String, customData: [String: String?]) {
            self.id = id
            self.title = title
            self.body = body
            self.customData = customData
        }

        public enum CodingKeys: String, CodingKey {
            case id
            case title
            case body
            case customData = "custom_data"
        }

        public static func == (lhs: PushNotification, rhs: PushNotification) -> Bool {
            lhs.id == rhs.id
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }
}
