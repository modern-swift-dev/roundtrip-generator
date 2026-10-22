import Foundation
import GeneratorBuilder
import GeneratorModels

struct TypeScriptBackendModelEmitter {
    /// Whether a value being decoded has already been parsed by an enclosing wire schema.
    enum WireValue {
        case unvalidated
        case validated
    }

    /// Which schema validates a value being encoded.
    enum EncodeValidation {
        /// The encoder parses its own output.
        case encoder
        /// An enclosing wire schema parses the output, so nested encoders skip their own parse.
        case enclosingSchema
    }

    let dataTypes: [ApiTypeSchema]

    func source() -> String {
        let schemas = TypeScriptBackendSchemaCache()
        let declarations = [
            dataTypes.map { declaration(for: $0, schemas: schemas) }.joined(separator: "\n\n"),
            schemas.source()
        ]
        .filter { !$0.isEmpty }
        .joined(separator: "\n\n")
        let runtimeImports = [
            "base64ToUint8Array", "decodeValidBase64", "isValidBase64", "isValidCalendarDate", "isValidISODate",
            "isValidLocalTime", "isValidURL", "isValidUUID", "lazySchema", "parseDate", "parseDouble",
            "parseNarrowInteger", "parseURL", "serializeDate", "serializeURL", "uint8ArrayToBase64"
        ]
        .filter(declarations.contains)
        .joined(separator: ",\n    ")
        return """
        // Generated code. Do not edit.

        import { z } from "zod";
        import {
            \(runtimeImports)
        } from "./runtime.js";

        export interface PagedResults<T> {
            results: T[];
            next?: string | null;
            count?: number | null;
        }

        export function PagedResultsWireSchema<T extends z.ZodTypeAny>(itemSchema: T) {
            return z.object({
                results: z.array(itemSchema),
                next: z.string().nullable().optional(),
                count: z.union([z.number(), z.bigint()])
                    .transform((value) => Number(value))
                    .refine((value) => Number.isSafeInteger(value) && value >= 0)
                    .nullable()
                    .optional()
            });
        }

        \(declarations)
        """
    }

    private func declaration(for dataType: ApiTypeSchema, schemas: TypeScriptBackendSchemaCache) -> String {
        switch dataType {
            case let .object(typeName, properties, _, _, _, _):
                objectDeclaration(typeName: typeName, properties: properties, schemas: schemas)
            case let .stringEnum(typeName, values, _, _, _):
                stringEnumDeclaration(typeName: typeName, values: values.map(\.rawName))
            case let .intEnum(typeName, values, _, _):
                intEnumDeclaration(typeName: typeName, values: values.map(\.rawValue))
            case let .dynamicObject(typeName, objectTypePropertyName, objectDataPropertyName, alternateObjectDataPropertyName, objectTypes, _, _, _, extraProperties):
                dynamicObjectDeclaration(
                    typeName: typeName,
                    objectTypePropertyName: objectTypePropertyName,
                    objectDataPropertyName: objectDataPropertyName,
                    alternateObjectDataPropertyName: alternateObjectDataPropertyName,
                    objectTypes: objectTypes,
                    extraProperties: extraProperties.filter(\.publishedAsField),
                    schemas: schemas,
                )
            default:
                ""
        }
    }

