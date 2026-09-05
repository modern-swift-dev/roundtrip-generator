import Foundation
import GeneratorBuilder
import GeneratorModels
import SwiftSyntax
import SwiftSyntaxBuilder

struct ApiModuleGenerator {

    let module: ApiModule

    func write(to url: URL, imports: [ApiImport]) throws {
        try ApiTypeNameResolver.shared.withExclusiveAccess {
            try writeLocked(to: url, imports: imports)
        }
    }

    private func writeLocked(to url: URL, imports: [ApiImport]) throws {
        let safeModuleName = try module.name.safeFilePathComponent(allowEmpty: true)
        var pushedModuleReferences = false
        defer {
            if pushedModuleReferences {
                ApiTypeNameResolver.shared.pop()
            }
        }

        // Write the top level referenced types
        if !module.references.isEmpty {
            let sharedDir = module.name.isEmpty
                ? url.appendingPathComponent("Shared")
                : url.appendingPathComponent(safeModuleName).appendingPathComponent("Shared")
            if !FileManager.default.dirExist(at: sharedDir) {
                try FileManager.default.createDirectory(at: sharedDir, withIntermediateDirectories: true, attributes: [:])
            }

            if !module.name.isEmpty {
                let rootApiFile = url.appendingPathComponent(try "\(safeModuleName)Api.generated.swift".safeFilePathComponent())
                try generateRootModelApi(imports: imports).write(to: rootApiFile)

                try ApiTypeSchemasGenerator(dataTypes: module.references)
                    .write(
                        toDirectory: sharedDir,
                        extensionName: module.swiftApiTypeName,
                        fileNamePrefix: "\(module.name)Api+",
                        imports: imports
                    )

                ApiTypeNameResolver.shared.push(module: module.swiftApiTypeName, types: module.references)
                pushedModuleReferences = true
            } else {
                try ApiTypeSchemasGenerator(dataTypes: module.references)
                    .write(
                        toDirectory: sharedDir,
                        extensionName: "",
                        fileNamePrefix: "",
                        imports: imports
                    )
            }

        }

        for definition in module.definitions {
            try ApiServiceGenerator(definition: definition)
                .write(moduleName: safeModuleName, to: url, imports: imports)
        }

        if !module.definitions.isEmpty, !module.name.isEmpty {
            let moduleServiceFile = try "\(safeModuleName)ApiModule.generated.swift".safeFilePathComponent()
            try generateModuleService(imports: imports).write(to: url.appendingPathComponent(moduleServiceFile))
        }
    }

    private func generateRootModelApi(imports: [ApiImport]) -> any Node {
        let source = SourceFileSyntax {
            for value in imports.swiftUniqueImports {
                Self.importDeclaration(value)
            }

            DeclSyntax(
                """
                // ☠️☠️☠️ This is generated code, modify at your own risk
                public final class \(raw: module.swiftApiTypeName): Sendable { }
                """
            )
        }

        return SwiftSyntaxNode(source)
    }

    private func generateModuleService(imports: [ApiImport]) -> any Node {
        let source = SourceFileSyntax {
            for value in imports.swiftUniqueImports {
                Self.importDeclaration(value)
            }

            SwiftGeneratedSyntax.parse("aggregate API module") {
                try StructDeclSyntax(
                    """
                    // ☠️☠️☠️ This is generated code, modify at your own risk
                    public struct \(raw: module.swiftApiModuleTypeName): Sendable
                    """
                ) {
                    for definition in module.definitions {
                        let propertyName = definition.swiftAsyncApiPropertyName
                        let apiTypeName = definition.swiftApiTypeName(moduleName: module.name)
                        try VariableDeclSyntax(
                            """
                            /// \(raw: apiTypeName)AsyncAwaitProtocol
                            public let \(raw: propertyName): any \(raw: apiTypeName)AsyncAwaitProtocol
                            """
                        )
                    }

                    try InitializerDeclSyntax(
                        """
                        /// Initializer
                        public init(client: any RestClientProtocol) {
                        \(raw: module.definitions.map { definition in
                            let propertyName = definition.swiftAsyncApiPropertyName
                            let implName = definition.swiftImplementationPropertyName
                            let apiTypeName = definition.swiftApiTypeName(moduleName: module.name)
                            return """
                                let \(implName) = \(apiTypeName)(client: client)
                                \(propertyName) = \(implName)
                            """
                        }.joined(separator: "\n"))
                        }
                        """
                    )

                    try InitializerDeclSyntax(
                        """
                        /// Initializer
                        public init(
                        \(raw: module.definitions.map { definition in
                            let propertyName = definition.swiftAsyncApiPropertyName
                            let apiTypeName = definition.swiftApiTypeName(moduleName: module.name)
                            return "    \(propertyName): any \(apiTypeName)AsyncAwaitProtocol"
                        }.joined(separator: ",\n"))
                        ) {
                        \(raw: module.definitions.map { definition in
                            let propertyName = definition.swiftAsyncApiPropertyName
                            return "    self.\(propertyName) = \(propertyName)"
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
