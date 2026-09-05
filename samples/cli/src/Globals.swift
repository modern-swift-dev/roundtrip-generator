import Foundation
import GeneratorModels
import KotlinApiGenerator
import SwiftApiGenerator
import SwiftVaporGenerator
import TypeScriptApiGenerator

extension ApiPackage {
    static let global: ApiPackage = {
        let currentDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let codeDir = currentDir.appendingPathComponent("/swift-client/src/generated")
        return ApiPackage(
            name: "Global",
            targetDirUrl: codeDir,
            modules: [
                ApiRestResourceGroup(name: "Admin", resources: [
                    .user,
                    .role,
                    .group
                ])
                .module(),

                ApiRestResourceGroup(name: "Location", resources: [
                    .structure
                ])
                .module(),

                ApiModule.showcase,

                ApiRestResourceGroup(
                    name: "Tenant",
                    references: [
                        .predefined.tenantStatus
                    ],
                    parameters: [
                        .header("X-Tenant-Id", .string(), propertyName: "tenantId").immutable
                    ],
                    resources: [
                        .project
                    ],
                )
                .module()
            ],
            referencedModules: [],
            references: [
                .predefined.idObject,
                .predefined.namedObject,
                .predefined.localizedNamedObject,
                .predefined.structureType,
                .predefined.auditStamp
            ],
            commonReferences: [],
            imports: [
                "Combine"
            ],
        )
    }()

    static let globalKotlin = global.output(
        to: URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("kotlin"),
    )

    static let globalAndroid = global.output(
        to: URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("android"),
    )

    static let globalSpring = global.output(
        to: URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("spring"),
    )

    static let globalTypeScript = global.output(
        to: URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("typescript"),
    )

    static let globalOpenApi = global.output(
        to: URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("openapi"),
    )

    static let globalVapor: ApiPackage = {
        let currentDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let codeDir = currentDir.appendingPathComponent("/swift-vapor")
        return ApiPackage(
            name: global.name,
            targetDirUrl: codeDir,
            modules: global.modules.map(\.linuxPortableVaporSample),
            referencedModules: global.referencedModules.map(\.linuxPortableVaporSample),
            references: global.references.map(\.linuxPortableVaporSample),
            commonReferences: global.commonReferences.map(\.linuxPortableVaporSample),
            imports: [],
            generateApiModules: global.generateApiModules,
        )
    }()
}

extension ApiModule {
    static let showcase = ApiModule(
        name: "Showcase",
        definitions: [
            .sampleModels,
            .transport
        ],
        references: [
            .predefined.sampleVisibility
        ],
    )
}

extension ApiService {
    static let sampleModels = ApiService(
        name: "SampleModels",
        operations: [
            .get(
                name: "getMatrix",
                path: .relative("/showcase/matrix/{matrix_id}"),
                security: .optional,
                parameters: [
                    .path("matrix_id", .string(), propertyName: "matrixId").immutable,
                    .query("visible", .bool(true)),
                    .query("visibility", .stringEnumValue(type: .predefined.sampleVisibility.asRef, defaultValue: "public")),
                    .query("scores", .intEnumArray(type: .predefined.sampleScore.asRef, defaultValues: [100])).optional,
                    .header("X-Trace-Id", .string(), propertyName: "traceId").optional,
                    .cookie("sample_session", .string(), propertyName: "sampleSession").optional
                ],
                response: .predefined.primitiveMatrix.asRef,
                acceptableStatuses: [200],
                extraImports: ["UniformTypeIdentifiers"],
            ),
            .post(
                name: "createNotification",
                path: .relative("/showcase/notifications"),
                security: .secured,
                parameters: [
                    .header("Idempotency-Key", .string(), propertyName: "idempotencyKey").optional
                ],
                request: .predefined.notificationEnvelope.asRef,
                response: .predefined.notificationEnvelope.asRef,
                acceptableStatuses: [200, 201, 202],
            ),
            .get(
                name: "followRuntimeUrl",
                path: .runtime,
                security: .optional,
                response: .genericReference(typeName: "PagedResults", genericTypes: [.predefined.primitiveMatrix.asRef]),
            )
        ],
        references: [
            .predefined.primitiveMatrix,
            .predefined.sampleScore,
            .predefined.emailNotification,
            .predefined.pushNotification,
            .predefined.notificationEnvelope
        ],
    )

