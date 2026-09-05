// Generated code. Do not edit.
import Foundation
import Vapor

public struct LocationStructurePatchOperationRequest: Sendable {
    public var structureId: Int64
    public var body: LocationStructurePatchedStructure

    public init(structureId: Int64, body: LocationStructurePatchedStructure) {
        self.structureId = structureId
        self.body = body
    }
}
