// Generated code. Do not edit.
import Foundation
import Vapor

public protocol ShowcaseSampleModelsService: Sendable {
    func getMatrix(_ request: ShowcaseSampleModelsGetMatrixOperationRequest) async throws -> GeneratedResponse<ShowcaseSampleModelsPrimitiveMatrix>
    func createNotification(_ request: ShowcaseSampleModelsCreateNotificationOperationRequest) async throws -> GeneratedResponse<ShowcaseSampleModelsNotificationEnvelope>
}

public struct NotImplementedShowcaseSampleModelsService: ShowcaseSampleModelsService {
    public init() {}

    public func getMatrix(_: ShowcaseSampleModelsGetMatrixOperationRequest) async throws -> GeneratedResponse<ShowcaseSampleModelsPrimitiveMatrix> {
        throw Abort(.notImplemented)
    }

    public func createNotification(_: ShowcaseSampleModelsCreateNotificationOperationRequest) async throws -> GeneratedResponse<ShowcaseSampleModelsNotificationEnvelope> {
        throw Abort(.notImplemented)
    }
}