    static let transport = ApiService(
        name: "Transport",
        operations: [
            .postMultipart(
                name: "uploadMultipart",
                path: .relative("/showcase/uploads/multipart"),
                security: .secured,
                parameters: [
                    .query("compress", .bool(false)).optional
                ],
                multiParts: [
                    "file",
                    "metadata"
                ],
                response: .predefined.uploadReceipt.asRef,
                acceptableStatuses: [200, 201],
            ),
            .post(
                name: "uploadFile",
                path: .relative("/showcase/uploads/file"),
                security: .secured,
                requestType: .file,
                responseType: .json(.predefined.uploadReceipt.asRef),
                acceptableStatuses: [200, 201],
            ),
            .post(
                name: "uploadBinary",
                path: .relative("/showcase/uploads/binary"),
                security: .secured,
                parameters: [
                    .header("Content-MD5", .string(), propertyName: "contentMd5").optional
                ],
                requestType: .binary(mimeType: "application/octet-stream"),
                responseType: .binary(mimeType: "application/zip"),
                acceptableStatuses: [200, 202],
            ),
            .delete(
                name: "deleteWithBody",
                path: .relative("/showcase/uploads"),
                security: .secured,
                request: .predefined.deleteReceiptRequest.asRef,
                response: .predefined.uploadReceipt.asRef,
                acceptableStatuses: [200, 202],
            )
        ],
        references: [
            .predefined.uploadReceipt,
            .predefined.deleteReceiptRequest
        ],
    )
}

extension ApiTypeSchema.predefined {
    static let idObject: ApiTypeSchema = .object(typeName: "IdObject", properties: [
        .int64("id", equatable: true, hashable: true)
    ])

    static let namedObject: ApiTypeSchema = .object(typeName: "NamedObject", properties: [
        .int64("id", equatable: true, hashable: true),
        .string("name")
    ])

    static let localizedNamedObject: ApiTypeSchema = .object(typeName: "LocalizedNamedObject", properties: [
        .int64("id", equatable: true, hashable: true),
        .ref("name", of: .predefined.localizedData)
    ])

    static let localizedData: ApiTypeSchema = .genericReference(typeName: "LocalizedData", genericTypes: [.string()])

    static let structureType: ApiTypeSchema = .stringEnum(typeName: "StructureType", values: [
        (name: "Plant", rawName: "plant"),
        (name: "ProductionLine", rawName: "production_line"),
        (name: "Workstation", rawName: "workstation"),
        (name: "Equipment", rawName: "equipment")
    ])

    static let auditStamp: ApiTypeSchema = .object(typeName: "AuditStamp", properties: [
        .uuid("created_by", propertyName: "createdBy"),
        .date("created_at"),
        .date("updated_at").optional,
        .string("internal_note").unpublished
    ])

    static let sampleVisibility: ApiTypeSchema = .stringEnum(
        typeName: "SampleVisibility",
        values: [
            (name: "Public", rawName: "public"),
            (name: "Internal", rawName: "internal"),
            (name: "Private", rawName: "private")
        ],
        initialValue: "Public",
        supportGarbage: true,
    )

    static let sampleScore: ApiTypeSchema = .intEnum(
        typeName: "SampleScore",
        values: [
            (name: "Low", rawValue: 10),
            (name: "Medium", rawValue: 50),
            (name: "High", rawValue: 100)
        ],
        initialValue: 50,
    )

