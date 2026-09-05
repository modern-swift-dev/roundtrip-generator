import Foundation
import GeneratorModels

extension [ApiTypeSchema] {
    var hasDuplicateKotlinAndroidDeclarations: Bool {
        let declarationNames = compactMap(\.declaredKotlinAndroidTypeDeclaration)
        return Set(declarationNames).count != declarationNames.count
    }
}

extension ApiTypeSchema {
    var declaredKotlinAndroidTypeID: UUID? {
        switch self {
            case let .object(_, _, _, _, _, uuid),
                 let .stringEnum(_, _, _, uuid, _),
                 let .intEnum(_, _, _, uuid),
                 let .dynamicObject(_, _, _, _, _, _, _, uuid, _):
                uuid
            case let .reference(_, _, _, uuid, _):
                uuid
            default:
                nil
        }
    }

    var declaredKotlinAndroidTypeDeclaration: String? {
        switch self {
            case .object,
                 .stringEnum,
                 .intEnum,
                 .dynamicObject:
                KotlinAndroidTypeEmitter(dataType: self).typeName.declaration
            case let .array(type),
                 let .keyedByString(type, _):
                type.declaredKotlinAndroidTypeDeclaration
            case let .reference(_, _, _, _, dataType):
                dataType?.declaredKotlinAndroidTypeDeclaration ?? KotlinAndroidTypeEmitter(dataType: self).typeName.declaration
            default:
                nil
        }
    }

    var kotlinTypeDeclaration: String {
        kotlinTypeDeclaration(options: .init())
    }

    func kotlinTypeDeclaration(options: KotlinAndroidGeneratorOptions) -> String {
        KotlinAndroidTypeEmitter(dataType: self, options: options).typeName.declaration
    }

    var kotlinTypeImports: Set<String> {
        KotlinAndroidTypeEmitter(dataType: self, options: .init()).typeName.imports
    }

    func kotlinTypeImports(options: KotlinAndroidGeneratorOptions) -> Set<String> {
        KotlinAndroidTypeEmitter(dataType: self, options: options).typeName.imports
    }

    func kotlinDefaultValue(required: Bool) -> String? {
        kotlinDefaultValue(required: required, options: .init())
    }

    func kotlinDefaultValue(required: Bool, options: KotlinAndroidGeneratorOptions) -> String? {
        KotlinAndroidTypeEmitter(dataType: self, options: options).defaultValue(required: required)
    }

    var isKotlinAndroidPatchableValue: Bool {
        switch self {
            case let .genericReference(typeName, _):
                typeName == "PatchableValue"
            case let .reference(_, _, _, _, dataType):
                dataType?.isKotlinAndroidPatchableValue ?? false
            default:
                false
        }
    }

    var usesDirectKotlinAndroidByteArraySerializer: Bool {
        switch self {
            case .binary:
                true
            case let .reference(_, _, _, _, dataType):
                dataType?.usesDirectKotlinAndroidByteArraySerializer ?? false
            default:
                false
        }
    }

    var needsKotlinAndroidByteArrayBase64SerializerImport: Bool {
        switch self {
            case let .object(_, properties, _, _, _, _):
                properties
                    .filter(\.publishedAsField)
                    .contains { $0.dataType.usesDirectKotlinAndroidByteArraySerializer || $0.dataType.needsKotlinAndroidByteArrayBase64SerializerImport }
            case let .dynamicObject(_, _, _, _, objectTypes, _, _, _, extraProperties):
                objectTypes.contains { $0.objectType.needsKotlinAndroidByteArrayBase64SerializerImport }
                    || extraProperties
                    .contains { $0.dataType.usesDirectKotlinAndroidByteArraySerializer || $0.dataType.needsKotlinAndroidByteArrayBase64SerializerImport }
            case let .reference(_, _, _, _, dataType):
                dataType?.needsKotlinAndroidByteArrayBase64SerializerImport ?? false
            case let .array(type),
                 let .keyedByString(type, _):
                type.needsKotlinAndroidByteArrayBase64SerializerImport
            case let .genericReference(_, types):
                types.contains { $0.needsKotlinAndroidByteArrayBase64SerializerImport }
            default:
                false
        }
    }
}
