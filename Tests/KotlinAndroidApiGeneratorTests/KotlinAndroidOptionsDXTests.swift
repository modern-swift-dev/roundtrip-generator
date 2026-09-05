import Testing
@testable import KotlinAndroidApiGenerator

struct KotlinAndroidOptionsDXTests {
    @Test func mappingPreservesDefaultsAndOverridesExistingNames() {
        let original = KotlinAndroidGeneratorOptions()
        let added = original.mapping(.init(apiTypeName: "External", kotlinType: "CustomExternal"))
        #expect(added.mapping(for: "PagedResults") == original.mapping(for: "PagedResults"))
        #expect(added.mapping(for: "External")?.kotlinType == "CustomExternal")
        #expect(original.mapping(for: "External") == nil)
        let overridden = added.mapping(.init(apiTypeName: "PagedResults", kotlinType: "CustomPage"))
        #expect(overridden.mapping(for: "PagedResults")?.kotlinType == "CustomPage")
        #expect(overridden.typeMappings.filter { $0.apiTypeName == "PagedResults" }.count == 1)
        #expect(overridden.mapping(for: "External") == added.mapping(for: "External"))
    }
}
