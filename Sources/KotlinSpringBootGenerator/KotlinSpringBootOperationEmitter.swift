import Foundation
import GeneratorBuilder
import GeneratorModels

struct KotlinSpringBootOperationEmitter {
    let module: ApiModule
    let definition: ApiService
    let options: KotlinSpringBootGeneratorOptions
    let packageName: String
    let importsProvider: (ApiTypeSchema?, String) -> Set<String>
    let parameterImportsProvider: (ApiParameter.DataType, String) -> Set<String>

    private var serviceName: String {
        definition.kotlinSpringBootServiceTypeName(moduleName: module.name)
    }

    private var controllerName: String {
        definition.kotlinSpringBootControllerTypeName(moduleName: module.name)
    }

    private var routableOperations: [ApiOperation] {
        definition.operations.filter { routePath($0.path) != nil }
    }

    func requestFiles() -> [KotlinSpringBootGeneratedTextFile] {
        routableOperations.map { operation in
            KotlinSpringBootGeneratedTextFile(
                relativePath:
                "src/main/kotlin/\(packageName.kotlinSpringBootPackagePath)/\(operation.kotlinSpringBootRequestTypeName(moduleName: module.name, definitionName: definition.name)).kt",
                contents: requestFileContents(operation)
            )
        }
    }

    func serviceFile() -> KotlinSpringBootGeneratedTextFile {
        KotlinSpringBootGeneratedTextFile(
            relativePath: "src/main/kotlin/\(packageName.kotlinSpringBootPackagePath)/\(serviceName).kt",
            contents: serviceFileContents()
        )
    }

    func controllerFile() -> KotlinSpringBootGeneratedTextFile {
        KotlinSpringBootGeneratedTextFile(
            relativePath:
            "src/main/kotlin/\(packageName.kotlinSpringBootPackagePath)/\(controllerName).kt",
            contents: controllerFileContents()
        )
    }

    private func requestFileContents(_ operation: ApiOperation) -> String {
        let requestName = operation.kotlinSpringBootRequestTypeName(
            moduleName: module.name, definitionName: definition.name
        )
        let properties = requestProperties(operation)
        let imports = requestImports(operation, properties: properties)
        let declaration = KotlinSpringBootDataClass(
            name: requestName,
            properties: properties.map(\.property),
            isDataClass: !properties.isEmpty,
            includeGeneratedComment: false
        )
        .toString()

        return KotlinSpringBootFileEmitter.render(
            packageName: packageName, imports: imports, body: declaration
        )
    }

    private func serviceFileContents() -> String {
        let methods = routableOperations.map { operation in
            let requestName = operation.kotlinSpringBootRequestTypeName(
                moduleName: module.name, definitionName: definition.name
            )
            return
                "    suspend fun \(operation.kotlinSpringBootMethodName)(request: \(requestName)): \(responseType(operation.response))"
        }
        .joined(separator: "\n\n")

        let notImplementedMethods = routableOperations.map { operation in
            let requestName = operation.kotlinSpringBootRequestTypeName(
                moduleName: module.name, definitionName: definition.name
            )
            return """
                override suspend fun \(operation.kotlinSpringBootMethodName)(request: \(requestName)): \(responseType(operation.response)) =
                    throw ResponseStatusException(HttpStatus.NOT_IMPLEMENTED)
            """
        }
        .joined(separator: "\n\n")

        let imports = serviceImports()
        let body = """
        interface \(serviceName) {
        \(methods)
        }

        @ConditionalOnMissingBean(\(serviceName)::class)
        @Service
        class NotImplemented\(serviceName) : \(serviceName) {
        \(notImplementedMethods)
        }
        """
        return KotlinSpringBootFileEmitter.render(
            packageName: packageName, imports: imports, body: body
        )
    }

    private func controllerFileContents() -> String {
        let imports = controllerImports()
        let skippedRoutes = definition.operations.compactMap(skippedRouteComment).joined(separator: "\n")
        let declarations = [
            parseBadRequestHelperDeclaration(),
            routableOperations.map(routeMethodDeclaration).joined(separator: "\n\n"),
            skippedRoutes
        ]
        .filter { !$0.isEmpty }
        .joined(separator: "\n\n")
        let body = """
        @RestController
        class \(controllerName)(
            private val service: \(serviceName),
            private val security: GeneratedSecurityMiddleware,
        ) {
        \(declarations)
        }
        """
        return KotlinSpringBootFileEmitter.render(
            packageName: packageName, imports: imports, body: body
        )
    }

