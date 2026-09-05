import Foundation
import GeneratorBuilder
import GeneratorModels

struct SwiftVaporOperationEmitter {
    let module: ApiModule
    let definition: ApiService
    let registry: SwiftVaporTypeRegistry
    let sourceRoot: String
    let packageImports: [ApiImport]

    private var serviceName: String {
        definition.swiftVaporServiceTypeName(moduleName: module.name)
    }

    private var controllerName: String {
        definition.swiftVaporControllerTypeName(moduleName: module.name)
    }

    func requestFiles() -> [SwiftVaporGeneratedTextFile] {
        routableOperations.map { operation in
            SwiftVaporGeneratedTextFile(
                relativePath: "\(sourceRoot)/Generated/Requests/\(operation.swiftVaporRequestTypeName(moduleName: module.name, definitionName: definition.name)).generated.swift",
                contents: requestFileContents(operation)
            )
        }
    }

    func serviceFile() -> SwiftVaporGeneratedTextFile {
        SwiftVaporGeneratedTextFile(
            relativePath: "\(sourceRoot)/Generated/Services/\(serviceName).generated.swift",
            contents: serviceFileContents()
        )
    }

    func controllerFile() -> SwiftVaporGeneratedTextFile {
        SwiftVaporGeneratedTextFile(
            relativePath: "\(sourceRoot)/Generated/Controllers/\(controllerName).generated.swift",
            contents: controllerFileContents()
        )
    }

    private func requestFileContents(_ operation: ApiOperation) -> String {
        let imports = importLines(for: [operation])
        let requestName = operation.swiftVaporRequestTypeName(moduleName: module.name, definitionName: definition.name)
        let multipartDeclaration = multipartBodyDeclaration(operation)
        let properties = requestProperties(operation)
        let propertyDeclarations = properties.map { property in
            "    public var \(property.name): \(property.type)"
        }
        .joined(separator: "\n")
        let initParameters = properties.map { property in
            "\(property.name): \(property.type)"
        }
        .joined(separator: ", ")
        let assignments = properties.map { property in
            "        self.\(property.name) = \(property.name)"
        }
        .joined(separator: "\n")

        return """
        // Generated code. Do not edit.
        \(imports)

        \(multipartDeclaration)
        public struct \(requestName)\(requestConformanceClause(operation)) {
        \(propertyDeclarations)

            public init(\(initParameters)) {
        \(assignments)
            }
        }
        """
    }

    private func serviceFileContents() -> String {
        let imports = importLines(for: routableOperations)
        let methods = routableOperations.map { operation in
            "    func \(operation.swiftVaporOperationName)(_ request: \(operation.swiftVaporRequestTypeName(moduleName: module.name, definitionName: definition.name))) async throws -> \(responseType(operation.response))"
        }
        .joined(separator: "\n")

        let notImplementedMethods = routableOperations.map { operation in
            let requestName = operation.swiftVaporRequestTypeName(moduleName: module.name, definitionName: definition.name)
            return """
            public func \(operation.swiftVaporOperationName)(_: \(requestName)) async throws -> \(responseType(operation.response)) {
                throw Abort(.notImplemented)
            }
            """
        }
        .joined(separator: "\n\n")

        return """
        // Generated code. Do not edit.
        \(imports)

        public protocol \(serviceName): Sendable {
        \(methods)
        }

        public struct NotImplemented\(serviceName): \(serviceName) {
            public init() {}

        \(notImplementedMethods)
        }
        """
    }

    private func controllerFileContents() -> String {
        let imports = importLines(for: routableOperations)
        let routeMethods = routableOperations.map(routeMethodDeclaration)
            .joined(separator: "\n\n")

        let routeRegistrations = definition.operations.compactMap(routeRegistration)
            .joined(separator: "\n")

        let skippedRoutes = definition.operations.compactMap { operation -> String? in
            skippedRouteComment(operation)
        }
        .joined(separator: "\n")

        return """
        // Generated code. Do not edit.
        \(imports)

        public struct \(controllerName): Sendable {
            private let service: any \(serviceName)
            private let security: any GeneratedSecurityMiddleware

            public init(service: any \(serviceName), security: any GeneratedSecurityMiddleware) {
                self.service = service
                self.security = security
            }

            public func register(routes: RoutesBuilder) throws {
        \(routeRegistrations)\(routeRegistrations.isEmpty || skippedRoutes.isEmpty ? "" : "\n")\(skippedRoutes)
            }

        \(routeMethods)
        }
        """
    }

