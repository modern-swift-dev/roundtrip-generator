import Foundation
import GeneratorBuilder
import GeneratorModels
import SwiftSyntax
import SwiftSyntaxBuilder

struct ApiPackageServiceGenerator {

    let package: ApiPackage

    func write(url: URL) throws {
        try apiServiceCode().write(to: url.appendingPathComponent("ApiModules.generated.swift"))
    }

    private func apiServiceCode() -> any Node {
        let modules = package.referencedModules + package.modules
        let modulesWithDefinitions = modules.filter { !$0.definitions.isEmpty }

        let source = SourceFileSyntax {
            for value in (package.swiftImports + ["Combine"]).swiftUniqueImports {
                Self.importDeclaration(value)
            }

            SwiftGeneratedSyntax.parse("aggregate API service") {
                try StructDeclSyntax(
                    """
                    // ☠️☠️☠️ This is generated code, modify at your own risk
                    /// ⚠️⚠️⚠️ use of @unchecked Sendable is done here because PassthroughSubject is not
                    /// technically sendable, but is still completely thread-safe in the way it operates.
                    ///
                    /// The collection of services
                    public struct ApiModules: @unchecked Sendable
                    """
                ) {
                    try VariableDeclSyntax(
                        """
                        /// The rest client
                        public let restClient: any RestClientProtocol
                        """
                    )
                    try VariableDeclSyntax(
                        """
                        /// The subject that publishes all `ApiError`
                        public let errorSubject: PassthroughSubject<ApiError, Never> = .init()
                        """
                    )

                    for module in modulesWithDefinitions {
                        try VariableDeclSyntax(
                            """
                            /// \(raw: module.swiftApiModuleTypeName)
                            public let \(raw: module.swiftModulePropertyName): \(raw: module.swiftApiModuleTypeName)
                            """
                        )
                    }

                    try InitializerDeclSyntax(
                        """
                        /// initializer
                        public init(
                            apiKeyProvider: any ApiKeyProvider,
                            baseURLProvider: any BaseURLProvider,
                            networkService: any NetworkServiceProtocol,
                            httpHeaderProvider: any DefaultHttpHeaderProvider
                        ) {
                            restClient = RestClient(
                                baseURLProvider: baseURLProvider,
                                apiKeyProvider: apiKeyProvider,
                                service: networkService,
                                headerProvider: httpHeaderProvider,
                                errorSubject: errorSubject
                            )
                        \(raw: modulesWithDefinitions.map { module in
                            "    \(module.swiftModulePropertyName) = \(module.swiftApiModuleTypeName)(client: restClient)"
                        }.joined(separator: "\n"))
                        }
                        """
                    )

                    try InitializerDeclSyntax(
                        """
                        /// initializer
                        public init(
                            apiKeyProvider: any ApiKeyProvider,
                            baseURLProvider: any BaseURLProvider,
                            networkService: any NetworkServiceProtocol,
                            httpHeaderProvider: any DefaultHttpHeaderProvider,
                        \(raw: modulesWithDefinitions.map { module in
                            "    \(module.swiftModulePropertyName): \(module.swiftApiModuleTypeName)"
                        }.joined(separator: ",\n"))
                        ) {
                            restClient = RestClient(
                                baseURLProvider: baseURLProvider,
                                apiKeyProvider: apiKeyProvider,
                                service: networkService,
                                headerProvider: httpHeaderProvider,
                                errorSubject: errorSubject
                            )
                        \(raw: modulesWithDefinitions.map { module in
                            "    self.\(module.swiftModulePropertyName) = \(module.swiftModulePropertyName)"
                        }.joined(separator: "\n"))
                        }
                        """
                    )
                }
            }
        }

        return SwiftSyntaxNode(source)
    }

    private static func importDeclaration(_ value: ApiImport) -> DeclSyntax {
        SwiftImport(name: value.name, annotation: value.annotation).declaration
    }

}