    private func routeMethodDeclaration(_ operation: ApiOperation) -> String {
        guard let path = routePath(operation.path) else {
            return skippedRouteComment(operation) ?? ""
        }

        let annotation = routeAnnotation(operation: operation, path: path)
        let parameters = controllerParameters(operation)
        let parameterDeclaration = controllerParameterDeclaration(parameters)
        let serviceRequest = serviceRequestDeclaration(operation)
        let securityLine = securityLine(operation)
        let responseLine = responseEncodeLine(operation)

        return Block {
            annotation.prepad(1)
            "    suspend fun \(operation.kotlinSpringBootMethodName)\(parameterDeclaration): \(controllerReturnType(operation.response)) {"
            securityLine
            serviceRequest
            "        val serviceResponse = service.\(operation.kotlinSpringBootMethodName)(serviceRequest)"
            "        return \(responseLine)"
            "    }"
        }
        .toString()
    }

    private func skippedRouteComment(_ operation: ApiOperation) -> String? {
        guard routePath(operation.path) == nil else {
            return nil
        }
        let reason = switch operation.path {
            case .absolute:
                "absolute paths cannot be registered by a backend."
            case .runtime:
                "runtime paths cannot be registered by a backend."
            case .relative:
                "invalid paths cannot be registered by a backend."
        }
        return "    // Skipped \(operation.kotlinSpringBootMethodName): \(reason)"
    }

    private func controllerParameterDeclaration(_ parameters: [String]) -> String {
        if parameters.count == 1,
           let parameter = parameters.first,
           !parameter.contains("@") {
            return "(\(parameter))"
        }
        let renderedParameters = parameters
            .map { $0.kotlinSpringBootAppendingCommaToLastLine().prepad(2) }
            .joined(separator: "\n")
        return """
        (
        \(renderedParameters)
            )
        """
    }

    private func routeAnnotation(operation: ApiOperation, path: String) -> String {
        let annotationName =
            switch operation.method {
                case .get:
                    "GetMapping"
                case .post:
                    "PostMapping"
                case .put:
                    "PutMapping"
                case .patch:
                    "PatchMapping"
                case .delete:
                    "DeleteMapping"
            }
        var arguments = [path.kotlinSpringBootStringLiteral]
        if let consumes = consumesValue(operation.request) {
            arguments.append("consumes = [\(consumes)]")
        }
        if let produces = producesValue(operation.response) {
            arguments.append("produces = [\(produces)]")
        }
        let singleLine = "@\(annotationName)(\(arguments.joined(separator: ", ")))"
        guard singleLine.count > 140 else {
            return singleLine
        }
        return Block {
            "@\(annotationName)("
            Indentation {
                NodeList(arguments.map { "\($0)," as any Node })
            }
            ")"
        }
        .toString()
    }

    private func controllerParameters(_ operation: ApiOperation) -> [String] {
        var parameters = ["servletRequest: HttpServletRequest"]
        parameters.append(contentsOf: operation.expandedParameters.map(controllerParameter))
        switch operation.request {
            case let .json(type):
                if let type {
                    parameters.append(
                        "@RequestBody body: \(type.kotlinSpringBootTypeName(options: options).declaration)"
                    )
                }
            case .binary,
                 .file:
                parameters.append("@RequestBody body: ByteArray")
            case let .multiPart(parts):
                parameters.append(
                    contentsOf: parts.map { part in
                        "@RequestPart(\(part.kotlinSpringBootStringLiteral), required = false) \(part.kotlinSpringBootPropertyName): Part?"
                    }
                )
            case .none:
                break
        }
        return parameters
    }

