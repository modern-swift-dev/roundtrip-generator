import Foundation
import GeneratorBuilder
import GeneratorModels

struct KotlinOperationEmitter {
    let operation: ApiOperation
    let options: KotlinGeneratorOptions

    init(operation: ApiOperation, options: KotlinGeneratorOptions = .init()) {
        self.operation = operation
        self.options = options
    }

    func kotlinCode(packageName: String? = nil, imports: [String] = []) -> any Node {
        KotlinFileEmitter.renderNode(
            packageName: packageName,
            imports: Array(Set(imports).union(operation.kotlinOperationImports(options: options))),
            body: operationDeclaration(),
        )
    }

    func operationDeclaration() -> any Node {
        Block {
            "object \(operation.kotlinOperationTypeName) {"
            Indentation {
                requestDeclaration()
            }
            "}"
        }
    }

    func serviceMethodDeclaration(
        includeProgressDefault: Bool = true,
        includeNativeCoroutinesAnnotation: Bool = false,
    ) -> String {
        let declaration = serviceMethodSignature(includeProgressDefault: includeProgressDefault)
        guard includeNativeCoroutinesAnnotation else {
            return declaration
        }
        return "@NativeCoroutines\n\(declaration)"
    }

    func nextPageMethodDeclaration(includeNativeCoroutinesAnnotation: Bool = false) -> String {
        let declaration = nextPageMethodSignature()
        guard includeNativeCoroutinesAnnotation else {
            return declaration
        }
        return "@NativeCoroutines\n\(declaration)"
    }

    private func serviceMethodSignature(includeProgressDefault: Bool) -> String {
        let progressDefault = includeProgressDefault ? " = null" : ""
        var parameters = ["request: \(operation.kotlinOperationTypeName).Request"]
        if operation.request.requiresProgress {
            parameters.append("progress: ApiProgress?\(progressDefault)")
        }

        let declaration = "suspend fun \(operation.kotlinMethodName)(\(parameters.joined(separator: ", "))): \(serviceReturnType)"
        guard declaration.count > 112 else {
            return declaration
        }

        return Block {
            "suspend fun \(operation.kotlinMethodName)("
            Indentation {
                NodeList(parameters.map { "\($0)," as any Node })
            }
            "): \(serviceReturnType)"
        }
        .toString()
    }

    func serviceMethodImplementation() -> any Node {
        let requestArgument = operation.security == .unsecured ? "request" : "adaptedRequest"
        var callArguments = ["request = \(requestArgument)"]
        if operation.request.requiresProgress {
            callArguments.append("progress = progress")
        }
        if let responseType = operation.response.dataType {
            let typeDeclaration = responseType.kotlinTypeDeclaration(options: options)
            callArguments.append(
                "responseType = ApiResponseType<\(typeDeclaration)>(typeName = \(typeDeclaration.kotlinStringLiteral), mimeType = \(operation.response.mimeType.kotlinStringLiteral))",
            )
        }
        callArguments.append("validStatusCodes = setOf(\(validStatusCodes.map(String.init).joined(separator: ", ")))")

        let argumentNodes = callArguments.map { argument in
            "\(argument)," as any Node
        }
        let executeMethod = operation.request.isMultipart ? "postMultipart" : (operation.request.isUpload ? "upload" : "execute")

        return Block {
            "override \(serviceMethodDeclaration(includeProgressDefault: false)) {"
            Indentation {
                if operation.security != .unsecured {
                    "val adaptedRequest = \(adaptedRequestExpression)"
                }
                "return client.\(executeMethod)("
                Indentation {
                    NodeList(argumentNodes)
                }
                ")"
            }
            "}"
        }
    }

    private var serviceReturnType: String {
        guard let dataType = operation.response.dataType else {
            return "ApiResponse"
        }
        return "ApiOperationResult<\(dataType.kotlinTypeDeclaration(options: options))>"
    }

    private var validStatusCodes: [Int] {
        guard operation.response.dataType != nil else {
            return operation.acceptableStatuses
        }
        return operation.acceptableStatuses.filter { !$0.isHttpBodylessStatus }
    }

    var hasPagedResultsResponse: Bool {
        guard case let .genericReference(typeName, _) = operation.response.dataType else {
            return false
        }
        return typeName == "PagedResults"
    }

