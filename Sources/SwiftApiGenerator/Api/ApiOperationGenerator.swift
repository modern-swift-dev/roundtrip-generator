import Foundation
import GeneratorBuilder
import GeneratorModels
import SwiftBasicFormat
import SwiftSyntax
import SwiftSyntaxBuilder

// swiftlint:disable function_body_length
struct ApiOperationGenerator {
    let operation: ApiOperation

    private var requestBodyTypeDeclaration: String? {
        switch operation.request {
            case let .json(type):
                type.map { ApiTypeSchemaGenerator(dataType: $0).swiftTypeDeclaration }
            case .file:
                "URL"
            case .binary:
                "Data"
            case .none,
                 .multiPart:
                nil
        }
    }

    private var acceptableStatusCodes: [Int] {
        guard operation.response.swiftDecodableDataType != nil else {
            return operation.acceptableStatuses
        }
        return operation.acceptableStatuses.filter(Self.statusCodeCanCarryResponseBody)
    }

    private static func statusCodeCanCarryResponseBody(_ statusCode: Int) -> Bool {
        !(100 ..< 200 ~= statusCode || statusCode == 204 || statusCode == 205 || statusCode == 304)
    }

    func write(className: String, to url: URL, imports: [ApiImport]) throws {
        try swiftCode(
            parentClassName: className,
            imports: imports,
        )
        .write(to: url)
    }

    func swiftCode(parentClassName: String, imports: [ApiImport]) -> any Node {
        let allImports = imports + [ApiImport(stringLiteral: "Foundation")] + operation.extraImports + operation.allImports

        let operationDeclaration = SwiftGeneratedSyntax.parse("operation \(operation.typeName) operation") {
            try StructDeclSyntax("struct \(raw: operation.typeName): Sendable") {
                generateRequestDeclaration(parentClassName: parentClassName)
                generateRequestBodyDeclarations(parentClassName: parentClassName)
                generateResponseDeclarations(parentClassName: parentClassName)
            }
        }

        let body = if !parentClassName.isEmpty {
            DeclSyntax(
                SwiftGeneratedSyntax.parse("operation \(parentClassName) extension") {
                    try ExtensionDeclSyntax(
                        """
                        // ☠️☠️☠️ This is generated code, modify at your own risk
                        public extension \(raw: parentClassName)
                        """,
                    ) {
                        operationDeclaration
                    }
                },
            )
        } else {
            DeclSyntax(
                SwiftGeneratedSyntax.parse("operation \(operation.typeName) top-level operation") {
                    try StructDeclSyntax(
                        """
                        // ☠️☠️☠️ This is generated code, modify at your own risk
                        struct \(raw: operation.typeName): Sendable
                        """,
                    ) {
                        generateRequestDeclaration(parentClassName: parentClassName)
                        generateRequestBodyDeclarations(parentClassName: parentClassName)
                        generateResponseDeclarations(parentClassName: parentClassName)
                    }
                },
            )
        }

        let source = SourceFileSyntax {
            for value in allImports.swiftUniqueImports {
                SwiftImport(name: value.name, annotation: value.annotation).declaration
            }
            body
        }

        return SwiftSyntaxNode(source)
    }

    var swiftMethodName: String {
        operation.name.swiftPropertyName
    }

    func swiftExecuteMethodDelegation() -> any Node {
        let progressArgument = operation.request.isMultipart || operation.request.isFile ? ", progress: progress" : ""
        return SwiftSyntaxNode(SwiftGeneratedSyntax.parse("operation \(operation.typeName) execute delegation") {
            ExprSyntax("value.\(raw: swiftMethodName)(request: request\(raw: progressArgument))")
        })
    }

    private func swiftExecuteAsyncAwaitDelegationExpression() -> ExprSyntax {
        let progressArgument = operation.request.isMultipart || operation.request.isFile ? ", progress: progress" : ""
        return SwiftGeneratedSyntax.parse("operation \(operation.typeName) execute async delegation") {
            ExprSyntax("try await value.\(raw: swiftMethodName)(request: request\(raw: progressArgument))")
        }
    }

