import Foundation
import GeneratorBuilder
import GeneratorModels

struct TypeScriptBackendOperationEmitter {
    let module: ApiModule
    let definition: ApiService
    let operation: ApiOperation
    let models: TypeScriptBackendModelEmitter

    var operationTypeName: String {
        "\(module.name.backendTypeName)\(definition.name.backendTypeName)\(operation.name.backendTypeName)"
    }

    var handlerName: String {
        operationTypeName.backendPropertyName
    }

    func handlerDeclaration() -> String {
        let requestType = handlerRequestType()
        let responseType = handlerResponseType()
        let inputDeclaration = parameterInputDeclaration()
        return """
        \(inputDeclaration)
        export type \(operationTypeName)Handler<Bindings extends GeneratedSchemaBindings = {}> = (input: GeneratedHandlerInput<Bindings[\"\(handlerName)\"], \(requestType)>) => GeneratedHandlerOutput<Bindings[\"\(handlerName)\"], \(responseType)>;
        """
    }

    func handlerField() -> String {
        "\(handlerName): \(operationTypeName)Handler<Bindings>;"
    }

    var requiresInputSchemaBinding: Bool {
        operation.request.dataType?.containsBackendCustomizableType == true
    }

    var requiresOutputSchemaBinding: Bool {
        operation.response.dataType?.containsBackendCustomizableType == true
    }

    func schemaBindingValidation() -> String {
        var lines: [String] = []
        if requiresInputSchemaBinding {
            lines.append("if (!bindings?.\(handlerName)?.input) { throw new Error(\"Missing schema binding for \(handlerName) input\"); }")
        }
        if requiresOutputSchemaBinding {
            lines.append("if (!bindings?.\(handlerName)?.output) { throw new Error(\"Missing schema binding for \(handlerName) output\"); }")
        }
        return lines.joined(separator: "\n")
    }

    func routeSource() -> String {
        let path = relativePath()
        let method = operation.method.rawValue
        let status = operation.acceptableStatuses.first ?? 200
        let routeParser = requestParser().map { ", \($0)" } ?? ""
        return """
            app.\(method)(\(path.backendStringLiteral)\(routeParser), async (request, response, next) => {
                let input: GeneratedHandlerInput<Bindings["\(handlerName)"], \(handlerRequestType())>;
                try {
            \(requestDecodeLines().prepad(4))
                } catch {
                    response.status(400).json({ error: "Invalid request" });
                    return;
                }

                try {
                    const output = normalizeGeneratedResponse(await handlers.\(handlerName)(input), \(status));
                    validateGeneratedResponseStatus(output.status, [\(operation.acceptableStatuses.map(String.init).joined(separator: ", "))]);
                    for (const [name, value] of Object.entries(output.headers)) {
                        response.setHeader(name, value);
                    }
            \(responseHandling().prepad(4))
                } catch (error) {
                    next(error);
                }
            });
        """
    }

    private func handlerRequestType() -> String {
        if !operation.expandedParameters.isEmpty {
            return "\(operationTypeName)Input"
        }
        return switch operation.request {
            case .none:
                "void"
            case .binary,
                 .file:
                "Uint8Array"
            case let .json(dataType):
                dataType.map { models.typeDeclaration(for: $0) } ?? "void"
            case .multiPart:
                "unknown"
        }
    }

    private func handlerResponseType() -> String {
        switch operation.response {
            case .none:
                "void"
            case .binary:
                "Uint8Array"
            case let .json(dataType):
                dataType.map { models.typeDeclaration(for: $0) } ?? "void"
        }
    }

    private func requestParser() -> String? {
        switch operation.request {
            case .none:
                nil
            case .json:
                "options?.jsonBodyParser ?? express.raw({ type: \"application/json\" })"
            case let .binary(mimeType):
                "options?.rawBodyParser ?? express.raw({ type: \(mimeType.backendStringLiteral) })"
            case .file:
                "options?.rawBodyParser ?? express.raw({ type: \"*/*\" })"
            case .multiPart:
                nil
        }
    }

