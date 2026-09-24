import Foundation
import GeneratorBuilder

/// A public, non-success response that is part of an operation's wire contract.
///
/// Generated clients treat these statuses as failures while retaining their raw
/// response for application-owned error handling. Generated server and OpenAPI
/// targets validate and describe the declared body for the matching status.
public struct ApiPublicError: Sendable {
    public let status: Int
    public let response: ApiResponseBody

    public init(status: Int, response: ApiResponseBody) {
        self.status = status
        self.response = response
    }
}

/// A successful status whose body or required headers differ from the operation default.
public struct ApiSuccessResponse: Sendable {
    public let status: Int
    public let response: ApiResponseBody
    public let requiredHeaders: [String]

    public init(status: Int, response: ApiResponseBody, requiredHeaders: [String] = []) {
        self.status = status
        self.response = response
        self.requiredHeaders = requiredHeaders
    }
}

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

    /// Multipart names represented as arrays of files in generated API descriptions.
    public let repeatedMultipartParts: Set<String>

    /// Multipart names that may be omitted from a request. All others remain required.
    public let optionalMultipartParts: Set<String>

    /// Multipart names whose wire content is text rather than binary.
    public let textMultipartParts: Set<String>

    /// Maximum number of parts permitted for each repeated multipart name.
    public let maxMultipartParts: [String: Int]

    /// The response type
    public let response: ApiResponseBody

    /// The acceptable status
    public let acceptableStatuses: [Int]

    /// Additional statuses accepted by clients after HTTP redirects, not declared endpoint responses.
    public let clientOnlyAcceptableStatuses: [Int]

    /// Statuses accepted when a generated client observes the final HTTP response.
    public var clientAcceptableStatuses: [Int] {
        acceptableStatuses + clientOnlyAcceptableStatuses
    }

    /// Status-specific overrides for successful response bodies and required headers.
    public let successResponses: [ApiSuccessResponse]

    /// Public errors, each with its declared HTTP status and response body.
    public let publicErrors: [ApiPublicError]

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
        repeatedMultipartParts: Set<String> = [],
        optionalMultipartParts: Set<String> = [],
        textMultipartParts: Set<String> = [],
        maxMultipartParts: [String: Int] = [:],
        response: ApiResponseBody,
        acceptableStatuses: [Int],
        clientOnlyAcceptableStatuses: [Int] = [],
        successResponses: [ApiSuccessResponse] = [],
        publicErrors: [ApiPublicError] = [],
        extraImports: [ApiImport],
    ) {
        self.name = name
        self.method = method
        self.path = path
        self.parameters = parameters
        self.request = request
        self.repeatedMultipartParts = repeatedMultipartParts
        self.optionalMultipartParts = optionalMultipartParts
        self.textMultipartParts = textMultipartParts
        self.maxMultipartParts = maxMultipartParts
        self.response = response
        self.acceptableStatuses = acceptableStatuses
        self.clientOnlyAcceptableStatuses = clientOnlyAcceptableStatuses
        self.successResponses = successResponses
        self.publicErrors = publicErrors
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
            repeatedMultipartParts: repeatedMultipartParts,
            optionalMultipartParts: optionalMultipartParts,
            textMultipartParts: textMultipartParts,
            maxMultipartParts: maxMultipartParts,
            response: response,
            acceptableStatuses: acceptableStatuses,
            clientOnlyAcceptableStatuses: clientOnlyAcceptableStatuses,
            successResponses: successResponses,
            publicErrors: publicErrors,
            extraImports: extraImports,
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
            repeatedMultipartParts: repeatedMultipartParts,
            optionalMultipartParts: optionalMultipartParts,
            textMultipartParts: textMultipartParts,
            maxMultipartParts: maxMultipartParts,
            response: response,
            acceptableStatuses: acceptableStatuses,
            clientOnlyAcceptableStatuses: clientOnlyAcceptableStatuses,
            successResponses: successResponses,
            publicErrors: publicErrors,
            extraImports: extraImports,
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
            repeatedMultipartParts: repeatedMultipartParts,
            optionalMultipartParts: optionalMultipartParts,
            textMultipartParts: textMultipartParts,
            maxMultipartParts: maxMultipartParts,
            response: adaptedResponse,
            acceptableStatuses: acceptableStatuses,
            clientOnlyAcceptableStatuses: clientOnlyAcceptableStatuses,
            successResponses: successResponses,
            publicErrors: publicErrors,
            extraImports: extraImports,
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
            repeatedMultipartParts: repeatedMultipartParts,
            optionalMultipartParts: optionalMultipartParts,
            textMultipartParts: textMultipartParts,
            maxMultipartParts: maxMultipartParts,
            response: response,
            acceptableStatuses: acceptableStatuses,
            clientOnlyAcceptableStatuses: clientOnlyAcceptableStatuses,
            successResponses: successResponses,
            publicErrors: publicErrors,
            extraImports: extraImports,
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
            repeatedMultipartParts: repeatedMultipartParts,
            optionalMultipartParts: optionalMultipartParts,
            textMultipartParts: textMultipartParts,
            maxMultipartParts: maxMultipartParts,
            response: response,
            acceptableStatuses: acceptableStatuses,
            clientOnlyAcceptableStatuses: clientOnlyAcceptableStatuses,
            successResponses: successResponses,
            publicErrors: publicErrors,
            extraImports: extraImports + extras,
        )
    }

    /// Returns a copy with a status-specific successful response contract.
    func withSuccessResponse(status: Int, response: ApiResponseBody, requiredHeaders: [String] = []) -> ApiOperation {
        .init(
            name: name,
            method: method,
            path: path,
            security: security,
            parameters: parameters,
            request: request,
            repeatedMultipartParts: repeatedMultipartParts,
            optionalMultipartParts: optionalMultipartParts,
            textMultipartParts: textMultipartParts,
            maxMultipartParts: maxMultipartParts,
            response: self.response,
            acceptableStatuses: acceptableStatuses,
            clientOnlyAcceptableStatuses: clientOnlyAcceptableStatuses,
            successResponses: successResponses + [.init(status: status, response: response, requiredHeaders: requiredHeaders)],
            publicErrors: publicErrors,
            extraImports: extraImports,
        )
    }

    /// Marks declared multipart names that may occur more than once on the wire.
    func withRepeatedMultipartParts(_ names: Set<String>) -> ApiOperation {
        .init(
            name: name,
            method: method,
            path: path,
            security: security,
            parameters: parameters,
            request: request,
            repeatedMultipartParts: names,
            optionalMultipartParts: optionalMultipartParts,
            textMultipartParts: textMultipartParts,
            maxMultipartParts: maxMultipartParts,
            response: response,
            acceptableStatuses: acceptableStatuses,
            clientOnlyAcceptableStatuses: clientOnlyAcceptableStatuses,
            successResponses: successResponses,
            publicErrors: publicErrors,
            extraImports: extraImports,
        )
    }

    /// Marks declared multipart names that may be omitted from a request.
    func withOptionalMultipartParts(_ names: Set<String>) -> ApiOperation {
        .init(
            name: name,
            method: method,
            path: path,
            security: security,
            parameters: parameters,
            request: request,
            repeatedMultipartParts: repeatedMultipartParts,
            optionalMultipartParts: names,
            textMultipartParts: textMultipartParts,
            maxMultipartParts: maxMultipartParts,
            response: response,
            acceptableStatuses: acceptableStatuses,
            clientOnlyAcceptableStatuses: clientOnlyAcceptableStatuses,
            successResponses: successResponses,
            publicErrors: publicErrors,
            extraImports: extraImports,
        )
    }

    /// Marks declared multipart names whose wire content is text rather than binary.
    func withTextMultipartParts(_ names: Set<String>) -> ApiOperation {
        .init(
            name: name,
            method: method,
            path: path,
            security: security,
            parameters: parameters,
            request: request,
            repeatedMultipartParts: repeatedMultipartParts,
            optionalMultipartParts: optionalMultipartParts,
            textMultipartParts: names,
            maxMultipartParts: maxMultipartParts,
            response: response,
            acceptableStatuses: acceptableStatuses,
            clientOnlyAcceptableStatuses: clientOnlyAcceptableStatuses,
            successResponses: successResponses,
            publicErrors: publicErrors,
            extraImports: extraImports,
        )
    }

    /// Sets maximum counts for repeated multipart names.
    func withMaxMultipartParts(_ maximums: [String: Int]) -> ApiOperation {
        .init(
            name: name,
            method: method,
            path: path,
            security: security,
            parameters: parameters,
            request: request,
            repeatedMultipartParts: repeatedMultipartParts,
            optionalMultipartParts: optionalMultipartParts,
            textMultipartParts: textMultipartParts,
            maxMultipartParts: maximums,
            response: response,
            acceptableStatuses: acceptableStatuses,
            clientOnlyAcceptableStatuses: clientOnlyAcceptableStatuses,
            successResponses: successResponses,
            publicErrors: publicErrors,
            extraImports: extraImports,
        )
    }

    /// Accepts additional client-observed statuses without declaring endpoint responses.
    func withClientOnlyAcceptableStatuses(_ statuses: [Int]) -> ApiOperation {
        .init(
            name: name,
            method: method,
            path: path,
            security: security,
            parameters: parameters,
            request: request,
            repeatedMultipartParts: repeatedMultipartParts,
            optionalMultipartParts: optionalMultipartParts,
            textMultipartParts: textMultipartParts,
            maxMultipartParts: maxMultipartParts,
            response: response,
            acceptableStatuses: acceptableStatuses,
            clientOnlyAcceptableStatuses: statuses,
            successResponses: successResponses,
            publicErrors: publicErrors,
            extraImports: extraImports,
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
        publicErrors: [ApiPublicError] = [],
        extraImports: [ApiImport] = [],
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
            publicErrors: publicErrors,
            extraImports: extraImports,
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
        publicErrors: [ApiPublicError] = [],
        extraImports: [ApiImport] = [],
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
            publicErrors: publicErrors,
            extraImports: extraImports,
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
        publicErrors: [ApiPublicError] = [],
        extraImports: [ApiImport] = [],
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
            publicErrors: publicErrors,
            extraImports: extraImports,
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
        publicErrors: [ApiPublicError] = [],
        extraImports: [ApiImport] = [],
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
            publicErrors: publicErrors,
            extraImports: extraImports,
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
        publicErrors: [ApiPublicError] = [],
        extraImports: [ApiImport] = [],
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
            publicErrors: publicErrors,
            extraImports: extraImports,
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
        publicErrors: [ApiPublicError] = [],
        extraImports: [ApiImport] = [],
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
            publicErrors: publicErrors,
            extraImports: extraImports,
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
        publicErrors: [ApiPublicError] = [],
        extraImports: [ApiImport] = [],
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
            publicErrors: publicErrors,
            extraImports: extraImports,
        )
    }
}
