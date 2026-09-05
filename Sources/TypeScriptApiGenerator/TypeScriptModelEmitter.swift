import Foundation
import GeneratorBuilder
import GeneratorModels

struct TypeScriptModelEmitter {
    let dataTypes: [ApiTypeSchema]
    let options: TypeScriptGeneratorOptions
    let codecPrefix: String

    init(dataTypes: [ApiTypeSchema], options: TypeScriptGeneratorOptions, codecPrefix: String = "") {
        self.dataTypes = dataTypes
        self.options = options
        self.codecPrefix = codecPrefix
    }

    func source() -> String {
        let declarations = dataTypes.compactMap { dataType in
            declaration(for: dataType)
        }
        let mappedImports = options.typeMappings
            .flatMap(\.imports)
            .withoutDuplicates()
            .joined(separator: "\n")
        return """
        // Generated code. Do not edit.

        \(mappedImports)
        import {
            DateInterval,
            LocalizedData,
            PagedResults,
            PatchableValue,
            JsonDecoder,
            decodeArrayBuffer,
            decodeDate,
            decodePagedResults,
            decodeUrl,
            encodeJsonValue
        } from "./runtime.js";

        \(declarations.joined(separator: "\n\n"))
        """
    }

    private func declaration(for dataType: ApiTypeSchema) -> String? {
        switch dataType {
            case let .object(typeName, properties, _, _, _, _):
                objectDeclaration(typeName: typeName, properties: properties.filter(\.publishedAsField))
            case let .stringEnum(typeName, values, _, _, supportGarbage):
                stringEnumDeclaration(typeName: typeName, values: values, supportGarbage: supportGarbage)
            case let .intEnum(typeName, values, _, _):
                intEnumDeclaration(typeName: typeName, values: values)
            case let .dynamicObject(
            typeName,
            objectTypePropertyName,
            objectDataPropertyName,
            alternateObjectDataPropertyName,
            objectTypes,
            supportGarbage,
            _,
            _,
            extraProperties
        ):
                dynamicObjectDeclaration(
                    typeName: typeName,
                    objectTypePropertyName: objectTypePropertyName,
                    objectDataPropertyName: objectDataPropertyName,
                    alternateObjectDataPropertyName: alternateObjectDataPropertyName,
                    objectTypes: objectTypes,
                    supportGarbage: supportGarbage,
                    extraProperties: extraProperties.filter(\.publishedAsField)
                )
            default:
                nil
        }
    }

    private func objectDeclaration(typeName: String, properties: [ApiModelProperty]) -> String {
        let name = typeName.tsTypeName
        let fields = properties.map(propertyDeclaration).joined(separator: "\n")
        let decodes = properties.map { property in
            let value = "object[\(property.rawName.tsStringLiteral)]"
            return "\(property.propertyName.tsPropertyName): \(decodeExpression(for: property.dataType, value: value, optional: !property.required)),"
        }
        .joined(separator: "\n")
        let encodes = properties.map { property in
            let prop = "value.\(property.propertyName.tsPropertyName)"
            if property.required {
                return "output[\(property.rawName.tsStringLiteral)] = \(encodeExpression(for: property.dataType, value: prop));"
            }
            return """
            if (\(prop) !== undefined) {
                output[\(property.rawName.tsStringLiteral)] = \(prop) === null ? null : \(encodeExpression(for: property.dataType, value: prop));
            }
            """
        }
        .joined(separator: "\n")

        return """
        export interface \(name) {
        \(fields.prepad())
        }

        export function decode\(name)(value: unknown): \(name) {
            const object = (value ?? {}) as Record<string, unknown>;
            return {
        \(decodes.prepad(2))
            };
        }

        export function encode\(name)(value: \(name)): unknown {
            const output: Record<string, unknown> = {};
        \(encodes.prepad())
            return output;
        }
        """
    }

    private func stringEnumDeclaration(
        typeName: String,
        values: [(name: String, rawName: String)],
        supportGarbage: Bool
    ) -> String {
        let name = typeName.tsTypeName
        let cases = (values.map(\.rawName) + (supportGarbage ? ["__garbage__"] : []))
            .map(\.tsStringLiteral)
            .joined(separator: " | ")
        let validCases = values.map { "case \($0.rawName.tsStringLiteral):" }.joined(separator: "\n")
        let fallback = supportGarbage ? "return \"__garbage__\";" : "throw new Error(`Unknown \(name) value: ${String(value)}`);"
        return """
        export type \(name) = \(cases);

        export function decode\(name)(value: unknown): \(name) {
            const rawValue = String(value);
            switch (rawValue) {
        \(validCases.prepad(2))
                    return rawValue as \(name);
                default:
                    \(fallback)
            }
        }

        export function encode\(name)(value: \(name)): unknown {
            return value;
        }
        """
    }

