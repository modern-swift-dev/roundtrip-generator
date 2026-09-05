// Generated code. Do not edit.
import Foundation
import Vapor

public struct ShowcaseTransportUploadMultipartOperationMultipartBody: Sendable {
    public var file: GeneratedMultipartPart?
    public var metadata: GeneratedMultipartPart?

    public init(file: GeneratedMultipartPart? = nil, metadata: GeneratedMultipartPart? = nil) {
        self.file = file
        self.metadata = metadata
    }
}

struct ShowcaseTransportUploadMultipartOperationMultipartBodyDecode: Content {
    var file: File?
    var metadata: File?

    enum CodingKeys: String, CodingKey {
        case file
        case metadata
    }
}

public struct ShowcaseTransportUploadMultipartOperationRequest: Sendable {
    public var compress: Bool
    public var apiKey: String
    public var body: ShowcaseTransportUploadMultipartOperationMultipartBody

    public init(compress: Bool, apiKey: String, body: ShowcaseTransportUploadMultipartOperationMultipartBody) {
        self.compress = compress
        self.apiKey = apiKey
        self.body = body
    }
}
