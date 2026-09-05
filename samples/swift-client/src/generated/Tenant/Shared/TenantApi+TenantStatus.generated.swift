import Combine
import Foundation
import RoundTrip
import RoundTripREST

/// ☠️☠️☠️ This is generated code, modify at your own risk
public extension TenantApi {
    enum TenantStatus: String, Codable, CaseIterable, Sendable, Identifiable {
        case trial
        case active
        case suspended
        public var id: String {
            rawValue
        }
    }
}
