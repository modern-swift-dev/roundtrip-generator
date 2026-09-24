import Foundation
import GeneratorModels
import Testing

struct ApiAudienceTests {
    @Test func copiesPreserveBackendAudience() {
        let operation = ApiOperation.get(name: "private", path: .relative("/private"), security: .unsecured).backendOnly()
        let copies = [
            operation.adding([]), operation.adaptingRequest { $0 }, operation.adaptingResponse { $0 },
            operation.renaming(to: "other"), operation.withExtraImports([]),
            operation.withSuccessResponse(status: 200, response: .none), operation.withRepeatedMultipartParts([]),
            operation.withOptionalMultipartParts([]), operation.withTextMultipartParts([]),
            operation.withMaxMultipartParts([:]), operation.withClientOnlyAcceptableStatuses([201])
        ]
        #expect(copies.allSatisfy { $0.audience == .backendOnly })
        #expect(ApiOperation.get(name: "public", path: .relative("/public"), security: .unsecured).audience == .all)
    }

    @Test func clientProjectionRemovesOnlyExclusiveDependencies() {
        let shared = ApiTypeSchema.object(typeName: "Shared", properties: [.string("name")])
        let privateLeaf = ApiTypeSchema.object(typeName: "PrivateLeaf", properties: [.string("secret")])
        let privateBody = ApiTypeSchema.object(typeName: "PrivateBody", properties: [.ref("leaf", of: privateLeaf), .ref("shared", of: shared)])
        let standaloneLeaf = ApiTypeSchema.object(typeName: "StandaloneLeaf", properties: [.string("name")])
        let standalone = ApiTypeSchema.object(typeName: "Standalone", properties: [.ref("leaf", of: standaloneLeaf)])
        let privateParameter = ApiTypeSchema.stringEnum(typeName: "PrivateParameter", values: [(name: "one", rawName: "one")])
        let privateError = ApiTypeSchema.object(typeName: "PrivateError", properties: [.ref("shared", of: shared), .ref("other", of: standaloneLeaf)])
        let publicOp = ApiOperation.get(name: "public", path: .relative("/public"), security: .unsecured, response: shared.asRef)
        let privateOp = ApiOperation.get(
            name: "private",
            path: .relative("/private"),
            security: .unsecured,
            parameters: [.query("filter", .stringEnumValue(type: privateParameter.asRef))],
            response: privateBody.asRef,
            publicErrors: [.init(status: 409, response: .json(privateError.asRef))]
        ).backendOnly()
        let package = ApiPackage(name: "Audience", targetDirUrl: URL(fileURLWithPath: "/unused"), modules: [
            ApiModule(name: "Mixed", definitions: [ApiService(name: "Records", operations: [publicOp, privateOp], references: [privateBody, privateParameter])], references: [privateError]),
            ApiModule(name: "Private", definitions: [ApiService(name: "Hidden", operations: [privateOp])])
        ], references: [shared, privateLeaf, standalone, standaloneLeaf])
        let projected = package.clientAudiencePackage
        #expect(projected.modules.map(\.name) == ["Mixed"])
        #expect(projected.modules[0].definitions[0].operations.map(\.name) == [publicOp.name])
        #expect(projected.modules[0].references.isEmpty)
        #expect(projected.modules[0].definitions[0].referencedTypes.isEmpty)
        #expect(projected.references.compactMap(\.uuid) == [shared, standalone, standaloneLeaf].compactMap(\.uuid))
    }

    @Test func backendOnlyServicesDoNotLeakSharedDeclarationsOrEmptyAPIs() {
        let shared = ApiTypeSchema.object(typeName: "Shared", properties: [.string("name")])
        let unused = ApiTypeSchema.object(typeName: "UnusedBackend", properties: [.string("name")])
        let visible = ApiOperation.get(name: "visible", path: .relative("/visible"), security: .unsecured, response: shared.asRef)
        let hidden = ApiOperation.get(name: "hidden", path: .relative("/hidden"), security: .unsecured, response: shared.asRef).backendOnly()
        let package = ApiPackage(name: "Audience", targetDirUrl: URL(fileURLWithPath: "/unused"), modules: [
            ApiModule(name: "Mixed", definitions: [
                ApiService(name: "Visible", operations: [visible]),
                ApiService(name: "Backend", operations: [hidden], references: [shared, unused]),
                ApiService(name: "OtherBackend", operations: [hidden], references: [shared])
            ])
        ])
        let projected = package.clientAudiencePackage
        #expect(projected.modules[0].definitions.map(\.name) == ["Visible"])
        #expect(projected.modules[0].references.compactMap(\.uuid) == [shared.uuid].compactMap(\.self))
    }

}
