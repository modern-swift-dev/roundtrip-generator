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
        export type \(operationTypeName)Handler = (input: \(requestType)) => \(responseType) | Promise<\(responseType)>;
        """
    }

    func handlerField() -> String {
        "\(handlerName): \(operationTypeName)Handler;"
    }

    func routeSource() -> String {
        guard let requestType = operation.request.dataType,
              let responseType = operation.response.dataType else {
            return ""
        }
        let requestName = models.typeDeclaration(for: requestType)
        let requestDecoder = models.decodeExpression(for: requestType, value: "request.body")
        let responseEncoder = models.encodeExpression(for: responseType, value: "output")
        let path = relativePath()
        let method = operation.method.rawValue
        let status = operation.acceptableStatuses.first ?? 200
        return """
            app.\(method)(\(path.backendStringLiteral), express.json(), async (request, response, next) => {
                let input: \(requestName);
                try {
                    input = \(requestDecoder);
                } catch {
                    response.status(400).json({ error: "Invalid request" });
                    return;
                }

                try {
                    const output = await handlers.\(handlerName)(input);
                    const body = \(responseEncoder);
                    response.status(\(status)).json(body);
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
        import {
            \(imports)
        } from "./models.js";

        \(handlers)

        export interface GeneratedHandlers {
        \(fields.prepad())
        }

        export function registerGeneratedRoutes(app: Express, handlers: GeneratedHandlers): void {
        \(routes.prepad())
        }
        """
    }

    private func codecImports(for dataType: ApiTypeSchema) -> [String]? {
        switch dataType {
            case let .reference(typeName, _, _, _, dataType):
                dataType.map(codecImports(for:)) ?? [
                    "decode\(typeName.backendTypeName)",
                    "encode\(typeName.backendTypeName)",
                    "type \(typeName.backendTypeName)"
                ]
            case let .object(typeName, _, _, _, _, _),
                 let .stringEnum(typeName, _, _, _, _),
                 let .intEnum(typeName, _, _, _),
                 let .dynamicObject(typeName, _, _, _, _, _, _, _, _):
                [
                    "decode\(typeName.backendTypeName)",
                    "encode\(typeName.backendTypeName)",
                    "type \(typeName.backendTypeName)"
                ]
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
