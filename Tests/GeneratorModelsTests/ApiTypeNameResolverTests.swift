import Foundation
@testable import GeneratorModels
import Testing

struct ApiTypeNameResolverTests {
    @Test func indexedNamesPreserveScopePrecedenceAndFallbacks() {
        let context = ApiTypeNameResolver()
        let model = ApiTypeSchema.object(typeName: "Model", properties: [.string("value")])
        let alias = ApiTypeSchema.object(typeName: "Alias", properties: [], uuid: model.uuid!)
        context.push(module: "Outer", types: [model])
        #expect(context.scopedName(for: alias) == "Outer.Model")
        #expect(context.scopedName(for: model.asRef) == "Outer.Model")

        // An exact reference in an inner scope still precedes an outer UUID match.
        context.push([model.asRef: "Inner.Reference", .string(): "Inner.String"])
        #expect(context.scopedName(for: model.asRef) == "Inner.Reference")
        #expect(context.scopedName(for: model) == "Outer.Model")
        #expect(context.scopedName(for: .string()) == "Inner.String")
        context.pop()
        #expect(context.scopedName(for: model.asRef) == "Outer.Model")
        #expect(context.scopedName(for: .string()) == nil)
        context.clear()
        context.pop()
        #expect(context.scopedName(for: model) == nil)
        #expect(context.name(for: model) == "Model")
    }

    @Test func indexedNamesResolveLargeScopes() {
        let context = ApiTypeNameResolver()
        let types = (0..<2_000).map { index in
            ApiTypeSchema.object(typeName: "Model\(index)", properties: [.string("value")])
        }
        context.push(module: "Shared", types: types)
        for (index, type) in types.enumerated() {
            #expect(context.scopedName(for: type.asRef) == "Shared.Model\(index)")
        }
    }
}
