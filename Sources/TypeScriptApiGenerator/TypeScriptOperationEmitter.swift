import Foundation
import GeneratorBuilder
import GeneratorModels

struct TypeScriptOperationFileEmitter {
    let package: ApiPackage
    let options: TypeScriptGeneratorOptions

    func source() -> String {
        let definitions = package.modules.flatMap { module in
            module.definitions.map { definition in (module, definition) }
        }
        let requests = definitions
            .flatMap { module, definition in
                definition.operations.map { TypeScriptOperationEmitter(module: module, definition: definition, operation: $0, options: options).requestDeclaration() }
            }
            .joined(separator: "\n\n")
        let builders = definitions
            .flatMap { module, definition in
                definition.operations.map { TypeScriptOperationEmitter(module: module, definition: definition, operation: $0, options: options).requestBuilder() }
            }
            .joined(separator: "\n\n")
        let services = definitions.map { module, definition in
            TypeScriptApiServiceEmitter(module: module, definition: definition, options: options).source()
        }
        .joined(separator: "\n\n")
        let modules = package.generateApiModules ? apiModulesSource() : ""

        return """
        // Generated code. Do not edit.

        import {
            ApiClient,
            ApiOperationResult,
            ApiRequest,
            ApiResponse,
            DateInterval,
            LocalizedData,
            MultipartBody,
            PagedResults,
            PatchableValue,
            appendQueryParameter,
            decodePagedResults,
            encodeFormValue,
            makeCookieHeader
        } from "./runtime.js";
        import type * as Models from "./models.js";
        import * as ModelCodecs from "./models.js";

        \(requests)

        \(builders)

        \(services)

        \(modules)
        """
    }

    private func apiModulesSource() -> String {
        let moduleFields = package.modules.map { module in
            "\(module.tsModulePropertyName): \(module.tsApiModuleTypeName);"
        }.joined(separator: "\n")
        let moduleAssignments = package.modules.map { module in
            "this.\(module.tsModulePropertyName) = new \(module.tsApiModuleTypeName)(client);"
        }.joined(separator: "\n")
        let moduleDeclarations = package.modules.map { module in
            let fields = module.definitions.map { definition in
                "\(definition.tsApiPropertyName): \(definition.tsApiTypeName(moduleName: module.name));"
            }.joined(separator: "\n")
            let assignments = module.definitions.map { definition in
                "this.\(definition.tsApiPropertyName) = new \(definition.tsApiServiceTypeName(moduleName: module.name))(client);"
            }.joined(separator: "\n")
            return """
            export class \(module.tsApiModuleTypeName) {
            \(fields.prepad())

                constructor(client: ApiClient) {
            \(assignments.prepad(2))
                }
            }
            """
        }.joined(separator: "\n\n")

        return """
        \(moduleDeclarations)

        export class ApiModules {
        \(moduleFields.prepad())

            constructor(client: ApiClient) {
        \(moduleAssignments.prepad(2))
            }
        }
        """
    }
}

struct TypeScriptOperationEmitter {
    let module: ApiModule
    let definition: ApiService
    let operation: ApiOperation
    let options: TypeScriptGeneratorOptions

    var operationPrefix: String {
        "\(module.name.tsTypeName)\(definition.name.tsTypeName)\(operation.name.tsTypeName)"
    }

    var requestTypeName: String {
        "\(operationPrefix)Request"
    }

    var builderName: String {
        "build\(operationPrefix)Request"
    }

    func requestDeclaration() -> String {
        let fields = requestFields().joined(separator: "\n")
        return """
        export interface \(requestTypeName) {
        \(fields.prepad())
        }
        """
    }