    private var routableOperations: [ApiOperation] {
        definition.operations.filter(\.isSwiftVaporRoutable)
    }

    private func importLines(for operations: [ApiOperation]) -> String {
        let baseImports = [
            ApiImport(stringLiteral: "Foundation"),
            ApiImport(stringLiteral: "Vapor")
        ]
        let baseImportNames = Set(baseImports.map(\.name))
        let extraImports = Set(packageImports + operations.flatMap(\.swiftVaporImports))
            .filter { !baseImportNames.contains($0.name) }
            .sorted()
        return (baseImports + extraImports).map(\.swiftVaporImportLine).joined(separator: "\n")
    }

    private func requestConformanceClause(_ operation: ApiOperation) -> String {
        operation.request.isSwiftVaporSendable ? ": Sendable" : ""
    }

    private func routeRegistration(_ operation: ApiOperation) -> String? {
        guard let components = routePathComponents(operation.path) else {
            return nil
        }
        let pathArguments = components.isEmpty ? "" : ", \(components.joined(separator: ", "))"
        return "        routes.on(.\(operation.method.httpMethod)\(pathArguments), use: \(operation.swiftVaporOperationName))"
    }

    private func routeMethodDeclaration(_ operation: ApiOperation) -> String {
        let properties = requestProperties(operation)
        let propertyBindings = localBindings(for: properties.map(\.name))
        let paramLines = zip(operation.expandedParameters, propertyBindings.prefix(operation.expandedParameters.count))
            .map { parameterDecodeLine($0, localName: $1.localName) }
        let bodyLines = requestBodyDecodeLines(operation, localName: propertyBindings.first { $0.propertyName == "body" }?.localName ?? "body")
        let requestName = operation.swiftVaporRequestTypeName(moduleName: module.name, definitionName: definition.name)
        let serviceRequestSource = if properties.isEmpty {
            "\(requestName)()"
        } else {
            """
            \(requestName)(
            \(propertyBindings.map { binding in "            \(binding.propertyName): \(binding.localName)" }.joined(separator: ",\n"))
                    )
            """
        }
        let securityLines = securityLines(operation)
        let responseLine = responseEncodeLine(operation)

        return ([
            "    private func \(operation.swiftVaporOperationName)(req: Request) async throws -> Response {",
            "        let securityRequest = GeneratedSecurityRequest(request: req, operationID: \(operationID(operation).swiftVaporStringLiteral))",
            securityLines
        ] + paramLines + bodyLines + [
            "        let serviceRequest = \(serviceRequestSource)",
            "        let serviceResponse = try await service.\(operation.swiftVaporOperationName)(serviceRequest)",
            "        return \(responseLine)",
            "    }"
        ])
        .joined(separator: "\n")
    }

    private func parameterDecodeLine(_ parameter: ApiParameter) -> String {
        parameterDecodeLine(parameter, localName: parameter.propertyName)
    }

    private func parameterDecodeLine(_ parameter: ApiParameter, localName: String) -> String {
        let rawValue = parameterRawValueExpression(parameter)
        let parser = parserExpression(parameter: parameter, rawValue: rawValue)
        return "        let \(localName) = \(parser)"
    }

    private func requestBodyDecodeLines(_ operation: ApiOperation, localName: String = "body") -> [String] {
        switch operation.request {
            case .none:
                return []
            case let .json(type):
                guard let type else {
                    return []
                }
                return ["        let \(localName) = try req.content.decode(\(registry.swiftType(for: type)).self)"]
            case let .binary(mimeType):
                return ["        let \(localName) = try GeneratedBodyReader.data(from: req, expectedContentType: \(mimeType.swiftVaporStringLiteral))"]
            case .file:
                return ["        let \(localName) = try GeneratedBodyReader.data(from: req)"]
            case let .multiPart(parts):
                let multipartType = operation.swiftVaporMultipartTypeName(moduleName: module.name, definitionName: definition.name)
                let decodeType = "\(multipartType)Decode"
                let mapLines = parts.map { part -> String in
                    let propertyName = part.swiftPropertyName
                    return "            \(propertyName): decodedMultipart.\(propertyName).map(GeneratedMultipartPart.init(file:))"
                }
                .joined(separator: ",\n")
                return [
                    "        let decodedMultipart = try req.content.decode(\(decodeType).self)",
                    """
                            let \(localName) = \(multipartType)(
                    \(mapLines)
                            )
                    """
                ]
        }
    }

