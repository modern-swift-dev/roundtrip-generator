import Foundation
import GeneratorBuilder
import GeneratorModels
import SwiftSyntax
import SwiftSyntaxBuilder

struct ApiServiceGenerator {
    let definition: ApiService

    /// The class name that will be generated. Ex: UsersApi
    func className(moduleName: String) -> String {
        definition.swiftApiTypeName(moduleName: moduleName)
    }

    /// The class name that will be generated. Ex: UsersApi
    var dirName: String {
        "\(definition.name.capitalCased)"
    }

    /// The file name
    var fileName: String {
        "\(definition.name.capitalCased)Api.generated.swift"
    }

    /// Write the code on disk, in the specified directory
    func write(moduleName: String, to url: URL, imports: [ApiImport]) throws {
        let safeModuleName = try moduleName.safeFilePathComponent(allowEmpty: true)
        let safeDefinitionDirName = try dirName.safeFilePathComponent()
        let safeFileName = try fileName.safeFilePathComponent()
        var dirUrl = url
        if !safeModuleName.isEmpty {
            dirUrl = dirUrl.appendingPathComponent(safeModuleName)

            if !FileManager.default.dirExist(at: dirUrl) {
                try? FileManager.default.createDirectory(at: dirUrl, withIntermediateDirectories: true, attributes: [:])
            }
        }

        let apiDir = dirUrl.appendingPathComponent(safeDefinitionDirName)

        let apiSharedDir = apiDir.appendingPathComponent("Models")

        let localReferencedTypes = definition.referencedTypes.filter {
            ApiTypeNameResolver.shared.scopedName(for: $0) == nil
        }

        try ApiTypeSchemasGenerator(dataTypes: localReferencedTypes).write(
            toDirectory: apiSharedDir,
            extensionName: className(moduleName: moduleName),
            fileNamePrefix: "\(moduleName.capitalCased)\(definition.name.capitalCased)+",
            imports: imports
        )

        for operation in definition.operations {
            let operationFileName = try "\(safeModuleName.capitalCased)\(definition.name.capitalCased)+\(operation.typeName).generated.swift".safeFilePathComponent()
            let operationUrl = apiDir.appendingPathComponent(operationFileName)
            try write(moduleName: moduleName, operation: operation, to: operationUrl, imports: imports)
        }

        try swiftBodyCode(moduleName: moduleName, imports: imports).write(to: dirUrl.appendingPathComponent("\(safeModuleName)\(safeFileName)"))
    }

    func write(moduleName: String, operation: ApiOperation, to url: URL, imports: [ApiImport]) throws {
        try ApiOperationGenerator(operation: operation).write(
            className: className(moduleName: moduleName),
            to: url,
            imports: imports
        )
    }

    private var pagedResultsOperations: [ApiOperation] {
        definition.operations.filter { operation in
            guard let dataType = operation.response.swiftDecodableDataType else {
                return false
            }
            if case let ApiTypeSchema.genericReference(typeName, _) = dataType, typeName == "PagedResults" {
                return true
            }
            return false
        }
    }

    private func hasPagedResultsDataType() -> Bool {
        !pagedResultsOperations.isEmpty
    }

    private func carriesHttpHeaders(_ operation: ApiOperation) -> Bool {
        operation.expandedParameters.contains { parameter in
            parameter.location == .header || parameter.location == .cookie
        }
    }

    private func nextPageSecuritySource(for operation: ApiOperation) -> String {
        guard operation.security != .unsecured else {
            return ""
        }
        let apiKeySource = switch operation.security {
            case .optional:
                """
                if adaptedRequest.apiKey?.isEmpty != false {
                    adaptedRequest.apiKey = await client.apiKey()
                }
                """
            case .secured:
                """
                if adaptedRequest.apiKey.isEmpty {
                    adaptedRequest.apiKey = try await client.requireApiKey()
                }
                """
            case .unsecured:
                ""
        }
        return """
            var adaptedRequest = request
        \(apiKeySource)
        """
    }

    private func nextPageHttpHeadersSource(for operation: ApiOperation) -> String {
        guard carriesHttpHeaders(operation) else {
            return "[:]"
        }
        return operation.security == .unsecured ? "request.httpHeaders" : "adaptedRequest.httpHeaders"
    }

    private func nextPageMethodDeclaration(for operation: ApiOperation, className: String) -> FunctionDeclSyntax {
        SwiftGeneratedSyntax.parse("API definition next page declaration") {
            try FunctionDeclSyntax(
                """
                func getNextPage(
                    _ currentPage: \(raw: className).\(raw: operation.typeName).Response,
                    request: \(raw: className).\(raw: operation.typeName).Request
                ) async throws -> ApiOperationResult<\(raw: className).\(raw: operation.typeName).Response>
                """
            )
        }
    }

