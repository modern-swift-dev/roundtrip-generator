import Foundation
import GeneratorBuilder

public struct ApiOperation: Sendable {

    /// The name of the operation
    ///
    /// > This is used to derive the name of the method in Swift
    public let name: String

    /// The http method
    public let method: HttpMethod

    /// The query path
    public let path: ApiOperationPath

    /// The parameters
    public let parameters: [ApiParameter]

    /// The request type
    public let request: ApiRequestBody

    /// The response type
    public let response: ApiResponseBody

    /// The acceptable status
    public let acceptableStatuses: [Int]

    /// The extra imports for this operation
    public let extraImports: [ApiImport]

    /// The security
    public let security: ApiAuthorizationHeaderPolicy

    /// The expanded parameters
    public var expandedParameters: [ApiParameter] {
        var params: [ApiParameter] = parameters
        security.append(to: &params)
        return params
    }

    public init(
        name: String,
        method: HttpMethod,
        path: ApiOperationPath,
        security: ApiAuthorizationHeaderPolicy,
        parameters: [ApiParameter],
        request: ApiRequestBody,
        response: ApiResponseBody,
        acceptableStatuses: [Int],
        extraImports: [ApiImport]
    ) {
        self.name = name
        self.method = method
        self.path = path
        self.parameters = parameters
        self.request = request
        self.response = response
        self.acceptableStatuses = acceptableStatuses
        self.extraImports = extraImports
        self.security = security
    }
}

// MARK: - Extending Sugar Syntax
public extension ApiOperation {

    /// A utility method allowing to get a copy of an existing operation with appended array of `ApiParameter`
    /// - parameter parameters: The list of api parameter to add
    /// - returns: The copied operation
    ///
    /// > Note this is useful for operation extension
    func adding(_ parameters: [ApiParameter]) -> ApiOperation {
        .init(
            name: name,
            method: method,
            path: path,
            security: security,
            parameters: self.parameters + parameters,
            request: request,
            response: response,
            acceptableStatuses: acceptableStatuses,
            extraImports: extraImports
        )
    }

    /// A utility method allowing to get a copy of an existing operation with a new request `ApiTypeSchema`
    /// - parameter handler: A method returning the new data-type
    /// - returns: The copied operation
    ///
    /// > Note this is useful for operation extension
    func adaptingRequest(_ handler: (ApiTypeSchema?) -> ApiTypeSchema?) -> ApiOperation {
        let adaptedRequest: ApiRequestBody = switch request {
            case let .json(type):
                .json(handler(type))
            case .none:
                if let type = handler(nil) {
                    .json(type)
                } else {
                    .none
                }
            case .binary,
                 .file,
                 .multiPart:
                request
        }

        return .init(
            name: name,
            method: method,
            path: path,
            security: security,
            parameters: parameters,
            request: adaptedRequest,
            response: response,
            acceptableStatuses: acceptableStatuses,
            extraImports: extraImports
        )

    }

    /// A utility method allowing to get a copy of an existing operation with a new response `ApiTypeSchema`
    /// - parameter handler: A method returning the new data-type
    /// - returns: The copied operation
    ///
    /// > Note this is useful for operation extension
    func adaptingResponse(_ handler: (ApiTypeSchema?) -> ApiTypeSchema?) -> ApiOperation {
        let adaptedResponse: ApiResponseBody = switch response {
            case let .json(type):
                .json(handler(type))
            case .none:
                if let type = handler(nil) {
                    .json(type)
                } else {
                    .none
                }
            case .binary:
                response
        }

        return .init(
            name: name,
            method: method,
            path: path,
            security: security,
            parameters: parameters,
            request: request,
            response: adaptedResponse,
            acceptableStatuses: acceptableStatuses,
            extraImports: extraImports
        )
    }

    /// A utility method allowing to get a copy of an existing operation with a new name
    /// - parameter newName: The new name
    /// - returns: The copied operation
    ///
    /// > Note this is useful for operation extension
    func renaming(to newName: String) -> ApiOperation {
        .init(
            name: newName,
            method: method,
            path: path,
            security: security,
            parameters: parameters,
            request: request,
            response: response,
            acceptableStatuses: acceptableStatuses,
            extraImports: extraImports
        )
    }

    /// Returns a copy of this operation with appended extra imports.
    /// - parameter extras: Imports to append to the operation.
    /// - returns: The copied operation.
    func withExtraImports(_ extras: [ApiImport]) -> ApiOperation {
        .init(
            name: name,
            method: method,
            path: path,
            security: security,
            parameters: parameters,
            request: request,
            response: response,
            acceptableStatuses: acceptableStatuses,
            extraImports: extraImports + extras
        )
    }
}

