import Foundation
import GeneratorBuilder
import GeneratorModels

public enum TypeScriptBackendGeneratorError: Error, LocalizedError, Equatable {
    case invalidPackageName(String)
    case invalidSourceDirectory(String)
    case invalidPackage(reason: String)
    case unsupportedSecurity(operationName: String)
    case unsupportedPath(operationName: String)
    case unsupportedRequest(operationName: String)
    case unsupportedResponse(operationName: String)
    case unsupportedDataType(String)
    case unresolvedExternalType(String)

    public var errorDescription: String? {
        switch self {
            case let .invalidPackageName(value):
                "Invalid TypeScript backend package name: \(value)"
            case let .invalidSourceDirectory(value):
                "Invalid TypeScript backend source directory: \(value)"
            case let .invalidPackage(reason):
                "Invalid TypeScript backend package: \(reason)"
            case let .unsupportedSecurity(operationName):
                "TypeScript backend operation \(operationName) requires authentication integration"
            case let .unsupportedPath(operationName):
                "TypeScript backend operation \(operationName) must use a relative path"
            case let .unsupportedRequest(operationName):
                "TypeScript backend operation \(operationName) must use a JSON request body"
            case let .unsupportedResponse(operationName):
                "TypeScript backend operation \(operationName) must use a JSON response body"
            case let .unsupportedDataType(description):
                "TypeScript backend does not support \(description) in this slice"
            case let .unresolvedExternalType(typeName):
                "Missing TypeScript backend schema for external type: \(typeName)"
        }
    }
}

extension String {
    var backendPropertyName: String {
        camelized
            .backendIdentifierWithValidLeadingCharacter
            .backendIdentifier
    }

    var backendTypeName: String {
        capitalCased
            .backendIdentifierWithValidLeadingCharacter
            .backendIdentifier
    }

    var backendStringLiteral: String {
        debugDescription
    }

    var isValidBackendPackageName: Bool {
        let pattern = #"^(@[a-z0-9][a-z0-9._~-]*/)?[a-z0-9][a-z0-9._~-]*$"#
        return range(of: pattern, options: .regularExpression) != nil
    }

    private var backendIdentifier: String {
        let keywords: Set = [
            "any", "as", "boolean", "break", "case", "class", "const", "continue", "default",
            "delete", "do", "else", "enum", "export", "extends", "false", "for", "from", "function",
            "if", "implements", "import", "in", "interface", "let", "new", "null", "number", "object",
            "of", "package", "private", "protected", "public", "return", "string", "super", "this",
            "true", "type", "undefined", "unknown", "var", "void", "while", "with"
        ]
        return keywords.contains(self) ? "\(self)_" : self
    }

    private var backendIdentifierWithValidLeadingCharacter: String {
        first?.isNumber == true ? "_\(self)" : self
    }
}

extension ApiTypeSchema {
    var backendDeclaredTypeID: UUID? {
        switch self {
            case let .object(_, _, _, _, _, uuid),
                 let .stringEnum(_, _, _, uuid, _),
                 let .intEnum(_, _, _, uuid),
                 let .dynamicObject(_, _, _, _, _, _, _, uuid, _),
                 let .reference(_, _, _, uuid, _):
                uuid
            default:
                nil
        }
    }

    func appendBackendDeclaredTypes(to result: inout [ApiTypeSchema], seen: inout Set<UUID>) {
        if case let .reference(_, _, _, _, dataType) = self {
            dataType?.appendBackendDeclaredTypes(to: &result, seen: &seen)
            return
        }
        if let id = backendDeclaredTypeID, seen.insert(id).inserted {
            result.append(self)
        }
        switch self {
            case let .object(_, properties, _, _, _, _):
                for property in properties where property.publishedAsField {
                    property.dataType.appendBackendDeclaredTypes(to: &result, seen: &seen)
                }
            case let .dynamicObject(_, _, _, _, objectTypes, _, _, _, extraProperties):
                for objectType in objectTypes {
                    objectType.objectType.appendBackendDeclaredTypes(to: &result, seen: &seen)
                }
                for property in extraProperties where property.publishedAsField {
                    property.dataType.appendBackendDeclaredTypes(to: &result, seen: &seen)
                }
            case let .array(type),
                 let .keyedByString(type, _):
                type.appendBackendDeclaredTypes(to: &result, seen: &seen)
            case let .genericReference(_, types):
                for type in types {
                    type.appendBackendDeclaredTypes(to: &result, seen: &seen)
                }
            default:
                break
        }
    }

    var backendExternalTypeName: String? {
        switch self {
            case let .reference(typeName, _, _, _, dataType):
                dataType == nil ? typeName : dataType?.backendExternalTypeName
            case let .genericReference(typeName, _):
                typeName
            case let .array(type),
                 let .keyedByString(type, _):
                type.backendExternalTypeName
            case let .object(_, properties, _, _, _, _):
                properties.lazy.compactMap(\.dataType.backendExternalTypeName).first
            default:
                nil
        }
    }
}

extension ApiOperation {
    var backendDataTypes: [ApiTypeSchema] {
        [request.dataType, response.dataType].compactMap(\.self)
    }
}