    private func nextPageMethod(for operation: ApiOperation) -> FunctionDeclSyntax {
        let securitySource = nextPageSecuritySource(for: operation)
        let httpHeadersSource = nextPageHttpHeadersSource(for: operation)
        let acceptableStatusCode = operation.acceptableStatuses
            .filter(Self.statusCodeCanCarryResponseBody)
            .map { String($0) }
            .joined(separator: ", ")
        let bodySource = [securitySource, """
            guard let next = currentPage.next else { throw ApiError.invalidURL }
            return try await client.execute(
                request: NextPageRequest(requestPath: next, httpHeaders: \(httpHeadersSource)),
                validStatusCode: [\(acceptableStatusCode)]
            )
        """]
        .filter { !$0.isEmpty }
        .joined(separator: "\n")

        return SwiftGeneratedSyntax.parse("API definition next page method") {
            try FunctionDeclSyntax(
                """
                public func getNextPage(
                    _ currentPage: \(raw: operation.typeName).Response,
                    request: \(raw: operation.typeName).Request
                ) async throws -> ApiOperationResult<\(raw: operation.typeName).Response> {
                \(raw: bodySource)
                }
                """
            )
        }
    }

    private static func statusCodeCanCarryResponseBody(_ statusCode: Int) -> Bool {
        !(100 ..< 200 ~= statusCode || statusCode == 204 || statusCode == 205 || statusCode == 304)
    }

    func swiftBodyCode(moduleName: String, imports: [ApiImport]) -> any Node {
        let computedClassName = className(moduleName: moduleName)
        let pagedResultsOperations = pagedResultsOperations
        let allImports = imports + [ApiImport(stringLiteral: "Foundation")]
        let source = SourceFileSyntax {
            for value in allImports.swiftUniqueImports {
                SwiftImport(name: value.name, annotation: value.annotation).declaration
            }

            SwiftGeneratedSyntax.parse("API definition protocol") {
                try ProtocolDeclSyntax("public protocol \(raw: computedClassName)AsyncAwaitProtocol: Sendable") {
                    for operation in definition.operations {
                        ApiOperationGenerator(operation: operation)
                            .generateExecuteAsyncAwaitMethodDeclarationSyntax(className: computedClassName)
                    }
                    for operation in pagedResultsOperations {
                        nextPageMethodDeclaration(for: operation, className: computedClassName)
                    }
                }
                .with(
                    \.leadingTrivia,
                    .newlines(2) + .lineComment("// ☠️☠️☠️ This is generated code, modify at your own risk\n") + .lineComment("// sourcery: AutoMockable\n")
                )
            }

            SwiftGeneratedSyntax.parse("API definition class") {
                try ClassDeclSyntax("public final class \(raw: computedClassName): \(raw: computedClassName)AsyncAwaitProtocol, Sendable") {
                    try VariableDeclSyntax("private let client: any RestClientProtocol")

                    try InitializerDeclSyntax(
                        """
                        public init(client: any RestClientProtocol) {
                            self.client = client
                        }
                        """
                    )

                    if hasPagedResultsDataType() {
                        try StructDeclSyntax(
                            """
                            private struct NextPageRequest: URLRequestConvertible, Sendable {
                                let requestPath: URL
                                let httpHeaders: [String: String]

                                func buildRequest(baseUrl _: URL?, encoder _: JSONEncoder) throws -> URLRequest {
                                    var request = try URLRequest(url: requestPath, queryParams: nil)
                                    request.httpMethod = "GET"
                                    let hasExplicitAccept = httpHeaders.keys.contains { $0.lowercased() == "accept" }
                                    if !hasExplicitAccept {
                                        request.accept(mimeType: "application/json")
                                    }
                                    for (key, value) in httpHeaders {
                                        request.addHeader(value, name: key)
                                    }
                                    return request
                                }
                            }
                            """
                        )

                        for operation in pagedResultsOperations {
                            nextPageMethod(for: operation)
                        }
                    }

                    for operation in definition.operations {
                        ApiOperationGenerator(operation: operation).generateExecuteAsyncAwaitMethodSyntax()
                    }
                }
                .with(\.leadingTrivia, .newlines(2) + .lineComment("// ☠️☠️☠️ This is generated code, modify at your own risk\n"))
            }
        }

        return SwiftSyntaxNode(source)
    }
}
