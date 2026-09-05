// Generated code. Do not edit.
import Foundation
import Vapor

public struct ShowcaseSampleModelsCreateNotificationOperationRequest: Sendable {
    public var idempotencyKey: String?
    public var apiKey: String
    public var body: ShowcaseSampleModelsNotificationEnvelope

    public init(idempotencyKey: String?, apiKey: String, body: ShowcaseSampleModelsNotificationEnvelope) {
        self.idempotencyKey = idempotencyKey
        self.apiKey = apiKey
        self.body = body
    }
}