    private func requestDecodeLines() -> String {
        if !operation.expandedParameters.isEmpty {
            return parameterizedRequestDecodeLines()
        }
        switch operation.request {
            case .none:
                return "input = undefined as GeneratedHandlerInput<Bindings[\"\(handlerName)\"], void>;"
            case let .json(dataType):
                guard let dataType else {
                    return "input = undefined as GeneratedHandlerInput<Bindings[\"\(handlerName)\"], void>;"
                }
                let requestType = models.typeDeclaration(for: dataType)
                let requestDecoder = models.decodeExpression(for: dataType, value: "parseJsonBody(request.body)")
                return """
                const decodedInput = \(requestDecoder);
                input = (bindings?.\(handlerName)?.input ? bindings.\(handlerName).input.parse(decodedInput) : decodedInput) as GeneratedHandlerInput<Bindings["\(handlerName)"], \(requestType)>;
                """
            case .binary,
                 .file:
                return """
                if (!(request.body instanceof Uint8Array)) {
                    throw new Error("Invalid raw request body");
                }
                input = request.body as GeneratedHandlerInput<Bindings["\(handlerName)"], Uint8Array>;
                """
            case .multiPart:
                return "input = undefined as GeneratedHandlerInput<Bindings[\"\(handlerName)\"], void>;"
        }
    }

    private func responseHandling() -> String {
        switch operation.response {
            case .none:
                return """
                if (output.value !== undefined) {
                    throw new Error("Bodyless response cannot include a response value");
                }
                response.status(output.status).end();
                """
            case let .binary(mimeType):
                return """
                if (!(output.value instanceof Uint8Array)) {
                    throw new Error("Invalid raw response body");
                }
                if (!generatedResponseHasBody(output.status)) {
                    response.status(output.status).end();
                    return;
                }
                response.status(output.status).type(\(mimeType.backendStringLiteral)).send(output.value);
                """
            case let .json(dataType):
                guard let dataType else {
                    return "response.status(output.status).end();"
                }
                let responseType = models.typeDeclaration(for: dataType)
                let responseEncoder = models.encodeRootExpression(for: dataType, value: "publicOutput")
                return """
                const publicOutput = (bindings?.\(handlerName)?.output ? bindings.\(handlerName).output.parse(output.value) : output.value) as GeneratedWireOutput<Bindings["\(handlerName)"], \(responseType)>;
                const body = \(responseEncoder);
                if (!generatedResponseHasBody(output.status)) {
                    response.status(output.status).end();
                    return;
                }
                response.status(output.status).type("application/json").send(stringifyJsonResponse(body));
                """
        }
    }

    private func parameterInputDeclaration() -> String {
        guard !operation.expandedParameters.isEmpty else {
            return ""
        }
        var properties = operation.expandedParameters.map { parameter in
            let optional = parameter.isRequired ? "" : "?"
            return "    \(parameter.propertyName.backendPropertyName)\(optional): \(parameterTypeDeclaration(for: parameter.dataType));"
        }
        if hasRequestBody {
            properties.append("    body: \(handlerBodyType());")
        }
        return """
        export interface \(operationTypeName)Input {
        \(properties.joined(separator: "\n"))
        }
        """
    }

    private func parameterizedRequestDecodeLines() -> String {
        let parameterLines = operation.expandedParameters.map(parameterDecodeLines).joined(separator: "\n")
        let bodyLines: String = switch operation.request {
            case let .json(dataType):
                dataType.map {
                    "const body = \(models.decodeExpression(for: $0, value: "parseJsonBody(request.body)"));"
                } ?? ""
            case .binary,
                 .file:
                """
                if (!(request.body instanceof Uint8Array)) {
                    throw new Error("Invalid raw request body");
                }
                const body = request.body;
                """
            case .none,
                 .multiPart:
                ""
        }
        var fields = operation.expandedParameters.map { parameter in
            "\(parameter.propertyName.backendPropertyName): parsed_\(parameterVariableName(parameter)),"
        }
        if hasRequestBody {
            fields.append("body,")
        }
        let decodedInput = "const decodedInput = {\n\(fields.joined(separator: "\n").prepad())\n};"
        return """
        \(parameterLines)
        \(bodyLines)
        \(decodedInput)
        input = (bindings?.\(handlerName)?.input ? bindings.\(handlerName).input.parse(decodedInput) : decodedInput) as GeneratedHandlerInput<Bindings[\"\(handlerName)\"], \(handlerRequestType())>;
        """
    }

