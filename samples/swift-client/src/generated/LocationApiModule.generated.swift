import Combine
import Foundation
import RoundTrip
import RoundTripREST

/// ☠️☠️☠️ This is generated code, modify at your own risk
public struct LocationApiModule: Sendable {
    /// LocationStructureApiAsyncAwaitProtocol
    public let structureAsyncApi: any LocationStructureApiAsyncAwaitProtocol
    /// Initializer
    public init(client: any RestClientProtocol) {
        let structureImpl = LocationStructureApi(client: client)
        structureAsyncApi = structureImpl
    }

    /// Initializer
    public init(
        structureAsyncApi: any LocationStructureApiAsyncAwaitProtocol,
    ) {
        self.structureAsyncApi = structureAsyncApi
    }
}
