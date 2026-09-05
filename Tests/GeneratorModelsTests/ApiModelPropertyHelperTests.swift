import Foundation
import GeneratorModels
import Testing

struct ApiModelPropertyHelperTests {
    @Test func urlRequirednessIsExplicitAndConsistent() {
        #expect(ApiModelProperty.url("website").required)
        #expect(!ApiModelProperty.url("website", required: false).required)
        #expect(!ApiModelProperty.url("website").optional.required)
        let property = ApiModelProperty.url("website", propertyName: "link", equatable: true, hashable: true).optional.unpublished.mandatory
        #expect(property.required)
        #expect(property.rawName == "website")
        #expect(property.propertyName == "link")
        #expect(property.equatable)
        #expect(property.hashable)
        #expect(!property.publishedAsField)
        #expect(property.dataType == .url(nil))
    }
}
