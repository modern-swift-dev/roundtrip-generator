import Combine
import Foundation
import RoundTrip
import RoundTripREST

/// ☠️☠️☠️ This is generated code, modify at your own risk
public enum StructureType: String, Codable, CaseIterable, Sendable, Identifiable {
    case plant
    case productionLine = "production_line"
    case workstation
    case equipment
    public var id: String {
        rawValue
    }
}