    func swiftExecuteMethodAsyncAwait() -> any Node {
        generateExecuteAsyncAwaitMethod()
    }

    func swiftExecuteMethodAsyncAwaitDeclaration(parentClassName: String) -> any Node {
        generateExecuteAsyncAwaitMethodDeclaration(className: parentClassName)
    }

    func swiftExecuteMethodAsyncAwaitDelegation() -> any Node {
        SwiftSyntaxNode(swiftExecuteAsyncAwaitDelegationExpression())
    }

    private func generateRequestBodyDeclarations(parentClassName: String) -> [DeclSyntax] {
        if let type = operation.request.dataType,
           let requestType = ApiTypeSchemaGenerator(dataType: type).getSwiftDeclaration(parentClassName: parentClassName, outputWithExtension: false) {
            return [requestType]
        }
        return []
    }

    private func generateBodyDeclarations() -> [DeclSyntax] {
        switch operation.request {
            case .none:
                return []
            case let .multiPart(parts):
                let bodyDeclaration = DeclSyntax(
                    SwiftGeneratedSyntax.parse("operation \(operation.typeName).Request multipart body") {
                        try VariableDeclSyntax("public private(set) var body: [String: MultipartBody.Part] = [:]")
                    },
                )
                let setterDeclarations = parts.map { part in
                    DeclSyntax(
                        SwiftGeneratedSyntax.parse("operation \(operation.typeName).Request multipart setter") {
                            try FunctionDeclSyntax(
                                """
                                public mutating func setBodyPart\(raw: part.capitalCased)(part: MultipartBody.Part) {
                                    body[\(raw: part.debugDescription)] = part
                                }
                                """,
                            )
                        },
                    )
                }
                return [bodyDeclaration] + setterDeclarations
            case let .json(type):
                guard let type else {
                    return []
                }
                return [
                    DeclSyntax(
                        SwiftGeneratedSyntax.parse("operation \(operation.typeName).Request JSON body") {
                            try VariableDeclSyntax("public var body: \(raw: ApiTypeSchemaGenerator(dataType: type).swiftTypeDeclaration)")
                        },
                    )
                ]
            case .file:
                return [
                    DeclSyntax(
                        SwiftGeneratedSyntax.parse("operation \(operation.typeName).Request file body") {
                            try VariableDeclSyntax("public var body: URL")
                        },
                    )
                ]
            case .binary:
                return [
                    DeclSyntax(
                        SwiftGeneratedSyntax.parse("operation \(operation.typeName).Request binary body") {
                            try VariableDeclSyntax("public var body: Data")
                        },
                    )
                ]
        }
    }

    /// Generate the `Request` struct for the endpoint
    private func generateRequest(parentClassName _: String) -> any Node {
        SwiftSyntaxNode(generateRequestDeclaration(parentClassName: ""))
    }

    private func generateRequestDeclaration(parentClassName _: String) -> DeclSyntax {
        let protocols = [
            "URLRequestConvertible",
            operation.request.isMultipart ? "MultipartBodyConvertible" : nil,
            operation.request.isEquatable ? "Equatable" : nil,
            operation.request.isSwiftSendable ? "Sendable" : nil
        ]
        .compactMap(\.self)
        .joined(separator: ", ")

        let pathParameters = operation.expandedParameters.filter { $0.location == .path }
        let cookies = operation.expandedParameters.filter { $0.location == .cookie }
        let headers = operation.expandedParameters.filter { $0.location == .header }
        let queryParams = operation.expandedParameters.filter { $0.location == .query }

        let declaration = SwiftGeneratedSyntax.parse("operation \(operation.typeName).Request") {
            try StructDeclSyntax("public struct Request: \(raw: protocols)") {
                if !operation.expandedParameters.isEmpty {
                    for param in operation.expandedParameters {
                        param.swiftProperty.declaration
                    }
                }

                for declaration in generateBodyDeclarations() {
                    declaration
                }

                generateRequestPathAccessor(path: operation.path, from: pathParameters)

                if !headers.isEmpty || !cookies.isEmpty {
                    generateHttpHeaderAccessor(from: headers, hasCookies: !cookies.isEmpty)
                }

                if !cookies.isEmpty {
                    generateHttpCookieAccessor(from: cookies)
                }

                if !queryParams.isEmpty {
                    generateQueryParamsAccessor(from: queryParams)
                }

                generateInitDeclaration()

                generateUrlRequestConvertibleSyntax(hasBody: requestBodyTypeDeclaration != nil, hasQueryParams: !queryParams.isEmpty, hasHeaders: !cookies.isEmpty || !headers.isEmpty)

                if operation.request.isMultipart {
                    generateMultipartConvertibleSyntax()
                }
            }
        }

        return DeclSyntax(declaration)
    }

