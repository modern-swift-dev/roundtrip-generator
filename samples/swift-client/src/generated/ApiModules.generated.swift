import Combine
import Foundation
import RoundTrip
import RoundTripREST

/// ☠️☠️☠️ This is generated code, modify at your own risk
/// ⚠️⚠️⚠️ use of @unchecked Sendable is done here because PassthroughSubject is not
/// technically sendable, but is still completely thread-safe in the way it operates.
///
/// The collection of services
public struct ApiModules: @unchecked Sendable {
    /// The rest client
    public let restClient: any RestClientProtocol
    /// The subject that publishes all `ApiError`
    public let errorSubject: PassthroughSubject<ApiError, Never> = .init()
    /// AdminApiModule
    public let adminModule: AdminApiModule
    /// LocationApiModule
    public let locationModule: LocationApiModule
    /// ShowcaseApiModule
    public let showcaseModule: ShowcaseApiModule
    /// TenantApiModule
    public let tenantModule: TenantApiModule
    /// initializer
    public init(
        apiKeyProvider: any ApiKeyProvider,
        baseURLProvider: any BaseURLProvider,
        networkService: any NetworkServiceProtocol,
        httpHeaderProvider: any DefaultHttpHeaderProvider,
    ) {
        restClient = RestClient(
            baseURLProvider: baseURLProvider,
            apiKeyProvider: apiKeyProvider,
            service: networkService,
            headerProvider: httpHeaderProvider,
            errorSubject: errorSubject,
        )
        adminModule = AdminApiModule(client: restClient)
        locationModule = LocationApiModule(client: restClient)
        showcaseModule = ShowcaseApiModule(client: restClient)
        tenantModule = TenantApiModule(client: restClient)
    }

    /// initializer
    public init(
        apiKeyProvider: any ApiKeyProvider,
        baseURLProvider: any BaseURLProvider,
        networkService: any NetworkServiceProtocol,
        httpHeaderProvider: any DefaultHttpHeaderProvider,
        adminModule: AdminApiModule,
        locationModule: LocationApiModule,
        showcaseModule: ShowcaseApiModule,
        tenantModule: TenantApiModule,
    ) {
        restClient = RestClient(
            baseURLProvider: baseURLProvider,
            apiKeyProvider: apiKeyProvider,
            service: networkService,
            headerProvider: httpHeaderProvider,
            errorSubject: errorSubject,
        )
        self.adminModule = adminModule
        self.locationModule = locationModule
        self.showcaseModule = showcaseModule
        self.tenantModule = tenantModule
    }
}
