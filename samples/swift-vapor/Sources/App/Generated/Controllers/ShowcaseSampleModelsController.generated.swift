// Generated code. Do not edit.
import Foundation
import Vapor

public struct ShowcaseSampleModelsController: Sendable {
    private let service: any ShowcaseSampleModelsService
    private let security: any GeneratedSecurityMiddleware

    public init(service: any ShowcaseSampleModelsService, security: any GeneratedSecurityMiddleware) {
        self.service = service
        self.security = security
    }

    public func register(routes: RoutesBuilder) throws {
        routes.on(.GET, .constant("showcase"), .constant("matrix"), .parameter("matrix_id"), use: getMatrix)
        routes.on(.POST, .constant("showcase"), .constant("notifications"), use: createNotification)
        // Skipped followRuntimeUrl: runtime paths cannot be registered by a backend.
    }

    private func getMatrix(req: Request) async throws -> Response {
        let securityRequest = GeneratedSecurityRequest(request: req, operationID: "Showcase.SampleModels.GetMatrix")
        try await security.authorizeOptional(securityRequest)
        let matrixId = try GeneratedRequestValueParser.requiredString(req.parameters.get("matrix_id"), name: "matrix_id")
        let visible = (try GeneratedRequestValueParser.optional(req.query[String.self, at: "visible"], name: "visible", as: Bool.self)) ?? true
        let visibility = (try GeneratedRequestValueParser.optionalStringRawEnum(req.query[String.self, at: "visibility"], name: "visibility", as: ShowcaseSampleVisibility.self)) ?? .`public`
        let scores = (try GeneratedRequestValueParser.optionalIntRawEnumArray(req.query[String.self, at: "scores"], name: "scores", as: ShowcaseSampleModelsPrimitiveMatrixSampleScore.self)) ?? [.high]
        let traceId = GeneratedRequestValueParser.optionalString(req.headers.first(name: "X-Trace-Id"))
        let sampleSession = GeneratedRequestValueParser.optionalString(req.cookies["sample_session"]?.string)
        let apiKey = GeneratedRequestValueParser.optionalString(req.headers.first(name: "Authorization"))
        let serviceRequest = ShowcaseSampleModelsGetMatrixOperationRequest(
            matrixId: matrixId,
            visible: visible,
            visibility: visibility,
            scores: scores,
            traceId: traceId,
            sampleSession: sampleSession,
            apiKey: apiKey
        )
        let serviceResponse = try await service.getMatrix(serviceRequest)
        return try GeneratedResponseEncoder.json(serviceResponse, validStatusCodes: [200])
    }

    private func createNotification(req: Request) async throws -> Response {
        let securityRequest = GeneratedSecurityRequest(request: req, operationID: "Showcase.SampleModels.CreateNotification")
        try await security.requireAuthorization(securityRequest)
        let idempotencyKey = GeneratedRequestValueParser.optionalString(req.headers.first(name: "Idempotency-Key"))
        let apiKey = try GeneratedRequestValueParser.requiredString(req.headers.first(name: "Authorization"), name: "Authorization")
        let body = try req.content.decode(ShowcaseSampleModelsNotificationEnvelope.self)
        let serviceRequest = ShowcaseSampleModelsCreateNotificationOperationRequest(
            idempotencyKey: idempotencyKey,
            apiKey: apiKey,
            body: body
        )
        let serviceResponse = try await service.createNotification(serviceRequest)
        return try GeneratedResponseEncoder.json(serviceResponse, validStatusCodes: [200, 201, 202])
    }
}