    private func objectDeclaration(typeName: String, properties: [ApiModelProperty], schemas: TypeScriptBackendSchemaCache) -> String {
        let publishedProperties = properties.filter(\.publishedAsField)
        let encodeParameterName = publishedProperties.isEmpty ? "_value" : "value"
        let decodeParameterName = publishedProperties.isEmpty ? "_value" : "value"
        let decodedObject = publishedProperties.isEmpty ? "" : "const object = value as Record<string, unknown>;\n    "
        let interfaceFields = publishedProperties.map { property in
            let patchable = property.dataType.isBackendPatchableValue
            let optional = property.required && !patchable ? "" : "?"
            let nullable = property.presence == .optionalNullable && !patchable ? " | null" : ""
            return "\(property.propertyName.backendPropertyName)\(optional): \(typeDeclaration(for: property.dataType))\(nullable);"
        }.joined(separator: "\n")
        let schemaFields = publishedProperties.map { property in
            let optional = property.dataType.isBackendPatchableValue
                ? ".optional()"
                : property.required ? "" : property.presence == .optionalNullable ? ".nullable().optional()" : ".optional()"
            return "\(property.rawName.backendStringLiteral): \(schemaExpression(for: property))\(optional),"
        }.joined(separator: "\n")
        let decodedFields = publishedProperties.map { property in
            let value = "object[\(property.rawName.backendStringLiteral)]"
            let decoded = decodeExpression(for: property.dataType, value: value, wireValue: .validated, schemas: schemas)
            let expression: String = if property.dataType.isBackendPatchableValue {
                "(\(value) === undefined ? undefined : \(decoded))"
            } else if property.presence == .optionalNonNullable {
                "(\(value) === undefined ? undefined : \(decoded))"
            } else {
                decodeExpression(for: property.dataType, value: value, optional: !property.required, wireValue: .validated, schemas: schemas)
            }
            return "\(property.propertyName.backendPropertyName): \(expression),"
        }.joined(separator: "\n")
        let encodedFields = publishedProperties.map { property in
            let value = "value.\(property.propertyName.backendPropertyName)"
            let encoded = encodeExpression(for: property.dataType, value: value, validation: .enclosingSchema, schemas: schemas)
            let optional: String = if property.dataType.isBackendPatchableValue {
                "(\(value) === undefined || String(\(value).state) === \"unmodified\" ? undefined : \(encoded))"
            } else if property.presence == .optionalNonNullable {
                "(\(value) === undefined ? undefined : \(encoded))"
            } else {
                property.required ? encoded : "(\(value) == null ? \(value) : \(encoded))"
            }
            return "\(property.rawName.backendStringLiteral): \(optional),"
        }.joined(separator: "\n")
        return """
        export interface \(typeName.backendTypeName) {
        \(interfaceFields.prepad())
        }

        export const \(typeName.backendTypeName)WireSchema = lazySchema(() => z.object({
        \(schemaFields.prepad())
        }));

        export function decode\(typeName.backendTypeName)(value: unknown): \(typeName.backendTypeName) {
            return decodeValidated\(typeName.backendTypeName)(\(typeName.backendTypeName)WireSchema().parse(value));
        }

        /** Decodes a value that `\(typeName.backendTypeName)WireSchema` has already parsed. */
        export function decodeValidated\(typeName.backendTypeName)(\(decodeParameterName): unknown): \(typeName.backendTypeName) {
            \(decodedObject)return {
        \(decodedFields.prepad(2))
            };
        }

        export function encode\(typeName.backendTypeName)(value: \(typeName.backendTypeName)): unknown {
            return \(typeName.backendTypeName)WireSchema().parse(encodeUnvalidated\(typeName.backendTypeName)(value));
        }

        /** Encodes without validating; the caller must parse the result with a schema containing `\(typeName.backendTypeName)WireSchema`. */
        export function encodeUnvalidated\(typeName.backendTypeName)(\(encodeParameterName): \(typeName.backendTypeName)): Record<string, unknown> {
            return {
        \(encodedFields.prepad(2))
            };
        }
        """
    }

    private func stringEnumDeclaration(typeName: String, values: [String]) -> String {
        let literalValues = values.map(\.backendStringLiteral).joined(separator: " | ")
        let schemaValues = values.map(\.backendStringLiteral).joined(separator: ", ")
        return """
        export type \(typeName.backendTypeName) = \(literalValues);

        export const \(typeName.backendTypeName)WireSchema = lazySchema(() => z.enum([\(schemaValues)]));

        export function decode\(typeName.backendTypeName)(value: unknown): \(typeName.backendTypeName) {
            return \(typeName.backendTypeName)WireSchema().parse(value);
        }

        export function encode\(typeName.backendTypeName)(value: \(typeName.backendTypeName)): unknown {
            return \(typeName.backendTypeName)WireSchema().parse(value);
        }
        """
    }

    private func intEnumDeclaration(typeName: String, values: [Int]) -> String {
        let literals = values.flatMap { integerEnumLiterals($0) }
        let literalValues = literals.joined(separator: " | ")
        let schemaValues = literals.map { "z.literal(\($0))" }.joined(separator: ", ")
        let schema = literals.count == 1 ? schemaValues : "z.union([\(schemaValues)])"
        return """
        export type \(typeName.backendTypeName) = \(literalValues);

        export const \(typeName.backendTypeName)WireSchema = lazySchema(() => \(schema));

        export function decode\(typeName.backendTypeName)(value: unknown): \(typeName.backendTypeName) {
            return \(typeName.backendTypeName)WireSchema().parse(value);
        }

        export function encode\(typeName.backendTypeName)(value: \(typeName.backendTypeName)): unknown {
            return \(typeName.backendTypeName)WireSchema().parse(value);
        }
        """
    }