    private func intEnumDeclaration(typeName: String, values: [(name: String?, rawValue: Int)]) -> String {
        let name = typeName.tsTypeName
        let cases = values.map { String($0.rawValue) }.joined(separator: " | ")
        let validCases = values.map { "case \($0.rawValue):" }.joined(separator: "\n")
        return """
        export type \(name) = \(cases);

        export function decode\(name)(value: unknown): \(name) {
            const rawValue = Number(value);
            switch (rawValue) {
        \(validCases.prepad(2))
                    return rawValue as \(name);
                default:
                    throw new Error(`Unknown \(name) value: ${String(value)}`);
            }
        }

        export function encode\(name)(value: \(name)): unknown {
            return value;
        }
        """
    }

    private func dynamicObjectDeclaration(
        typeName: String,
        objectTypePropertyName: String,
        objectDataPropertyName: String,
        alternateObjectDataPropertyName: String,
        objectTypes: [(objectTypeName: String, objectTypeRawName: String, objectType: ApiTypeSchema)],
        supportGarbage: Bool,
        extraProperties: [ApiModelProperty]
    ) -> String {
        let name = typeName.tsTypeName
        let extraFields = extraProperties.map(propertyDeclaration).joined(separator: "\n")
        let cases = objectTypes.map { objectType -> String in
            let payloadType = TypeScriptTypeEmitter(dataType: objectType.objectType, options: options).declaration
            let extra = extraFields.isEmpty ? "" : "\n\(extraFields)"
            return "{ objectType: \("\(objectType.objectTypeRawName)".tsStringLiteral); payload: \(payloadType);\(extra) }"
        } + (supportGarbage ? ["{ objectType: \"__garbage__\"; rawValue: unknown }"] : [])
        let typeUnion = cases.joined(separator: "\n    | ")

        let decoderCases = objectTypes.map { objectType in
            let extraDecodes = extraProperties.map { property in
                "\(property.propertyName.tsPropertyName): \(decodeExpression(for: property.dataType, value: "object[\(property.rawName.tsStringLiteral)]", optional: !property.required)),"
            }.joined(separator: "\n")
            let payloadSource = objectDataPropertyName == "__self__"
                ? "value"
                : "(object[\(objectDataPropertyName.tsStringLiteral)] ?? object[\(alternateObjectDataPropertyName.tsStringLiteral)])"
            let payloadDecode = decodeExpression(for: objectType.objectType, value: payloadSource, optional: false)
            return """
            case \(objectType.objectTypeRawName.tsStringLiteral):
                return {
                    objectType: \(objectType.objectTypeRawName.tsStringLiteral),
                    payload: \(payloadDecode),
            \(extraDecodes.prepad(2))
                };
            """
        }
        .joined(separator: "\n")
        let unknownCase = supportGarbage
            ? "return { objectType: \"__garbage__\", rawValue: value };"
            : "throw new Error(`Unknown \(name) discriminator: ${String(objectType)}`);"

        let encoderCases = objectTypes.map { objectType in
            let extraEncodes = extraProperties.map { property in
                let prop = "value.\(property.propertyName.tsPropertyName)"
                if property.required {
                    return "output[\(property.rawName.tsStringLiteral)] = \(encodeExpression(for: property.dataType, value: prop));"
                }
                return """
                if (\(prop) !== undefined) {
                    output[\(property.rawName.tsStringLiteral)] = \(prop) === null ? null : \(encodeExpression(for: property.dataType, value: prop));
                }
                """
            }
            .joined(separator: "\n")
            let payloadEncode = encodeExpression(for: objectType.objectType, value: "value.payload")
            let payloadLine = objectDataPropertyName == "__self__"
                ? "Object.assign(output, \(payloadEncode));"
                : "output[\(objectDataPropertyName.tsStringLiteral)] = \(payloadEncode);"
            return """
            case \(objectType.objectTypeRawName.tsStringLiteral):
                output[\(objectTypePropertyName.tsStringLiteral)] = value.objectType;
            \(extraEncodes.prepad())
                \(payloadLine)
                return output;
            """
        }
        .joined(separator: "\n")

        return """
        export type \(name) =
            | \(typeUnion);

        export function decode\(name)(value: unknown): \(name) {
            const object = (value ?? {}) as Record<string, unknown>;
            const objectType = object[\(objectTypePropertyName.tsStringLiteral)];
            switch (objectType) {
        \(decoderCases.prepad())
                default:
                    \(unknownCase)
            }
        }

        export function encode\(name)(value: \(name)): unknown {
            if (value.objectType === "__garbage__") {
                return value.rawValue;
            }
            const output: Record<string, unknown> = {};
            switch (value.objectType) {
        \(encoderCases.prepad())
            }
        }
        """
    }

