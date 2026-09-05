import Combine
import Foundation
import RoundTrip
import RoundTripREST

/// ☠️☠️☠️ This is generated code, modify at your own risk
public extension ShowcaseApi {
    enum SampleVisibility: String, Codable, CaseIterable, Sendable, Identifiable {
        case garbage = "__garbage__"
        case `public`
        case `internal`
        case `private`
        public var id: String {
            rawValue
        }

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(rawValue)
        }

        public init(from decoder: any Decoder) throws {
            do {
                let container = try decoder.singleValueContainer()
                let rawValue = try container.decode(String.self)
                self = .init(rawValue: rawValue) ?? .garbage
            } catch {
                self = .garbage
            }
        }
    }
}
