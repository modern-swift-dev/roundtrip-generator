import Testing
@testable import TypeScriptApiGenerator

struct TypeScriptOptionsDXTests {
    @Test func `mapping preserves defaults and overrides existing names`() {
        let original = TypeScriptGeneratorOptions()
        let added = original.mapping(.init(apiTypeName: "External", typeScriptType: "CustomExternal"))
        #expect(added.mapping(for: "PagedResults") == original.mapping(for: "PagedResults"))
        #expect(added.mapping(for: "External")?.typeScriptType == "CustomExternal")
        #expect(original.mapping(for: "External") == nil)
        let overridden = added.mapping(.init(apiTypeName: "PagedResults", typeScriptType: "CustomPage"))
        #expect(overridden.mapping(for: "PagedResults")?.typeScriptType == "CustomPage")
        #expect(overridden.typeMappings.filter { $0.apiTypeName == "PagedResults" }.count == 1)
        #expect(overridden.mapping(for: "External") == added.mapping(for: "External"))
    }
}
