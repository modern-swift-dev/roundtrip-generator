import GeneratorModels
import Testing

struct ApiRestResourceDXTests {
    private func relativePath(_ operation: ApiOperation) -> String? {
        guard case let .relative(path) = operation.path else { return nil }
        return path
    }

    private var user: ApiTypeSchema { .object("User") { .string("name") } }

    @Test func defaultsPreserveConventionalContract() {
        let resource = ApiRestResource(dataType: user)
        let operations = resource.generateOperations(parentPath: "", parentPathParams: [])
        #expect(operations.map(\.method) == [.post, .put, .patch, .delete, .get, .get])
        #expect(operations.map(relativePath) == ["/user", "/user/{user_id}", "/user/{user_id}", "/user/{user_id}", "/user", "/user/{user_id}"])
        #expect(operations.allSatisfy { $0.security == .unsecured })
        guard case let .genericReference(name, types) = operations[4].response.dataType else {
            Issue.record("Expected legacy PagedResults response")
            return
        }
        #expect(name == "PagedResults")
        #expect(types == [resource.identifiedDataType.asRef])
        guard case let .object(_, properties, _, _, _, _) = resource.identifiedDataType else {
            Issue.record("Expected identified object")
            return
        }
        #expect(properties.map(\.rawName) == ["id", "name"])
    }

    @Test func typedIdentifiersUseMatchingModelAndParameterTypes() {
        let cases: [ApiRestResource.Identifier] = [.int64(), .string("key"), .uuid("uuid", pathParameterName: "user_key")]
        for identifier in cases {
            let resource = ApiRestResource(dataType: user, identifier: identifier, operationTypes: [.retrieve])
            #expect(resource.identifierProperty.rawName == identifier.name)
            #expect(resource.identifierProperty.propertyName == "id")
            let parameter = resource.generateOperations(parentPath: "", parentPathParams: [])[0].parameters[0]
            switch identifier.kind {
            case .int64:
                #expect(resource.identifierProperty.dataType == .int64())
                guard case .int64 = parameter.dataType else { Issue.record("Expected Int64 path parameter"); continue }
            case .string:
                #expect(resource.identifierProperty.dataType == .string())
                guard case .string = parameter.dataType else { Issue.record("Expected string path parameter"); continue }
            case .uuid:
                #expect(resource.identifierProperty.dataType == .uuid)
                #expect(parameter.rawName == "user_key")
                guard case .string = parameter.dataType else { Issue.record("Expected UUID encoded as string path parameter"); continue }
            }
        }
    }

    @Test func readOnlySecurityAndArrayPaginationAreExplicit() {
        let resource = ApiRestResource(dataType: user, operationTypes: .readOnly, path: "/users/", security: .secured)
        let operations = resource.generateOperations(parentPath: "/v1/", parentPathParams: [])
        #expect(operations.count == 2)
        #expect(operations.allSatisfy { $0.method == .get && $0.security == .secured })
        #expect(relativePath(operations[0]) == "/v1/users")
        #expect(operations.allSatisfy { $0.expandedParameters.contains { $0.rawName == "Authorization" && $0.isRequired } })
        let arrayResource = ApiRestResource(dataType: user, operationTypes: [.list(parameters: [.query("limit", .int())], pagination: .array)])
        let list = arrayResource.generateOperations(parentPath: "", parentPathParams: [])[0]
        #expect(list.response.dataType == .array(arrayResource.identifiedDataType.asRef))
        #expect(list.parameters.map(\.rawName) == ["limit"])
    }

    @Test func nestedPathsAndCustomOperationsHonorIdentifierOverrides() {
        let child = ApiRestResource(dataType: .object("Photo") {}, identifier: .string(pathParameterName: "photo_key"), operationTypes: .readOnly, path: "/profile/photos/")
        let parent = ApiRestResource(
            dataType: user,
            identifier: .uuid(pathParameterName: "user_key"),
            operationTypes: .readOnly,
            subResources: [child],
            subOperations: [.post(name: "activate", path: .relative("/activate/"), security: .optional)],
            path: "/users/",
            security: .secured
        )
        let definitions = parent.generateDefinitions()
        #expect(definitions[0].operations.last.flatMap(relativePath) == "/users/{user_key}/activate")
        #expect(definitions[0].operations.last?.security == .optional)
        #expect(relativePath(definitions[1].operations[0]) == "/users/{user_key}/profile/photos")
        #expect(relativePath(definitions[1].operations[1]) == "/users/{user_key}/profile/photos/{photo_key}")
        #expect(definitions[1].operations[1].parameters.map(\.rawName) == ["user_key", "photo_key"])
        #expect(definitions[1].operations.allSatisfy { $0.security == .unsecured })
    }
}