// MARK: - Creation-Time Syntax
public extension ApiOperation {

    /// Create a json `GET` operation
    ///
    /// - parameter name: The name of the operation. Ex: `getUsers`
    /// - parameter path: The request path of the operation. Ex: `.relative("/user")`
    /// - parameter security: The security level of the operation. Defaults to `secured`
    /// - parameter parameters: The list of `path`, `query` or `header` parameters for the operation
    /// - parameter response: The response `ApiTypeSchema` of the operation.
    /// - parameter acceptableStatuses: The list of acceptable http status code for this operation. Defaults to 200
    /// - parameter extraImports: Imports added to the generated operation file.
    static func get(
        name: String,
        path: ApiOperationPath,
        security: ApiAuthorizationHeaderPolicy = .secured,
        parameters: [ApiParameter] = [],
        response: ApiTypeSchema? = nil,
        acceptableStatuses: [Int] = [200],
        extraImports: [ApiImport] = []
    ) -> ApiOperation {
        .init(
            name: name.capitalCased,
            method: .get,
            path: path,
            security: security,
            parameters: parameters,
            request: .none,
            response: response != nil ? .json(response) : .none,
            acceptableStatuses: acceptableStatuses,
            extraImports: extraImports
        )
    }

    /// Create a json `POST` operation
    ///
    /// - parameter name: The name of the operation. Ex: `createUser`
    /// - parameter path: The request path of the operation. Ex: `.relative("/user")`
    /// - parameter security: The security level of the operation. Defaults to `secured`
    /// - parameter parameters: The list of `path`, `query` or `header` parameters for the operation
    /// - parameter request: The request `ApiTypeSchema` of the operation.
    /// - parameter response: The response `ApiTypeSchema` of the operation. Defaults to `nil`
    /// - parameter acceptableStatuses: The list of acceptable http status code for this operation. Defaults to 200, 201, 204
    /// - parameter extraImports: Imports added to the generated operation file.
    static func post(
        name: String,
        path: ApiOperationPath,
        security: ApiAuthorizationHeaderPolicy = .secured,
        parameters: [ApiParameter] = [],
        request: ApiTypeSchema?,
        response: ApiTypeSchema? = nil,
        acceptableStatuses: [Int] = [200, 201, 204],
        extraImports: [ApiImport] = []
    ) -> ApiOperation {
        .init(
            name: name.capitalCased,
            method: .post,
            path: path,
            security: security,
            parameters: parameters,
            request: .json(request),
            response: response.map { .json($0) } ?? .none,
            acceptableStatuses: acceptableStatuses,
            extraImports: extraImports
        )
    }

    /// Create a `POST` operation
    ///
    /// - parameter name: The name of the operation. Ex: `createUser`
    /// - parameter path: The request path of the operation. Ex: `.relative("/user")`
    /// - parameter security: The security level of the operation. Defaults to `secured`
    /// - parameter parameters: The list of `path`, `query` or `header` parameters for the operation
    /// - parameter request: The request type of the operation. Defaults to `none`
    /// - parameter response: The response type of the operation. Defaults to `none`
    /// - parameter acceptableStatuses: The list of acceptable http status code for this operation. Defaults to 200, 201, 204
    /// - parameter extraImports: Imports added to the generated operation file.
    static func post(
        name: String,
        path: ApiOperationPath,
        security: ApiAuthorizationHeaderPolicy = .secured,
        parameters: [ApiParameter] = [],
        requestType: ApiRequestBody = .none,
        responseType: ApiResponseBody = .none,
        acceptableStatuses: [Int] = [200, 201, 204],
        extraImports: [ApiImport] = []
    ) -> ApiOperation {
        .init(
            name: name.capitalCased,
            method: .post,
            path: path,
            security: security,
            parameters: parameters,
            request: requestType,
            response: responseType,
            acceptableStatuses: acceptableStatuses,
            extraImports: extraImports
        )
    }