    private func multipartBodyDeclaration(_ operation: ApiOperation) -> String {
        guard case let .multiPart(parts) = operation.request else {
            return ""
        }

        let multipartType = operation.swiftVaporMultipartTypeName(moduleName: module.name, definitionName: definition.name)
        let decodeType = "\(multipartType)Decode"
        let partProperties = parts.map { part in
            "    public var \(part.swiftPropertyName): GeneratedMultipartPart?"
        }
        .joined(separator: "\n")
        let decodeProperties = parts.map { part in
            "    public var \(part.swiftPropertyName): File?"
        }
        .joined(separator: "\n")
        let initParameters = parts.map { part in
            "\(part.swiftPropertyName): GeneratedMultipartPart? = nil"
        }
        .joined(separator: ", ")
        let assignments = parts.map { part in
            "        self.\(part.swiftPropertyName) = \(part.swiftPropertyName)"
        }
        .joined(separator: "\n")
        let codingKeys = parts.map { part -> String in
            let propertyName = part.swiftPropertyName
            if propertyName == part {
                return "        case \(propertyName)"
            }
            return "        case \(propertyName) = \(part.swiftVaporStringLiteral)"
        }
        .joined(separator: "\n")

        return """
        public struct \(multipartType): Sendable {
        \(partProperties)

            public init(\(initParameters)) {
        \(assignments)
            }
        }

        struct \(decodeType): Content {
        \(decodeProperties)

            enum CodingKeys: String, CodingKey {
        \(codingKeys)
            }
        }

        """
    }

    private func requestProperties(_ operation: ApiOperation) -> [(name: String, type: String)] {
        var properties = operation.expandedParameters.map { parameter in
            let optional = parameter.isRequired || parameter.swiftVaporDefaultExpression(registry: registry) != nil ? "" : "?"
            return (name: parameter.propertyName, type: "\(parameter.dataType.swiftVaporType(registry: registry))\(optional)")
        }

        switch operation.request {
            case let .json(type):
                if let type {
                    properties.append((name: "body", type: registry.swiftType(for: type)))
                }
            case .binary,
                 .file:
                properties.append((name: "body", type: "Data"))
            case .multiPart:
                properties.append((name: "body", type: operation.swiftVaporMultipartTypeName(moduleName: module.name, definitionName: definition.name)))
            case .none:
                break
        }

        return properties
    }

    private func localBindings(for propertyNames: [String]) -> [(propertyName: String, localName: String)] {
        var usedNames: Set = [
            "decodedMultipart",
            "req",
            "securityRequest",
            "serviceRequest",
            "serviceResponse"
        ]
        return propertyNames.map { propertyName in
            let localName = uniqueLocalName(baseName: propertyName, usedNames: usedNames)
            usedNames.insert(localName)
            return (propertyName: propertyName, localName: localName)
        }
    }

    private func uniqueLocalName(baseName: String, usedNames: Set<String>) -> String {
        guard usedNames.contains(baseName) else {
            return baseName
        }

        let unescapedBaseName = baseName.swiftVaporUnescapedIdentifier
        var index = 0
        var candidate = "\(unescapedBaseName)Value".swiftPropertyName
        while usedNames.contains(candidate) {
            index += 1
            candidate = "\(unescapedBaseName)Value\(index)".swiftPropertyName
        }
        return candidate
    }

