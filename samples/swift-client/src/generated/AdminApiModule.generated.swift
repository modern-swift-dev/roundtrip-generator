import Combine
import Foundation
import RoundTrip
import RoundTripREST

/// ☠️☠️☠️ This is generated code, modify at your own risk
public struct AdminApiModule: Sendable {
    /// AdminUserApiAsyncAwaitProtocol
    public let userAsyncApi: any AdminUserApiAsyncAwaitProtocol
    /// AdminRoleApiAsyncAwaitProtocol
    public let roleAsyncApi: any AdminRoleApiAsyncAwaitProtocol
    /// AdminGroupApiAsyncAwaitProtocol
    public let groupAsyncApi: any AdminGroupApiAsyncAwaitProtocol
    /// Initializer
    public init(client: any RestClientProtocol) {
        let userImpl = AdminUserApi(client: client)
        userAsyncApi = userImpl
        let roleImpl = AdminRoleApi(client: client)
        roleAsyncApi = roleImpl
        let groupImpl = AdminGroupApi(client: client)
        groupAsyncApi = groupImpl
    }

    /// Initializer
    public init(
        userAsyncApi: any AdminUserApiAsyncAwaitProtocol,
        roleAsyncApi: any AdminRoleApiAsyncAwaitProtocol,
        groupAsyncApi: any AdminGroupApiAsyncAwaitProtocol,
    ) {
        self.userAsyncApi = userAsyncApi
        self.roleAsyncApi = roleAsyncApi
        self.groupAsyncApi = groupAsyncApi
    }
}
