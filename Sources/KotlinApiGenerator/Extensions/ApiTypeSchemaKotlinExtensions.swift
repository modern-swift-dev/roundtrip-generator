import Foundation
import GeneratorModels

extension [ApiTypeSchema] {
    var hasDuplicateKotlinDeclarations: Bool {
        let declarationNames = compactMap(\.declaredKotlinTypeDeclaration)
        return Set(declarationNames).count != declarationNames.count
    }
}

extension ApiTypeSchema {
    var declaredKotlinTypeID: UUID? {
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

    var declaredKotlinTypeDeclaration: String? {
        switch self {
            case .object,
                 .stringEnum,
                 .intEnum,
                 .dynamicObject:
                KotlinTypeEmitter(dataType: self).typeName.declaration
            case let .array(type),
                 let .keyedByString(type, _):
                type.declaredKotlinTypeDeclaration
            case let .reference(_, _, _, _, dataType):
                dataType?.declaredKotlinTypeDeclaration ?? KotlinTypeEmitter(dataType: self).typeName.declaration
            default:
                nil
        }
    }

    var kotlinTypeDeclaration: String {
        kotlinTypeDeclaration(options: .init())
    }

    func kotlinTypeDeclaration(options: KotlinGeneratorOptions) -> String {
        KotlinTypeEmitter(dataType: self, options: options).typeName.declaration
    }

    var kotlinTypeImports: Set<String> {
        KotlinTypeEmitter(dataType: self, options: .init()).typeName.imports
    }

    func kotlinTypeImports(options: KotlinGeneratorOptions) -> Set<String> {
        KotlinTypeEmitter(dataType: self, options: options).typeName.imports
    }

    func kotlinDefaultValue(required: Bool) -> String? {
        kotlinDefaultValue(required: required, options: .init())
    }

    func kotlinDefaultValue(required: Bool, options: KotlinGeneratorOptions) -> String? {
        KotlinTypeEmitter(dataType: self, options: options).defaultValue(required: required)
    }

    var isKotlinPatchableValue: Bool {
        switch self {
            case let .genericReference(typeName, _):
                typeName == "PatchableValue"
            case let .reference(_, _, _, _, dataType):
                dataType?.isKotlinPatchableValue ?? false
            default:
                false
        }
    }

    var usesDirectKotlinByteArraySerializer: Bool {
        switch self {
            case .binary:
                true
            case let .reference(_, _, _, _, dataType):
                dataType?.usesDirectKotlinByteArraySerializer ?? false
            default:
                false
        }
    }

    var needsKotlinByteArrayBase64SerializerImport: Bool {
        switch self {
            case let .object(_, properties, _, _, _, _):
                properties
                    .filter(\.publishedAsField)
                    .contains { $0.dataType.usesDirectKotlinByteArraySerializer || $0.dataType.needsKotlinByteArrayBase64SerializerImport }
            case let .dynamicObject(_, _, _, _, objectTypes, _, _, _, extraProperties):
                objectTypes.contains { $0.objectType.needsKotlinByteArrayBase64SerializerImport }
                    || extraProperties
                    .contains { $0.dataType.usesDirectKotlinByteArraySerializer || $0.dataType.needsKotlinByteArrayBase64SerializerImport }
            case let .reference(_, _, _, _, dataType):
                dataType?.needsKotlinByteArrayBase64SerializerImport ?? false
            case let .array(type),
                 let .keyedByString(type, _):
                type.needsKotlinByteArrayBase64SerializerImport
            case let .genericReference(_, types):
                types.contains { $0.needsKotlinByteArrayBase64SerializerImport }
            default:
                false
        }
    }
}