    static let primitiveMatrix: ApiTypeSchema = .object(
        typeName: "PrimitiveMatrix",
        properties: [
            .uuid("uuid", equatable: true, hashable: true),
            .string("title", initialValue: "Untitled"),
            .int("count", initialValue: 1),
            .int64("large_count", initialValue: 1),
            .int32("medium_count", initialValue: 1),
            .int16("small_count", initialValue: 1),
            .int8("tiny_count", initialValue: 1),
            .uint("unsigned_count", initialValue: 1),
            .uint64("unsigned_large_count", initialValue: 1),
            .uint32("unsigned_medium_count", initialValue: 1),
            .uint16("unsigned_small_count", initialValue: 1),
            .uint8("unsigned_tiny_count", initialValue: 1),
            .double("ratio", initialValue: 0.5),
            .bool("enabled", initialValue: true),
            .date("created_at"),
            .timelessDate("business_date"),
            .time("business_time"),
            .url("callback_url").optional,
            .binary("payload"),
            .keyedByString("metadata", valueType: .string(), valueOptional: true),
            .arrayOfString("aliases"),
            .arrayOfInt("steps"),
            .ref("visibility", of: .predefined.sampleVisibility),
            .ref("score", of: .predefined.sampleScore),
            .object("audit", of: .predefined.auditStamp),
            .arrayOfRef("related", of: .predefined.namedObject),
            .object("external_window", propertyName: "externalWindow", of: .reference(typeName: "DateInterval", strict: false, imports: ["Foundation"])),
            .bool("archived", initialValue: false)
        ],
        protocols: [
            "Equatable",
            "Hashable"
        ],
    )

    static let emailNotification: ApiTypeSchema = .object(typeName: "EmailNotification", properties: [
        .uuid("id", equatable: true, hashable: true),
        .string("subject"),
        .string("body"),
        .arrayOfString("recipients")
    ], protocols: [
        "Identifiable"
    ])

    static let pushNotification: ApiTypeSchema = .object(typeName: "PushNotification", properties: [
        .uuid("id", equatable: true, hashable: true),
        .string("title"),
        .string("body"),
        .keyedByString("custom_data", valueType: .string(), valueOptional: true)
    ], protocols: [
        "Identifiable"
    ])

    static let notificationEnvelope: ApiTypeSchema = .dynamicObject(
        typeName: "NotificationEnvelope",
        objectTypePropertyName: "channel",
        objectDataPropertyName: "payload",
        alternateObjectDataPropertyName: "data",
        objectTypes: [
            (objectTypeName: "Email", objectTypeRawName: "email", objectType: .predefined.emailNotification.asRef),
            (objectTypeName: "Push", objectTypeRawName: "push", objectType: .predefined.pushNotification.asRef)
        ],
        supportGarbage: true,
        extraProperties: [
            .ref("visibility", of: .predefined.sampleVisibility),
            .date("sent_at").optional
        ],
    )

    static let uploadReceipt: ApiTypeSchema = .object(typeName: "UploadReceipt", properties: [
        .uuid("upload_id", propertyName: "uploadId", equatable: true, hashable: true),
        .int64("bytes"),
        .stringEnum(
            "state",
            typeName: "UploadState",
            values: [
                (name: "Queued", rawName: "queued"),
                (name: "Stored", rawName: "stored"),
                (name: "Scanned", rawName: "scanned")
            ],
            initialValue: "Queued",
        )
    ])

    static let deleteReceiptRequest: ApiTypeSchema = .object(typeName: "DeleteReceiptRequest", properties: [
        .array("upload_ids", propertyName: "uploadIds", of: .uuid),
        .string("reason").optional
    ])

    static let tenantStatus: ApiTypeSchema = .stringEnum(typeName: "TenantStatus", values: [
        (name: "Trial", rawName: "trial"),
        (name: "Active", rawName: "active"),
        (name: "Suspended", rawName: "suspended")
    ])
}

extension ApiRestResource {
    static let structure = ApiRestResource(
        name: "Structure",
        dataType: .object(typeName: "Structure", properties: [
            .string("name"),
            .ref("type", of: .predefined.structureType)
        ]),
        identifierProperty: .int64("id"),
        identifierPathParamType: .int64(),
        operationTypes: [
            .create,
            .update,
            .patch,
            .delete,
            .list([
                .query("text", .string()).optional,
                .query("type", .stringEnumArray(type: .predefined.structureType, defaultValues: nil))
            ], paged: true),
            .retrieve
        ],
        metadataProperties: [
            .date("creation_date"),
            .date("last_update_date")
        ],
        references: [],
        subResources: [],
        subOperations: [],
    )

    static let role = ApiRestResource(
        name: "Role",
        dataType: .object(typeName: "Role", properties: [
            .string("name")
        ]),
        identifierProperty: .int64("id"),
        identifierPathParamType: .int64(),
        operationTypes: [
            .create,
            .update,
            .patch,
            .delete,
            .list([
                .query("text", .string()).optional
            ], paged: true),
            .retrieve
        ],
        metadataProperties: [
            .date("creation_date"),
            .date("last_update_date")
        ],
        references: [],
        subResources: [],
        subOperations: [],
    )

