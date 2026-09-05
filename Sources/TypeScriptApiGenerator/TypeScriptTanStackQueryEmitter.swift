import Foundation
import GeneratorBuilder
import GeneratorModels

struct TypeScriptTanStackQueryEmitter {
    let package: ApiPackage
    let options: TypeScriptGeneratorOptions

    func source() -> String {
        let operations = package.modules.flatMap { module in
            module.definitions.flatMap { definition in
                definition.operations.map { operation in
                    (module: module, definition: definition, operation: operation)
                }
            }
        }

        guard !operations.isEmpty else {
            return """
            // Generated code. Do not edit.
            """
        }

        let tanStackImports = tanStackImportNames(operations: operations)
            .sorted()
            .joined(separator: ", ")
        let operationImports = operationImportNames(operations: operations)
            .sorted()
            .joined(separator: ",\n    ")
        let helpers = operations
            .map { module, definition, operation in
                operationSource(module: module, definition: definition, operation: operation)
            }
            .joined(separator: "\n\n")

        return """
        // Generated code. Do not edit.

        import { \(tanStackImports) } from "@tanstack/react-query";
        import type {
            \(operationImports)
        } from "./operations.js";

        \(helpers)
        """
    }

    private func operationSource(module: ApiModule, definition: ApiService, operation: ApiOperation) -> String {
        if operation.method == .get {
            return querySource(module: module, definition: definition, operation: operation)
        }
        return mutationSource(module: module, definition: definition, operation: operation)
    }

    private func querySource(module: ApiModule, definition: ApiService, operation: ApiOperation) -> String {
        let serviceTypeName = definition.tsApiTypeName(moduleName: module.name)
        let requestTypeName = requestTypeName(module: module, definition: definition, operation: operation)
        let keyName = keyFunctionName(module: module, definition: definition, operation: operation)
        let optionsName = queryOptionsFunctionName(module: module, definition: definition, operation: operation)
        let operationKey = operation.name.tsPropertyName.tsStringLiteral
        let serviceMethod = operation.name.tsPropertyName

        return """
        export function \(keyName)(request: \(requestTypeName)) {
            return [\(serviceTypeName.tsStringLiteral), \(operationKey), request] as const;
        }

        export function \(optionsName)(api: \(serviceTypeName), request: \(requestTypeName)) {
            return queryOptions({
                queryKey: \(keyName)(request),
                queryFn: () => api.\(serviceMethod)(request)
            });
        }
        """
    }

    private func mutationSource(module: ApiModule, definition: ApiService, operation: ApiOperation) -> String {
        let serviceTypeName = definition.tsApiTypeName(moduleName: module.name)
        let requestTypeName = requestTypeName(module: module, definition: definition, operation: operation)
        let optionsName = mutationOptionsFunctionName(module: module, definition: definition, operation: operation)
        let serviceMethod = operation.name.tsPropertyName

        return """
        export function \(optionsName)(api: \(serviceTypeName)) {
            return mutationOptions({
                mutationKey: [\(serviceTypeName.tsStringLiteral), \(operation.name.tsPropertyName.tsStringLiteral)] as const,
                mutationFn: (request: \(requestTypeName)) => api.\(serviceMethod)(request)
            });
        }
        """
    }

    private func tanStackImportNames(operations: [(module: ApiModule, definition: ApiService, operation: ApiOperation)]) -> Set<String> {
        var names: Set<String> = []
        if operations.contains(where: { $0.operation.method == .get }) {
            names.insert("queryOptions")
        }
        if operations.contains(where: { $0.operation.method != .get }) {
            names.insert("mutationOptions")
        }
        return names
    }

    private func operationImportNames(operations: [(module: ApiModule, definition: ApiService, operation: ApiOperation)]) -> Set<String> {
        var names: Set<String> = []
        for item in operations {
            names.insert(item.definition.tsApiTypeName(moduleName: item.module.name))
            names.insert(requestTypeName(module: item.module, definition: item.definition, operation: item.operation))
        }
        return names
    }

    private func requestTypeName(module: ApiModule, definition: ApiService, operation: ApiOperation) -> String {
        TypeScriptOperationEmitter(
            module: module,
            definition: definition,
            operation: operation,
            options: options,
        )
        .requestTypeName
    }

    private func operationPrefix(module: ApiModule, definition: ApiService, operation: ApiOperation) -> String {
        TypeScriptOperationEmitter(
            module: module,
            definition: definition,
            operation: operation,
            options: options,
        )
        .operationPrefix
    }

    private func keyFunctionName(module: ApiModule, definition: ApiService, operation: ApiOperation) -> String {
        "\(operationPrefix(module: module, definition: definition, operation: operation).lowercasingFirst)Key"
    }

    private func queryOptionsFunctionName(module: ApiModule, definition: ApiService, operation: ApiOperation) -> String {
        "\(operationPrefix(module: module, definition: definition, operation: operation).lowercasingFirst)QueryOptions"
    }

    private func mutationOptionsFunctionName(module: ApiModule, definition: ApiService, operation: ApiOperation) -> String {
        "\(operationPrefix(module: module, definition: definition, operation: operation).lowercasingFirst)MutationOptions"
    }
}
