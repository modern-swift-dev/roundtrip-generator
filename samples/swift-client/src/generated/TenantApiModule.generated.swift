import Combine
import Foundation
import RoundTrip
import RoundTripREST

/// ☠️☠️☠️ This is generated code, modify at your own risk
public struct TenantApiModule: Sendable {
    /// TenantProjectApiAsyncAwaitProtocol
    public let projectAsyncApi: any TenantProjectApiAsyncAwaitProtocol
    /// TenantProjectTaskApiAsyncAwaitProtocol
    public let projectTaskAsyncApi: any TenantProjectTaskApiAsyncAwaitProtocol
    /// Initializer
    public init(client: any RestClientProtocol) {
        let projectImpl = TenantProjectApi(client: client)
        projectAsyncApi = projectImpl
        let projectTaskImpl = TenantProjectTaskApi(client: client)
        projectTaskAsyncApi = projectTaskImpl
    }

    /// Initializer
    public init(
        projectAsyncApi: any TenantProjectApiAsyncAwaitProtocol,
        projectTaskAsyncApi: any TenantProjectTaskApiAsyncAwaitProtocol
    ) {
        self.projectAsyncApi = projectAsyncApi
        self.projectTaskAsyncApi = projectTaskAsyncApi
    }
}