    func nextPageMethodImplementation() -> any Node {
        let responseType = operation.response.dataType.map { dataType in
            let typeDeclaration = dataType.kotlinTypeDeclaration(options: options)
            return "ApiResponseType<\(typeDeclaration)>(typeName = \(typeDeclaration.kotlinStringLiteral), mimeType = \(operation.response.mimeType.kotlinStringLiteral))"
        } ?? "ApiResponseType<Unit>(typeName = \"Unit\", mimeType = \(operation.response.mimeType.kotlinStringLiteral))"
        let requestArgument = operation.security == .unsecured ? "request" : "adaptedRequest"

        return Block {
            "override \(nextPageMethodSignature()) {"
            Indentation {
                "val next = currentPage.next ?: throw ApiError.InvalidUrl"
                if operation.security != .unsecured {
                    "val adaptedRequest = \(adaptedRequestExpression)"
                }
                "return client.execute("
                Indentation {
                    "request = NextPageRequest("
                    Indentation {
                        "requestUrl = next,"
                        "headers = \(requestArgument).toApiRequest().headers,"
                    }
                    "),"
                    "responseType = \(responseType),"
                    "validStatusCodes = setOf(\(validStatusCodes.map(String.init).joined(separator: ", "))),"
                }
                ")"
            }
            "}"
        }
    }

    private func nextPageMethodSignature() -> String {
        let responseType = operation.response.dataType?.kotlinTypeDeclaration(options: options) ?? "Unit"
        return "suspend fun getNextPage(currentPage: \(responseType), request: \(operation.kotlinOperationTypeName).Request): \(serviceReturnType)"
    }

    private var adaptedRequestExpression: String {
        switch operation.security {
            case .unsecured:
                "request"
            case .optional:
                "request.copy(apiKey = request.apiKey?.takeIf { it.isNotBlank() } ?: client.apiKey())"
            case .secured:
                "request.copy(apiKey = request.apiKey?.takeIf { it.isNotBlank() } ?: client.requireApiKey())"
        }
    }

    private func requestDeclaration() -> any Node {
        let constructor = requestConstructor()
        let members = requestMembers()
        if constructor.isEmpty {
            return Block {
                "class Request : ApiRequestConvertible {"
                Indentation {
                    members
                }
                "}"
            }
        }
        if members.isEmpty {
            return Block {
                "data class Request("
                Indentation {
                    constructor
                }
                ") : ApiRequestConvertible"
            }
        }

        return Block {
            "data class Request("
            Indentation {
                constructor
            }
            ") : ApiRequestConvertible {"
            Indentation {
                members
            }
            "}"
        }
    }

    private func requestConstructor() -> String {
        let runtimePathProperty = operation.path.isRuntime ? ["val requestUrl: String"] : []
        let parameterProperties = operation.expandedParameters.map(requestProperty)
        let bodyProperty = requestBodyProperty()
        return (runtimePathProperty + parameterProperties + bodyProperty)
            .map { "\($0)," }
            .joined(separator: "\n")
    }

    private func requestProperty(for parameter: ApiParameter) -> String {
        let isNullable = !parameter.isRequired || isGeneratedApiKeyParameter(parameter)
        let nullable = isNullable ? "?" : ""
        let defaultValue = requestDefaultValue(for: parameter)
        return "val \(parameter.propertyName.kotlinPropertyName): \(parameter.dataType.kotlinOperationTypeDeclaration(options: options))\(nullable)\(defaultValue)"
    }

    private func requestDefaultValue(for parameter: ApiParameter) -> String {
        if isGeneratedApiKeyParameter(parameter) {
            return " = null"
        }
        if !parameter.isRequired {
            return kotlinDefaultAssignment(parameter.dataType.kotlinOperationDefaultValue(options: options) ?? "null")
        }
        if let value = parameter.dataType.kotlinOperationDefaultValue(options: options) {
            return kotlinDefaultAssignment(value)
        }
        return ""
    }

    private func kotlinDefaultAssignment(_ value: String) -> String {
        if value.contains("\n") {
            return " =\n\(value.prepad(1))"
        }
        return " = \(value)"
    }

    private func requestBodyProperty() -> [String] {
        switch operation.request {
            case .none:
                []
            case .binary:
                ["val body: ByteArray"]
            case .file:
                ["val body: ApiFileContent"]
            case .multiPart:
                ["val body: MultipartBody = MultipartBody()"]
            case let .json(type):
                type.map { ["val body: \($0.kotlinTypeDeclaration(options: options))"] } ?? []
        }
    }