    private func controllerParameter(_ parameter: ApiParameter) -> String {
        let propertyName = parameter.propertyName.kotlinSpringBootPropertyName
        let typeName = parameter.dataType.kotlinSpringBootBindingTypeName(options: options)
        let defaultValue = parameterBindingDefaultValue(parameter)
        let nullable = parameter.isRequired || defaultValue != nil ? "" : "?"
        let typeDeclaration = "\(typeName.declaration)\(nullable)"
        let required = parameter.isRequired && defaultValue == nil ? "" : ", required = false"
        let defaultDeclaration =
            defaultValue.map { " = \($0)" } ?? (!parameter.isRequired ? " = null" : "")

        switch parameter.location {
            case .path:
                return
                    "@PathVariable(\(parameter.rawName.kotlinSpringBootStringLiteral)) \(propertyName): \(typeDeclaration)\(defaultDeclaration)"
            case .query:
                return
                    "@RequestParam(\(parameter.rawName.kotlinSpringBootStringLiteral)\(required)) \(propertyName): \(typeDeclaration)\(defaultDeclaration)"
            case .header:
                return
                    "@RequestHeader(\(parameter.rawName.kotlinSpringBootStringLiteral)\(required)) \(propertyName): \(typeDeclaration)\(defaultDeclaration)"
            case .cookie:
                return
                    "@CookieValue(\(parameter.rawName.kotlinSpringBootStringLiteral)\(required)) \(propertyName): \(typeDeclaration)\(defaultDeclaration)"
        }
    }

    private func requestProperties(_ operation: ApiOperation) -> [(
        property: KotlinSpringBootProperty, dataType: ApiTypeSchema?,
        parameterType: ApiParameter.DataType?
    )] {
        var properties:
            [(
                property: KotlinSpringBootProperty, dataType: ApiTypeSchema?,
                parameterType: ApiParameter.DataType?
            )] = operation.expandedParameters.map { parameter in
                let typeName = parameter.dataType.kotlinSpringBootTypeName(options: options)
                let defaultValue = parameterDefaultValue(parameter)
                return (
                    property: KotlinSpringBootProperty(
                        name: parameter.propertyName.kotlinSpringBootPropertyName,
                        typeName: typeName,
                        nullable: !parameter.isRequired && defaultValue == nil,
                        defaultValue: defaultValue,
                        annotations: []
                    ),
                    dataType: nil as ApiTypeSchema?,
                    parameterType: parameter.dataType
                )
            }

        switch operation.request {
            case let .json(type):
                if let type {
                    properties.append(
                        (
                            property: KotlinSpringBootProperty(
                                name: "body",
                                typeName: type.kotlinSpringBootTypeName(options: options),
                                nullable: false,
                                defaultValue: nil,
                                annotations: []
                            ),
                            dataType: type,
                            parameterType: nil
                        )
                    )
                }
            case .binary,
                 .file:
                properties.append(
                    (
                        property: KotlinSpringBootProperty(
                            name: "body", typeName: .init("ByteArray"), nullable: false, defaultValue: nil,
                            annotations: []
                        ),
                        dataType: nil,
                        parameterType: nil
                    )
                )
            case .multiPart:
                properties.append(
                    (
                        property: KotlinSpringBootProperty(
                            name: "body",
                            typeName: .init(
                                "Map<String, GeneratedMultipartPart?>",
                                imports: runtimeImports(["GeneratedMultipartPart"])
                            ),
                            nullable: false,
                            defaultValue: nil,
                            annotations: []
                        ),
                        dataType: nil,
                        parameterType: nil
                    )
                )
            case .none:
                break
        }
        return properties
    }

    private func parameterDefaultValue(_ parameter: ApiParameter) -> String? {
        if parameter.isGeneratedRequiredAuthorizationHeader {
            return nil
        }
        return parameter.dataType.kotlinSpringBootDefaultValue(options: options)
    }

    private func parameterBindingDefaultValue(_ parameter: ApiParameter) -> String? {
        if parameter.isGeneratedRequiredAuthorizationHeader {
            return nil
        }
        return parameter.dataType.kotlinSpringBootBindingDefaultValue(options: options)
    }

    private func serviceRequestDeclaration(_ operation: ApiOperation) -> String {
        let expression = serviceRequestExpression(operation)
        if expression.contains("\n") {
            return """
                    val serviceRequest =
            \(expression.prepad(3))
            """
        }
        return "        val serviceRequest = \(expression)"
    }

    private func serviceRequestExpression(_ operation: ApiOperation) -> String {
        let requestName = operation.kotlinSpringBootRequestTypeName(
            moduleName: module.name, definitionName: definition.name
        )
        let arguments = requestProperties(operation).map { item in
            "\(item.property.name) = \(serviceRequestValueExpression(item: item, operation: operation))"
        }
        guard !arguments.isEmpty else {
            return "\(requestName)()"
        }
        return Block {
            "\(requestName)("
            Indentation {
                NodeList(arguments.map { "\($0)," as any Node })
            }
            ")"
        }
        .toString()
    }

