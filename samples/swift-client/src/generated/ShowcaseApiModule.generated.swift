import Combine
import Foundation
import RoundTrip
import RoundTripREST

/// ☠️☠️☠️ This is generated code, modify at your own risk
public struct ShowcaseApiModule: Sendable {
    /// ShowcaseSampleModelsApiAsyncAwaitProtocol
    public let sampleModelsAsyncApi: any ShowcaseSampleModelsApiAsyncAwaitProtocol
    /// ShowcaseTransportApiAsyncAwaitProtocol
    public let transportAsyncApi: any ShowcaseTransportApiAsyncAwaitProtocol
    /// Initializer
    public init(client: any RestClientProtocol) {
        let sampleModelsImpl = ShowcaseSampleModelsApi(client: client)
        sampleModelsAsyncApi = sampleModelsImpl
        let transportImpl = ShowcaseTransportApi(client: client)
        transportAsyncApi = transportImpl
    }

    /// Initializer
    public init(
        sampleModelsAsyncApi: any ShowcaseSampleModelsApiAsyncAwaitProtocol,
        transportAsyncApi: any ShowcaseTransportApiAsyncAwaitProtocol
    ) {
        self.sampleModelsAsyncApi = sampleModelsAsyncApi
        self.transportAsyncApi = transportAsyncApi
    }
}
