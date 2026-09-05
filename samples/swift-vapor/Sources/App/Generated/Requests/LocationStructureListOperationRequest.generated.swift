// Generated code. Do not edit.
import Foundation
import Vapor

public struct LocationStructureListOperationRequest: Sendable {
    public var text: String?
    public var type: [StructureType]

    public init(text: String?, type: [StructureType]) {
        self.text = text
        self.type = type
    }
}