    private func integerEnumLiterals(_ value: Int) -> [String] {
        let maximumSafeInteger = 9_007_199_254_740_991
        let safeIntegerRange = (-maximumSafeInteger ... maximumSafeInteger)
        guard safeIntegerRange.contains(value) else {
            return ["\(value)n"]
        }
        return [String(value), "\(value)n"]
    }

    private func dynamicObjectDeclaration(
        typeName: String,
        objectTypePropertyName: String,
        objectDataPropertyName: String,
        alternateObjectDataPropertyName: String,
        objectTypes: [(objectTypeName: String, objectTypeRawName: String, objectType: ApiTypeSchema)],
        extraProperties: [ApiModelProperty],
        schemas: TypeScriptBackendSchemaCache,
    ) -> String {
        let typeCases = objectTypes.map { objectType in
            let extraFields = extraProperties.map { property in
                let optional = property.required ? "" : "?"
                let nullable = property.presence == .optionalNullable ? " | null" : ""
                return "\(property.propertyName.backendPropertyName)\(optional): \(typeDeclaration(for: property.dataType))\(nullable);"
            }.joined(separator: "\n")
            let extra = extraFields.isEmpty ? "" : "\n\(extraFields)"
            return "{ objectType: \(objectType.objectTypeRawName.backendStringLiteral); payload: \(typeDeclaration(for: objectType.objectType));\(extra) }"
        }.joined(separator: "\n    | ")

        let extraSchemaFields = extraProperties.map { property in
            let optional = property.required ? "" : property.presence == .optionalNullable ? ".nullable().optional()" : ".optional()"
            return "\(property.rawName.backendStringLiteral): \(schemaExpression(for: property.dataType))\(optional),"
        }
        let payloadSchemaFields: [String] = objectDataPropertyName == "__self__"
            ? []
            : [
                "\(objectDataPropertyName.backendStringLiteral): z.unknown().optional(),",
                objectDataPropertyName == alternateObjectDataPropertyName ? "" : "\(alternateObjectDataPropertyName.backendStringLiteral): z.unknown().optional(),"
            ].filter { !$0.isEmpty }
        let variantSchemas = objectTypes.map { objectType in
            let fields = [
                "\(objectTypePropertyName.backendStringLiteral): z.literal(\(objectType.objectTypeRawName.backendStringLiteral)),"
            ] + payloadSchemaFields + extraSchemaFields
            let passthrough = objectDataPropertyName == "__self__" ? ".passthrough()" : ""
            return "z.object({\n\(fields.joined(separator: "\n").prepad())\n})\(passthrough)"
        }.joined(separator: ",\n")
        let wireSchema = objectTypes.count == 1
            ? variantSchemas
            : "z.discriminatedUnion(\(objectTypePropertyName.backendStringLiteral), [\n\(variantSchemas.prepad())\n])"

        let decoderCases = objectTypes.map { objectType in
            let payloadSource = objectDataPropertyName == "__self__"
                ? "value"
                : "(object[\(objectDataPropertyName.backendStringLiteral)] ?? object[\(alternateObjectDataPropertyName.backendStringLiteral)])"
            let payload = decodeExpression(for: objectType.objectType, value: payloadSource, schemas: schemas)
            let extras = extraProperties.map { property in
                let value = "object[\(property.rawName.backendStringLiteral)]"
                let decoded = decodeExpression(for: property.dataType, value: value, optional: property.presence == .optionalNullable, wireValue: .validated, schemas: schemas)
                let expression = property.presence == .optionalNonNullable
                    ? "(\(value) === undefined ? undefined : \(decoded))"
                    : decoded
                return "\(property.propertyName.backendPropertyName): \(expression),"
            }.joined(separator: "\n")
            return """
            case \(objectType.objectTypeRawName.backendStringLiteral):
                return {
                    objectType: \(objectType.objectTypeRawName.backendStringLiteral),
                    payload: \(payload),
            \(extras.prepad(2))
                };
            """
        }.joined(separator: "\n")

        let encoderCases = objectTypes.map { objectType in
            let extras = extraProperties.map { property in
                let value = "value.\(property.propertyName.backendPropertyName)"
                let encoded = encodeExpression(for: property.dataType, value: value, validation: .enclosingSchema, schemas: schemas)
                if property.required {
                    return "output[\(property.rawName.backendStringLiteral)] = \(encoded);"
                }
                let expression = property.presence == .optionalNullable ? "\(value) === null ? null : \(encoded)" : encoded
                return "if (\(value) !== undefined) { output[\(property.rawName.backendStringLiteral)] = \(expression); }"
            }.joined(separator: "\n")
            let payload = "\(cachedSchemaExpression(for: objectType.objectType, schemas: schemas)).parse(\(encodeExpression(for: objectType.objectType, value: "value.payload", validation: .enclosingSchema, schemas: schemas)))"
            let payloadLine = objectDataPropertyName == "__self__"
                ? "Object.assign(output, \(payload));"
                : "output[\(objectDataPropertyName.backendStringLiteral)] = \(payload);"
            return """
            case \(objectType.objectTypeRawName.backendStringLiteral):
                output[\(objectTypePropertyName.backendStringLiteral)] = value.objectType;
            \(extras.prepad())
                \(payloadLine)
                return \(typeName.backendTypeName)WireSchema().parse(output);
            """
        }.joined(separator: "\n")

        return """
        export type \(typeName.backendTypeName) =
            | \(typeCases);

        export const \(typeName.backendTypeName)WireSchema = lazySchema(() => \(wireSchema));

        export function decode\(typeName.backendTypeName)(value: unknown): \(typeName.backendTypeName) {
            const object = \(typeName.backendTypeName)WireSchema().parse(value) as Record<string, unknown>;
            const objectType = object[\(objectTypePropertyName.backendStringLiteral)];
            switch (objectType) {
        \(decoderCases.prepad())
                default:
                    throw new Error(`Unknown \(typeName.backendTypeName) discriminator: ${String(objectType)}`);
            }
        }

        export function encode\(typeName.backendTypeName)(value: \(typeName.backendTypeName)): unknown {
            const output: Record<string, unknown> = {};
            switch (value.objectType) {
        \(encoderCases.prepad())
            }
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
            case let .reference(_, _, _, _, dataType):
                dataType.map(typeDeclaration(for:)) ?? "unknown"
            case let .genericReference(typeName, types):
                if typeName == "PatchableValue", let valueType = types.first {
                    "{ state: \"unmodified\" } | { state: \"modified\"; value: \(typeDeclaration(for: valueType)) | null }"
                } else if typeName == "PagedResults", let valueType = types.first {
                    "PagedResults<\(typeDeclaration(for: valueType))>"
                } else {
                    "unknown"
                }
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
            case let .reference(_, _, _, _, dataType):
                return dataType.map(schemaExpression(for:)) ?? "z.unknown()"
            case let .genericReference(typeName, types):
                if typeName == "PatchableValue", let valueType = types.first {
                    return "\(schemaExpression(for: valueType)).nullable()"
                } else if typeName == "PagedResults", let valueType = types.first {
                    return "PagedResultsWireSchema(\(schemaExpression(for: valueType)))"
                }
                return "z.unknown()"
        }
    }

    private func schemaExpression(for property: ApiModelProperty) -> String {
        switch property.constraint {
            case let .booleanLiteral(value):
                "z.literal(\(value))"
            case nil:
                schemaExpression(for: property.dataType)
        }
    }

    /// A schema expression that is cheap to evaluate per call: named types are already shared, everything else goes through `schemas`.
    private func cachedSchemaExpression(for dataType: ApiTypeSchema, schemas: TypeScriptBackendSchemaCache) -> String {
        switch dataType {
            case .object,
                 .stringEnum,
                 .intEnum,
                 .dynamicObject:
                schemaExpression(for: dataType)
            case let .reference(_, _, _, _, resolved?):
                cachedSchemaExpression(for: resolved, schemas: schemas)
            default:
                schemas.reference(to: schemaExpression(for: dataType))
        }
    }

    func decodeExpression(for dataType: ApiTypeSchema, value: String, optional: Bool = false, wireValue: WireValue = .unvalidated, schemas: TypeScriptBackendSchemaCache) -> String {
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
                expression = switch wireValue {
                    case .unvalidated: "\(cachedSchemaExpression(for: dataType, schemas: schemas)).parse(\(value)) as \(typeDeclaration(for: dataType))"
                    case .validated: "\(value) as \(typeDeclaration(for: dataType))"
                }
            case .date,
                 .url,
                 .binary:
                expression = decodeStringEncodedExpression(for: dataType, value: value, wireValue: wireValue)
            case let .array(type):
                expression = "(\(value) as unknown[]).map((item) => \(decodeExpression(for: type, value: "item", wireValue: wireValue, schemas: schemas)))"
            case let .keyedByString(type, isOptional):
                let item = decodeExpression(for: type, value: "item", optional: isOptional, wireValue: wireValue, schemas: schemas)
                expression = "Object.fromEntries(Object.entries(\(value) as Record<string, unknown>).map(([key, item]) => [key, \(item)])) as \(typeDeclaration(for: dataType))"
            case .object,
                 .stringEnum,
                 .intEnum,
                 .dynamicObject:
                expression = decodeNamedTypeExpression(for: dataType, value: value, wireValue: wireValue)
            case let .reference(_, _, _, _, dataType):
                expression = dataType.map { decodeExpression(for: $0, value: value, wireValue: wireValue, schemas: schemas) } ?? "\(value) as unknown"
            case let .genericReference(typeName, types):
                if typeName == "PatchableValue", let valueType = types.first {
                    let patchValue = switch wireValue {
                        case .unvalidated: "\(cachedSchemaExpression(for: dataType, schemas: schemas)).parse(\(value))"
                        case .validated: value
                    }
                    let decodedValue = "patchValue == null ? null : \(decodeExpression(for: valueType, value: "patchValue", wireValue: .validated, schemas: schemas))"
                    expression = "(() => { const patchValue = \(patchValue); return { state: \"modified\", value: \(decodedValue) }; })()"
                } else if typeName == "PagedResults", let valueType = types.first {
                    let decodedItem = decodeExpression(for: valueType, value: "item", wireValue: .validated, schemas: schemas)
                    let pagedResults = switch wireValue {
                        case .unvalidated: "\(cachedSchemaExpression(for: dataType, schemas: schemas)).parse(\(value))"
                        case .validated: value
                    }
                    expression = "(() => { const pagedResultsObject = \(pagedResults) as { results: unknown[]; next?: string | null; count?: number | null }; return { results: pagedResultsObject.results.map((item) => \(decodedItem)), next: pagedResultsObject.next, count: pagedResultsObject.count }; })()"
                } else {
                    expression = "\(value) as \(typeDeclaration(for: dataType))"
                }
        }
        return optional ? "(\(value) == null ? \(value) : \(expression))" : expression
    }

    private func decodeStringEncodedExpression(for dataType: ApiTypeSchema, value: String, wireValue: WireValue) -> String {
        switch (dataType, wireValue) {
            case (.date, .unvalidated):
                "parseDate(\(value))"
            case (.date, .validated):
                "new Date(\(value) as string)"
            case (.url, .unvalidated):
                "parseURL(\(value))"
            case (.url, .validated):
                "new URL(\(value) as string)"
            case (.binary, .unvalidated):
                "base64ToUint8Array(\(value))"
            case (.binary, .validated):
                "decodeValidBase64(\(value) as string)"
            default:
                fatalError("Not a string-encoded data type")
        }
    }

    private func decodeNamedTypeExpression(for dataType: ApiTypeSchema, value: String, wireValue: WireValue) -> String {
        switch (dataType, wireValue) {
            case let (.object(typeName, _, _, _, _, _), .validated):
                "decodeValidated\(typeName.backendTypeName)(\(value))"
            case let (.stringEnum(typeName, _, _, _, _), .validated),
                 let (.intEnum(typeName, _, _, _), .validated):
                "\(value) as \(typeName.backendTypeName)"
            case let (.object(typeName, _, _, _, _, _), .unvalidated),
                 let (.stringEnum(typeName, _, _, _, _), .unvalidated),
                 let (.intEnum(typeName, _, _, _), .unvalidated),
                 // An enclosing schema leaves a dynamic object's payload unvalidated, so its decoder always parses.
                 let (.dynamicObject(typeName, _, _, _, _, _, _, _, _), _):
                "decode\(typeName.backendTypeName)(\(value))"
            default:
                fatalError("Not a named data type")
        }
    }

    func encodeExpression(for dataType: ApiTypeSchema, value: String, validation: EncodeValidation = .encoder, schemas: TypeScriptBackendSchemaCache) -> String {
        switch dataType {
            case .date:
                return "serializeDate(\(value))"
            case .url:
                return "serializeURL(\(value))"
            case .binary:
                return "uint8ArrayToBase64(\(value))"
            case let .array(type):
                return "\(value).map((item) => \(encodeExpression(for: type, value: "item", validation: validation, schemas: schemas)))"
            case let .keyedByString(type, isOptional):
                let itemValue = "(item as \(typeDeclaration(for: type)))"
                let encoded = encodeExpression(for: type, value: itemValue, validation: validation, schemas: schemas)
                let item = isOptional ? "(item == null ? item : \(encoded))" : encoded
                return "Object.fromEntries(Object.entries(\(value)).map(([key, item]) => [key, \(item)]))"
            case let .object(typeName, _, _, _, _, _):
                return switch validation {
                    case .encoder: "encode\(typeName.backendTypeName)(\(value))"
                    case .enclosingSchema: "encodeUnvalidated\(typeName.backendTypeName)(\(value))"
                }
            case let .stringEnum(typeName, _, _, _, _),
                 let .intEnum(typeName, _, _, _):
                return switch validation {
                    case .encoder: "encode\(typeName.backendTypeName)(\(value))"
                    case .enclosingSchema: value
                }
            case let .dynamicObject(typeName, _, _, _, _, _, _, _, _):
                // An enclosing schema leaves the payload unvalidated, so the encoder always parses.
                return "encode\(typeName.backendTypeName)(\(value))"
            case let .reference(_, _, _, _, dataType):
                return dataType.map { encodeExpression(for: $0, value: value, validation: validation, schemas: schemas) } ?? value
            case let .genericReference(typeName, types) where typeName == "PatchableValue":
                guard let valueType = types.first else {
                    return value
                }
                let encodedValue = encodeExpression(for: valueType, value: "\(value).value", validation: validation, schemas: schemas)
                return "(\(value).state === \"unmodified\" ? undefined : \(value).value == null ? null : \(encodedValue))"
            case let .genericReference(typeName, types) where typeName == "PagedResults":
                guard let valueType = types.first else {
                    return value
                }
                let encodedItem = encodeExpression(for: valueType, value: "item", validation: .enclosingSchema, schemas: schemas)
                let pagedResults = "{ results: \(value).results.map((item) => \(encodedItem)), next: \(value).next, count: \(value).count }"
                return switch validation {
                    case .encoder: "\(cachedSchemaExpression(for: dataType, schemas: schemas)).parse(\(pagedResults))"
                    case .enclosingSchema: pagedResults
                }
            default:
                return value
        }
    }

    func encodeRootExpression(for dataType: ApiTypeSchema, value: String, schemas: TypeScriptBackendSchemaCache) -> String {
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
                "\(cachedSchemaExpression(for: dataType, schemas: schemas)).parse(\(value))"
            case .date,
                 .url,
                 .binary:
                "\(cachedSchemaExpression(for: dataType, schemas: schemas)).parse(\(encodeExpression(for: dataType, value: value, schemas: schemas)))"
            case .array,
                 .keyedByString:
                "\(cachedSchemaExpression(for: dataType, schemas: schemas)).parse(\(encodeExpression(for: dataType, value: value, validation: .enclosingSchema, schemas: schemas)))"
            case let .reference(_, _, _, _, resolved):
                resolved.map { encodeRootExpression(for: $0, value: value, schemas: schemas) } ?? encodeExpression(for: dataType, value: value, schemas: schemas)
            case let .genericReference(typeName, _) where typeName == "PatchableValue":
                "\(cachedSchemaExpression(for: dataType, schemas: schemas)).parse(\(encodeExpression(for: dataType, value: value, validation: .enclosingSchema, schemas: schemas)))"
            default:
                encodeExpression(for: dataType, value: value, schemas: schemas)
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
