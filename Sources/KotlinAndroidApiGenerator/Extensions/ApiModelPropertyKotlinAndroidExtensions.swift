import Foundation
import GeneratorModels

extension ApiModelProperty {
    var kotlinProperty: KotlinAndroidProperty {
        kotlinProperty(options: .init())
    }

    func kotlinProperty(options: KotlinAndroidGeneratorOptions) -> KotlinAndroidProperty {
        let name = propertyName.kotlinPropertyName
        let needsSerialName = rawName != propertyName
        let annotations = needsSerialName
            ? ["@SerialName(\(rawName.kotlinStringLiteral))"]
            : []
        let patchableAnnotations = dataType.isKotlinAndroidPatchableValue
            ? ["@EncodeDefault(EncodeDefault.Mode.NEVER)"]
            : []
        let requiredBooleanAnnotations: [String] = if required, case .bool = dataType {
            ["@EncodeDefault(EncodeDefault.Mode.ALWAYS)"]
        } else {
            []
        }
        let serializerAnnotations: [String] = if dataType.usesDirectKotlinAndroidByteArraySerializer {
            ["@Serializable(with = ByteArrayBase64Serializer::class)"]
        } else if let serializer = dataType.kotlinAndroidStrictIntegerSerializerName {
            ["@Serializable(with = \(serializer)::class)"]
        } else {
            []
        }
        var imports: Set<String> = needsSerialName ? ["kotlinx.serialization.SerialName"] : []
        if let serializer = dataType.kotlinAndroidStrictIntegerSerializerName {
            imports.insert("\(options.basePackage).\(serializer)")
        }
        if dataType.isKotlinAndroidPatchableValue || !requiredBooleanAnnotations.isEmpty {
            imports.insert("kotlinx.serialization.EncodeDefault")
        }

        return KotlinAndroidProperty(
            name: name,
            typeName: KotlinAndroidTypeEmitter(dataType: dataType, options: options).typeName,
            nullable: dataType.isKotlinAndroidPatchableValue ? false : !required,
            defaultValue: dataType.kotlinDefaultValue(required: required, options: options),
            annotations: annotations + patchableAnnotations + requiredBooleanAnnotations + serializerAnnotations,
            additionalImports: imports,
        )
    }
}

private extension ApiTypeSchema {
    var kotlinAndroidStrictIntegerSerializerName: String? {
        switch self {
            case .int,
                 .int32:
                "StrictIntSerializer"
            case .int64:
                "StrictLongSerializer"
            case let .reference(_, _, _, _, dataType):
                dataType?.kotlinAndroidStrictIntegerSerializerName
            default:
                nil
        }
    }
}