    private func generateInit() -> any Node {
        SwiftSyntaxNode(generateInitDeclaration())
    }

    private func generateInitDeclaration() -> DeclSyntax {
        let properties = operation.expandedParameters.map(\.swiftProperty)
        let initializedProperties = properties.filter { $0.mutable || $0.defaultValue == nil }
        let isEmpty = !operation.path.isRuntime && properties.isEmpty && requestBodyTypeDeclaration == nil
        if isEmpty {
            return SwiftGeneratedSyntax.parse("operation \(operation.typeName).Request empty init") {
                try DeclSyntax(InitializerDeclSyntax("public init() {}"))
            }
        }

        var parameters: [FunctionParameterSyntax] = []
        if operation.path.isRuntime {
            parameters.append(
                SwiftGeneratedSyntax.parse("operation \(operation.typeName).Request runtime path parameter") {
                    FunctionParameterSyntax("requestPath: URL")
                },
            )
        }

        parameters += initializedProperties.map(\.initParameter)

        if let bodyType = requestBodyTypeDeclaration {
            parameters.append(
                SwiftGeneratedSyntax.parse("operation \(operation.typeName).Request body parameter") {
                    FunctionParameterSyntax("body: \(raw: bodyType)")
                },
            )
        }

        let parameterSource = parameters
            .map { $0.formatted().description }
            .joined(separator: ", ")

        var assignmentLines: [String] = []
        if operation.path.isRuntime {
            assignmentLines.append("self.requestPath = requestPath")
        }
        assignmentLines += initializedProperties
            .map { "self.\($0.name) = \($0.name)" }
        if requestBodyTypeDeclaration != nil {
            assignmentLines.append("self.body = body")
        }
        let assignmentSource = assignmentLines.joined(separator: "\n")

        return SwiftGeneratedSyntax.parse("operation \(operation.typeName).Request init") {
            try DeclSyntax(
                InitializerDeclSyntax(
                    """
                    public init(\(raw: parameterSource)) {
                    \(raw: assignmentSource)
                    }
                    """,
                ),
            )
        }
    }

    /// Generate the `Response` struct for the endpoint
    private func generateResponse(parentClassName: String) -> (any Node)? {
        let declarations = generateResponseDeclarations(parentClassName: parentClassName)
        guard !declarations.isEmpty else {
            return nil
        }
        return SwiftSyntaxNode(SourceFileSyntax {
            declarations
        })
    }

    private func generateResponseDeclarations(parentClassName: String) -> [DeclSyntax] {
        if let dataType = operation.response.swiftDecodableDataType {
            var declarations: [DeclSyntax] = []

            if let responseType = ApiTypeSchemaGenerator(dataType: dataType).getSwiftDeclaration(parentClassName: parentClassName, outputWithExtension: false) {
                declarations.append(responseType)
            }

            declarations.append(
                DeclSyntax(
                    SwiftGeneratedSyntax.parse("operation \(operation.typeName).Response typealias") {
                        try TypeAliasDeclSyntax("public typealias Response = \(raw: ApiTypeSchemaGenerator(dataType: dataType).swiftTypeDeclaration)")
                    },
                ),
            )
            return declarations
        }
        return []
    }

    private func generateExecuteAsyncAwaitMethodDeclaration(className: String) -> any Node {
        SwiftSyntaxNode(generateExecuteAsyncAwaitMethodDeclarationSyntax(className: className))
    }