    private func serviceRequestValueExpression(
        item: (
            property: KotlinSpringBootProperty, dataType: ApiTypeSchema?,
            parameterType: ApiParameter.DataType?
        ),
        operation: ApiOperation
    ) -> String {
        let propertyName = item.property.name
        guard propertyName == "body",
              case let .multiPart(parts) = operation.request else {
            return item.parameterType.map {
                serviceRequestParameterValueExpression(
                    propertyName: propertyName, dataType: $0, nullable: item.property.nullable
                )
            } ?? propertyName
        }
        let entries = parts.map { part in
            "\(part.kotlinSpringBootStringLiteral) to \(part.kotlinSpringBootPropertyName)?.let(GeneratedMultipartPart::from)"
        }
        return "mapOf(\(entries.joined(separator: ", ")))"
    }

    private func serviceRequestParameterValueExpression(
        propertyName: String,
        dataType: ApiParameter.DataType,
        nullable: Bool
    ) -> String {
        switch dataType {
            case let .stringEnumValue(type, _):
                let typeDeclaration = type.kotlinSpringBootTypeName(options: options).declaration
                return nullable
                    ? "\(propertyName)?.let { \(parseBadRequestExpression("\(typeDeclaration).fromValue(it)")) }"
                    : parseBadRequestExpression("\(typeDeclaration).fromValue(\(propertyName))")
            case let .intEnumValue(type, _):
                let typeDeclaration = type.kotlinSpringBootTypeName(options: options).declaration
                return nullable
                    ? "\(propertyName)?.let { \(parseBadRequestExpression("\(typeDeclaration).fromValue(it)")) }"
                    : parseBadRequestExpression("\(typeDeclaration).fromValue(\(propertyName))")
            case let .stringEnumArray(type, _):
                let typeDeclaration = type.kotlinSpringBootTypeName(options: options).declaration
                return nullable
                    ? "\(propertyName)?.map { \(parseBadRequestExpression("\(typeDeclaration).fromValue(it)")) }"
                    : "\(propertyName).map { \(parseBadRequestExpression("\(typeDeclaration).fromValue(it)")) }"
            case let .intEnumArray(type, _):
                let typeDeclaration = type.kotlinSpringBootTypeName(options: options).declaration
                return nullable
                    ? "\(propertyName)?.map { \(parseBadRequestExpression("\(typeDeclaration).fromValue(it)")) }"
                    : "\(propertyName).map { \(parseBadRequestExpression("\(typeDeclaration).fromValue(it)")) }"
            case .dateTime:
                return nullable
                    ? "\(propertyName)?.let { \(parseBadRequestExpression("Instant.parse(it)")) }"
                    : parseBadRequestExpression("Instant.parse(\(propertyName))")
            case .date:
                return nullable
                    ? "\(propertyName)?.let { \(parseBadRequestExpression("LocalDate.parse(it)")) }"
                    : parseBadRequestExpression("LocalDate.parse(\(propertyName))")
            case .time:
                return nullable
                    ? "\(propertyName)?.let { \(parseBadRequestExpression("LocalTime.parse(it)")) }"
                    : parseBadRequestExpression("LocalTime.parse(\(propertyName))")
            default:
                return propertyName
        }
    }

    private func parseBadRequestExpression(_ expression: String) -> String {
        "this.badRequestOnParse { \(expression) }"
    }

    private func parseBadRequestHelperDeclaration() -> String {
        guard needsParseBadRequestHelper else {
            return ""
        }
        return """
            private fun <T> badRequestOnParse(block: () -> T): T =
                try {
                    block()
                } catch (exception: Exception) {
                    throw ResponseStatusException(HttpStatus.BAD_REQUEST, exception.message, exception)
                }
        """
    }

    private var needsParseBadRequestHelper: Bool {
        routableOperations.contains { operation in
            operation.expandedParameters.contains { parameter in
                parameter.dataType.needsSpringBootParseBadRequestHelper
            }
        }
    }

    private func securityLine(_ operation: ApiOperation) -> String {
        switch operation.security {
            case .secured:
                """
                        val securityRequest = GeneratedSecurityRequest(servletRequest, \(operationID(operation).kotlinSpringBootStringLiteral))
                        security.requireAuthorization(securityRequest)
                """
            case .optional:
                """
                        val securityRequest = GeneratedSecurityRequest(servletRequest, \(operationID(operation).kotlinSpringBootStringLiteral))
                        security.authorizeOptional(securityRequest)
                """
            case .unsecured:
                ""
        }
    }

