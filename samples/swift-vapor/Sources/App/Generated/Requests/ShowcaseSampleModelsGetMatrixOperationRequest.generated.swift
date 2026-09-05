// Generated code. Do not edit.
import Foundation
import Vapor


public struct ShowcaseSampleModelsGetMatrixOperationRequest: Sendable {
    public var matrixId: String
    public var visible: Bool
    public var visibility: ShowcaseSampleVisibility
    public var scores: [ShowcaseSampleModelsPrimitiveMatrixSampleScore]
    public var traceId: String?
    public var sampleSession: String?
    public var apiKey: String?

    public init(matrixId: String, visible: Bool, visibility: ShowcaseSampleVisibility, scores: [ShowcaseSampleModelsPrimitiveMatrixSampleScore], traceId: String?, sampleSession: String?, apiKey: String?) {
        self.matrixId = matrixId
        self.visible = visible
        self.visibility = visibility
        self.scores = scores
        self.traceId = traceId
        self.sampleSession = sampleSession
        self.apiKey = apiKey
    }
}
