import Foundation
import GeneratorModels
import Testing

struct ApiCollectionBuilderTests {
    @Test func propertyBuilderComposesReusableArraysConditionalsAndLoops() {
        let auditProperties: [ApiModelProperty] = [.date("created_at"), .date("updated_at")]
        let includeAudit = true
        let includeHidden = false
        let model = ApiTypeSchema.object("User") {
            .string("name")
            if includeAudit { auditProperties }
            if includeHidden {
                ApiModelProperty.string("hidden")
            } else {
                ApiModelProperty.string("visible")
            }
            if includeHidden { ApiModelProperty.string("excluded") }
            for name in ["email", "phone"] { ApiModelProperty.string(name).optional }
        }
        guard case let .object(name, properties, _, _, _, _) = model else {
            Issue.record("Expected an object")
            return
        }
        #expect(name == "User")
        #expect(properties.map(\.rawName) == ["name", "created_at", "updated_at", "visible", "email", "phone"])
        #expect(!properties.last!.required)
    }

    @Test func builderAndArrayDeclarationsAreEquivalent() {
        let uuid = UUID()
        let properties: [ApiModelProperty] = [.string("name")]
        let built = ApiTypeSchema.object(typeName: "User", protocols: ["Equatable"], imports: ["Foundation"], isValueType: false, uuid: uuid) {
            properties
        }
        let array = ApiTypeSchema.object(typeName: "User", properties: properties, protocols: ["Equatable"], imports: ["Foundation"], isValueType: false, uuid: uuid)
        guard case let .object(name, actual, protocols, imports, isValueType, actualUUID) = built else {
            Issue.record("Expected an object")
            return
        }
        #expect(built == array)
        #expect(name == "User")
        #expect(actual.map(\.rawName) == properties.map(\.rawName))
        #expect(protocols == ["Equatable"])
        #expect(imports.count == 1)
        #expect(!isValueType)
        #expect(actualUUID == uuid)
    }

    @Test func nestedPackageDeclarationsPreserveReferencesAndOperations() {
        let user = ApiTypeSchema.object("User") { ApiModelProperty.string("name") }
        let package = ApiPackage(name: "Example", targetDirUrl: URL(fileURLWithPath: "/unused"), references: [user], generateApiModules: false) {
            ApiModule(name: "Main", references: [user]) {
                ApiService(name: "Users", references: [user]) {
                    ApiOperation.get(name: "list", path: .relative("/users"), response: .array(user.asRef))
                }
            }
        }
        #expect(!package.generateApiModules)
        #expect(package.references == [user])
        #expect(package.modules.map(\.name) == ["Main"])
        #expect(package.modules[0].references == [user])
        #expect(package.modules[0].definitions[0].referencedTypes == [user])
        #expect(package.modules[0].definitions[0].operations.count == 1)
    }

    @Test func emptyBlocksAndResourceGroupsCompile() {
        let empty = ApiTypeSchema.object("Empty") {}
        guard case let .object(_, properties, _, _, _, _) = empty else {
            Issue.record("Expected an object")
            return
        }
        #expect(properties.isEmpty)
        #expect(ApiService(name: "Empty") {}.operations.isEmpty)
        #expect(ApiModule(name: "Empty") {}.definitions.isEmpty)
        #expect(ApiPackage(name: "Empty", targetDirUrl: URL(fileURLWithPath: "/unused")) {}.modules.isEmpty)
        #expect(ApiRestResourceGroup {}.resources.isEmpty)
        let group = ApiRestResourceGroup(name: "Resources") {
            ApiRestResource(dataType: empty, metadataProperties: [])
        }
        #expect(group.resources.count == 1)
        #expect(group.module().name == "Resources")
    }
}
