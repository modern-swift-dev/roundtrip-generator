// Generated code. Do not edit.
import Foundation
import Vapor

public enum ShowcaseSampleVisibility: String, Codable, Sendable, CaseIterable, Identifiable {
    case `public`
    case `internal`
    case `private`
    case garbage = "__garbage__"

    public var id: String {
        rawValue
    }

    public init(from decoder: Decoder) throws {
        do {
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            self = Self(rawValue: value) ?? .garbage
        } catch {
            self = .garbage
        }
    }
}