    /// Create a multipart `POST` operation
    ///
    /// - parameter name: The name of the operation. Ex: `sendPicture`
    /// - parameter path: The request path of the operation. Ex: `.relative("/attachment/pictures")`
    /// - parameter security: The security level of the operation. Defaults to `secured`
    /// - parameter parameters: The list of `path`, `query` or `header` parameters for the operation
    /// - parameter multiParts: The list of parts. Ex: `["file", "metadata"]`
    /// - parameter response: The response type of the operation. Defaults to nil
    /// - parameter acceptableStatuses: The list of acceptable http status code for this operation. Defaults to 200, 201, 204
    /// - parameter extraImports: Imports added to the generated operation file.
    static func postMultipart(
        name: String,
        path: ApiOperationPath,
        security: ApiAuthorizationHeaderPolicy = .secured,
        parameters: [ApiParameter] = [],
        multiParts: [String],
        response: ApiTypeSchema? = nil,
        acceptableStatuses: [Int] = [200, 201, 204],
        extraImports: [ApiImport] = []
    ) -> ApiOperation {
        .init(
            name: name.capitalCased,
            method: .post,
            path: path,
            security: security,
            parameters: parameters,
            request: .multiPart(multiParts),
            response: response.map { .json($0) } ?? .none,
            acceptableStatuses: acceptableStatuses,
            extraImports: extraImports
        )
    }

    /// Create a `PATCH` operation
    ///
    /// - parameter name: The name of the operation. Ex: `updateUser`
    /// - parameter path: The request path of the operation. Ex: `.relative("/user/{id}")`
    /// - parameter security: The security level of the operation. Defaults to `secured`
    /// - parameter parameters: The list of `path`, `query` or `header` parameters for the operation
    /// - parameter request: The request type of the operation
    /// - parameter response: The response type of the operation. Defaults to nil
    /// - parameter acceptableStatuses: The list of acceptable http status code for this operation. Defaults to 200
    /// - parameter extraImports: Imports added to the generated operation file.
    static func patch(
        name: String,
        path: ApiOperationPath,
        security: ApiAuthorizationHeaderPolicy = .secured,
        parameters: [ApiParameter] = [],
        request: ApiTypeSchema,
        response: ApiTypeSchema? = nil,
        acceptableStatuses: [Int] = [200],
        extraImports: [ApiImport] = []
    ) -> ApiOperation {
        .init(
            name: name.capitalCased,
            method: .patch,
            path: path,
            security: security,
            parameters: parameters,
            request: .json(request),
            response: response.map { .json($0) } ?? .none,
            acceptableStatuses: acceptableStatuses,
            extraImports: extraImports
        )
    }

    /// Create a `PUT` operation
    ///
    /// - parameter name: The name of the operation. Ex: `updateUser`
    /// - parameter path: The request path of the operation. Ex: `.relative("/user/{id}")`
    /// - parameter security: The security level of the operation. Defaults to `secured`
    /// - parameter parameters: The list of `path`, `query` or `header` parameters for the operation
    /// - parameter request: The request type of the operation
    /// - parameter response: The response type of the operation. Defaults to nil
    /// - parameter acceptableStatuses: The list of acceptable http status code for this operation. Defaults to 200
    /// - parameter extraImports: Imports added to the generated operation file.
    static func put(
        name: String,
        path: ApiOperationPath,
        security: ApiAuthorizationHeaderPolicy = .secured,
        parameters: [ApiParameter] = [],
        request: ApiTypeSchema,
        response: ApiTypeSchema? = nil,
        acceptableStatuses: [Int] = [200],
        extraImports: [ApiImport] = []
    ) -> ApiOperation {
        .init(
            name: name.capitalCased,
            method: .put,
            path: path,
            security: security,
            parameters: parameters,
            request: .json(request),
            response: response.map { .json($0) } ?? .none,
            acceptableStatuses: acceptableStatuses,
            extraImports: extraImports
        )
    }

    /// Create a `DELETE` operation
    ///
    /// - parameter name: The name of the operation. Ex: `deleteUser`
    /// - parameter path: The request path of the operation. Ex: `.relative("/user/{id}")`
    /// - parameter security: The security level of the operation. Defaults to `secured`
    /// - parameter parameters: The list of `path`, `query` or `header` parameters for the operation
    /// - parameter request: The optional request body data type.
    /// - parameter response: The response type of the operation. Defaults to nil
    /// - parameter acceptableStatuses: The list of acceptable http status code for this operation. Defaults to 200, 204, 205
    /// - parameter extraImports: Imports added to the generated operation file.
    static func delete(
        name: String,
        path: ApiOperationPath,
        security: ApiAuthorizationHeaderPolicy = .secured,
        parameters: [ApiParameter] = [],
        request: ApiTypeSchema? = nil,
        response: ApiTypeSchema? = nil,
        acceptableStatuses: [Int] = [200, 204, 205],
        extraImports: [ApiImport] = []
    ) -> ApiOperation {
        .init(
            name: name.capitalCased,
            method: .delete,
            path: path,
            security: security,
            parameters: parameters,
            request: request == nil ? .none : .json(request),
            response: response.map { .json($0) } ?? .none,
            acceptableStatuses: acceptableStatuses,
            extraImports: extraImports
        )
    }
}
