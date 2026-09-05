import Foundation
import GeneratorBuilder

/// A group of REST resources that can generate a full ``ApiModule`` with
/// conventional operations and data types.
public class ApiRestResourceGroup {
    /// The module name generated for these resources.
    public let name: String

    /// The resources used to generate module definitions.
    public let resources: [ApiRestResource]

    /// Data types generated at module scope.
    public let references: [ApiTypeSchema]

    /// Parameters inherited by every generated resource operation.
    public let parameters: [ApiParameter]

    /// Initializer
    public init(
        name: String = "",
        references: [ApiTypeSchema] = [],
        parameters: [ApiParameter] = [],
        resources: [ApiRestResource],
    ) {
        self.name = name
        self.resources = resources
        self.parameters = parameters
        self.references = references
    }

    /// Generates an ``ApiModule`` from the resource declarations.
    public func module() -> ApiModule {
        .init(
            name: name,
            definitions: resources.flatMap { $0.generateDefinitions(parentPathParams: parameters) },
            references: references,
        )
    }
}

/// A resource definition
public struct ApiRestResource: Sendable {
    /// Conventional operations that can be generated for a resource.
    public enum Operation: Sendable {
        /// Generates a `POST /resource` operation.
        case create

        /// Generates a `DELETE /resource/{resource_id}` operation.
        case delete

        /// Generates a `PUT /resource/{resource_id}` operation.
        case update

        /// Generates a `PATCH /resource/{resource_id}` operation.
        case patch

        /// Generates a `GET /resource/{resource_id}` operation.
        case retrieve

        /// Generates a `GET /resource` operation, returning either paged results or an array.
        case list([ApiParameter], paged: Bool)
    }

    /// The resource type name.
    public let typeName: String

    /// The request data type used for create and update operations.
    public let dataType: ApiTypeSchema

    /// The `id` property
    public let identifierProperty: ApiModelProperty

    /// The data type used by generated id path parameters.
    public let identifierPathParamType: ApiParameter.DataType

    /// The response data type for operations returning only the identifier.
    public let referenceDataType: ApiTypeSchema

    /// The response data type for persisted resources.
    public let identifiedDataType: ApiTypeSchema

    /// The request data type used for patch operations.
    public let patchableDatatype: ApiTypeSchema

    /// The sub-resources (if any)
    public let subResources: [ApiRestResource]

    /// The Operation types for this resource
    public let operationTypes: [Operation]

    /// Additional data types generated with this resource definition.
    public let references: [ApiTypeSchema]

    /// Extra operations generated below the resource id path, preserving their own security.
    public let subOperations: [ApiOperation]

    /// The relative resource path, normalized without leading or trailing slashes.
    public let path: String

    /// Security applied to conventional operations.
    public let security: ApiAuthorizationHeaderPolicy

    /// The wire name of the resource identifier path parameter.
    public let identifierPathParameterName: String

    /// Initializer
    public init(
        name: String? = nil,
        dataType: ApiTypeSchema,
        identifierProperty: ApiModelProperty = .int64("id"),
        identifierPathParamType: ApiParameter.DataType = .int64(),
        operationTypes: [Operation] = [
            .create,
            .update,
            .patch,
            .delete,
            .list([], paged: true),
            .retrieve
        ],
        metadataProperties: [ApiModelProperty] = [],
        references: [ApiTypeSchema] = [],
        subResources: [ApiRestResource] = [],
        subOperations: [ApiOperation] = [],
        path: String? = nil,
        security: ApiAuthorizationHeaderPolicy = .unsecured,
        identifierPathParameterName: String? = nil,
    ) {
        typeName = name ?? dataType.typeName ?? ""
        self.path = (path ?? typeName.lowercased()).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        self.security = security
        self.identifierPathParameterName = identifierPathParameterName ?? "\(typeName.lowercased())_id"
        self.operationTypes = operationTypes
        self.dataType = dataType
        self.identifierProperty = identifierProperty
        self.identifierPathParamType = identifierPathParamType

        referenceDataType = .object(typeName: "Id\(typeName)", properties: [
            identifierProperty
        ])

        if case let .object(_, properties, protocols, imports, isValueType, _) = dataType {
            identifiedDataType = .object(
                typeName: "Identified\(typeName)",
                properties: [identifierProperty] + properties + metadataProperties,
                protocols: protocols + ["Identifiable"],
                imports: imports,
                isValueType: isValueType,
            )

            patchableDatatype = .object(
                typeName: "Patched\(typeName)",
                properties: properties.map { prop in
                    ApiModelProperty(
                        rawName: prop.rawName,
                        propertyName: prop.propertyName,
                        dataType: prop.dataType.asPatchable,
                        required: prop.required,
                        equatable: prop.equatable,
                        hashable: prop.hashable,
                        publishedAsField: prop.publishedAsField,
                    )
                },
                protocols: protocols,
                imports: imports,
                isValueType: isValueType,
            )
        } else {
            identifiedDataType = dataType
            patchableDatatype = dataType
        }

        self.subResources = subResources
        self.references = references
        self.subOperations = subOperations
    }

    private func resourcePath(parentPath: String) -> String {
        let parent = parentPath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return "/" + [parent, path].filter { !$0.isEmpty }.joined(separator: "/")
    }