    private func responseEncodeLine(_ operation: ApiOperation) -> String {
        let validStatusCodes = "setOf(\(validStatusCodes(operation).map(String.init).joined(separator: ", ")))"
        return switch operation.response {
            case .none:
                "GeneratedResponseEntityEncoder.empty(serviceResponse, validStatusCodes = \(validStatusCodes))"
            case let .binary(mimeType):
                "GeneratedResponseEntityEncoder.binary(serviceResponse, MediaType.parseMediaType(\(mimeType.kotlinSpringBootStringLiteral)), validStatusCodes = \(validStatusCodes))"
            case .json:
                "GeneratedResponseEntityEncoder.json(serviceResponse, validStatusCodes = \(validStatusCodes))"
        }
    }

    private func validStatusCodes(_ operation: ApiOperation) -> [Int] {
        operation.acceptableStatuses
    }

    private func responseType(_ response: ApiResponseBody) -> String {
        switch response {
            case .none:
                "GeneratedResponse<Unit>"
            case .binary:
                "GeneratedResponse<ByteArray>"
            case let .json(type):
                "GeneratedResponse<\(type.map { $0.kotlinSpringBootTypeName(options: options).declaration } ?? "Unit")>"
        }
    }

    private func controllerReturnType(_ response: ApiResponseBody) -> String {
        switch response {
            case .none:
                "ResponseEntity<Unit>"
            case .binary:
                "ResponseEntity<ByteArray>"
            case let .json(type):
                "ResponseEntity<\(type.map { $0.kotlinSpringBootTypeName(options: options).declaration } ?? "Unit")>"
        }
    }

    private func consumesValue(_ request: ApiRequestBody) -> String? {
        switch request {
            case let .json(type):
                guard type != nil else {
                    return nil
                }
                return "MediaType.APPLICATION_JSON_VALUE"
            case let .binary(mimeType):
                return mediaTypeConstant(mimeType)
            case .file:
                return "MediaType.APPLICATION_OCTET_STREAM_VALUE"
            case .multiPart:
                return "MediaType.MULTIPART_FORM_DATA_VALUE"
            case .none:
                return nil
        }
    }

    private func producesValue(_ response: ApiResponseBody) -> String? {
        switch response {
            case .none:
                nil
            case .json:
                "MediaType.APPLICATION_JSON_VALUE"
            case let .binary(mimeType):
                mediaTypeConstant(mimeType)
        }
    }

    private func mediaTypeConstant(_ mimeType: String) -> String {
        switch mimeType {
            case "application/octet-stream":
                "MediaType.APPLICATION_OCTET_STREAM_VALUE"
            case "application/json":
                "MediaType.APPLICATION_JSON_VALUE"
            case "text/plain":
                "MediaType.TEXT_PLAIN_VALUE"
            default:
                mimeType.kotlinSpringBootStringLiteral
        }
    }

    private func routePath(_ path: ApiOperationPath) -> String? {
        switch path {
            case let .relative(path):
                normalizedRelativePath(path)
            case .absolute,
                 .runtime:
                nil
        }
    }

    private func normalizedRelativePath(_ path: String) -> String {
        let routePath = path.split(whereSeparator: { $0 == "?" || $0 == "#" })
            .first
            .map(String.init) ?? ""
        return routePath.starts(with: "/") ? routePath : "/\(routePath)"
    }

    private func operationID(_ operation: ApiOperation) -> String {
        [module.name, definition.name, operation.name].filter { !$0.isEmpty }.joined(separator: ".")
    }

    private func requestImports(
        _ operation: ApiOperation,
        properties: [(
            property: KotlinSpringBootProperty, dataType: ApiTypeSchema?,
            parameterType: ApiParameter.DataType?
        )]
    ) -> [String] {
        var imports: Set<String> = []
        for item in properties {
            imports.formUnion(item.property.imports)
            imports.formUnion(importsProvider(item.dataType, packageName))
            if let parameterType = item.parameterType {
                imports.formUnion(parameterImportsProvider(parameterType, packageName))
                imports.formUnion(parameterType.kotlinSpringBootTypeName(options: options).imports)
            }
        }
        return Array(imports)
    }

