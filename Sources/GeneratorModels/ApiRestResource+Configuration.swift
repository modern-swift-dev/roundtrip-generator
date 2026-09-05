import Foundation

public extension ApiRestResource {
    /// A single identifier declaration supplies the model property and URL parameter type.
    struct Identifier: Sendable {
        public enum Kind: Sendable {
            case int64
            case string
            case uuid
        }

        public let name: String
        public let kind: Kind
        public let pathParameterName: String?

        public init(name: String = "id", kind: Kind, pathParameterName: String? = nil) {
            self.name = name
            self.kind = kind
            self.pathParameterName = pathParameterName
        }

        public static func int64(_ name: String = "id", pathParameterName: String? = nil) -> Self {
            .init(name: name, kind: .int64, pathParameterName: pathParameterName)
        }

        public static func string(_ name: String = "id", pathParameterName: String? = nil) -> Self {
            .init(name: name, kind: .string, pathParameterName: pathParameterName)
        }

        /// UUID identifiers use a UUID model property and a string URL parameter.
        public static func uuid(_ name: String = "id", pathParameterName: String? = nil) -> Self {
            .init(name: name, kind: .uuid, pathParameterName: pathParameterName)
        }

        /// The identifier always exposes `id` in generated code to satisfy `Identifiable`.
        public var property: ApiModelProperty {
            switch kind {
                case .int64: .int64(name, propertyName: "id")
                case .string: .string(name, propertyName: "id")
                case .uuid: .uuid(name, propertyName: "id")
            }
        }

        public var parameterType: ApiParameter.DataType {
            switch kind {
                case .int64: .int64()
                case .string,
                     .uuid: .string()
            }
        }
    }

    /// The response shape for conventional list operations.
    enum ListResponseShape: Sendable {
        /// A plain array of identified resources.
        case array
        /// A `PagedResults` reference containing identified resources.
        case pagedResults
    }

    /// Declares a resource with a shared, typed model and path identifier configuration.
    init(
        name: String? = nil,
        dataType: ApiTypeSchema,
        identifier: Identifier,
        operationTypes: [Operation] = .crud,
        metadataProperties: [ApiModelProperty] = [],
        references: [ApiTypeSchema] = [],
        subResources: [ApiRestResource] = [],
        subOperations: [ApiOperation] = [],
        path: String? = nil,
        security: ApiAuthorizationHeaderPolicy = .unsecured,
    ) {
        self.init(
            name: name,
            dataType: dataType,
            identifierProperty: identifier.property,
            identifierPathParamType: identifier.parameterType,
            operationTypes: operationTypes,
            metadataProperties: metadataProperties,
            references: references,
            subResources: subResources,
            subOperations: subOperations,
            path: path,
            security: security,
            identifierPathParameterName: identifier.pathParameterName,
        )
    }
}

public extension ApiRestResource.Operation {
    /// Generates a list operation with an explicit response shape.
    static func list(parameters: [ApiParameter] = [], pagination: ApiRestResource.ListResponseShape = .pagedResults) -> Self {
        .list(parameters, paged: pagination == .pagedResults)
    }
}

public extension [ApiRestResource.Operation] {
    /// List and retrieve operations, with paged list responses.
    static var readOnly: Self {
        [.list(), .retrieve]
    }

    /// The standard create, update, patch, delete, list, and retrieve operations.
    static var crud: Self {
        [.create, .update, .patch, .delete, .list(), .retrieve]
    }
}
