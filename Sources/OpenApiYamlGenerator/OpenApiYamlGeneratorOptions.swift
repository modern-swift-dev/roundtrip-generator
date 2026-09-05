import Foundation

public struct OpenApiYamlGeneratorOptions: Sendable, Equatable {
    public let title: String?
    public let version: String
    public let servers: [String]
    public let fileName: String

    public init(
        title: String? = nil,
        version: String = "1.0.0",
        servers: [String] = [],
        fileName: String = "openapi.yaml"
    ) {
        self.title = title
        self.version = version
        self.servers = servers
        self.fileName = fileName
    }
}
