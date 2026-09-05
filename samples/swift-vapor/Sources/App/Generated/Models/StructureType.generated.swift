// Generated code. Do not edit.
import Foundation
import Vapor

public enum StructureType: String, Codable, Sendable, CaseIterable, Identifiable {
    case plant
    case productionLine = "production_line"
    case workstation
    case equipment

    public var id: String {
        rawValue
    }

}