    func generateExecuteAsyncAwaitMethodDeclarationSyntax(className: String) -> FunctionDeclSyntax {
        let progressParameter = operation.request.isMultipart || operation.request.isFile ? ", progress: Progress?" : ""
        let returnType = if operation.response.swiftDecodableDataType != nil {
            "ApiOperationResult<\(className).\(operation.typeName).Response>"
        } else {
            "ApiResponse"
        }

        return SwiftGeneratedSyntax.parse("operation \(operation.typeName) execute declaration") {
            try FunctionDeclSyntax(
                """
                func \(raw: swiftMethodName)(
                    request: \(raw: className).\(raw: operation.typeName).Request\(raw: progressParameter)
                ) async throws -> \(raw: returnType)
                """,
            )
        }
    }

    private func generateExecuteAsyncAwaitMethod() -> any Node {
        SwiftSyntaxNode(generateExecuteAsyncAwaitMethodSyntax())
    }

    func generateExecuteAsyncAwaitMethodSyntax() -> FunctionDeclSyntax {
        let acceptableStatusCode = acceptableStatusCodes.map { String($0) }.joined(separator: ", ")
        let progressParameter = operation.request.isMultipart || operation.request.isFile ? ", progress: Progress?" : ""
        let returnType = if operation.response.swiftDecodableDataType != nil {
            "ApiOperationResult<\(operation.typeName).Response>"
        } else {
            "ApiResponse"
        }
        let requestVariable: String
        let securitySource: String
        if operation.security != .unsecured {
            requestVariable = "adaptedRequest"
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
            securitySource = """
                var adaptedRequest = request
            \(apiKeySource)
            """
        } else {
            requestVariable = "request"
            securitySource = ""
        }

        let executeSource = if operation.request.isMultipart {
            """
                return try await client.postMultipart(
                    request: \(requestVariable),
                    progress: progress,
                    validStatusCode: [\(acceptableStatusCode)]
                )
            """
        } else if operation.request.isFile {
            """
                return try await client.upload(
                    request: \(requestVariable),
                    fileUrl: request.body,
                    progress: progress,
                    validStatusCode: [\(acceptableStatusCode)]
                )
            """
        } else {
            """
                return try await client.execute(
                    request: \(requestVariable),
                    validStatusCode: [\(acceptableStatusCode)]
                )
            """
        }
        let bodySource = [securitySource, executeSource]
            .filter { !$0.isEmpty }
            .joined(separator: "\n")

        return SwiftGeneratedSyntax.parse("operation \(operation.typeName) execute method") {
            try FunctionDeclSyntax(
                """
                public func \(raw: swiftMethodName)(request: \(raw: operation.typeName).Request\(raw: progressParameter)) async throws -> \(raw: returnType) {
                \(raw: bodySource)
                }
                """,
            )
        }
    }

    /// Generate the url request convertible method for generating a valid url request
    /// - parameter method: The http method
    /// - parameter body: The request body definition, if any
    private func generateUrlRequestConvertible(hasBody: Bool, hasQueryParams: Bool, hasHeaders: Bool) -> any Node {
        SwiftSyntaxNode(generateUrlRequestConvertibleSyntax(hasBody: hasBody, hasQueryParams: hasQueryParams, hasHeaders: hasHeaders))
    }