    private func parameterDecodeLines(_ parameter: ApiParameter) -> String {
        let variable = parameterVariableName(parameter)
        let raw = "raw_\(variable)"
        let parsed = parameterValueExpression(parameter, value: raw, required: parameter.isRequired)
        return """
        const \(raw) = readRequestParameter(request, \(parameter.location.rawValue.backendStringLiteral), \(parameter.rawName.backendStringLiteral));
        const parsed_\(variable) = \(parsed);
        """
    }

    private func parameterValueExpression(_ parameter: ApiParameter, value: String, required: Bool) -> String {
        parameterValueExpression(dataType: parameter.dataType, name: parameter.rawName, value: value, required: required)
    }

    private func parameterValueExpression(
        dataType: ApiParameter.DataType,
        name: String,
        value: String,
        required: Bool,
    ) -> String {
        let requiredLiteral = required ? "true" : "false"
        switch dataType {
            case .bool:
                return "parseParameterBoolean(\(value), \(name.backendStringLiteral), \(requiredLiteral))"
            case .string:
                return "parseParameterString(\(value), \(name.backendStringLiteral), \(requiredLiteral))"
            case .int,
                 .int64,
                 .uint,
                 .uint64:
                return "parseParameterBigInt(\(value), \(name.backendStringLiteral), \(requiredLiteral), \(bigIntLiteral(for: dataType, minimum: true)), \(bigIntLiteral(for: dataType, minimum: false)))"
            case .int16,
                 .int32,
                 .uint16,
                 .uint32:
                let bounds = narrowBounds(for: dataType)
                return "parseParameterNarrowInteger(\(value), \(name.backendStringLiteral), \(requiredLiteral), \(bounds.minimum), \(bounds.maximum))"
            case .dateTime:
                return "parseParameterDateTime(\(value), \(name.backendStringLiteral), \(requiredLiteral))"
            case .date:
                return "parseParameterDate(\(value), \(name.backendStringLiteral), \(requiredLiteral))"
            case .time:
                return "parseParameterTime(\(value), \(name.backendStringLiteral), \(requiredLiteral))"
            case .boolArray,
                 .stringArray,
                 .intArray,
                 .int16Array,
                 .int32Array,
                 .int64Array,
                 .uintArray,
                 .uint16Array,
                 .uint32Array,
                 .uint64Array:
                let item = parameterValueExpression(dataType: dataType.arrayItemDataType, name: name, value: "item", required: true)
                return "parseParameterArray(\(value), \(name.backendStringLiteral), \(requiredLiteral))?.map((item) => \(item))"
            case let .stringEnumValue(type, _):
                let parsed = parameterValueExpression(dataType: .string(), name: name, value: value, required: required)
                return required ? "decode\(enumTypeName(type))(\(parsed))" : "(() => { const value = \(parsed); return value === undefined ? undefined : decode\(enumTypeName(type))(value); })()"
            case let .stringEnumArray(type, _):
                return "parseParameterArray(\(value), \(name.backendStringLiteral), \(requiredLiteral))?.map((item) => decode\(enumTypeName(type))(item))"
            case let .intEnumValue(type, _):
                let parsed = "parseParameterInteger(\(value), \(name.backendStringLiteral), \(requiredLiteral))"
                return required ? "decode\(enumTypeName(type))(\(parsed))" : "(() => { const value = \(parsed); return value === undefined ? undefined : decode\(enumTypeName(type))(value); })()"
            case let .intEnumArray(type, _):
                return "parseParameterArray(\(value), \(name.backendStringLiteral), \(requiredLiteral))?.map((item) => decode\(enumTypeName(type))(parseParameterInteger(item, \(name.backendStringLiteral), true)))"
        }
    }