    private func requestMembers() -> String {
        [
            binaryRequestEqualityMembers(),
            multipartSetters(),
            apiRequestConvertible(),
            pathFunction(),
            queryParametersFunction(),
            headersFunction()
        ]
        .filter { !$0.isEmpty }
        .joined(separator: "\n\n")
    }

    private func binaryRequestEqualityMembers() -> String {
        guard operation.request.isBinary else {
            return ""
        }
        let properties = requestComparableProperties()
        return [
            requestEqualsFunction(properties: properties),
            requestHashCodeFunction(properties: properties)
        ]
        .joined(separator: "\n\n")
    }

    private func requestComparableProperties() -> [(
        name: String,
        nullable: Bool,
        isByteArray: Bool,
    )] {
        let runtimePathProperty = operation.path.isRuntime
            ? [(name: "requestUrl", nullable: false, isByteArray: false)] : []
        let parameterProperties = operation.expandedParameters.map { parameter in
            (
                name: parameter.propertyName.kotlinPropertyName,
                nullable: !parameter.isRequired || isGeneratedApiKeyParameter(parameter),
                isByteArray: false,
            )
        }
        return runtimePathProperty + parameterProperties + [(name: "body", nullable: false, isByteArray: true)]
    }

    private func requestEqualsFunction(
        properties: [(name: String, nullable: Bool, isByteArray: Bool)],
    ) -> String {
        Block {
            "override fun equals(other: Any?): Boolean {"
            Indentation {
                "if (this === other) return true"
                "if (other !is Request) return false"
                for property in properties {
                    if property.isByteArray {
                        "if (!\(property.name).contentEquals(other.\(property.name))) return false"
                    } else {
                        "if (\(property.name) != other.\(property.name)) return false"
                    }
                }
                "return true"
            }
            "}"
        }
        .toString()
    }

    private func requestHashCodeFunction(
        properties: [(name: String, nullable: Bool, isByteArray: Bool)],
    ) -> String {
        guard let firstProperty = properties.first else {
            return "override fun hashCode(): Int = 0"
        }
        let remainingProperties = properties.dropFirst()
        return Block {
            "override fun hashCode(): Int {"
            Indentation {
                "var result = \(requestHashCodeExpression(firstProperty))"
                for property in remainingProperties {
                    "result = 31 * result + \(requestHashCodeExpression(property))"
                }
                "return result"
            }
            "}"
        }
        .toString()
    }

    private func requestHashCodeExpression(
        _ property: (name: String, nullable: Bool, isByteArray: Bool),
    ) -> String {
        if property.isByteArray {
            return property.nullable
                ? "(\(property.name)?.contentHashCode() ?: 0)"
                : "\(property.name).contentHashCode()"
        }
        return property.nullable
            ? "(\(property.name)?.hashCode() ?: 0)"
            : "\(property.name).hashCode()"
    }

    private func multipartSetters() -> String {
        guard case let .multiPart(parts) = operation.request else {
            return ""
        }
        let setters = parts.map { part in
            Block {
                "fun with\(part.capitalCased)(part: MultipartBody.Part): Request ="
                Indentation {
                    "copy(body = body.copy(parts = body.parts + (\(part.kotlinStringLiteral) to part)))"
                }
            }
            .toString() as any Node
        }
        return Block {
            setters.map { $0.toString() }.joined(separator: "\n\n")
        }
        .toString()
    }

    private func apiRequestConvertible() -> String {
        let body = operation.request.hasBody ? "body" : "null"
        let bodyType = operation.request.bodyTypeExpression(options: options)
        let contentType = operation.request.hasBody ? operation.request.mimeType.map(\.kotlinStringLiteral) ?? "null" : "null"
        return Block {
            "override fun toApiRequest(): ApiRequest ="
            Indentation {
                "ApiRequest("
                Indentation {
                    "method = \(operation.method.httpMethod.kotlinStringLiteral),"
                    "path = requestPath(),"
                    "queryParameters = queryParameters(),"
                    "headers = headers(),"
                    "body = \(body),"
                    "bodyType = \(bodyType),"
                    "contentType = \(contentType),"
                    "accept = \(operation.response.mimeType.kotlinStringLiteral),"
                }
                ")"
            }
        }
        .toString()
    }