    private func parserExpression(parameter: ApiParameter, rawValue: String) -> String {
        let defaultExpression = parameter.swiftVaporDefaultExpression(registry: registry)
        let required = parameter.isRequired && defaultExpression == nil
        let parsed: String = switch parameter.dataType {
            case .string:
                required
                    ? "try GeneratedRequestValueParser.requiredString(\(rawValue), name: \(parameter.rawName.swiftVaporStringLiteral))"
                    : "GeneratedRequestValueParser.optionalString(\(rawValue))"
            case .stringArray:
                required
                    ? "try GeneratedRequestValueParser.requiredStringArray(\(rawValue), name: \(parameter.rawName.swiftVaporStringLiteral))"
                    : "GeneratedRequestValueParser.optionalStringArray(\(rawValue))"
            case .date:
                required
                    ? "try GeneratedRequestValueParser.requiredDateOnly(\(rawValue), name: \(parameter.rawName.swiftVaporStringLiteral))"
                    : "try GeneratedRequestValueParser.optionalDateOnly(\(rawValue), name: \(parameter.rawName.swiftVaporStringLiteral))"
            case .time:
                required
                    ? "try GeneratedRequestValueParser.requiredTime(\(rawValue), name: \(parameter.rawName.swiftVaporStringLiteral))"
                    : "try GeneratedRequestValueParser.optionalTime(\(rawValue), name: \(parameter.rawName.swiftVaporStringLiteral))"
            case .dateTime:
                required
                    ? "try GeneratedRequestValueParser.requiredDate(\(rawValue), name: \(parameter.rawName.swiftVaporStringLiteral))"
                    : "try GeneratedRequestValueParser.optionalDate(\(rawValue), name: \(parameter.rawName.swiftVaporStringLiteral))"
            case .stringEnumValue:
                rawEnumParser("StringRawEnum", parameter: parameter, rawValue: rawValue, required: required)
            case .stringEnumArray:
                rawEnumParser("StringRawEnumArray", parameter: parameter, rawValue: rawValue, required: required)
            case .intEnumValue:
                rawEnumParser("IntRawEnum", parameter: parameter, rawValue: rawValue, required: required)
            case .intEnumArray:
                rawEnumParser("IntRawEnumArray", parameter: parameter, rawValue: rawValue, required: required)
            default:
                if parameter.dataType.isSwiftVaporArray {
                    required
                        ?
                        "try GeneratedRequestValueParser.requiredArray(\(rawValue), name: \(parameter.rawName.swiftVaporStringLiteral), as: \(parameter.dataType.swiftVaporType(registry: registry).dropArraySyntax).self)"
                        :
                        "try GeneratedRequestValueParser.optionalArray(\(rawValue), name: \(parameter.rawName.swiftVaporStringLiteral), as: \(parameter.dataType.swiftVaporType(registry: registry).dropArraySyntax).self)"
                } else {
                    required
                        ? "try GeneratedRequestValueParser.required(\(rawValue), name: \(parameter.rawName.swiftVaporStringLiteral), as: \(parameter.dataType.swiftVaporType(registry: registry)).self)"
                        : "try GeneratedRequestValueParser.optional(\(rawValue), name: \(parameter.rawName.swiftVaporStringLiteral), as: \(parameter.dataType.swiftVaporType(registry: registry)).self)"
                }
        }

        if let defaultExpression {
            return "(\(parsed)) ?? \(defaultExpression)"
        }
        return parsed
    }

    private func rawEnumParser(_ parserName: String, parameter: ApiParameter, rawValue: String, required: Bool) -> String {
        let method = required ? "required\(parserName)" : "optional\(parserName)"
        return "try GeneratedRequestValueParser.\(method)(\(rawValue), name: \(parameter.rawName.swiftVaporStringLiteral), as: \(parameter.dataType.swiftVaporType(registry: registry).dropArraySyntax).self)"
    }

    private func parameterRawValueExpression(_ parameter: ApiParameter) -> String {
        switch parameter.location {
            case .path:
                "req.parameters.get(\(parameter.rawName.swiftVaporStringLiteral))"
            case .query:
                "req.query[String.self, at: \(parameter.rawName.swiftVaporStringLiteral)]"
            case .header:
                "req.headers.first(name: \(parameter.rawName.swiftVaporStringLiteral))"
            case .cookie:
                "req.cookies[\(parameter.rawName.swiftVaporStringLiteral)]?.string"
        }
    }

    private func securityLines(_ operation: ApiOperation) -> String {
        switch operation.security {
            case .secured:
                "        try await security.requireAuthorization(securityRequest)"
            case .optional:
                "        try await security.authorizeOptional(securityRequest)"
            case .unsecured:
                "        _ = securityRequest"
        }
    }

