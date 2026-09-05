// Generated code. Do not edit.
import Foundation
import Vapor

public enum TenantStatus: String, Codable, Sendable, CaseIterable, Identifiable {
    case trial
    case active
    case suspended

    public var id: String {
        rawValue
    }

}