    private func pathFunction() -> String {
        switch operation.path {
            case .runtime:
                Block {
                    "private fun requestPath(): ApiRequestPath = ApiRequestPath.Runtime(requestUrl = requestUrl)"
                }
                .toString()
            case let .relative(path):
                fixedPathFunction(path: normalizedRelativePath(path), pathType: "Relative")
            case let .absolute(path):
                fixedPathFunction(path: path, pathType: "Absolute")
        }
    }

    private func fixedPathFunction(path: String, pathType: String) -> String {
        let argumentName = pathType == "Absolute" ? "url" : "path"
        let pathParameters = operation.expandedParameters.filter { $0.location == .path }
        guard !pathParameters.isEmpty else {
            return fixedPathExpression(path: path, pathType: pathType, argumentName: argumentName)
        }

        let replacements = pathParameters
            .map { parameter in
                let value = parameter.dataType.kotlinOperationPathSegmentExpression(parameter.propertyName.kotlinPropertyName)
                return ".replace(\("{\(parameter.rawName)}".kotlinStringLiteral), \(value))"
                    .prepad(1) as any Node
            }

        return Block {
            "private fun requestPath(): ApiRequestPath {"
            Indentation {
                "val path ="
                Indentation {
                    path.kotlinStringLiteral
                    NodeList(replacements)
                }
                "return ApiRequestPath.\(pathType)(\(argumentName) = path)"
            }
            "}"
        }
        .toString()
    }

    private func fixedPathExpression(path: String, pathType: String, argumentName: String) -> String {
        let expression = "ApiRequestPath.\(pathType)(\(argumentName) = \(path.kotlinStringLiteral))"
        let declaration = "private fun requestPath(): ApiRequestPath = \(expression)"
        guard declaration.count > 112 else {
            return declaration
        }

        return Block {
            "private fun requestPath(): ApiRequestPath ="
            Indentation {
                "ApiRequestPath.\(pathType)("
                Indentation {
                    "\(argumentName) = \(path.kotlinStringLiteral),"
                }
                ")"
            }
        }
        .toString()
    }

    private func queryParametersFunction() -> String {
        mapFunction(
            name: "queryParameters",
            parameters: operation.expandedParameters.filter { $0.location == .query },
        )
    }

    private func headersFunction() -> String {
        let headers = operation.expandedParameters.filter { $0.location == .header }
        let cookies = operation.expandedParameters.filter { $0.location == .cookie }
        return mapFunction(name: "headers", parameters: headers, additionalLines: cookieHeaderLines(cookies))
    }

    private func mapFunction(name: String, parameters: [ApiParameter], additionalLines: [String] = []) -> String {
        if parameters.isEmpty, additionalLines.isEmpty {
            return Block {
                "private fun \(name)(): Map<String, String> = emptyMap()"
            }
            .toString()
        }

        let lines = (parameters.map(mapAssignment) + additionalLines).map { $0 as any Node }
        return Block {
            "private fun \(name)(): Map<String, String> {"
            Indentation {
                "val values = mutableMapOf<String, String>()"
                NodeList(lines)
                "return values"
            }
            "}"
        }
        .toString()
    }

    private func mapAssignment(for parameter: ApiParameter) -> String {
        let propertyName = parameter.propertyName.kotlinPropertyName
        let value = parameter.dataType.kotlinOperationFormValueExpression(propertyName)
        let key = parameter.rawName.kotlinStringLiteral
        if isGeneratedApiKeyParameter(parameter) {
            return "\(propertyName)?.takeIf { it.isNotBlank() }?.let { values[\(key)] = \(parameter.dataType.kotlinOperationFormValueExpression("it")) }"
        }

        if parameter.isRequired {
            return "values[\(key)] = \(value)"
        }

        if parameter.dataType.isKotlinOperationCollection {
            let itemValue = parameter.dataType.kotlinOperationFormValueExpression("it")
            return Block {
                "\(propertyName)?.takeIf { it.isNotEmpty() }?.let {"
                Indentation {
                    "values[\(key)] = \(itemValue)"
                }
                "}"
            }
            .toString()
        }

        return "\(propertyName)?.let { values[\(key)] = \(parameter.dataType.kotlinOperationFormValueExpression("it")) }"
    }

    private func isGeneratedApiKeyParameter(_ parameter: ApiParameter) -> Bool {
        guard parameter.location == .header,
              parameter.rawName == "Authorization",
              parameter.propertyName == "apiKey",
              case .string = parameter.dataType else {
            return false
        }
        return true
    }