    private func responseEncodeLine(_ operation: ApiOperation) -> String {
        let statusCodes = "[\(validStatusCodes(operation).map(String.init).joined(separator: ", "))]"
        return switch operation.response {
            case .none:
                "try GeneratedResponseEncoder.empty(serviceResponse, validStatusCodes: \(statusCodes))"
            case .json:
                "try GeneratedResponseEncoder.json(serviceResponse, validStatusCodes: \(statusCodes))"
            case let .binary(mimeType):
                "try GeneratedResponseEncoder.binary(serviceResponse, contentType: \(mimeType.swiftVaporStringLiteral), validStatusCodes: \(statusCodes))"
        }
    }

    private func validStatusCodes(_ operation: ApiOperation) -> [Int] {
        operation.acceptableStatuses
    }

    private func responseType(_ response: ApiResponseBody) -> String {
        switch response {
            case .none:
                "GeneratedResponse<Void>"
            case .binary:
                "GeneratedResponse<Data>"
            case let .json(type):
                "GeneratedResponse<\(type.map { registry.swiftType(for: $0) } ?? "Void")>"
        }
    }

    private func routePathComponents(_ path: ApiOperationPath) -> [String]? {
        switch path {
            case let .relative(path):
                path.swiftVaporRouteComponents
            case .absolute:
                nil
            case .runtime:
                nil
        }
    }

    private func skippedRouteComment(_ operation: ApiOperation) -> String? {
        guard routePathComponents(operation.path) == nil else {
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
        return "        // Skipped \(operation.swiftVaporOperationName): \(reason)"
    }

    private func operationID(_ operation: ApiOperation) -> String {
        [module.name, definition.name, operation.name].filter { !$0.isEmpty }.joined(separator: ".")
    }
}

private extension ApiParameter {
    func swiftVaporDefaultExpression(registry: SwiftVaporTypeRegistry) -> String? {
        if isRequiredPredefinedApiKey {
            return nil
        }
        return dataType.swiftVaporDefaultExpression(registry: registry)
    }

    private var isRequiredPredefinedApiKey: Bool {
        guard isRequired,
              propertyName == "apiKey",
              rawName == "Authorization",
              location == .header,
              case let .string(defaultValue) = dataType else {
            return false
        }
        return defaultValue == ""
    }
}

private extension ApiOperation {
    var swiftVaporImports: [ApiImport] {
        let bodyImports = [request.dataType, response.dataType]
            .compactMap(\.self)
            .flatMap(\.swiftVaporImports)
        let parameterImports = expandedParameters.compactMap(\.swiftVaporDeclaredDataType)
            .flatMap(\.swiftVaporImports)
        return extraImports + bodyImports + parameterImports
    }
}

private extension ApiParameter.DataType {
    func swiftVaporDefaultExpression(registry: SwiftVaporTypeRegistry) -> String? {
        switch self {
            case let .bool(value):
                value.map(String.init)
            case let .boolArray(value):
                value.map { "[\($0.map(String.init).joined(separator: ", "))]" }
            case let .string(value):
                value?.swiftVaporStringLiteral
            case let .stringArray(value):
                value.map { "[\($0.map(\.swiftVaporStringLiteral).joined(separator: ", "))]" }
            case let .int(value):
                value.map(String.init)
            case let .int16(value):
                value.map(String.init)
            case let .int32(value):
                value.map(String.init)
            case let .int64(value):
                value.map(String.init)
            case let .uint(value):
                value.map(String.init)
            case let .uint16(value):
                value.map(String.init)
            case let .uint32(value):
                value.map(String.init)
            case let .uint64(value):
                value.map(String.init)
            case let .intArray(value):
                value.map { "[\($0.map(String.init).joined(separator: ", "))]" }
            case let .int16Array(value):
                value.map { "[\($0.map(String.init).joined(separator: ", "))]" }
            case let .int32Array(value):
                value.map { "[\($0.map(String.init).joined(separator: ", "))]" }
            case let .int64Array(value):
                value.map { "[\($0.map(String.init).joined(separator: ", "))]" }
            case let .uintArray(value):
                value.map { "[\($0.map(String.init).joined(separator: ", "))]" }
            case let .uint16Array(value):
                value.map { "[\($0.map(String.init).joined(separator: ", "))]" }
            case let .uint32Array(value):
                value.map { "[\($0.map(String.init).joined(separator: ", "))]" }
            case let .uint64Array(value):
                value.map { "[\($0.map(String.init).joined(separator: ", "))]" }
            case let .stringEnumValue(type, value):
                value.map { value in
                    type.swiftVaporStringEnumCase(for: value)
                        ?? "(try GeneratedRequestValueParser.requiredStringRawEnum(\(value.swiftVaporStringLiteral), name: \"default\", as: \(registry.swiftType(for: type)).self))"
                }
            case let .stringEnumArray(type, value):
                value.map { values in
                    let expressions = values.map { value in
                        type.swiftVaporStringEnumCase(for: value)
                            ?? "try GeneratedRequestValueParser.requiredStringRawEnum(\(value.swiftVaporStringLiteral), name: \"default\", as: \(registry.swiftType(for: type)).self)"
                    }
                    return "[\(expressions.joined(separator: ", "))]"
                }
            case let .intEnumValue(type, value):
                value.map { value in
                    type.swiftVaporIntEnumCase(for: value)
                        ?? "(try GeneratedRequestValueParser.requiredIntRawEnum(\(String(value).swiftVaporStringLiteral), name: \"default\", as: \(registry.swiftType(for: type)).self))"
                }
            case let .intEnumArray(type, value):
                value.map { values in
                    let expressions = values.map { value in
                        type.swiftVaporIntEnumCase(for: value)
                            ?? "try GeneratedRequestValueParser.requiredIntRawEnum(\(String(value).swiftVaporStringLiteral), name: \"default\", as: \(registry.swiftType(for: type)).self)"
                    }
                    return "[\(expressions.joined(separator: ", "))]"
                }
            case .date,
                 .dateTime,
                 .time:
                nil
        }
    }
}

private extension ApiTypeSchema {
    func swiftVaporStringEnumCase(for rawValue: String) -> String? {
        switch self {
            case let .reference(_, _, _, _, dataType):
                dataType?.swiftVaporStringEnumCase(for: rawValue)
            case let .stringEnum(_, values, _, _, _):
                values.first { $0.rawName == rawValue }
                    .map { ".\($0.name.swiftEnumValueDeclaration)" }
            default:
                nil
        }
    }

