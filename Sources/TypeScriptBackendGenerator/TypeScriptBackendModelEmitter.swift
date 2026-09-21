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
            parseNarrowInteger,
            parseURL,
            serializeDate,
            serializeURL,
            uint8ArrayToBase64
        } from "./runtime.js";

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
            let optional = property.required ? encoded : "(\(value) == null ? \(value) : \(encoded))"
            return "\(property.rawName.backendStringLiteral): \(optional),"
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
                 .uint,
                 .int64,
                 .uint64:
                "bigint"
            case .int8,
                 .int16,
                 .int32,
                 .uint8,
                 .uint16,
                 .uint32,
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
            case .uuid:
                return "z.string().refine((value) => isValidUUID(value))"
            case .string:
                return "z.string()"
            case .timelessDate:
                return "z.string().refine((value) => isValidCalendarDate(value))"
            case .time:
                return "z.string().refine((value) => isValidLocalTime(value))"
            case .bool:
                return "z.boolean()"
            case .int,
                 .uint,
                 .int64,
                 .uint64:
                let bounds = integerBounds(for: dataType)
                return "z.bigint().refine((value) => value >= \(bounds.minimum)n && value <= \(bounds.maximum)n)"
            case .int8,
                 .int16,
                 .int32,
                 .uint8,
                 .uint16,
                 .uint32:
                let bounds = integerBounds(for: dataType)
                return "z.union([z.number(), z.bigint()]).transform((value) => parseNarrowInteger(value, \(bounds.minimum)n, \(bounds.maximum)n))"
            case .double:
                return "z.union([z.number(), z.bigint()]).transform((value) => parseDouble(value))"
            case .date:
                return "z.string().refine((value) => isValidISODate(value))"
            case .url:
                return "z.string().refine((value) => isValidURL(value))"
            case .binary:
                return "z.string().refine((value) => isValidBase64(value))"
            case let .array(type):
                return "z.array(\(schemaExpression(for: type)))"
            case let .keyedByString(type, isOptional):
                let valueSchema = schemaExpression(for: type) + (isOptional ? ".nullable()" : "")
                return "z.record(z.string(), \(valueSchema))"
            case let .object(typeName, _, _, _, _, _),
                 let .stringEnum(typeName, _, _, _, _),
                 let .intEnum(typeName, _, _, _),
                 let .dynamicObject(typeName, _, _, _, _, _, _, _, _):
                return "\(typeName.backendTypeName)WireSchema()"
            case let .reference(typeName, _, _, _, dataType):
                return dataType.map(schemaExpression(for:)) ?? "\(typeName.backendTypeName)WireSchema()"
            case let .genericReference(typeName, _):
                return "\(typeName.backendTypeName)WireSchema()"
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
                expression = "\(schemaExpression(for: dataType)).parse(\(value)) as \(typeDeclaration(for: dataType))"
            case .date:
                expression = "parseDate(\(value))"
            case .url:
                expression = "parseURL(\(value))"
            case .binary:
                expression = "base64ToUint8Array(\(value))"
            case let .array(type):
                expression = "(\(value) as unknown[]).map((item) => \(decodeExpression(for: type, value: "item")))"
            case let .keyedByString(type, isOptional):
                let item = decodeExpression(for: type, value: "item", optional: isOptional)
                expression = "Object.fromEntries(Object.entries(\(value) as Record<string, unknown>).map(([key, item]) => [key, \(item)])) as \(typeDeclaration(for: dataType))"
            case let .object(typeName, _, _, _, _, _),
                 let .stringEnum(typeName, _, _, _, _),
                 let .intEnum(typeName, _, _, _),
                 let .dynamicObject(typeName, _, _, _, _, _, _, _, _):
                expression = "decode\(typeName.backendTypeName)(\(value))"
            case let .reference(typeName, _, _, _, dataType):
                expression = dataType.map { decodeExpression(for: $0, value: value) } ?? "decode\(typeName.backendTypeName)(\(value))"
            case .genericReference:
                expression = "\(value) as \(typeDeclaration(for: dataType))"
        }
        return optional ? "(\(value) == null ? \(value) : \(expression))" : expression
    }

    func encodeExpression(for dataType: ApiTypeSchema, value: String) -> String {
        switch dataType {
            case .date:
                return "serializeDate(\(value))"
            case .url:
                return "serializeURL(\(value))"
            case .binary:
                return "uint8ArrayToBase64(\(value))"
            case let .array(type):
                return "\(value).map((item) => \(encodeExpression(for: type, value: "item")))"
            case let .keyedByString(type, isOptional):
                let itemValue = "item as \(typeDeclaration(for: type))"
                let encoded = encodeExpression(for: type, value: itemValue)
                let item = isOptional ? "(item == null ? item : \(encoded))" : encoded
                return "Object.fromEntries(Object.entries(\(value)).map(([key, item]) => [key, \(item)]))"
            case let .object(typeName, _, _, _, _, _),
                 let .stringEnum(typeName, _, _, _, _),
                 let .intEnum(typeName, _, _, _),
                 let .dynamicObject(typeName, _, _, _, _, _, _, _, _):
                return "encode\(typeName.backendTypeName)(\(value))"
            case let .reference(typeName, _, _, _, dataType):
                return dataType.map { encodeExpression(for: $0, value: value) } ?? "encode\(typeName.backendTypeName)(\(value))"
            default:
                return value
        }
    }

    func encodeRootExpression(for dataType: ApiTypeSchema, value: String) -> String {
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
                "\(schemaExpression(for: dataType)).parse(\(value))"
            case .date,
                 .url,
                 .binary:
                "\(schemaExpression(for: dataType)).parse(\(encodeExpression(for: dataType, value: value)))"
            case .array,
                 .keyedByString:
                "\(schemaExpression(for: dataType)).parse(\(encodeExpression(for: dataType, value: value)))"
            case let .reference(_, _, _, _, resolved):
                resolved.map { encodeRootExpression(for: $0, value: value) } ?? encodeExpression(for: dataType, value: value)
            default:
                encodeExpression(for: dataType, value: value)
        }
    }

    private func integerBounds(for dataType: ApiTypeSchema) -> (minimum: String, maximum: String) {
        switch dataType {
            case .int,
                 .int64:
                ("-9223372036854775808", "9223372036854775807")
            case .uint,
                 .uint64:
                ("0", "18446744073709551615")
            case .int8:
                ("-128", "127")
            case .int16:
                ("-32768", "32767")
            case .int32:
                ("-2147483648", "2147483647")
            case .uint8:
                ("0", "255")
            case .uint16:
                ("0", "65535")
            case .uint32:
                ("0", "4294967295")
            default:
                fatalError("Not an integer data type")
        }
    }
}