    private func cookieHeaderLines(_ cookies: [ApiParameter]) -> [String] {
        guard !cookies.isEmpty else {
            return []
        }

        let cookieMap = cookies.map(mapAssignment).joined(separator: "\n")
        return [
            Block {
                "val cookies = mutableMapOf<String, String>()"
                cookieMap.replacingOccurrences(of: "values[", with: "cookies[")
                "cookies.toCookieHeader()?.let { values[\"Cookie\"] = it }"
            }
            .toString()
        ]
    }

    private func normalizedRelativePath(_ path: String) -> String {
        path.starts(with: "/") ? path : "/\(path)"
    }
}

struct KotlinApiServiceEmitter {
    let definition: ApiService
    let moduleName: String
    let options: KotlinGeneratorOptions

    init(definition: ApiService, moduleName: String, options: KotlinGeneratorOptions = .init()) {
        self.definition = definition
        self.moduleName = moduleName
        self.options = options
    }

    func kotlinCode(packageName: String? = nil, imports: [String] = []) -> any Node {
        KotlinFileEmitter.renderNode(
            packageName: packageName,
            imports: imports,
            body: serviceDeclaration(),
        )
    }

    func serviceDeclaration() -> any Node {
        let pagedResultsOperations = definition.operations.filter {
            KotlinOperationEmitter(operation: $0, options: options).hasPagedResultsResponse
        }
        let nextPageRequest = pagedResultsOperations.isEmpty ? "" : nextPageRequestDeclaration()
        return Block {
            "interface \(definition.kotlinApiTypeName(moduleName: moduleName)) {"
            Indentation {
                (
                    definition.operations.map {
                        KotlinOperationEmitter(operation: $0, options: options).serviceMethodDeclaration(includeNativeCoroutinesAnnotation: true) as any Node
                    }
                        + pagedResultsOperations.map {
                            KotlinOperationEmitter(operation: $0, options: options).nextPageMethodDeclaration(includeNativeCoroutinesAnnotation: true) as any Node
                        },
                )
                .map { $0.toString() }
                .joined(separator: "\n\n")
            }
            "}"
            NewLine()
            nextPageRequest
            if !nextPageRequest.isEmpty {
                NewLine()
            }
            "class \(definition.kotlinApiServiceTypeName(moduleName: moduleName))("
            Indentation {
                "private val client: RestClient,"
            }
            ") : \(definition.kotlinApiTypeName(moduleName: moduleName)) {"
            Indentation {
                (
                    definition.operations.map {
                        KotlinOperationEmitter(operation: $0, options: options).serviceMethodImplementation() as any Node
                    }
                        + pagedResultsOperations.map {
                            KotlinOperationEmitter(operation: $0, options: options).nextPageMethodImplementation()
                        },
                )
                .map { $0.toString() }
                .joined(separator: "\n\n")
            }
            "}"
        }
    }

    private func nextPageRequestDeclaration() -> String {
        Block {
            "private data class NextPageRequest("
            Indentation {
                "val requestUrl: String,"
                "val headers: Map<String, String>,"
            }
            ") : ApiRequestConvertible {"
            Indentation {
                "override fun toApiRequest(): ApiRequest ="
                Indentation {
                    "ApiRequest("
                    Indentation {
                        "method = \"GET\","
                        "path = ApiRequestPath.Runtime(requestUrl = requestUrl),"
                        "headers = headers,"
                        "accept = \"application/json\","
                    }
                    ")"
                }
            }
            "}"
        }
        .toString()
    }
}

struct KotlinApiAggregateServiceEmitter {
    let modules: [ApiModule]

    func kotlinCode(packageName: String? = nil, imports: [String] = []) -> any Node {
        KotlinFileEmitter.renderNode(
            packageName: packageName,
            imports: imports,
            body: aggregateDeclaration(),
        )
    }