    static let group = ApiRestResource(
        name: "Group",
        dataType: .object(typeName: "Group", properties: [
            .string("name")
        ]),
        identifierProperty: .int64("id"),
        identifierPathParamType: .int64(),
        operationTypes: [
            .create,
            .update,
            .patch,
            .delete,
            .list([
                .query("text", .string()).optional
            ], paged: true),
            .retrieve
        ],
        metadataProperties: [
            .date("creation_date"),
            .date("last_update_date")
        ],
        references: [],
        subResources: [],
        subOperations: [],
    )

    static let user = ApiRestResource(
        name: "User",
        dataType: .object(typeName: "User", properties: [
            .string("first_name"),
            .string("last_name"),
            .string("username"),
            .string("email").optional,
            .string("phone").optional,
            .date("hire_date").optional,
            .date("birth_date").optional,
            .url("picture").optional
        ]),
        identifierProperty: .int64("id"),
        identifierPathParamType: .int64(),
        operationTypes: [
            .create,
            .update,
            .patch,
            .delete,
            .list([
                .query("text", .string()).optional
            ], paged: true),
            .retrieve
        ],
        metadataProperties: [
            .date("creation_date"),
            .date("last_update_date")
        ],
        references: [],
        subOperations: [],
    )

    static let project = ApiRestResource(
        name: "Project",
        dataType: .object(typeName: "Project", properties: [
            .string("name"),
            .ref("status", of: .predefined.tenantStatus),
            .arrayOfRef("owners", of: .predefined.namedObject),
            .keyedByString("labels", valueType: .string(), valueOptional: true)
        ]),
        identifierProperty: .uuid("id"),
        identifierPathParamType: .string(),
        operationTypes: [
            .create,
            .update,
            .delete,
            .list([
                .query("status", .stringEnumArray(type: .predefined.tenantStatus.asRef, defaultValues: ["active"])).optional,
                .query("include_archived", .bool(false), propertyName: "includeArchived").optional
            ], paged: false),
            .retrieve
        ],
        metadataProperties: [
            .date("creation_date"),
            .date("last_update_date")
        ],
        references: [
            .predefined.tenantStatus
        ],
        subResources: [
            .task
        ],
        subOperations: [
            .post(
                name: "archive",
                path: .relative("/archive"),
                security: .secured,
                parameters: [
                    .query("cascade", .bool(false)).optional
                ],
                request: nil,
                response: .predefined.idObject.asRef,
                acceptableStatuses: [200, 202],
            )
        ],
    )

    static let task = ApiRestResource(
        name: "Task",
        dataType: .object(typeName: "Task", properties: [
            .string("title"),
            .string("details").optional,
            .date("due_at").optional,
            .bool("done", initialValue: false)
        ]),
        identifierProperty: .uuid("id"),
        identifierPathParamType: .string(),
        operationTypes: [
            .create,
            .patch,
            .list([
                .query("done", .bool()).optional
            ], paged: true),
            .retrieve
        ],
        metadataProperties: [
            .date("creation_date"),
            .date("last_update_date")
        ],
        subOperations: [
            .patch(
                name: "complete",
                path: .relative("/complete"),
                security: .optional,
                parameters: [
                    .query("notify", .bool(true)).optional
                ],
                request: .object(typeName: "CompleteTaskRequest", properties: [
                    .date("completed_at")
                ]),
                response: .predefined.idObject.asRef,
            )
        ],
    )
}

private extension ApiModule {
    var linuxPortableVaporSample: ApiModule {
        ApiModule(
            name: name,
            definitions: definitions.map(\.linuxPortableVaporSample),
            references: references.map(\.linuxPortableVaporSample),
        )
    }
}

private extension ApiService {
    var linuxPortableVaporSample: ApiService {
        ApiService(
            name: name,
            operations: operations.map(\.linuxPortableVaporSample),
            references: referencedTypes.map(\.linuxPortableVaporSample),
        )
    }
}