    private func parameterTypeDeclaration(for dataType: ApiParameter.DataType) -> String {
        switch dataType {
            case .bool: "boolean"
            case .boolArray: "boolean[]"
            case .string,
                 .date,
                 .time: "string"
            case .stringArray: "string[]"
            case .dateTime: "Date"
            case .int,
                 .int64,
                 .uint,
                 .uint64: "bigint"
            case .int16,
                 .int32,
                 .uint16,
                 .uint32: "number"
            case .intArray,
                 .int64Array,
                 .uintArray,
                 .uint64Array: "bigint[]"
            case .int16Array,
                 .int32Array,
                 .uint16Array,
                 .uint32Array: "number[]"
            case let .stringEnumValue(type, _),
                 let .intEnumValue(type, _): models.typeDeclaration(for: type)
            case let .stringEnumArray(type, _),
                 let .intEnumArray(type, _): "\(models.typeDeclaration(for: type))[]"
        }
    }

    private func handlerBodyType() -> String {
        switch operation.request {
            case .none: "never"
            case .binary,
                 .file: "Uint8Array"
            case let .json(dataType): dataType.map { models.typeDeclaration(for: $0) } ?? "never"
            case .multiPart: "unknown"
        }
    }

    private var hasRequestBody: Bool {
        switch operation.request {
            case .none: false
            case .json,
                 .binary,
                 .file,
                 .multiPart: true
        }
    }

    private func parameterVariableName(_ parameter: ApiParameter) -> String {
        parameter.propertyName.backendPropertyName
    }

    private func enumTypeName(_ type: ApiTypeSchema) -> String {
        switch type {
            case let .stringEnum(typeName, _, _, _, _),
                 let .intEnum(typeName, _, _, _): typeName.backendTypeName
            case let .reference(_, _, _, _, resolved): resolved.map(enumTypeName) ?? type.backendDeclaredTypeName?.backendTypeName ?? "UnknownEnum"
            default: type.backendDeclaredTypeName?.backendTypeName ?? "UnknownEnum"
        }
    }

    private func bigIntLiteral(for dataType: ApiParameter.DataType, minimum: Bool) -> String {
        switch dataType {
            case .uint,
                 .uint64: minimum ? "0n" : "18446744073709551615n"
            default: minimum ? "-9223372036854775808n" : "9223372036854775807n"
        }
    }

    private func narrowBounds(for dataType: ApiParameter.DataType) -> (minimum: String, maximum: String) {
        switch dataType {
            case .int16,
                 .int16Array: ("-32768", "32767")
            case .int32,
                 .int32Array: ("-2147483648", "2147483647")
            case .uint16,
                 .uint16Array: ("0", "65535")
            case .uint32,
                 .uint32Array: ("0", "4294967295")
            default: ("0", "0")
        }
    }

    private func relativePath() -> String {
        guard case let .relative(path) = operation.path else {
            return "/"
        }
        let normalizedPath = path.hasPrefix("/") ? path : "/\(path)"
        return operation.expandedParameters
            .filter { $0.location == .path }
            .reduce(normalizedPath) { result, parameter in
                result.replacingOccurrences(of: "{\(parameter.rawName)}", with: ":\(parameter.rawName)")
            }
    }
}

struct TypeScriptBackendRoutesEmitter {
    let package: ApiPackage
    let models: TypeScriptBackendModelEmitter