    func aggregateDeclaration() -> any Node {
        let moduleDeclarations = modules
            .filter { !$0.definitions.isEmpty }
            .map(moduleDeclaration)

        let apiModulesConstructor = modules
            .filter { !$0.definitions.isEmpty }
            .map { "val \($0.kotlinModulePropertyName): \($0.kotlinApiModuleTypeName)," }
            .joined(separator: "\n")

        return Block {
            moduleDeclarations.map { $0.toString() }.joined(separator: "\n\n")
            NewLine()
            "data class ApiModules("
            Indentation {
                apiModulesConstructor
                "val errors: SharedFlow<ApiError> = MutableSharedFlow(),"
            }
            ") {"
            Indentation {
                "constructor(client: RestClient) : this("
                Indentation {
                    modules
                        .filter { !$0.definitions.isEmpty }
                        .map { "\($0.kotlinModulePropertyName) = \($0.kotlinApiModuleTypeName)(client = client)," }
                        .joined(separator: "\n")
                    "errors = client.errors,"
                }
                ")"
            }
            "}"
        }
    }

    private func moduleDeclaration(_ module: ApiModule) -> any Node {
        let properties = module.definitions
            .map { "val \($0.kotlinApiPropertyName): \($0.kotlinApiTypeName(moduleName: module.name))," }
            .joined(separator: "\n")
        let serviceArguments = module.definitions
            .map {
                "\($0.kotlinApiPropertyName) = \($0.kotlinApiServiceTypeName(moduleName: module.name))(client = client),"
            }
            .joined(separator: "\n")

        return Block {
            "data class \(module.kotlinApiModuleTypeName)("
            Indentation {
                properties
            }
            ") {"
            Indentation {
                "constructor(client: RestClient) : this("
                Indentation {
                    serviceArguments
                }
                ")"
            }
            "}"
        }
    }
}

enum KotlinFileEmitter {
    static func render(packageName: String?, imports: [String], body: any Node) -> String {
        renderNode(packageName: packageName, imports: imports, body: body).toString()
    }

    static func renderNode(packageName: String?, imports: [String], body: any Node) -> any Node {
        var nodes: [any Node] = []
        nodes.append(KotlinGeneratedTextFile.managedHeader)
        if let packageName {
            nodes.append("package \(packageName)")
            nodes.append(NewLine())
        }
        if !imports.isEmpty {
            nodes.append(contentsOf: sortedImports(imports).map { "import \($0)" as any Node })
            nodes.append(NewLine())
        }
        nodes.append(body)
        return Block {
            NodeList(nodes)
        }
    }

    private static func sortedImports(_ imports: [String]) -> [String] {
        imports.sorted { lhs, rhs in
            let lhsGroup = importGroup(lhs)
            let rhsGroup = importGroup(rhs)
            if lhsGroup != rhsGroup {
                return lhsGroup < rhsGroup
            }
            return lhs < rhs
        }
    }

    private static func importGroup(_ importPath: String) -> Int {
        if importPath.contains(" as ") {
            return 4
        }
        if importPath.hasPrefix("java.") {
            return 1
        }
        if importPath.hasPrefix("javax.") {
            return 2
        }
        if importPath.hasPrefix("kotlin.") {
            return 3
        }
        return 0
    }
}

private extension ApiRequestBody {
    var hasBody: Bool {
        switch self {
            case .none:
                false
            case let .json(type):
                type != nil
            default:
                true
        }
    }

    var isMultipart: Bool {
        switch self {
            case .multiPart:
                true
            default:
                false
        }
    }

    var isFile: Bool {
        switch self {
            case .file:
                true
            default:
                false
        }
    }

    var isBinary: Bool {
        switch self {
            case .binary:
                true
            default:
                false
        }
    }

    var isUpload: Bool {
        isFile
    }

    var requiresProgress: Bool {
        isMultipart || isUpload
    }

    func bodyTypeExpression(options: KotlinGeneratorOptions) -> String {
        switch self {
            case let .json(type?):
                "typeInfo<\(type.kotlinTypeDeclaration(options: options))>()"
            case .none,
                 .binary,
                 .file,
                 .multiPart,
                 .json(nil):
                "null"
        }
    }
}

private extension Int {
    var isHttpBodylessStatus: Bool {
        (100 ..< 200).contains(self) || self == 204 || self == 205 || self == 304
    }
}

private extension ApiOperation {
    func kotlinOperationImports(options: KotlinGeneratorOptions) -> Set<String> {
        let parameterImports = expandedParameters
            .map { $0.dataType.kotlinOperationImports(options: options) }
            .reduce(Set<String>()) { $0.union($1) }
        let requestImports = request.dataType?.kotlinTypeImports(options: options) ?? []
        let responseImports = response.dataType?.kotlinTypeImports(options: options) ?? []
        return parameterImports
            .union(requestImports)
            .union(responseImports)
    }
}
