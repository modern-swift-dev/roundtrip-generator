// Generated code. Do not edit.
import Foundation
import Vapor

public struct LocationStructureUpdateOperationRequest: Sendable {
    public var structureId: Int64
    public var body: LocationStructureStructure

    public init(structureId: Int64, body: LocationStructureStructure) {
        self.structureId = structureId
        self.body = body
    }
}
