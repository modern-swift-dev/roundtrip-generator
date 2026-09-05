// Generated code. Do not edit.
import Vapor

public struct GeneratedApiServices: Sendable {
    public let adminUserService: any AdminUserService
    public let adminRoleService: any AdminRoleService
    public let adminGroupService: any AdminGroupService
    public let locationStructureService: any LocationStructureService
    public let showcaseSampleModelsService: any ShowcaseSampleModelsService
    public let showcaseTransportService: any ShowcaseTransportService
    public let tenantProjectService: any TenantProjectService
    public let tenantProjectTaskService: any TenantProjectTaskService

    public init(
        adminUserService: any AdminUserService,
        adminRoleService: any AdminRoleService,
        adminGroupService: any AdminGroupService,
        locationStructureService: any LocationStructureService,
        showcaseSampleModelsService: any ShowcaseSampleModelsService,
        showcaseTransportService: any ShowcaseTransportService,
        tenantProjectService: any TenantProjectService,
        tenantProjectTaskService: any TenantProjectTaskService,
    ) {
        self.adminUserService = adminUserService
        self.adminRoleService = adminRoleService
        self.adminGroupService = adminGroupService
        self.locationStructureService = locationStructureService
        self.showcaseSampleModelsService = showcaseSampleModelsService
        self.showcaseTransportService = showcaseTransportService
        self.tenantProjectService = tenantProjectService
        self.tenantProjectTaskService = tenantProjectTaskService
    }

    public static var notImplemented: GeneratedApiServices {
        GeneratedApiServices(
            adminUserService: NotImplementedAdminUserService(),
            adminRoleService: NotImplementedAdminRoleService(),
            adminGroupService: NotImplementedAdminGroupService(),
            locationStructureService: NotImplementedLocationStructureService(),
            showcaseSampleModelsService: NotImplementedShowcaseSampleModelsService(),
            showcaseTransportService: NotImplementedShowcaseTransportService(),
            tenantProjectService: NotImplementedTenantProjectService(),
            tenantProjectTaskService: NotImplementedTenantProjectTaskService(),
        )
    }
}

public func routes(
    _ app: Application,
    services: GeneratedApiServices = .notImplemented,
    security: any GeneratedSecurityMiddleware = AllowAllGeneratedSecurityMiddleware(),
) throws {
    try routes(app.routes, services: services, security: security)
}

public func routes(
    _ routes: RoutesBuilder,
    services: GeneratedApiServices = .notImplemented,
    security: any GeneratedSecurityMiddleware = AllowAllGeneratedSecurityMiddleware(),
) throws {
    try AdminUserController(
        service: services.adminUserService,
        security: security,
    ).register(routes: routes)
    try AdminRoleController(
        service: services.adminRoleService,
        security: security,
    ).register(routes: routes)
    try AdminGroupController(
        service: services.adminGroupService,
        security: security,
    ).register(routes: routes)
    try LocationStructureController(
        service: services.locationStructureService,
        security: security,
    ).register(routes: routes)
    try ShowcaseSampleModelsController(
        service: services.showcaseSampleModelsService,
        security: security,
    ).register(routes: routes)
    try ShowcaseTransportController(
        service: services.showcaseTransportService,
        security: security,
    ).register(routes: routes)
    try TenantProjectController(
        service: services.tenantProjectService,
        security: security,
    ).register(routes: routes)
    try TenantProjectTaskController(
        service: services.tenantProjectTaskService,
        security: security,
    ).register(routes: routes)
}
