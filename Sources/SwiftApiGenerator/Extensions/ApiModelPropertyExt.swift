import Foundation
import GeneratorModels

// MARK: - CodeGen
extension ApiModelProperty {

    var swiftProperty: SwiftProperty {
        SwiftProperty(
            visibility: .public,
            mutable: true,
            name: propertyName,
            dataType: ApiTypeSchemaGenerator(dataType: dataType).swiftTypeDeclaration,
            nullable: !required,
            defaultValue: getDefaultValue(),
            rawName: rawName,
            equatable: equatable,
            hashable: hashable
        )
    }

    /// The swift code for inclusing in an initializer signature
    func getDefaultValue() -> String? {
        ApiTypeSchemaGenerator(dataType: dataType).getDefaultValue(required: required)
    }

}

extension [ApiModelProperty] {

    var swiftCodingKeys: SwiftCodingKeys {
        .init(values: map { SwiftCodingKey(name: $0.propertyName, rawName: $0.rawName) })
    }

    var swiftInit: SwiftInit {
        .init(visibility: .public, properties: map(\.swiftProperty))
    }

}
