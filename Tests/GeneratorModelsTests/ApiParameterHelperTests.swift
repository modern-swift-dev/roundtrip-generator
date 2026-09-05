import GeneratorModels
import Testing

struct ApiParameterHelperTests {
    @Test func `query preserves wire name and options`() {
        let parameter = ApiParameter.query("include_tags", .stringArray(), propertyName: "includedTags", required: false, mutable: false)
        #expect(parameter.rawName == "include_tags")
        #expect(parameter.propertyName == "includedTags")
        #expect(parameter.location == .query)
        #expect(!parameter.isRequired)
        #expect(!parameter.isMutable)
    }
}