    private func serviceImports() -> [String] {
        var imports: Set<String> = runtimeImports(["GeneratedResponse"])
        imports.formUnion([
            "org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean",
            "org.springframework.http.HttpStatus",
            "org.springframework.stereotype.Service",
            "org.springframework.web.server.ResponseStatusException"
        ])
        for operation in routableOperations {
            imports.formUnion(importsProvider(operation.response.dataType, packageName))
            imports.formUnion(
                operation.response.dataType?.kotlinSpringBootTypeName(options: options).imports ?? []
            )
        }
        return Array(imports)
    }

    private func controllerImports() -> [String] {
        var imports: Set<String> = runtimeImports([
            "GeneratedResponseEntityEncoder",
            "GeneratedSecurityMiddleware",
            "GeneratedSecurityRequest"
        ])
        imports.formUnion([
            "jakarta.servlet.http.HttpServletRequest",
            "org.springframework.http.MediaType",
            "org.springframework.http.ResponseEntity",
            "org.springframework.web.bind.annotation.CookieValue",
            "org.springframework.web.bind.annotation.DeleteMapping",
            "org.springframework.web.bind.annotation.GetMapping",
            "org.springframework.web.bind.annotation.PatchMapping",
            "org.springframework.web.bind.annotation.PathVariable",
            "org.springframework.web.bind.annotation.PostMapping",
            "org.springframework.web.bind.annotation.PutMapping",
            "org.springframework.web.bind.annotation.RequestBody",
            "org.springframework.web.bind.annotation.RequestHeader",
            "org.springframework.web.bind.annotation.RequestParam",
            "org.springframework.web.bind.annotation.RequestPart",
            "org.springframework.web.bind.annotation.RestController"
        ])
        if needsParseBadRequestHelper {
            imports.formUnion([
                "org.springframework.http.HttpStatus",
                "org.springframework.web.server.ResponseStatusException"
            ])
        }
        if routableOperations.contains(where: \.request.isSpringBootMultipart) {
            imports.formUnion(runtimeImports(["GeneratedMultipartPart"]))
            imports.insert("jakarta.servlet.http.Part")
        }
        for operation in routableOperations {
            imports.formUnion(importsProvider(operation.request.dataType, packageName))
            imports.formUnion(importsProvider(operation.response.dataType, packageName))
            imports.formUnion(
                operation.request.dataType?.kotlinSpringBootTypeName(options: options).imports ?? []
            )
            imports.formUnion(
                operation.response.dataType?.kotlinSpringBootTypeName(options: options).imports ?? []
            )
            for parameter in operation.expandedParameters {
                imports.formUnion(parameterImportsProvider(parameter.dataType, packageName))
                imports.formUnion(
                    parameter.dataType.kotlinSpringBootBindingTypeName(options: options).imports
                )
                imports.formUnion(parameter.dataType.kotlinSpringBootTypeName(options: options).imports)
            }
        }
        return Array(imports)
    }

    private func runtimeImports(_ names: [String]) -> Set<String> {
        guard packageName != options.basePackage else {
            return []
        }
        return Set(names.map { "\(options.basePackage).\($0)" })
    }
}

private extension ApiRequestBody {
    var isSpringBootMultipart: Bool {
        switch self {
            case .multiPart:
                true
            default:
                false
        }
    }
}

private extension Int {
    var isHttpBodylessStatus: Bool {
        (100 ..< 200).contains(self) || self == 204 || self == 205 || self == 304
    }
}

private extension ApiParameter {
    var isGeneratedRequiredAuthorizationHeader: Bool {
        guard propertyName == "apiKey",
              location == .header,
              rawName.caseInsensitiveCompare("Authorization") == .orderedSame,
              isRequired else {
            return false
        }
        if case .string("") = dataType {
            return true
        }
        return false
    }
}

private extension ApiParameter.DataType {
    var needsSpringBootParseBadRequestHelper: Bool {
        switch self {
            case .stringEnumValue,
                 .stringEnumArray,
                 .intEnumValue,
                 .intEnumArray,
                 .dateTime,
                 .date,
                 .time:
                true
            default:
                false
        }
    }
}

private extension String {
    func kotlinSpringBootAppendingCommaToLastLine() -> String {
        var lines = components(separatedBy: "\n")
        guard let last = lines.indices.last else {
            return self
        }
        lines[last] += ","
        return lines.joined(separator: "\n")
    }
}
