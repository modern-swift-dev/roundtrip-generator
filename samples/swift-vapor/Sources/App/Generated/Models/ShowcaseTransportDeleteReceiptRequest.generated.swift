// Generated code. Do not edit.
import Foundation
import Vapor

public struct ShowcaseTransportDeleteReceiptRequest: Codable, Sendable {
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
