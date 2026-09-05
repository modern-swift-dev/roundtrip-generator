// Generated code. Do not edit.
import Foundation
import Vapor

public struct ShowcaseSampleModelsEmailNotification: Codable, Sendable, Equatable, Hashable, Identifiable {
    public var id: UUID
    public var subject: String
    public var body: String
    public var recipients: [String]

    public init(id: UUID, subject: String, body: String, recipients: [String]) {
        self.id = id
        self.subject = subject
        self.body = body
        self.recipients = recipients
    }

    public static func == (lhs: ShowcaseSampleModelsEmailNotification, rhs: ShowcaseSampleModelsEmailNotification) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