    func requestBuilder() -> String {
        let path = pathSource()
        let query = mapSource(
            variableName: "queryParameters",
            parameters: operation.expandedParameters.filter { $0.location == .query }
        )
        let headers = headersSource()
        let body = bodySource()
        return """
        export function \(builderName)(request: \(requestTypeName)): ApiRequest {
        \(path.prepad())
        \(query.prepad())
        \(headers.prepad())
        \(body.prepad())
            return {
                method: \(operation.method.httpMethod.tsStringLiteral),
                path,
                queryParameters,
                headers,
                body,
                contentType: \(operation.request.mimeType.map(\.tsStringLiteral) ?? "null"),
                accept: \(operation.response.mimeType.tsStringLiteral)
            };
        }
        """
    }

    private func requestFields() -> [String] {
        let runtimePath = operation.path.isRuntime ? ["requestUrl: string | URL;"] : []
        let params = operation.expandedParameters.map { parameter in
            let emitter = TypeScriptParameterEmitter(dataType: parameter.dataType, options: options, declaredTypePrefix: "Models.")
            let hasDefault = emitter.defaultValue() != nil || isGeneratedApiKeyParameter(parameter)
            let optional = parameter.isRequired && !hasDefault ? "" : "?"
            let nullable = parameter.isRequired && !hasDefault ? "" : " | null"
            return "\(parameter.propertyName.tsPropertyName)\(optional): \(emitter.declaration)\(nullable);"
        }
        let body = requestBodyField()
        return runtimePath + params + body
    }

    private func requestBodyField() -> [String] {
        switch operation.request {
            case .none:
                []
            case .binary:
                ["body: ArrayBuffer;"]
            case .file:
                ["body: Blob | File;"]
            case .multiPart:
                ["body: MultipartBody;"]
            case let .json(type):
                type.map {
                    ["body: \(TypeScriptTypeEmitter(dataType: $0, options: options, declaredTypePrefix: "Models.").declaration);"]
                } ?? []
        }
    }

    private func pathSource() -> String {
        switch operation.path {
            case .runtime:
                "const path = { kind: \"runtime\" as const, requestUrl: request.requestUrl };"
            case let .relative(path):
                fixedPathSource(path: normalizedRelativePath(path), kind: "relative", property: "path")
            case let .absolute(url):
                fixedPathSource(path: url, kind: "absolute", property: "url")
        }
    }

    private func fixedPathSource(path: String, kind: String, property: String) -> String {
        let parameters = operation.expandedParameters.filter { $0.location == .path }
        guard !parameters.isEmpty else {
            return "const path = { kind: \(kind.tsStringLiteral) as const, \(property): \(path.tsStringLiteral) };"
        }
        let replacements = parameters.map { parameter in
            """
            requestPath = requestPath.replace(
                \("{\(parameter.rawName)}".tsStringLiteral),
                encodeURIComponent(\(formValueExpression(for: parameter, value: requestValueExpression(for: parameter))))
            );
            """
        }.joined(separator: "\n")
        return """
        let requestPath = \(path.tsStringLiteral);
        \(replacements)
        const path = { kind: \(kind.tsStringLiteral) as const, \(property): requestPath };
        """
    }

    private func headersSource() -> String {
        let headerParams = operation.expandedParameters.filter { $0.location == .header }
        let cookieParams = operation.expandedParameters.filter { $0.location == .cookie }
        let headerMap = mapSource(variableName: "headers", parameters: headerParams)
        guard !cookieParams.isEmpty else {
            return headerMap
        }
        let cookieMap = mapSource(variableName: "cookies", parameters: cookieParams)
        return """
        \(headerMap)
        \(cookieMap)
        const cookieHeader = makeCookieHeader(cookies);
        if (cookieHeader) {
            headers.Cookie = cookieHeader;
        }
        """
    }

    private func mapSource(variableName: String, parameters: [ApiParameter]) -> String {
        guard !parameters.isEmpty else {
            return "const \(variableName): Record<string, string> = {};"
        }
        let assignments = parameters.map { parameter in
            let value = requestValueExpression(for: parameter)
            if parameter.isRequired {
                return "appendQueryParameter(\(variableName), \(parameter.rawName.tsStringLiteral), \(value));"
            }
            return """
            if (\(value) !== undefined && \(value) !== null) {
                appendQueryParameter(\(variableName), \(parameter.rawName.tsStringLiteral), \(value));
            }
            """
        }.joined(separator: "\n")
        return """
        const \(variableName): Record<string, string> = {};
        \(assignments)
        """
    }

