// Generated code. Do not edit.
import Foundation
import Vapor

public struct ShowcaseTransportUploadBinaryOperationRequest: Sendable {
    public var contentMd5: String?
    public var apiKey: String
    public var body: Data

    public init(contentMd5: String?, apiKey: String, body: Data) {
        self.contentMd5 = contentMd5
        self.apiKey = apiKey
        self.body = body
    }
}
