// Generated code. Do not edit.
import Vapor

public func configure(
    _ app: Application,
    services: GeneratedApiServices = .notImplemented,
    security: any GeneratedSecurityMiddleware = AllowAllGeneratedSecurityMiddleware(),
) async throws {
    try routes(app, services: services, security: security)
}
