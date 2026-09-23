import GeneratorModels
import Testing

struct ApiOperationClientStatusTests {
    @Test func `operation copies preserve client only statuses`() {
        let operation = ApiOperation.get(name: "image", path: .relative("/images"), security: .unsecured, acceptableStatuses: [302])
            .withClientOnlyAcceptableStatuses([200])
        let copies = [
            operation.adding([]),
            operation.adaptingRequest { $0 },
            operation.adaptingResponse { $0 },
            operation.renaming(to: "photo"),
            operation.withExtraImports([]),
            operation.withSuccessResponse(status: 302, response: .none),
            operation.withRepeatedMultipartParts([]),
            operation.withOptionalMultipartParts([]),
            operation.withTextMultipartParts([])
        ]

        #expect(copies.allSatisfy { $0.acceptableStatuses == [302] && $0.clientOnlyAcceptableStatuses == [200] })
    }
}
