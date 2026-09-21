import Foundation
import GeneratorBuilder
import GeneratorModels

struct TypeScriptBackendModelEmitter {
    let dataTypes: [ApiTypeSchema]

    func source() -> String {
        let declarations = dataTypes.map { declaration(for: $0) }.joined(separator: "\n\n")
        return """
        // Generated code. Do not edit.

        import { z } from "zod";

        \(declarations)
        """
    }

    private func declaration(for dataType: ApiTypeSchema) -> String {
        switch dataType {
            case let .object(typeName, properties, _, _, _, _):
                objectDeclaration(typeName: typeName, properties: properties)
            case let .stringEnum(typeName, values, _, _, _):
                enumDeclaration(typeName: typeName, values: values.map(\.rawName))
            case let .intEnum(typeName, values, _, _):
                enumDeclaration(typeName: typeName, values: values.map { String($0.rawValue) })
            default:
                ""
        }
    }

    private func objectDeclaration(typeName: String, properties: [ApiModelProperty]) -> String {
        let publishedProperties = properties.filter(\.publishedAsField)
        let interfaceFields = publishedProperties.map { property in
            let optional = property.required ? "" : "?"
            let nullable = property.required ? "" : " | null"
            return "\(property.propertyName.backendPropertyName)\(optional): \(typeDeclaration(for: property.dataType))\(nullable);"
        }.joined(separator: "\n")
        let schemaFields = publishedProperties.map { property in
            let optional = property.required ? "" : ".nullable().optional()"
            return "\(property.rawName.backendStringLiteral): \(schemaExpression(for: property.dataType))\(optional),"
        }.joined(separator: "\n")
        let decodedFields = publishedProperties.map { property in
            let value = "object[\(property.rawName.backendStringLiteral)]"
            return "\(property.propertyName.backendPropertyName): \(decodeExpression(for: property.dataType, value: value, optional: !property.required)),"
        }.joined(separator: "\n")
        let encodedFields = publishedProperties.map { property in
            let value = "value.\(property.propertyName.backendPropertyName)"
            let encoded = encodeExpression(for: property.dataType, value: value)
            return "\(property.rawName.backendStringLiteral): \(encoded),"
        }.joined(separator: "\n")
        return """
        export interface \(typeName.backendTypeName) {
        \(interfaceFields.prepad())
        }

        export function \(typeName.backendTypeName)WireSchema() {
            return z.object({
        \(schemaFields.prepad(2))
            });
        }

        export function decode\(typeName.backendTypeName)(value: unknown): \(typeName.backendTypeName) {
            const object = \(typeName.backendTypeName)WireSchema().parse(value) as Record<string, unknown>;
            return {
        \(decodedFields.prepad(2))
            };
        }

        export function encode\(typeName.backendTypeName)(value: \(typeName.backendTypeName)): unknown {
            return \(typeName.backendTypeName)WireSchema().parse({
        \(encodedFields.prepad(2))
            });
        }
        """
    }

    private func enumDeclaration(typeName: String, values: [String]) -> String {
        let literalValues = values.map(\.backendStringLiteral).joined(separator: " | ")
        let schemaValues = values.map(\.backendStringLiteral).joined(separator: ", ")
        return """
        export type \(typeName.backendTypeName) = \(literalValues);

        export function \(typeName.backendTypeName)WireSchema() {
            return z.enum([\(schemaValues)]);
        }

        export function decode\(typeName.backendTypeName)(value: unknown): \(typeName.backendTypeName) {
            return \(typeName.backendTypeName)WireSchema().parse(value);
        }

        export function encode\(typeName.backendTypeName)(value: \(typeName.backendTypeName)): unknown {
            return \(typeName.backendTypeName)WireSchema().parse(value);
        }
        """
    }

    func typeDeclaration(for dataType: ApiTypeSchema) -> String {
        switch dataType {
            case .uuid,
                 .string,
                 .timelessDate,
                 .time:
                "string"
            case .bool:
                "boolean"
            case .int,
                 .int8,
                 .int16,
                 .int32,
                 .int64,
                 .uint,
                 .uint8,
                 .uint16,
                 .uint32,
                 .uint64,
                 .double:
                "number"
            case .date:
                "Date"
            case .url:
                "URL"
            case .binary:
                "Uint8Array"
            case let .array(type):
                "\(typeDeclaration(for: type))[]"
            case let .keyedByString(type, isOptional):
                "Record<string, \(typeDeclaration(for: type))\(isOptional ? " | null" : "")>"
            case let .object(typeName, _, _, _, _, _),
                 let .stringEnum(typeName, _, _, _, _),
                 let .intEnum(typeName, _, _, _),
                 let .dynamicObject(typeName, _, _, _, _, _, _, _, _):
                typeName.backendTypeName
            case let .reference(typeName, _, _, _, dataType):
                dataType.map(typeDeclaration(for:)) ?? typeName.backendTypeName
            case let .genericReference(typeName, _):
                typeName.backendTypeName
        }
    }