    func swiftVaporIntEnumCase(for rawValue: Int) -> String? {
        switch self {
            case let .reference(_, _, _, _, dataType):
                dataType?.swiftVaporIntEnumCase(for: rawValue)
            case let .intEnum(_, values, _, _):
                values.first { $0.rawValue == rawValue }
                    .map { ".\(swiftVaporIntEnumCaseName($0))" }
            default:
                nil
        }
    }
}

private func swiftVaporIntEnumCaseName(_ value: (name: String?, rawValue: Int)) -> String {
    if let name = value.name, !name.isEmpty {
        return name.swiftEnumValueDeclaration
    }

    return switch value.rawValue {
        case 0: "zero"
        case 1: "one"
        case 2: "two"
        case 3: "three"
        case 4: "four"
        case 5: "five"
        case 6: "six"
        case 7: "seven"
        case 8: "eight"
        case 9: "nine"
        default: String(value.rawValue).swiftEnumValueDeclaration
    }
}

private extension Int {
    var isHttpBodylessStatus: Bool {
        (100 ..< 200).contains(self) || self == 204 || self == 205 || self == 304
    }
}

private extension String {
    var swiftVaporRouteComponents: [String] {
        let routePath = split(whereSeparator: { $0 == "?" || $0 == "#" })
            .first
            .map(String.init) ?? ""
        return routePath
            .split(separator: "/")
            .map(String.init)
            .filter { !$0.isEmpty }
            .map { component in
                if component.hasPrefix("{"), component.hasSuffix("}") {
                    let parameterName = String(component.dropFirst().dropLast())
                    return ".parameter(\(parameterName.swiftVaporStringLiteral))"
                }
                return ".constant(\(component.swiftVaporStringLiteral))"
            }
    }

    var dropArraySyntax: String {
        if hasPrefix("["), hasSuffix("]") {
            return String(dropFirst().dropLast())
        }
        return self
    }

    var swiftVaporUnescapedIdentifier: String {
        if hasPrefix("`"), hasSuffix("`"), count > 1 {
            return String(dropFirst().dropLast())
        }
        return self
    }
}
