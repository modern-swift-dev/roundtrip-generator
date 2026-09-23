import Foundation
import GeneratorModels
import Testing

struct ApiModelPropertyHelperTests {
    @Test func `url requiredness is explicit and consistent`() {
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

    @Test func `omittable presence is distinct from nullable optional presence`() {
        let nullable = ApiModelProperty.string("name").optional
        let omittable = ApiModelProperty.string("name").omittable

        #expect(nullable.presence == .optionalNullable)
        #expect(omittable.presence == .optionalNonNullable)
        #expect(!omittable.required)
        #expect(omittable.unpublished.presence == .optionalNonNullable)
        #expect(omittable.mandatory.presence == .required)
        #expect(ApiTypeSchema.object(typeName: "Example", properties: [nullable]) != ApiTypeSchema.object(typeName: "Example", properties: [omittable]))
    }
}