    func source() -> String {
        let operations = package.modules.flatMap { module in
            module.definitions.flatMap { definition in
                definition.operations.map {
                    TypeScriptBackendOperationEmitter(module: module, definition: definition, operation: $0, models: models)
                }
            }
        }
        let handlers = operations.map { $0.handlerDeclaration() }.joined(separator: "\n")
        let fields = operations.map { $0.handlerField() }.joined(separator: "\n")
        let routes = operations.map { $0.routeSource() }.joined(separator: "\n")
        let schemaBindingValidation = operations.map { $0.schemaBindingValidation() }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
        let importedDataTypes = operations.flatMap { operation in
            [operation.operation.request.dataType, operation.operation.response.dataType]
                .compactMap(\.self)
                + operation.operation.expandedParameters.compactMap(\.dataType.backendDataType)
        }
        let imports = importedDataTypes.flatMap { codecImports(for: $0) ?? [] }
            .uniqued()
            .sorted()
            .joined(separator: ",\n    ")
        return """
        // Generated code. Do not edit.

        import express, { type Express, type RequestHandler } from "express";
        import { z } from "zod";
        import {
            base64ToUint8Array,
            isValidBase64,
            isValidCalendarDate,
            isValidISODate,
            isValidLocalTime,
            isValidURL,
            isValidUUID,
            parseParameterArray,
            parseParameterBigInt,
            parseParameterBoolean,
            parseParameterDate,
            parseParameterDateTime,
            parseParameterInteger,
            parseParameterNarrowInteger,
            parseParameterString,
            parseParameterTime,
            parseDate,
            parseDouble,
            parseJsonBody,
            parseNarrowInteger,
            parseURL,
            readRequestParameter,
            generatedResponseHasBody,
            normalizeGeneratedResponse,
            serializeDate,
            serializeURL,
            stringifyJsonResponse,
            validateGeneratedResponseStatus,
            uint8ArrayToBase64
        } from "./runtime.js";
        import { type GeneratedResponse } from "./runtime.js";
        import {
            \(imports)
        } from "./models.js";

        export type GeneratedSchemaBinding<Output = unknown, Input = unknown> = z.ZodType<Output, Input>;

        export interface GeneratedOperationBinding<HandlerInput = unknown, HandlerOutput = unknown, WireOutput = unknown> {
            input?: GeneratedSchemaBinding<HandlerInput>;
            output?: GeneratedSchemaBinding<WireOutput, HandlerOutput>;
        }

        export interface GeneratedRouteOptions {
            jsonBodyParser?: RequestHandler;
            rawBodyParser?: RequestHandler;
        }

        export interface GeneratedSchemaBindings {
        \(operations.map { "    \($0.handlerName)?: GeneratedOperationBinding;" }.joined(separator: "\n"))
        }

        export type GeneratedHandlerInput<Binding, Default> = Binding extends { input?: infer Schema }
            ? NonNullable<Schema> extends z.ZodTypeAny ? z.output<NonNullable<Schema>> : Default
            : Default;

        export type GeneratedHandlerValue<Binding, Default> = Binding extends { output?: infer Schema }
            ? NonNullable<Schema> extends z.ZodTypeAny ? z.input<NonNullable<Schema>> | Promise<z.input<NonNullable<Schema>>> : Default | Promise<Default>
            : Default | Promise<Default>;

        export type GeneratedHandlerOutput<Binding, Default> = GeneratedHandlerValue<Binding, Default>
            | GeneratedResponse<Awaited<GeneratedHandlerValue<Binding, Default>>>
            | Promise<GeneratedResponse<Awaited<GeneratedHandlerValue<Binding, Default>>> | Awaited<GeneratedHandlerValue<Binding, Default>>>;

        export type GeneratedWireOutput<Binding, Default> = Binding extends { output?: infer Schema }
            ? NonNullable<Schema> extends z.ZodTypeAny ? z.output<NonNullable<Schema>> : Default
            : Default;

        \(handlers)

        export interface GeneratedHandlers<Bindings extends GeneratedSchemaBindings = {}> {
        \(fields.prepad())
        }

        export function registerGeneratedRoutes<Bindings extends GeneratedSchemaBindings = {}>(app: Express, handlers: GeneratedHandlers<Bindings>, bindings?: Bindings, options?: GeneratedRouteOptions): void {
        \(schemaBindingValidation.prepad())
        \(routes.prepad())
        }
        """
    }

    private func codecImports(for dataType: ApiTypeSchema) -> [String]? {
        switch dataType {
            case let .reference(_, _, _, _, dataType):
                dataType.map(codecImports(for:)) ?? []
            case let .object(typeName, _, _, _, _, _),
                 let .stringEnum(typeName, _, _, _, _),
                 let .intEnum(typeName, _, _, _),
                 let .dynamicObject(typeName, _, _, _, _, _, _, _, _):
                [
                    "decode\(typeName.backendTypeName)",
                    "encode\(typeName.backendTypeName)",
                    "type \(typeName.backendTypeName)"
                ]
            case let .array(type),
                 let .keyedByString(type, _):
                codecImports(for: type)
            default:
                nil
        }
    }
}

private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen: Set<Element> = []
        return filter { seen.insert($0).inserted }
    }
}
