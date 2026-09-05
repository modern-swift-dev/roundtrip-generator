// Generated code. Do not edit.
import Foundation
import Vapor

public struct ShowcaseTransportController: Sendable {
    private let service: any ShowcaseTransportService
    private let security: any GeneratedSecurityMiddleware

    public init(service: any ShowcaseTransportService, security: any GeneratedSecurityMiddleware) {
        self.service = service
        self.security = security
    }

    public func register(routes: RoutesBuilder) throws {
        routes.on(.POST, .constant("showcase"), .constant("uploads"), .constant("multipart"), use: uploadMultipart)
        routes.on(.POST, .constant("showcase"), .constant("uploads"), .constant("file"), use: uploadFile)
        routes.on(.POST, .constant("showcase"), .constant("uploads"), .constant("binary"), use: uploadBinary)
        routes.on(.DELETE, .constant("showcase"), .constant("uploads"), use: deleteWithBody)
    }

    private func uploadMultipart(req: Request) async throws -> Response {
        let securityRequest = GeneratedSecurityRequest(request: req, operationID: "Showcase.Transport.UploadMultipart")
        try await security.requireAuthorization(securityRequest)
        let compress = (try GeneratedRequestValueParser.optional(req.query[String.self, at: "compress"], name: "compress", as: Bool.self)) ?? false
        let apiKey = try GeneratedRequestValueParser.requiredString(req.headers.first(name: "Authorization"), name: "Authorization")
        let decodedMultipart = try req.content.decode(ShowcaseTransportUploadMultipartOperationMultipartBodyDecode.self)
        let body = ShowcaseTransportUploadMultipartOperationMultipartBody(
            file: decodedMultipart.file.map(GeneratedMultipartPart.init(file:)),
            metadata: decodedMultipart.metadata.map(GeneratedMultipartPart.init(file:))
        )
        let serviceRequest = ShowcaseTransportUploadMultipartOperationRequest(
            compress: compress,
            apiKey: apiKey,
            body: body
        )
        let serviceResponse = try await service.uploadMultipart(serviceRequest)
        return try GeneratedResponseEncoder.json(serviceResponse, validStatusCodes: [200, 201])
    }

    private func uploadFile(req: Request) async throws -> Response {
        let securityRequest = GeneratedSecurityRequest(request: req, operationID: "Showcase.Transport.UploadFile")
        try await security.requireAuthorization(securityRequest)
        let apiKey = try GeneratedRequestValueParser.requiredString(req.headers.first(name: "Authorization"), name: "Authorization")
        let body = try GeneratedBodyReader.data(from: req)
        let serviceRequest = ShowcaseTransportUploadFileOperationRequest(
            apiKey: apiKey,
            body: body
        )
        let serviceResponse = try await service.uploadFile(serviceRequest)
        return try GeneratedResponseEncoder.json(serviceResponse, validStatusCodes: [200, 201])
    }

    private func uploadBinary(req: Request) async throws -> Response {
        let securityRequest = GeneratedSecurityRequest(request: req, operationID: "Showcase.Transport.UploadBinary")
        try await security.requireAuthorization(securityRequest)
        let contentMd5 = GeneratedRequestValueParser.optionalString(req.headers.first(name: "Content-MD5"))
        let apiKey = try GeneratedRequestValueParser.requiredString(req.headers.first(name: "Authorization"), name: "Authorization")
        let body = try GeneratedBodyReader.data(from: req, expectedContentType: "application/octet-stream")
        let serviceRequest = ShowcaseTransportUploadBinaryOperationRequest(
            contentMd5: contentMd5,
            apiKey: apiKey,
            body: body
        )
        let serviceResponse = try await service.uploadBinary(serviceRequest)
        return try GeneratedResponseEncoder.binary(serviceResponse, contentType: "application/zip", validStatusCodes: [200, 202])
    }

    private func deleteWithBody(req: Request) async throws -> Response {
        let securityRequest = GeneratedSecurityRequest(request: req, operationID: "Showcase.Transport.DeleteWithBody")
        try await security.requireAuthorization(securityRequest)
        let apiKey = try GeneratedRequestValueParser.requiredString(req.headers.first(name: "Authorization"), name: "Authorization")
        let body = try req.content.decode(ShowcaseTransportDeleteReceiptRequest.self)
        let serviceRequest = ShowcaseTransportDeleteWithBodyOperationRequest(
            apiKey: apiKey,
            body: body
        )
        let serviceResponse = try await service.deleteWithBody(serviceRequest)
        return try GeneratedResponseEncoder.json(serviceResponse, validStatusCodes: [200, 202])
    }
}