    private func generateUrlRequestConvertibleSyntax(hasBody: Bool, hasQueryParams: Bool, hasHeaders: Bool) -> FunctionDeclSyntax {
        let requestBuildSource = switch operation.path {
            case .relative:
                if hasQueryParams {
                    """
                    guard let baseUrl else { throw ApiError.invalidURL }
                    var request = try URLRequest(
                        baseUrl: baseUrl,
                        path: requestPath,
                        queryParams: queryParameters
                    )
                    """
                } else {
                    """
                    guard let baseUrl else { throw ApiError.invalidURL }
                    var request = try URLRequest(
                        baseUrl: baseUrl,
                        path: requestPath,
                        queryParams: nil
                    )
                    """
                }
            case .absolute:
                if hasQueryParams {
                    """
                    guard let url = URL(string: requestPath) else { throw ApiError.invalidURL }
                    var request = try URLRequest(url: url, queryParams: queryParameters)
                    """
                } else {
                    """
                    guard let url = URL(string: requestPath) else { throw ApiError.invalidURL }
                    var request = try URLRequest(url: url, queryParams: nil)
                    """
                }
            case .runtime:
                if hasQueryParams {
                    """
                    var request = try URLRequest(url: requestPath, queryParams: queryParameters)
                    """
                } else {
                    """
                    var request = try URLRequest(url: requestPath, queryParams: nil)
                    """
                }
        }

        let encoderParameter = if hasBody, !operation.request.isMultipart, !operation.request.isFile {
            "encoder: JSONEncoder"
        } else {
            "encoder _: JSONEncoder"
        }
        let headerSource = if hasHeaders {
            """
            for (key, value) in httpHeaders {
                request.addHeader(value, name: key)
            }
            """
        } else {
            ""
        }
        let contentTypeSource = if hasBody, let mimeType = operation.request.mimeType {
            "request.contentType(mimeType: \(mimeType.debugDescription))"
        } else {
            ""
        }
        let acceptSource = if hasHeaders {
            """
                let httpHeaders = self.httpHeaders
                let hasExplicitAccept = httpHeaders.keys.contains {
                    $0.lowercased() == "accept"
                }
                if !hasExplicitAccept {
                    request.accept(mimeType: \(operation.response.mimeType.debugDescription))
                }
            """
        } else {
            "    request.accept(mimeType: \(operation.response.mimeType.debugDescription))"
        }
        let bodySource = if hasBody {
            switch operation.request {
                case .json:
                    "try request.codableBody(body, encoder: encoder)"
                case .binary:
                    "request.httpBody = body"
                default:
                    ""
            }
        } else {
            ""
        }

        return SwiftGeneratedSyntax.parse("operation \(operation.typeName).Request buildRequest") {
            try FunctionDeclSyntax(
                """
                public func buildRequest(baseUrl: URL?, \(raw: encoderParameter)) throws -> URLRequest {
                \(raw: requestBuildSource)
                    request.httpMethod = \(raw: operation.method.httpMethod.debugDescription)
                \(raw: acceptSource)
                \(raw: headerSource)
                \(raw: contentTypeSource)
                \(raw: bodySource)
                    return request
                }
                """,
            )
        }
    }

    /// Generate the url request convertible method for generating a valid url request
    /// - parameter method: The http method
    /// - parameter body: The request body definition, if any
    private func generateMultipartConvertible() -> any Node {
        SwiftSyntaxNode(generateMultipartConvertibleSyntax())
    }

    private func generateMultipartConvertibleSyntax() -> FunctionDeclSyntax {
        SwiftGeneratedSyntax.parse("operation \(operation.typeName).Request multipart convertible") {
            try FunctionDeclSyntax(
                """
                public func multiPartBody(encoder _: JSONEncoder) throws -> MultipartBody {
                    guard let builder = try MultipartBody.Builder() else { throw ApiError.requestEncodingFailed }
                \(raw: multipartRequiredPartsSource())
                    for (name, part) in body {
                        builder.addPart(name: name, part: part)
                    }
                    return try builder.build()
                }
                """,
            )
        }
    }

    private func multipartRequiredPartsSource() -> String {
        guard case let .multiPart(parts) = operation.request else {
            return ""
        }
        return parts
            .map { "guard body[\($0.debugDescription)] != nil else { throw ApiError.requestEncodingFailed }" }
            .joined(separator: "\n")
    }

    /// Generate accessor for the query parameters
    /// - parameter from: the query parameters if any
    private func generateQueryParamsAccessor(from params: [ApiParameter]) -> VariableDeclSyntax {
        let parameterAccessors = params.enumerated()
            .map { generateParameterAccessor(for: $0.element, index: $0.offset) }
            .joined(separator: "\n")
        return SwiftGeneratedSyntax.parse("operation \(operation.typeName).Request queryParameters") {
            try VariableDeclSyntax(
                """
                public var queryParameters: [String: any FormEncodable] {
                    var values: [String: any FormEncodable] = [:]
                \(raw: parameterAccessors)
                    return values
                }
                """,
            )
        }
    }

