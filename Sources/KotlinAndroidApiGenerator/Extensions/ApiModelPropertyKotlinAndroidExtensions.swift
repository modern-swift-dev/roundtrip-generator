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
        let serializerAnnotations = dataType.usesDirectKotlinAndroidByteArraySerializer
            ? ["@Serializable(with = ByteArrayBase64Serializer::class)"]
            : []
        var imports: Set<String> = needsSerialName ? ["kotlinx.serialization.SerialName"] : []
        if dataType.isKotlinAndroidPatchableValue {
            imports.insert("kotlinx.serialization.EncodeDefault")
        }

        return KotlinAndroidProperty(
            name: name,
            typeName: KotlinAndroidTypeEmitter(dataType: dataType, options: options).typeName,
            nullable: dataType.isKotlinAndroidPatchableValue ? false : !required,
            defaultValue: dataType.kotlinDefaultValue(required: required, options: options),
            annotations: annotations + patchableAnnotations + serializerAnnotations,
            additionalImports: imports
        )
    }
}