    // swiftlint:disable function_body_length
    public func generateOperations(parentPath: String, parentPathParams: [ApiParameter]) -> [ApiOperation] {
        var operations: [ApiOperation] = []
        for type in operationTypes {
            switch type {
                case .create:
                    operations.append(
                        .post(
                            name: "create",
                            path: .relative(resourcePath(parentPath: parentPath)),
                            security: security,
                            parameters: parentPathParams,
                            request: dataType.asRef,
                            response: referenceDataType.asRef,
                            acceptableStatuses: [200, 201],
                        ),
                    )
                case .delete:
                    operations.append(
                        .delete(
                            name: "delete",
                            path: .relative("\(resourcePath(parentPath: parentPath))/{\(identifierPathParameterName)}"),
                            security: security,
                            parameters: parentPathParams + [
                                .path(identifierPathParameterName, identifierPathParamType)
                            ],
                        ),
                    )
                case .update:
                    operations.append(
                        .put(
                            name: "update",
                            path: .relative("\(resourcePath(parentPath: parentPath))/{\(identifierPathParameterName)}"),
                            security: security,
                            parameters: parentPathParams + [
                                .path(identifierPathParameterName, identifierPathParamType)
                            ],
                            request: dataType.asRef,
                            response: referenceDataType.asRef,
                            acceptableStatuses: [200],
                        ),
                    )
                case .patch:
                    operations.append(
                        .patch(
                            name: "patch",
                            path: .relative("\(resourcePath(parentPath: parentPath))/{\(identifierPathParameterName)}"),
                            security: security,
                            parameters: parentPathParams + [
                                .path(identifierPathParameterName, identifierPathParamType)
                            ],
                            request: patchableDatatype.asRef,
                            response: referenceDataType.asRef,
                            acceptableStatuses: [200],
                        ),
                    )
                case .retrieve:
                    operations.append(
                        .get(
                            name: "get",
                            path: .relative("\(resourcePath(parentPath: parentPath))/{\(identifierPathParameterName)}"),
                            security: security,
                            parameters: parentPathParams + [
                                .path(identifierPathParameterName, identifierPathParamType)
                            ],
                            response: identifiedDataType.asRef,
                        ),
                    )
                case let .list(listParameters, paged):
                    if paged {
                        operations.append(
                            .get(
                                name: "list",
                                path: .relative(resourcePath(parentPath: parentPath)),
                                security: security,
                                parameters: parentPathParams + listParameters,
                                response: .genericReference(typeName: "PagedResults", genericTypes: [identifiedDataType.asRef]),
                            ),
                        )
                    } else {
                        operations.append(
                            .get(
                                name: "list",
                                path: .relative(resourcePath(parentPath: parentPath)),
                                security: security,
                                parameters: parentPathParams + listParameters,
                                response: .array(identifiedDataType.asRef),
                            ),
                        )
                    }
            }
        }

        for extraOperation in subOperations {
            let resourceIdParameter = ApiParameter.path(identifierPathParameterName, identifierPathParamType)
            let generatedPath = extraOperation.path.appending(
                toResourcePath: "\(resourcePath(parentPath: parentPath))/{\(identifierPathParameterName)}",
                fallbackSuffix: extraOperation.name.lowercased(),
            )
            let inheritedParameters = switch generatedPath {
                case .relative:
                    parentPathParams + [resourceIdParameter]
                case .absolute,
                     .runtime:
                    parentPathParams
            }
            operations.append(
                ApiOperation(
                    name: extraOperation.name,
                    method: extraOperation.method,
                    path: generatedPath,
                    security: extraOperation.security,
                    parameters: inheritedParameters + extraOperation.parameters,
                    request: extraOperation.request,
                    response: extraOperation.response,
                    acceptableStatuses: extraOperation.acceptableStatuses,
                    extraImports: extraOperation.extraImports,
                ),
            )
        }

        return operations
    }

    public func generateDefinitions(parentTypeName: String = "", parentPath: String = "", parentPathParams: [ApiParameter] = [], parentReferences: [ApiTypeSchema] = []) -> [ApiService] {
        var definitions: [ApiService] = []
        let operations: [ApiOperation] = generateOperations(
            parentPath: parentPath,
            parentPathParams: parentPathParams,
        )
        let definition: ApiService = .init(
            name: "\(parentTypeName)\(typeName)".capitalCased,
            operations: operations,
            references: [
                dataType,
                identifiedDataType,
                referenceDataType,
                patchableDatatype
            ] + references + parentReferences,
        )
        definitions.append(definition)

        let childParentPath = "\(resourcePath(parentPath: parentPath))/{\(identifierPathParameterName)}"
        let childParentParams = parentPathParams + [
            .path(identifierPathParameterName, identifierPathParamType)
        ]
        for sub in subResources {
            definitions += sub.generateDefinitions(
                parentTypeName: "\(parentTypeName)\(typeName)",
                parentPath: childParentPath,
                parentPathParams: childParentParams,
                parentReferences: references + parentReferences,
            )
        }
        return definitions
    }
}

private extension ApiOperationPath {
    func appending(toResourcePath resourcePath: String, fallbackSuffix: String) -> ApiOperationPath {
        switch self {
            case let .relative(path):
                let suffix = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                let effectiveSuffix = suffix.isEmpty ? fallbackSuffix : suffix
                return .relative("\(resourcePath)/\(effectiveSuffix)")
            case .absolute,
                 .runtime:
                return self
        }
    }
}

private extension ApiTypeSchema {
    var canModifyObjectProperties: Bool {
        switch self {
            case .object:
                true
            default:
                false
        }
    }
}