    private func propertyDeclaration(for property: ApiModelProperty) -> String {
        let type = TypeScriptTypeEmitter(dataType: property.dataType, options: options).declaration
        let optional = property.required ? "" : "?"
        let nullable = property.required ? "" : " | null"
        return "\(property.propertyName.tsPropertyName)\(optional): \(type)\(nullable);"
    }

    func decodeExpression(for dataType: ApiTypeSchema, value: String, optional: Bool = false) -> String {
        let expression: String
        switch dataType {
            case .uuid,
                 .string,
                 .timelessDate,
                 .time:
                expression = "String(\(value))"
            case .int,
                 .int64,
                 .int32,
                 .int16,
                 .int8,
                 .uint,
                 .uint64,
                 .uint32,
                 .uint16,
                 .uint8,
                 .double:
                expression = "Number(\(value))"
            case .date:
                expression = "decodeDate(\(value))"
            case .url:
                expression = "decodeUrl(\(value))"
            case .bool:
                expression = "Boolean(\(value))"
            case .binary:
                expression = "decodeArrayBuffer(\(value))"
            case let .keyedByString(type, isOptional):
                let item = decodeExpression(for: type, value: "item", optional: isOptional)
                expression = "Object.fromEntries(Object.entries((\(value) ?? {}) as Record<string, unknown>).map(([key, item]) => [key, \(item)]))"
            case let .array(type):
                let item = decodeExpression(for: type, value: "item")
                expression = "((\(value) ?? []) as unknown[]).map((item) => \(item))"
            case let .stringEnum(typeName, _, _, _, _),
                 let .intEnum(typeName, _, _, _),
                 let .object(typeName, _, _, _, _, _),
                 let .dynamicObject(typeName, _, _, _, _, _, _, _, _):
                if options.mapping(for: typeName) != nil {
                    expression = "\(value) as \(TypeScriptTypeEmitter(dataType: dataType, options: options).declaration)"
                } else {
                    expression = "\(codecPrefix)decode\(typeName.tsTypeName)(\(value))"
                }
            case let .reference(typeName, _, _, _, referencedDataType):
                if let referencedDataType {
                    expression = decodeExpression(for: referencedDataType, value: value)
                } else if options.mapping(for: typeName) != nil {
                    expression = "\(value) as \(TypeScriptTypeEmitter(dataType: dataType, options: options).declaration)"
                } else {
                    expression = "\(codecPrefix)decode\(typeName.tsTypeName)(\(value))"
                }
            case let .genericReference(typeName, types):
                if typeName == "PagedResults", let first = types.first {
                    let item = decodeExpression(for: first, value: "item")
                    expression = "decodePagedResults(\(value), (item) => \(item))"
                } else {
                    expression = "\(value) as \(TypeScriptTypeEmitter(dataType: dataType, options: options).declaration)"
                }
        }

        guard optional else {
            return expression
        }
        return "\(value) == null ? null : \(expression)"
    }

    func encodeExpression(for dataType: ApiTypeSchema, value: String) -> String {
        switch dataType {
            case let .array(type):
                let item = encodeExpression(for: type, value: "item")
                return "\(value).map((item) => \(item))"
            case let .keyedByString(type, isOptional):
                let item = encodeExpression(for: type, value: "item")
                let output = isOptional ? "item == null ? null : \(item)" : item
                return "Object.fromEntries(Object.entries(\(value)).map(([key, item]) => [key, \(output)]))"
            case let .stringEnum(typeName, _, _, _, _),
                 let .intEnum(typeName, _, _, _),
                 let .object(typeName, _, _, _, _, _),
                 let .dynamicObject(typeName, _, _, _, _, _, _, _, _):
                if options.mapping(for: typeName) != nil {
                    return "encodeJsonValue(\(value))"
                }
                return "\(codecPrefix)encode\(typeName.tsTypeName)(\(value))"
            case let .reference(typeName, _, _, _, referencedDataType):
                if let referencedDataType {
                    return encodeExpression(for: referencedDataType, value: value)
                }
                if options.mapping(for: typeName) != nil {
                    return "encodeJsonValue(\(value))"
                }
                return "\(codecPrefix)encode\(typeName.tsTypeName)(\(value))"
            default:
                return "encodeJsonValue(\(value))"
        }
    }
}
