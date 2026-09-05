// Generated code. Do not edit.
import Foundation
import Vapor

public struct ShowcaseTransportUploadReceipt: Codable, Sendable, Equatable, Hashable {
    public var uploadId: UUID
    public var bytes: Int64
    public var state: ShowcaseTransportUploadReceiptUploadState

    public init(uploadId: UUID, bytes: Int64, state: ShowcaseTransportUploadReceiptUploadState = .queued) {
        self.uploadId = uploadId
        self.bytes = bytes
        self.state = state
    }

    public enum CodingKeys: String, CodingKey {
        case uploadId = "upload_id"
        case bytes
        case state
    }

    public static func == (lhs: ShowcaseTransportUploadReceipt, rhs: ShowcaseTransportUploadReceipt) -> Bool {
        lhs.uploadId == rhs.uploadId
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.uploadId)
    }
}
