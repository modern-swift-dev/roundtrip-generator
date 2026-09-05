// Generated code. Do not edit.
import Foundation
import Vapor

public protocol LocationStructureService: Sendable {
    func create(_ request: LocationStructureCreateOperationRequest) async throws -> GeneratedResponse<LocationStructureIdStructure>
    func update(_ request: LocationStructureUpdateOperationRequest) async throws -> GeneratedResponse<LocationStructureIdStructure>
    func patch(_ request: LocationStructurePatchOperationRequest) async throws -> GeneratedResponse<LocationStructureIdStructure>
    func delete(_ request: LocationStructureDeleteOperationRequest) async throws -> GeneratedResponse<Void>
    func list(_ request: LocationStructureListOperationRequest) async throws -> GeneratedResponse<PagedResults<LocationStructureIdentifiedStructure>>
    func get(_ request: LocationStructureGetOperationRequest) async throws -> GeneratedResponse<LocationStructureIdentifiedStructure>
}

public struct NotImplementedLocationStructureService: LocationStructureService {
    public init() {}

    public func create(_: LocationStructureCreateOperationRequest) async throws -> GeneratedResponse<LocationStructureIdStructure> {
        throw Abort(.notImplemented)
    }

    public func update(_: LocationStructureUpdateOperationRequest) async throws -> GeneratedResponse<LocationStructureIdStructure> {
        throw Abort(.notImplemented)
    }

    public func patch(_: LocationStructurePatchOperationRequest) async throws -> GeneratedResponse<LocationStructureIdStructure> {
        throw Abort(.notImplemented)
    }

    public func delete(_: LocationStructureDeleteOperationRequest) async throws -> GeneratedResponse<Void> {
        throw Abort(.notImplemented)
    }

    public func list(_: LocationStructureListOperationRequest) async throws -> GeneratedResponse<PagedResults<LocationStructureIdentifiedStructure>> {
        throw Abort(.notImplemented)
    }

    public func get(_: LocationStructureGetOperationRequest) async throws -> GeneratedResponse<LocationStructureIdentifiedStructure> {
        throw Abort(.notImplemented)
    }
}