    private func bodySource() -> String {
        switch operation.request {
            case .none:
                return "const body = undefined;"
            case .binary,
                 .file,
                 .multiPart:
                return "const body = request.body;"
            case let .json(type):
                guard let type else {
                    return "const body = undefined;"
                }
                let encoder = TypeScriptModelEmitter(dataTypes: [], options: options, codecPrefix: "ModelCodecs.")
                return "const body = \(encoder.encodeExpression(for: type, value: "request.body"));"
        }
    }

    private func requestValueExpression(for parameter: ApiParameter) -> String {
        let property = "request.\(parameter.propertyName.tsPropertyName)"
        if isGeneratedApiKeyParameter(parameter) {
            return "(\(property) ?? undefined)"
        }
        let emitter = TypeScriptParameterEmitter(dataType: parameter.dataType, options: options, declaredTypePrefix: "Models.")
        if let defaultValue = emitter.defaultValue() {
            return "(\(property) ?? \(defaultValue))"
        }
        return property
    }

    private func formValueExpression(for parameter: ApiParameter, value: String) -> String {
        switch parameter.dataType {
            case .stringEnumValue,
                 .intEnumValue:
                "encodeFormValue(\(value))"
            default:
                "encodeFormValue(\(value))"
        }
    }

    private func normalizedRelativePath(_ path: String) -> String {
        path.hasPrefix("/") ? path : "/\(path)"
    }
}

struct TypeScriptApiServiceEmitter {
    let module: ApiModule
    let definition: ApiService
    let options: TypeScriptGeneratorOptions

    func source() -> String {
        let interfaceMethods = definition.operations.map(interfaceMethod).joined(separator: "\n")
        let implementations = definition.operations.map(implementation).joined(separator: "\n\n")
        return """
        export interface \(definition.tsApiTypeName(moduleName: module.name)) {
        \(interfaceMethods.prepad())
        }

        export class \(definition.tsApiServiceTypeName(moduleName: module.name)) implements \(definition.tsApiTypeName(moduleName: module.name)) {
            constructor(private readonly client: ApiClient) {}

        \(implementations.prepad())
        }
        """
    }

    private func interfaceMethod(operation: ApiOperation) -> String {
        let emitter = TypeScriptOperationEmitter(module: module, definition: definition, operation: operation, options: options)
        return "\(operation.name.tsPropertyName)(request: \(emitter.requestTypeName)): Promise<\(returnType(operation: operation))>;"
    }

    private func implementation(operation: ApiOperation) -> String {
        let emitter = TypeScriptOperationEmitter(module: module, definition: definition, operation: operation, options: options)
        let requestVariable = operation.security == .unsecured ? "request" : "adaptedRequest"
        let securitySource = securitySource(operation: operation)
        let execute = executeExpression(operation: operation, requestVariable: requestVariable, builderName: emitter.builderName)
        return """
        async \(operation.name.tsPropertyName)(request: \(emitter.requestTypeName)): Promise<\(returnType(operation: operation))> {
        \(securitySource.prepad())
            return \(execute);
        }
        """
    }

    private func securitySource(operation: ApiOperation) -> String {
        switch operation.security {
            case .unsecured:
                ""
            case .optional:
                "const adaptedRequest = { ...request, apiKey: request.apiKey || await this.client.apiKey() || undefined };"
            case .secured:
                "const adaptedRequest = { ...request, apiKey: request.apiKey || await this.client.requireApiKey() };"
        }
    }

