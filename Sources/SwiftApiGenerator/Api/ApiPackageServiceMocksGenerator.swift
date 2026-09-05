import Foundation
import GeneratorBuilder
import GeneratorModels
import SwiftSyntax
import SwiftSyntaxBuilder

// swiftlint:disable function_body_length
struct ApiPackageServiceMocksGenerator {

    let package: ApiPackage

    func write(url: URL) throws {
        try apiServiceMocksCode().write(to: url.appendingPathComponent("ApiModulesMocks.generated.swift"))
    }

    private func apiServiceMocksCode() -> any Node {
        let modules = package.referencedModules + package.modules
        let modulesWithDefinitions = modules.filter { !$0.definitions.isEmpty }
        let source = SourceFileSyntax {
            Self.importDeclaration(ApiImport(stringLiteral: package.name))
            for value in (package.swiftImports + [
                "SwiftyMocky",
                "XCTest"
            ]).swiftUniqueImports {
                Self.importDeclaration(value)
            }
            mocksStructDeclaration(modules: modules, modulesWithDefinitions: modulesWithDefinitions)
            mockingTestCaseDeclaration
        }

        return SwiftSyntaxNode(source)
    }

    private func mocksStructDeclaration(
        modules: [ApiModule],
        modulesWithDefinitions: [ApiModule]
    ) -> StructDeclSyntax {
        let moduleSetups = modulesWithDefinitions.map { module in
            let apiSetups = module.definitions.map { definition in
                let propertyName = "\(module.name)\(definition.name)AsyncApi".swiftPropertyName
                let typeBaseName = ApiServiceGenerator(definition: definition).className(moduleName: module.name)
                return "        \(propertyName) = \(typeBaseName)AsyncAwaitProtocolMock()"
            }.joined(separator: "\n")
            let moduleArguments = module.definitions.enumerated().map { index, definition in
                let propertyName = "\(module.name)\(definition.name)AsyncApi".swiftPropertyName
                let suffix = index < module.definitions.count - 1 ? "," : ""
                return "            \(definition.swiftAsyncApiPropertyName): \(propertyName)\(suffix)"
            }.joined(separator: "\n")

            return """

            \(apiSetups)
            \(module.swiftModulePropertyName) = \(module.swiftApiModuleTypeName)(
            \(moduleArguments)
            )
            """
        }.joined(separator: "\n")

        let apiResets = modulesWithDefinitions.flatMap { module in
            module.definitions.map { definition in
                let propertyName = "\(module.name)\(definition.name)AsyncApi".swiftPropertyName
                return "        \(propertyName)?.resetMock()"
            }
        }.joined(separator: "\n")

        let apiNils = modulesWithDefinitions.flatMap { module in
            module.definitions.map { definition in
                let propertyName = "\(module.name)\(definition.name)AsyncApi".swiftPropertyName
                return "        \(propertyName) = nil"
            }
        }.joined(separator: "\n")

        let moduleNils = modulesWithDefinitions.map { module in
            "        \(module.swiftModulePropertyName) = nil"
        }.joined(separator: "\n")

        return SwiftGeneratedSyntax.parse("API package mocks struct") {
            try StructDeclSyntax(
                """
                // ☠️☠️☠️ This is generated code, modify at your own risk
                @MainActor struct ApiModulesMocks
                """
            ) {
                try VariableDeclSyntax("var apiKeyMock: ApiKeyProviderMock!")
                try VariableDeclSyntax("var baseUrlMock: BaseURLProviderMock!")
                try VariableDeclSyntax("var networkMock: NetworkServiceProtocolMock!")
                try VariableDeclSyntax("var httpHeaderProviderMock: DefaultHttpHeaderProviderMock!")

                for module in modulesWithDefinitions {
                    for definition in module.definitions {
                        let propertyName = "\(module.name)\(definition.name)AsyncApi".swiftPropertyName
                        let typeBaseName = ApiServiceGenerator(definition: definition).className(moduleName: module.name)
                        try VariableDeclSyntax("var \(raw: propertyName): \(raw: typeBaseName)AsyncAwaitProtocolMock!")
                    }
                    try VariableDeclSyntax("var \(raw: module.swiftModulePropertyName): \(raw: module.swiftApiModuleTypeName)!")
                }

                try FunctionDeclSyntax(
                    """
                    mutating func setUp() {
                        apiKeyMock = ApiKeyProviderMock()
                        baseUrlMock = BaseURLProviderMock()
                        networkMock = NetworkServiceProtocolMock()
                        httpHeaderProviderMock = DefaultHttpHeaderProviderMock()
                    \(raw: moduleSetups)
                    }
                    """
                )

                try FunctionDeclSyntax(
                    """
                    mutating func tearDown() {
                        apiKeyMock?.resetMock()
                        baseUrlMock?.resetMock()
                        networkMock?.resetMock()
                        httpHeaderProviderMock?.resetMock()
                    \(raw: apiResets.isEmpty ? "" : "\n\(apiResets)")

                        apiKeyMock = nil
                        baseUrlMock = nil
                        networkMock = nil
                        httpHeaderProviderMock = nil
                    \(raw: apiNils.isEmpty ? "" : "\n\(apiNils)")
                    \(raw: moduleNils.isEmpty ? "" : "\n\(moduleNils)")
                    }
                    """
                )
            }
        }
    }

    private var mockingTestCaseDeclaration: ClassDeclSyntax {
        SwiftGeneratedSyntax.parse("API package mocks test case") {
            try ClassDeclSyntax(
                """
                // ☠️☠️☠️ This is generated code, modify at your own risk
                open class ApiModulesMockingTestCase: XCTestCase
                """
            ) {
                try VariableDeclSyntax("@MainActor internal private(set) var mocks = ApiModulesMocks()")

                try FunctionDeclSyntax(
                    """
                    @MainActor override open func setUp() {
                        super.setUp()
                        mocks.setUp()
                    }
                    """
                )

                try FunctionDeclSyntax(
                    """
                    @MainActor override open func tearDown() {
                        super.tearDown()
                        mocks.tearDown()
                    }
                    """
                )
            }
        }
    }

    private static func importDeclaration(_ value: ApiImport) -> DeclSyntax {
        SwiftImport(name: value.name, annotation: value.annotation).declaration
    }
}
