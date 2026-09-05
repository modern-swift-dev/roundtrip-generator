import Combine
import Foundation
import RoundTrip
import RoundTripREST

/// ☠️☠️☠️ This is generated code, modify at your own risk
public extension ShowcaseTransportApi {
    struct UploadReceipt: Codable, Sendable, Equatable, Hashable {
        public var uploadId: UUID
        public var bytes: Int64
        public var state: UploadState
        public init(uploadId: UUID, bytes: Int64, state: UploadState = .queued) {
            self.uploadId = uploadId
            self.bytes = bytes
            self.state = state
        }

        public enum CodingKeys: String, CodingKey {
            case uploadId = "upload_id"
            case bytes
            case state
        }

        public static func == (lhs: UploadReceipt, rhs: UploadReceipt) -> Bool {
            lhs.uploadId == rhs.uploadId
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(self.uploadId)
        }

        /// ☠️☠️☠️ This is generated code, modify at your own risk
        public enum UploadState: String, Codable, CaseIterable, Sendable, Identifiable {
            case queued
            case stored
            case scanned
            public var id: String {
                rawValue
            }
        }
    }
}