    private func executeExpression(operation: ApiOperation, requestVariable: String, builderName: String) -> String {
        let statuses = "[\(validStatusCodes(operation: operation).map(String.init).joined(separator: ", "))]"
        switch operation.response {
            case let .json(type):
                guard let type else {
                    return "this.client.execute(\(builderName)(\(requestVariable)), \(statuses))"
                }
                let decoder = responseDecoder(for: type)
                return "this.client.execute(\(builderName)(\(requestVariable)), \(statuses), \(decoder))"
            case .binary:
                return "this.client.executeBinary(\(builderName)(\(requestVariable)), \(statuses))"
            case .none:
                return "this.client.execute(\(builderName)(\(requestVariable)), \(statuses))"
        }
    }

    private func responseDecoder(for dataType: ApiTypeSchema) -> String {
        switch dataType {
            case let .genericReference(typeName, types) where typeName == "PagedResults" && types.count == 1:
                let itemDecoder = responseDecoder(for: types[0])
                return "(value) => decodePagedResults(value, \(itemDecoder))"
            case let .array(type):
                let itemDecoder = responseDecoder(for: type)
                return "(value) => ((value ?? []) as unknown[]).map(\(itemDecoder))"
            case let .keyedByString(type, isOptional):
                let itemDecoder = responseDecoder(for: type)
                let itemExpression = isOptional ? "(item == null ? null : \(itemDecoder)(item))" : "\(itemDecoder)(item)"
                return "(value) => Object.fromEntries(Object.entries((value ?? {}) as Record<string, unknown>).map(([key, item]) => [key, \(itemExpression)]))"
            case let .reference(typeName, _, _, _, referencedDataType):
                if let referencedDataType {
                    return responseDecoder(for: referencedDataType)
                }
                if options.mapping(for: typeName) != nil {
                    return "(value) => value as \(TypeScriptTypeEmitter(dataType: dataType, options: options, declaredTypePrefix: "Models.").declaration)"
                }
                return "ModelCodecs.decode\(typeName.tsTypeName)"
            case let .object(typeName, _, _, _, _, _),
                 let .stringEnum(typeName, _, _, _, _),
                 let .intEnum(typeName, _, _, _),
                 let .dynamicObject(typeName, _, _, _, _, _, _, _, _):
                return "ModelCodecs.decode\(typeName.tsTypeName)"
            default:
                return "(value) => value as \(TypeScriptTypeEmitter(dataType: dataType, options: options, declaredTypePrefix: "Models.").declaration)"
        }
    }

    private func returnType(operation: ApiOperation) -> String {
        switch operation.response {
            case let .json(type):
                guard let type else {
                    return "ApiResponse"
                }
                let typeName = TypeScriptTypeEmitter(dataType: type, options: options, declaredTypePrefix: "Models.").declaration
                return "ApiOperationResult<\(typeName)>"
            case .binary:
                return "ApiOperationResult<ArrayBuffer>"
            case .none:
                return "ApiResponse"
        }
    }

    private func validStatusCodes(operation: ApiOperation) -> [Int] {
        guard operation.response.dataType != nil else {
            return operation.acceptableStatuses
        }
        return operation.acceptableStatuses.filter { !$0.isHttpBodylessStatus }
    }
}

private func isGeneratedApiKeyParameter(_ parameter: ApiParameter) -> Bool {
    parameter.rawName == "Authorization" && parameter.propertyName == "apiKey"
}

extension ApiModule {
    var tsApiModuleTypeName: String {
        "\(name.tsTypeName)ApiModule"
    }

    var tsModulePropertyName: String {
        "\(name.tsPropertyName)Module"
    }
}

extension ApiService {
    func tsApiTypeName(moduleName: String) -> String {
        "\(moduleName.tsTypeName)\(name.tsTypeName)Api"
    }

    func tsApiServiceTypeName(moduleName: String) -> String {
        "\(moduleName.tsTypeName)\(name.tsTypeName)ApiService"
    }

    var tsApiPropertyName: String {
        "\(name.tsPropertyName)Api"
    }
}

extension Int {
    var isHttpBodylessStatus: Bool {
        (100 ..< 200).contains(self) || self == 204 || self == 205 || self == 304
    }
}