    func schemaExpression(for dataType: ApiTypeSchema) -> String {
        switch dataType {
            case .uuid,
                 .string,
                 .timelessDate,
                 .time:
                "z.string()"
            case .bool:
                "z.boolean()"
            case .int,
                 .int8,
                 .int16,
                 .int32,
                 .int64,
                 .uint,
                 .uint8,
                 .uint16,
                 .uint32,
                 .uint64,
                 .double:
                "z.number()"
            case .date,
                 .url,
                 .binary:
                "z.unknown()"
            case let .array(type):
                "z.array(\(schemaExpression(for: type)))"
            case let .keyedByString(type, _):
                "z.record(z.string(), \(schemaExpression(for: type)))"
            case let .object(typeName, _, _, _, _, _),
                 let .stringEnum(typeName, _, _, _, _),
                 let .intEnum(typeName, _, _, _),
                 let .dynamicObject(typeName, _, _, _, _, _, _, _, _):
                "\(typeName.backendTypeName)WireSchema()"
            case let .reference(typeName, _, _, _, dataType):
                dataType.map(schemaExpression(for:)) ?? "\(typeName.backendTypeName)WireSchema()"
            case let .genericReference(typeName, _):
                "\(typeName.backendTypeName)WireSchema()"
        }
    }

    func decodeExpression(for dataType: ApiTypeSchema, value: String, optional: Bool = false) -> String {
        let expression: String
        switch dataType {
            case .uuid,
                 .string,
                 .timelessDate,
                 .time,
                 .bool,
                 .int,
                 .int8,
                 .int16,
                 .int32,
                 .int64,
                 .uint,
                 .uint8,
                 .uint16,
                 .uint32,
                 .uint64,
                 .double:
                expression = "\(value) as \(typeDeclaration(for: dataType))"
            case let .array(type):
                expression = "(\(value) as unknown[]).map((item) => \(decodeExpression(for: type, value: "item")))"
            case let .keyedByString(type, isOptional):
                let item = decodeExpression(for: type, value: "item", optional: isOptional)
                expression = "Object.fromEntries(Object.entries(\(value) as Record<string, unknown>).map(([key, item]) => [key, \(item)]))"
            case let .object(typeName, _, _, _, _, _),
                 let .stringEnum(typeName, _, _, _, _),
                 let .intEnum(typeName, _, _, _),
                 let .dynamicObject(typeName, _, _, _, _, _, _, _, _):
                expression = "decode\(typeName.backendTypeName)(\(value))"
            case let .reference(typeName, _, _, _, dataType):
                expression = dataType.map { decodeExpression(for: $0, value: value) } ?? "decode\(typeName.backendTypeName)(\(value))"
            case .date,
                 .url,
                 .binary,
                 .genericReference:
                expression = "\(value) as \(typeDeclaration(for: dataType))"
        }
        return optional ? "(\(value) == null ? \(value) : \(expression))" : expression
    }

    func encodeExpression(for dataType: ApiTypeSchema, value: String) -> String {
        switch dataType {
            case let .array(type):
                "(\(value) as unknown[]).map((item) => \(encodeExpression(for: type, value: "item")))"
            case let .keyedByString(type, _):
                "Object.fromEntries(Object.entries(\(value)).map(([key, item]) => [key, \(encodeExpression(for: type, value: "item"))]))"
            case let .object(typeName, _, _, _, _, _),
                 let .stringEnum(typeName, _, _, _, _),
                 let .intEnum(typeName, _, _, _),
                 let .dynamicObject(typeName, _, _, _, _, _, _, _, _):
                "encode\(typeName.backendTypeName)(\(value))"
            case let .reference(typeName, _, _, _, dataType):
                dataType.map { encodeExpression(for: $0, value: value) } ?? "encode\(typeName.backendTypeName)(\(value))"
            default:
                value
        }
    }
}