private extension ApiOperation {
    var linuxPortableVaporSample: ApiOperation {
        ApiOperation(
            name: name,
            method: method,
            path: path,
            security: security,
            parameters: parameters,
            request: request.linuxPortableVaporSample,
            response: response.linuxPortableVaporSample,
            acceptableStatuses: acceptableStatuses,
            extraImports: extraImports.linuxPortableVaporSampleImports,
        )
    }
}

private extension ApiRequestBody {
    var linuxPortableVaporSample: ApiRequestBody {
        switch self {
            case .none,
                 .binary,
                 .file,
                 .multiPart:
                self
            case let .json(dataType):
                .json(dataType?.linuxPortableVaporSample)
        }
    }
}

private extension ApiResponseBody {
    var linuxPortableVaporSample: ApiResponseBody {
        switch self {
            case .none,
                 .binary:
                self
            case let .json(dataType):
                .json(dataType?.linuxPortableVaporSample)
        }
    }
}

private extension ApiTypeSchema {
    var linuxPortableVaporSample: ApiTypeSchema {
        switch self {
            case let .object(typeName, properties, protocols, imports, isValueType, uuid):
                return .object(
                    typeName: typeName,
                    properties: properties.map(\.linuxPortableVaporSample),
                    protocols: protocols,
                    imports: imports.linuxPortableVaporSampleImports,
                    isValueType: isValueType,
                    uuid: uuid,
                )
            case let .dynamicObject(
            typeName,
            objectTypePropertyName,
            objectDataPropertyName,
            alternateObjectDataPropertyName,
            objectTypes,
            supportGarbage,
            imports,
            uuid,
            extraProperties,
        ):
                return .dynamicObject(
                    typeName: typeName,
                    objectTypePropertyName: objectTypePropertyName,
                    objectDataPropertyName: objectDataPropertyName,
                    alternateObjectDataPropertyName: alternateObjectDataPropertyName,
                    objectTypes: objectTypes.map {
                        (
                            objectTypeName: $0.objectTypeName,
                            objectTypeRawName: $0.objectTypeRawName,
                            objectType: $0.objectType.linuxPortableVaporSample,
                        )
                    },
                    supportGarbage: supportGarbage,
                    imports: imports.linuxPortableVaporSampleImports,
                    uuid: uuid,
                    extraProperties: extraProperties.map(\.linuxPortableVaporSample),
                )
            case let .reference(typeName, strict, imports, uuid, dataType):
                if !strict, imports.contains(where: \.isForbiddenVaporSampleImport) {
                    return .string()
                }
                return .reference(
                    typeName: typeName,
                    strict: strict,
                    imports: imports.linuxPortableVaporSampleImports,
                    uuid: uuid,
                    dataType: dataType?.linuxPortableVaporSample,
                )
            case let .array(dataType):
                return .array(dataType.linuxPortableVaporSample)
            case let .keyedByString(dataType, isOptional):
                return .keyedByString(dataType.linuxPortableVaporSample, isOptional: isOptional)
            case let .genericReference(typeName, genericTypes):
                return .genericReference(typeName: typeName, genericTypes: genericTypes.map(\.linuxPortableVaporSample))
            default:
                return self
        }
    }
}

private extension ApiModelProperty {
    var linuxPortableVaporSample: ApiModelProperty {
        ApiModelProperty(
            rawName: rawName,
            propertyName: propertyName,
            dataType: dataType.linuxPortableVaporSample,
            required: required,
            equatable: equatable,
            hashable: hashable,
            publishedAsField: publishedAsField,
        )
    }
}

private extension [ApiImport] {
    var linuxPortableVaporSampleImports: [ApiImport] {
        filter { !$0.isForbiddenVaporSampleImport }
    }
}

private extension ApiImport {
    var isForbiddenVaporSampleImport: Bool {
        Set([
            "AppKit",
            "Cocoa",
            "Combine",
            "CoreData",
            "CoreGraphics",
            "CoreLocation",
            "CoreML",
            "Darwin",
            "MapKit",
            "Metal",
            "ObjectiveC",
            "OSLog",
            "QuartzCore",
            "SLFoundation",
            "SwiftUI",
            "UIKit",
            "UniformTypeIdentifiers",
            "UserNotifications",
            "WebKit"
        ]).contains(name)
    }
}
