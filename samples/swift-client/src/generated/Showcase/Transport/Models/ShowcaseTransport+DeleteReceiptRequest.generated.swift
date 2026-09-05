import Combine
import Foundation
import RoundTrip
import RoundTripREST

/// ☠️☠️☠️ This is generated code, modify at your own risk
public extension ShowcaseTransportApi {
    struct DeleteReceiptRequest: Codable, Sendable {
        public var uploadIds: [UUID]
        public var reason: String?
        public init(uploadIds: [UUID], reason: String? = nil) {
            self.uploadIds = uploadIds
            self.reason = reason
        }

        public enum CodingKeys: String, CodingKey {
            case uploadIds = "upload_ids"
            case reason
        }
    }
}
