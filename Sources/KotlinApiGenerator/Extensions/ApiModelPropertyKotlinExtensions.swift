import Foundation
import GeneratorModels

extension ApiModelProperty {
    var kotlinProperty: KotlinProperty {
        kotlinProperty(options: .init())
    }

    func kotlinProperty(options: KotlinGeneratorOptions) -> KotlinProperty {
        let name = propertyName.kotlinPropertyName
        let needsSerialName = rawName != propertyName
        let annotations = needsSerialName
            ? ["@SerialName(\(rawName.kotlinStringLiteral))"]
            : []
        let patchableAnnotations = dataType.isKotlinPatchableValue
            ? ["@EncodeDefault(EncodeDefault.Mode.NEVER)"]
            : []
        let serializerAnnotations = dataType.usesDirectKotlinByteArraySerializer
            ? ["@Serializable(with = ByteArrayBase64Serializer::class)"]
            : []
        var imports: Set<String> = needsSerialName ? ["kotlinx.serialization.SerialName"] : []
        if dataType.isKotlinPatchableValue {
            imports.insert("kotlinx.serialization.EncodeDefault")
        }

        return KotlinProperty(
            name: name,
            typeName: KotlinTypeEmitter(dataType: dataType, options: options).typeName,
            nullable: dataType.isKotlinPatchableValue ? false : !required,
            defaultValue: dataType.kotlinDefaultValue(required: required, options: options),
            annotations: annotations + patchableAnnotations + serializerAnnotations,
            additionalImports: imports
        )
    }
}
