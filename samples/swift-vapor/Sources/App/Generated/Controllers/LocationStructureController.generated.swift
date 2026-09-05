// Generated code. Do not edit.
import Foundation
import Vapor

public struct LocationStructureController: Sendable {
    private let service: any LocationStructureService
    private let security: any GeneratedSecurityMiddleware

    public init(service: any LocationStructureService, security: any GeneratedSecurityMiddleware) {
        self.service = service
        self.security = security
    }

    public func register(routes: RoutesBuilder) throws {
        routes.on(.POST, .constant("structure"), use: create)
        routes.on(.PUT, .constant("structure"), .parameter("structure_id"), use: update)
        routes.on(.PATCH, .constant("structure"), .parameter("structure_id"), use: patch)
        routes.on(.DELETE, .constant("structure"), .parameter("structure_id"), use: delete)
        routes.on(.GET, .constant("structure"), use: list)
        routes.on(.GET, .constant("structure"), .parameter("structure_id"), use: get)
    }

    private func create(req: Request) async throws -> Response {
        let securityRequest = GeneratedSecurityRequest(request: req, operationID: "Location.Structure.Create")
        _ = securityRequest
        let body = try req.content.decode(LocationStructureStructure.self)
        let serviceRequest = LocationStructureCreateOperationRequest(
            body: body,
        )
        let serviceResponse = try await service.create(serviceRequest)
        return try GeneratedResponseEncoder.json(serviceResponse, validStatusCodes: [200, 201])
    }

    private func update(req: Request) async throws -> Response {
        let securityRequest = GeneratedSecurityRequest(request: req, operationID: "Location.Structure.Update")
        _ = securityRequest
        let structureId = try GeneratedRequestValueParser.required(req.parameters.get("structure_id"), name: "structure_id", as: Int64.self)
        let body = try req.content.decode(LocationStructureStructure.self)
        let serviceRequest = LocationStructureUpdateOperationRequest(
            structureId: structureId,
            body: body,
        )
        let serviceResponse = try await service.update(serviceRequest)
        return try GeneratedResponseEncoder.json(serviceResponse, validStatusCodes: [200])
    }

    private func patch(req: Request) async throws -> Response {
        let securityRequest = GeneratedSecurityRequest(request: req, operationID: "Location.Structure.Patch")
        _ = securityRequest
        let structureId = try GeneratedRequestValueParser.required(req.parameters.get("structure_id"), name: "structure_id", as: Int64.self)
        let body = try req.content.decode(LocationStructurePatchedStructure.self)
        let serviceRequest = LocationStructurePatchOperationRequest(
            structureId: structureId,
            body: body,
        )
        let serviceResponse = try await service.patch(serviceRequest)
        return try GeneratedResponseEncoder.json(serviceResponse, validStatusCodes: [200])
    }

    private func delete(req: Request) async throws -> Response {
        let securityRequest = GeneratedSecurityRequest(request: req, operationID: "Location.Structure.Delete")
        _ = securityRequest
        let structureId = try GeneratedRequestValueParser.required(req.parameters.get("structure_id"), name: "structure_id", as: Int64.self)
        let serviceRequest = LocationStructureDeleteOperationRequest(
            structureId: structureId,
        )
        let serviceResponse = try await service.delete(serviceRequest)
        return try GeneratedResponseEncoder.empty(serviceResponse, validStatusCodes: [200, 204, 205])
    }

    private func list(req: Request) async throws -> Response {
        let securityRequest = GeneratedSecurityRequest(request: req, operationID: "Location.Structure.List")
        _ = securityRequest
        let text = GeneratedRequestValueParser.optionalString(req.query[String.self, at: "text"])
        let type = try GeneratedRequestValueParser.requiredStringRawEnumArray(req.query[String.self, at: "type"], name: "type", as: StructureType.self)
        let serviceRequest = LocationStructureListOperationRequest(
            text: text,
            type: type,
        )
        let serviceResponse = try await service.list(serviceRequest)
        return try GeneratedResponseEncoder.json(serviceResponse, validStatusCodes: [200])
    }

    private func get(req: Request) async throws -> Response {
        let securityRequest = GeneratedSecurityRequest(request: req, operationID: "Location.Structure.Get")
        _ = securityRequest
        let structureId = try GeneratedRequestValueParser.required(req.parameters.get("structure_id"), name: "structure_id", as: Int64.self)
        let serviceRequest = LocationStructureGetOperationRequest(
            structureId: structureId,
        )
        let serviceResponse = try await service.get(serviceRequest)
        return try GeneratedResponseEncoder.json(serviceResponse, validStatusCodes: [200])
    }
}
