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
        guard let requestDataType = operation.request.dataType,
              let responseDataType = operation.response.dataType else {
            return ""
        }
        let requestType = models.typeDeclaration(for: requestDataType)
        let responseType = models.typeDeclaration(for: responseDataType)
        return """
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
        guard let requestType = operation.request.dataType,
              let responseType = operation.response.dataType else {
            return ""
        }
        let requestName = models.typeDeclaration(for: requestType)
        let requestDecoder = models.decodeExpression(for: requestType, value: "parseJsonBody(request.body)")
        let responseName = models.typeDeclaration(for: responseType)
        let responseEncoder = models.encodeRootExpression(for: responseType, value: "publicOutput")
        let path = relativePath()
        let method = operation.method.rawValue
        let status = operation.acceptableStatuses.first ?? 200
        return """
            app.\(method)(\(path.backendStringLiteral), express.raw({ type: "application/json" }), async (request, response, next) => {
                let input: GeneratedHandlerInput<Bindings["\(handlerName)"], \(requestName)>;
                try {
                    const decodedInput = \(requestDecoder);
                    input = (bindings?.\(handlerName)?.input ? bindings.\(handlerName).input.parse(decodedInput) : decodedInput) as GeneratedHandlerInput<Bindings["\(handlerName)"], \(requestName)>;
                } catch {
                    response.status(400).json({ error: "Invalid request" });
                    return;
                }

                try {
                    const output = await handlers.\(handlerName)(input);
                    const publicOutput = (bindings?.\(handlerName)?.output ? bindings.\(handlerName).output.parse(output) : output) as GeneratedWireOutput<Bindings["\(handlerName)"], \(responseName)>;
                    const body = \(responseEncoder);
                    response.status(\(status)).type("application/json").send(stringifyJsonResponse(body));
                } catch (error) {
                    next(error);
                }
            });
        """
    }

    private func relativePath() -> String {
        guard case let .relative(path) = operation.path else {
            return "/"
        }
        return path.hasPrefix("/") ? path : "/\(path)"
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
        let imports = operations.flatMap { operation -> [String] in
            [operation.operation.request.dataType, operation.operation.response.dataType]
                .compactMap(\.self)
                .flatMap { codecImports(for: $0) ?? [] }
        }
        .uniqued()
        .sorted()
        .joined(separator: ",\n    ")
        return """
        // Generated code. Do not edit.

        import express, { type Express } from "express";
        import { z } from "zod";
        import {
            base64ToUint8Array,
            isValidBase64,
            isValidCalendarDate,
            isValidISODate,
            isValidLocalTime,
            isValidURL,
            isValidUUID,
            parseDate,
            parseDouble,
            parseJsonBody,
            parseNarrowInteger,
            parseURL,
            serializeDate,
            serializeURL,
            stringifyJsonResponse,
            uint8ArrayToBase64
        } from "./runtime.js";
        import {
            \(imports)
        } from "./models.js";

        export type GeneratedSchemaBinding<Output = unknown, Input = unknown> = z.ZodType<Output, Input>;

        export interface GeneratedOperationBinding<HandlerInput = unknown, HandlerOutput = unknown, WireOutput = unknown> {
            input?: GeneratedSchemaBinding<HandlerInput>;
            output?: GeneratedSchemaBinding<WireOutput, HandlerOutput>;
        }

        export interface GeneratedSchemaBindings {
        \(operations.map { "    \($0.handlerName)?: GeneratedOperationBinding;" }.joined(separator: "\n"))
        }

        export type GeneratedHandlerInput<Binding, Default> = Binding extends { input?: infer Schema }
            ? NonNullable<Schema> extends z.ZodTypeAny ? z.output<NonNullable<Schema>> : Default
            : Default;

        export type GeneratedHandlerOutput<Binding, Default> = Binding extends { output?: infer Schema }
            ? NonNullable<Schema> extends z.ZodTypeAny ? z.input<NonNullable<Schema>> | Promise<z.input<NonNullable<Schema>>> : Default | Promise<Default>
            : Default | Promise<Default>;

        export type GeneratedWireOutput<Binding, Default> = Binding extends { output?: infer Schema }
            ? NonNullable<Schema> extends z.ZodTypeAny ? z.output<NonNullable<Schema>> : Default
            : Default;

        \(handlers)

        export interface GeneratedHandlers<Bindings extends GeneratedSchemaBindings = {}> {
        \(fields.prepad())
        }

        export function registerGeneratedRoutes<Bindings extends GeneratedSchemaBindings = {}>(app: Express, handlers: GeneratedHandlers<Bindings>, bindings?: Bindings): void {
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