    /// Generate accessor for the http headers
    /// - parameter from: the http header parameters if any
    private func generateHttpHeaderAccessor(from params: [ApiParameter], hasCookies: Bool) -> VariableDeclSyntax {
        let parameterAccessors = params.enumerated()
            .map { generateParameterAccessor(for: $0.element, index: $0.offset) }
            .joined(separator: "\n")
        let cookieSource = hasCookies ? """
            let cookieAllowedCharacters = CharacterSet.urlQueryAllowed.subtracting(CharacterSet(charactersIn: ";,= "))
            let cookieValues = httpCookies
            let cookies = cookieValues.keys.sorted().compactMap { name -> String? in
                guard let encodedName = name.addingPercentEncoding(withAllowedCharacters: cookieAllowedCharacters),
                      let encodedValue = cookieValues[name]?.formEncodableValue().addingPercentEncoding(withAllowedCharacters: cookieAllowedCharacters) else {
                    return nil
                }
                return "\\(encodedName)=\\(encodedValue)"
            }.joined(separator: "; ")
            if !cookies.isEmpty {
                values["Cookie"] = cookies
            }
        """ : ""
        return SwiftGeneratedSyntax.parse("operation \(operation.typeName).Request httpHeaders") {
            try VariableDeclSyntax(
                """
                public var httpHeaders: [String: String] {
                    var values: [String: String] = [:]
                \(raw: parameterAccessors)
                \(raw: cookieSource)
                    return values
                }
                """,
            )
        }
    }

    /// Generate accessor for the http cookies
    /// - parameter from: the http cookies parameters if any
    private func generateHttpCookieAccessor(from params: [ApiParameter]) -> VariableDeclSyntax {
        let parameterAccessors = params.enumerated()
            .map { generateParameterAccessor(for: $0.element, index: $0.offset) }
            .joined(separator: "\n")
        return SwiftGeneratedSyntax.parse("operation \(operation.typeName).Request httpCookies") {
            try VariableDeclSyntax(
                """
                public var httpCookies: [String: any FormEncodable] {
                    var values: [String: any FormEncodable] = [:]
                \(raw: parameterAccessors)
                    return values
                }
                """,
            )
        }
    }

