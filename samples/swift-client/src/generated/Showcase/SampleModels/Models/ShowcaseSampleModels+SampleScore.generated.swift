import Combine
import Foundation
import RoundTrip
import RoundTripREST

/// ☠️☠️☠️ This is generated code, modify at your own risk
public extension ShowcaseSampleModelsApi {
    enum SampleScore: Int, Codable, CaseIterable, Sendable, Identifiable {
        case low = 10
        case medium = 50
        case high = 100
        public var id: Int {
            rawValue
        }
    }
}