    /// Generate accessor for one parameter
    /// - parameter for: the api parameter
    private func generateParameterAccessor(for param: ApiParameter, index: Int) -> String {
        var checkEmpty = false
        let rawNameLiteral = param.rawName.debugDescription
        let sourceValue = "__api\(index)\(param.propertyName.replacingOccurrences(of: "`", with: "").capitalCased)Value"
        let propertyValue = "self.\(param.propertyName)"
        let valueExpression: String
        switch param.dataType {
            case .string:
                valueExpression = sourceValue
            case .int,
                 .int16,
                 .int32,
                 .int64,
                 .uint,
                 .uint16,
                 .uint32,
                 .uint64:
                valueExpression = "String(describing: \(sourceValue))"
            case .bool:
                valueExpression = "String(describing: \(sourceValue))"
            case .intArray,
                 .int16Array,
                 .int32Array,
                 .int64Array,
                 .uintArray,
                 .uint16Array,
                 .uint32Array,
                 .uint64Array,
                 .boolArray:
                checkEmpty = true
                valueExpression = "\(sourceValue).map { String(describing: $0) }.joined(separator: \",\")"
            case .stringArray:
                checkEmpty = true
                valueExpression = "\(sourceValue).joined(separator: \",\")"
            case .stringEnumValue,
                 .intEnumValue:
                if param.location == .header {
                    valueExpression = "String(describing: \(sourceValue).rawValue)"
                } else {
                    valueExpression = "\(sourceValue).rawValue"
                }
            case .stringEnumArray,
                 .intEnumArray:
                checkEmpty = true
                valueExpression = "\(sourceValue).map { $0.rawValue.formEncodableValue() }.joined(separator: \",\")"
            case .date:
                valueExpression = "DateFormatter.isoDateFormatter.string(from: \(sourceValue))"
            case .time:
                if param.location == .header {
                    valueExpression = "String(\(sourceValue).formEncodableValue())"
                } else {
                    valueExpression = sourceValue
                }
            case .dateTime:
                valueExpression = "DateFormatter.iso8601WithoutFractionalSeconds.string(from: \(sourceValue))"
        }
        let assignation = "values[\(rawNameLiteral)] = \(valueExpression)"

        if !param.isRequired {
            let emptyCheck = checkEmpty ? ", !\(sourceValue).isEmpty" : ""
            return """
            if let \(sourceValue) = \(propertyValue)\(emptyCheck) {
                \(assignation)
            }
            """
        }

        if checkEmpty {
            return """
            let \(sourceValue) = \(propertyValue)
            if !\(sourceValue).isEmpty {
                \(assignation)
            }
            """
        }

        return """
        let \(sourceValue) = \(propertyValue)
        \(assignation)
        """
    }

    /// Generate accessor for the request path, either a dynamic, with path variables, or a static one,
    /// which is a plain hard-code
    /// - parameter path: The actual request path
    /// - parameter from: the path parameters if any
    private func generateRequestPathAccessor(path: ApiOperationPath, from parameters: [ApiParameter]) -> VariableDeclSyntax {
        var effectivePath = ""
        switch path {
            case let .relative(path):
                if path.starts(with: "/") {
                    effectivePath = path
                } else {
                    effectivePath = "/" + path
                }
            case let .absolute(path):
                effectivePath = path
            case .runtime:
                return SwiftGeneratedSyntax.parse("operation \(operation.typeName).Request runtime path") {
                    try VariableDeclSyntax("public var requestPath: URL")
                }
        }

        if parameters.isEmpty {
            return SwiftGeneratedSyntax.parse("operation \(operation.typeName).Request static path") {
                try VariableDeclSyntax("public var requestPath: String { \(raw: effectivePath.debugDescription) }")
            }
        }

        let replacementSource = parameters
            .map(Self.pathReplacementSource(for:))
            .joined(separator: "\n")
        return SwiftGeneratedSyntax.parse("operation \(operation.typeName).Request path") {
            try VariableDeclSyntax(
                """
                public var requestPath: String {
                    let pathSegmentAllowedCharacters = CharacterSet.urlPathAllowed.subtracting(CharacterSet(charactersIn: "/"))
                    var path = \(raw: effectivePath.debugDescription)
                \(raw: replacementSource)
                    return path
                }
                """,
            )
        }
    }

    private static func pathReplacementSource(for param: ApiParameter) -> String {
        let propertyValue = "self.\(param.propertyName)"
        let replacement = switch param.dataType {
            case .string,
                 .bool,
                 .int,
                 .int16,
                 .int32,
                 .int64,
                 .uint,
                 .uint16,
                 .uint32,
                 .uint64:
                "String(\(propertyValue))"
            case .stringEnumValue:
                "\(propertyValue).rawValue"
            case .intEnumValue:
                "String(\(propertyValue).rawValue)"
            case .boolArray,
                 .intArray,
                 .int16Array,
                 .int32Array,
                 .int64Array,
                 .uintArray,
                 .uint16Array,
                 .uint32Array,
                 .uint64Array:
                "\(propertyValue).map({ String($0) }).joined(separator: \",\")"
            case .stringArray:
                "\(propertyValue).joined(separator: \",\")"
            case .stringEnumArray:
                "\(propertyValue).map({ $0.rawValue }).joined(separator: \",\")"
            case .intEnumArray:
                "\(propertyValue).map({ String($0.rawValue) }).joined(separator: \",\")"
            case .dateTime:
                "\(propertyValue).formEncodableValue()"
            case .date:
                "DateFormatter.isoDateFormatter.string(from: \(propertyValue))"
            case .time:
                "String(\(propertyValue).formEncodableValue())"
        }

        return """
        path = path.replacingOccurrences(
            of: \("{\(param.rawName)}".debugDescription),
            with: \(replacement).addingPercentEncoding(withAllowedCharacters: pathSegmentAllowedCharacters) ?? \(replacement)
        )
        """
    }
}
