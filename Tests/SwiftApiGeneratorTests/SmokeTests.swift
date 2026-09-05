import Foundation
import GeneratorBuilder
import GeneratorModels
@testable import SwiftApiGenerator
import Testing

@Suite(.serialized) struct SmokeTests {
    @Test func builderComposesBlockText() {
        let block = Block {
            "alpha"
            Line {
                "beta"
                "gamma"
            }
        }

        #expect(block.toString() == "alpha\nbeta gamma")
    }

    @Test func builderPreservesExplicitBlankLines() {
        let block = Block {
            "alpha"
            NewLine()
            "beta"
        }

        #expect(block.toString() == "alpha\n\nbeta")
    }

    @Test func deleteDirContentRemovesSymlinkWithoutDeletingTarget() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let target = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: target, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: root)
            try? FileManager.default.removeItem(at: target)
        }

        let targetFile = target.appendingPathComponent("kept.txt")
        try "kept".write(to: targetFile, atomically: true, encoding: .utf8)

        let normalDir = root.appendingPathComponent("normal", isDirectory: true)
        try FileManager.default.createDirectory(at: normalDir, withIntermediateDirectories: true)
        try "gone".write(to: normalDir.appendingPathComponent("gone.txt"), atomically: true, encoding: .utf8)

        let symlink = root.appendingPathComponent("linked", isDirectory: true)
        try FileManager.default.createSymbolicLink(at: symlink, withDestinationURL: target)

        #expect(try FileManager.default.deleteDirContent(at: root.path) == 2)
        #expect(!FileManager.default.fileExists(atPath: symlink.path))
        #expect(!FileManager.default.fileExists(atPath: normalDir.path))
        #expect(FileManager.default.fileExists(atPath: targetFile.path))
    }

    @Test func swiftSyntaxStringEnumOutput() {
        let enumNode = SwiftStringEnum(
            name: "Status",
            values: [
                (name: "active", raw: "active"),
                (name: "disabled", raw: "DISABLED")
            ],
            supportGarbage: false
        )

        #expect(
            enumNode.toString() ==
                """
                // ☠️☠️☠️ This is generated code, modify at your own risk
                public enum Status: String, Codable, CaseIterable, Sendable, Identifiable {
                    case active
                    case disabled = "DISABLED"
                    public var id: String {
                        rawValue
                    }
                }
                """
        )
    }

    @Test func swiftSyntaxIntEnumOutput() {
        let enumNode = SwiftIntEnum(
            name: "Rank",
            values: [
                (name: "first", raw: "1"),
                (name: "two", raw: "2")
            ]
        )

        #expect(
            enumNode.toString() ==
                """
                // ☠️☠️☠️ This is generated code, modify at your own risk
                public enum Rank: Int, Codable, CaseIterable, Sendable, Identifiable {
                    case first = 1
                    case two = 2
                    public var id: Int {
                        rawValue
                    }
                }
                """
        )
    }

    @Test func swiftSyntaxImportOutput() {
        #expect(
            SwiftImport(name: "Foundation").toString() ==
                "import Foundation"
        )

        #expect(
            SwiftImport(name: "SwiftApiGenerator", annotation: "testable").toString() ==
                "@testable import SwiftApiGenerator"
        )
    }

    @Test func swiftSyntaxCodingKeysOutput() {
        let codingKeys = SwiftCodingKeys(
            values: [
                .init(name: "id", rawName: "id"),
                .init(name: "displayName", rawName: "display_name")
            ]
        )

        #expect(
            codingKeys.toString() ==
                """
                public enum CodingKeys: String, CodingKey {
                    case id
                    case displayName = "display_name"
                }
                """
        )
    }

    @Test func swiftSyntaxPropertyOutput() {
        #expect(
            SwiftProperty(name: "name", dataType: "String").bodyDeclaration.toString() ==
                "public var name: String"
        )

        #expect(
            SwiftProperty(mutable: false, name: "id", dataType: "UUID").bodyDeclaration.toString() ==
                "public let id: UUID"
        )

        #expect(
            SwiftProperty(name: "nickname", dataType: "String", nullable: true).bodyDeclaration.toString() ==
                "public var nickname: String?"
        )

        #expect(
            SwiftProperty(mutable: false, name: "createdAt", dataType: "Date", defaultValue: ".now").bodyDeclaration.toString() ==
                """
                public let createdAt: Date = .now
                """
        )

        #expect(
            SwiftProperty(name: "limit", dataType: "Int", defaultValue: "20").initDeclaration.toString() ==
                "limit: Int = 20"
        )
    }

    @Test func hashableGeneratedTypesCompareHashedFields() {
        let output = ApiTypeSchemaGenerator(
            dataType: .object(
                typeName: "Item",
                properties: [
                    .string("id", hashable: true)
                ]
            )
        )
        .getSwiftClass(parentClassName: nil, outputWithExtension: false)?
        .asNode()
        .toString()

        #expect(output?.contains("public struct Item: Codable, Sendable, Equatable, Hashable") == true)
        #expect(output?.contains("lhs.id == rhs.id") == true)
        #expect(output?.contains("hasher.combine(self.id)") == true)
    }

    @Test func structContainingClassReferenceDropsSendable() {
        let child = ApiTypeSchema.object(
            typeName: "Child",
            properties: [.string("name")],
            isValueType: false
        )
        let parent = ApiTypeSchema.object(
            typeName: "Parent",
            properties: [.ref("child", of: child)]
        )

        let output = ApiTypeSchemaGenerator(dataType: parent)
            .getSwiftClass(parentClassName: nil, outputWithExtension: false)?
            .asNode()
            .toString()

        #expect(output?.contains("public struct Parent: Codable") == true)
        #expect(output?.contains("public struct Parent: Codable, Sendable") == false)
    }

    @Test func emptyEnumsFailValidation() throws {
        #expect(throws: ApiValidationError.self) {
            try ApiTypeSchemaValidator(dataType: .stringEnum(typeName: "EmptyString", values: [])).validate()
        }
        #expect(throws: ApiValidationError.self) {
            try ApiTypeSchemaValidator(dataType: .intEnum(typeName: "EmptyInt", values: [])).validate()
        }
    }

    @Test func nonFiniteDoubleDefaultsFailValidation() throws {
        #expect(throws: ApiValidationError.self) {
            try ApiTypeSchemaValidator(dataType: .double(.infinity)).validate()
        }
        #expect(throws: ApiValidationError.self) {
            try ApiTypeSchemaValidator(dataType: .double(.nan)).validate()
        }
    }

    @Test func swiftIdentifierSanitizerEscapesKeywordsAndLeadingDigits() {
        #expect("class".swiftPropertyName == "`class`")
        #expect("1name".swiftPropertyName == "_1name")
        #expect("-".swiftPropertyName == "_value")
        #expect("2FAApi".swiftTypeName == "_2FAApi")
        #expect("default".swiftEnumValueDeclaration == "`default`")
        #expect("1active".swiftEnumValueDeclaration == "_1active")
        #expect("-".swiftEnumValueDeclaration == "_value")
        #expect("-".swiftTypeName == "_value")
    }

    @Test func apiNamingHelpersSanitizeComposedNames() {
        let module = ApiModule(name: "2FA", definitions: [])
        let definition = ApiService(name: "class", operations: [])

        #expect(module.swiftApiTypeName == "_2FAApi")
        #expect(module.swiftApiModuleTypeName == "_2FAApiModule")
        #expect(module.swiftModulePropertyName == "_2FAModule")
        #expect(definition.swiftApiTypeName(moduleName: module.name) == "_2FAClassApi")
        #expect(definition.swiftAsyncApiPropertyName == "classAsyncApi")
    }

    @Test func stringDefaultsUseEscapedSwiftLiterals() {
        #expect(
            ApiTypeSchemaGenerator(dataType: .string("line 1\n\"quoted\""))
                .getDefaultValue(required: true) ==
                "\"line 1\\n\\\"quoted\\\"\""
        )

        #expect(
            ApiParameter.DataType.string("line 1\n\"quoted\"")
                .getDefaultValue(isRequired: true) ==
                "\"line 1\\n\\\"quoted\\\"\""
        )
    }

    @Test func intEnumDefaultsUseGeneratedCaseNames() {
        let intEnum = ApiTypeSchema.intEnum(
            typeName: "Rank",
            values: [(name: "default", rawValue: 1), (name: nil, rawValue: 2)],
            initialValue: 1
        )
        let numericEnum = ApiTypeSchema.intEnum(
            typeName: "Code",
            values: [(name: nil, rawValue: 2)],
            initialValue: 2
        )

        #expect(ApiTypeSchemaGenerator(dataType: intEnum).getDefaultValue(required: true) == ".`default`")
        #expect(ApiTypeSchemaGenerator(dataType: numericEnum).getDefaultValue(required: true) == ".two")
    }

    @Test func optionalBoolDefaultsToInitialValue() {
        #expect(ApiTypeSchemaGenerator(dataType: .bool(false)).getDefaultValue(required: false) == "false")
        #expect(ApiTypeSchemaGenerator(dataType: .bool(true)).getDefaultValue(required: false) == "true")
    }

    @Test func dataTypeDeclarationsUseSanitizedTypeNames() {
        let stringEnum = ApiTypeSchema.stringEnum(typeName: "class", values: [(name: "active", rawName: "ACTIVE")])
        let intEnum = ApiTypeSchema.intEnum(typeName: "2FA", values: [(name: nil, rawValue: 1)])
        let object = ApiTypeSchema.object(typeName: "struct", properties: [.string("name")])
        let dynamicObject = ApiTypeSchema.dynamicObject(
            typeName: "2Event",
            objectTypes: [
                (
                    objectTypeName: "payload",
                    objectTypeRawName: "payload",
                    objectType: ApiTypeSchema.object(typeName: "Payload", properties: [.string("value")]).asRef
                )
            ]
        )

        #expect(
            ApiTypeSchemaGenerator(dataType: stringEnum)
                .getSwiftClass(parentClassName: nil, outputWithExtension: false)?
                .asNode()
                .toString()
                .contains("public enum Class") == true
        )
        #expect(
            ApiTypeSchemaGenerator(dataType: intEnum)
                .getSwiftClass(parentClassName: nil, outputWithExtension: false)?
                .asNode()
                .toString()
                .contains("public enum _2FA") == true
        )
        #expect(
            ApiTypeSchemaGenerator(dataType: object)
                .getSwiftClass(parentClassName: nil, outputWithExtension: false)?
                .asNode()
                .toString()
                .contains("public struct Struct") == true
        )
        #expect(
            ApiTypeSchemaGenerator(dataType: dynamicObject)
                .getSwiftClass(parentClassName: nil, outputWithExtension: false)?
                .asNode()
                .toString()
                .contains("public enum _2Event") == true
        )
    }

    @Test func dataTypeUsageUsesSanitizedGeneratedTypeNames() {
        let child = ApiTypeSchema.object(typeName: "class", properties: [.string("value")])
        let parent = ApiTypeSchema.object(typeName: "Parent", properties: [
            .object("child", of: child),
            .ref("referenced_child", propertyName: "referencedChild", of: child)
        ])

        let output = ApiTypeSchemaGenerator(dataType: parent)
            .getSwiftClass(parentClassName: nil, outputWithExtension: false)?
            .asNode()
            .toString()

        #expect(output?.contains("public var child: Class") == true)
        #expect(output?.contains("public var referencedChild: Class") == true)
        #expect(output?.contains("public struct Class: Codable, Sendable") == true)
    }

    @Test func enumParameterUsageUsesSanitizedGeneratedTypeNames() {
        let mode = ApiTypeSchema.stringEnum(typeName: "class", values: [(name: "active", rawName: "active")])
        let operation = ApiOperation.get(
            name: "search",
            path: .relative("/items"),
            security: .unsecured,
            parameters: [
                .query("mode", .stringEnumValue(type: mode))
            ]
        )

        let output = ApiOperationGenerator(operation: operation)
            .swiftCode(parentClassName: "", imports: [])
            .toString()

        #expect(output.contains("public var mode: Class"))
        #expect(!output.contains("public var mode: class"))
    }

    @Test func externalReferencesKeepExplicitRawTypeNames() {
        let output = ApiTypeSchemaGenerator(
            dataType: .reference(typeName: "Vendor.Type", strict: false)
        )
        .swiftTypeDeclaration

        #expect(output == "Vendor.Type")
    }

    @Test func operationNamesUseSanitizedGeneratedIdentifiers() {
        let operation = ApiOperation.get(name: "class", path: .relative("/users"))
        let digitOperation = ApiOperation.get(name: "2fa", path: .relative("/users"))

        #expect(operation.typeName == "ClassOperation")
        #expect(ApiOperationGenerator(operation: operation).swiftMethodName == "`class`")
        #expect(digitOperation.typeName == "_2faOperation")
        #expect(ApiOperationGenerator(operation: digitOperation).swiftMethodName == "_2fa")
    }

    @Test func operationFilesIncludeNestedTypeImports() {
        let externalUser = ApiTypeSchema.reference(typeName: "ExternalUser", imports: ["ExternalKit"])
        let operation = ApiOperation.post(
            name: "create",
            path: .relative("/users"),
            security: .unsecured,
            parameters: [
                .query("status", .stringEnumValue(type: .reference(typeName: "Status", imports: ["StatusKit"])))
            ],
            request: externalUser,
            response: .object(typeName: "User", properties: [
                .init(rawName: "owner", propertyName: "owner", dataType: externalUser)
            ])
        )

        let output = ApiOperationGenerator(operation: operation)
            .swiftCode(parentClassName: "", imports: [])
            .toString()

        #expect(output.contains("import ExternalKit"))
        #expect(output.contains("import StatusKit"))
    }

    @Test func operationFilesAlwaysImportFoundation() {
        let operation = ApiOperation.get(name: "list", path: .relative("/users"))

        let output = ApiOperationGenerator(operation: operation)
            .swiftCode(parentClassName: "", imports: [])
            .toString()

        #expect(output.contains("import Foundation"))
    }

    @Test func definitionFilesAlwaysImportFoundation() {
        let definition = ApiService(name: "Users", operations: [
            ApiOperation.get(name: "list", path: .relative("/users"))
        ])

        let output = ApiServiceGenerator(definition: definition)
            .swiftBodyCode(moduleName: "Admin", imports: [])
            .toString()

        #expect(output.contains("import Foundation"))
        #expect(output.contains(
            """
            // ☠️☠️☠️ This is generated code, modify at your own risk
            // sourcery: AutoMockable
            public protocol AdminUsersApiAsyncAwaitProtocol: Sendable
            """
        ))
        #expect(output.contains("public final class AdminUsersApi: AdminUsersApiAsyncAwaitProtocol, Sendable"))
        #expect(!output.contains("AdminUsersApiAsyncAwaitProtocol, @unchecked Sendable"))
        #expect(!output.contains("/// ☠️☠️☠️ This is generated code, modify at your own risk"))
    }

    @Test func explicitValueTypeEquatableHashableUsesSelectedFieldsOnly() {
        let output = SwiftClass(
            name: "Blob",
            protocols: ["Equatable", "Hashable"],
            properties: [
                SwiftProperty(name: "bytes", dataType: "Data", equatable: false, hashable: false)
            ]
        )
        .toString()

        #expect(output.contains("public static func == (lhs: Blob, rhs: Blob) -> Bool"))
        #expect(output.contains("true"))
        #expect(output.contains("public func hash(into hasher: inout Hasher)"))
        #expect(output.contains("hasher.combine(0)"))
    }

    @Test func annotatedImportsArePubliclyConstructible() {
        let apiImport = ApiImport(name: "PreviewKit", annotation: "_exported")

        #expect(apiImport.name == "PreviewKit")
        #expect(apiImport.annotation == "_exported")
    }

    @Test func modelFilesIncludeNestedTypeImports() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer {
            try? FileManager.default.removeItem(at: directory)
        }

        let externalUser = ApiTypeSchema.reference(typeName: "ExternalUser", imports: ["ExternalKit"])
        let user = ApiTypeSchema.object(typeName: "User", properties: [
            .init(rawName: "owner", propertyName: "owner", dataType: externalUser)
        ])

        try ApiTypeSchemasGenerator(dataTypes: [user]).write(
            toDirectory: directory,
            extensionName: "",
            fileNamePrefix: "",
            imports: []
        )

        let output = try String(contentsOf: directory.appendingPathComponent("User.generated.swift"), encoding: .utf8)
        #expect(output.contains("import ExternalKit"))
    }

    @Test func nestedTypeImportsDoNotRecurseIntoSeenReferences() {
        let uuid = UUID()
        let resolved = ApiTypeSchema.object(
            typeName: "ExternalUser",
            properties: [
                .string("name")
            ],
            imports: ["ModelKit"],
            uuid: uuid
        )
        let reference = ApiTypeSchema.reference(
            typeName: "ExternalUser",
            imports: ["ExternalKit"],
            uuid: uuid,
            dataType: resolved
        )
        let operation = ApiOperation.post(
            name: "create",
            path: .relative("/users"),
            security: .unsecured,
            request: .array(reference),
            response: .array(reference)
        )

        let output = ApiOperationGenerator(operation: operation)
            .swiftCode(parentClassName: "", imports: [])
            .toString()

        #expect(output.contains("import ExternalKit"))
    }

    @Test func strictReferenceDataTypesIncludeNestedResolvedReferences() {
        let child = ApiTypeSchema.object(typeName: "Child", properties: [
            .string("name")
        ])
        let parent = ApiTypeSchema.object(typeName: "Parent", properties: [
            .ref("child", of: child)
        ])

        #expect(parent.asRef.referenceDataTypes == [parent.asRef, child.asRef])
    }

    @Test func strictReferenceDataTypesSkipSeenResolvedReferences() {
        let uuid = UUID()
        let selfReference = ApiTypeSchema.reference(typeName: "Node", uuid: uuid)
        let node = ApiTypeSchema.object(
            typeName: "Node",
            properties: [
                .init(rawName: "parent", propertyName: "parent", dataType: selfReference)
            ],
            uuid: uuid
        )
        let resolvedReference = ApiTypeSchema.reference(typeName: "Node", uuid: uuid, dataType: node)

        #expect(resolvedReference.referenceDataTypes == [resolvedReference])
    }

    @Test func parameterAccessorsEscapeRawNames() {
        let operation = ApiOperation.get(
            name: "search",
            path: .relative("/search"),
            parameters: [
                .query("quote\"slash\\newline\n", .string(), propertyName: "value")
            ]
        )

        let output = ApiOperationGenerator(operation: operation)
            .swiftCode(parentClassName: "", imports: [])
            .toString()

        #expect(output.contains(#"values["quote\"slash\\newline\n"] = __api0ValueValue"#))
    }

    @Test func pathReplacementDoesNotForceUnwrapPercentEncoding() {
        let operation = ApiOperation.get(
            name: "get",
            path: .relative("/users/{id}"),
            parameters: [
                .path("id", .string())
            ]
        )

        let output = ApiOperationGenerator(operation: operation)
            .swiftCode(parentClassName: "", imports: [])
            .toString()

        #expect(output.contains("addingPercentEncoding(withAllowedCharacters: pathSegmentAllowedCharacters) ?? String(self.id)"))
    }

    @Test func parameterEnumDefaultsUnwrapReferencesRecursively() {
        let stringEnum = ApiTypeSchema.stringEnum(
            typeName: "Status",
            values: [(name: "default", rawName: "DEFAULT"), (name: "1active", rawName: "ACTIVE")]
        )
        let stringRef = ApiTypeSchema.reference(typeName: "StatusRef", dataType: .reference(typeName: "Status", dataType: stringEnum))

        #expect(
            ApiParameter.DataType.stringEnumValue(type: stringRef, defaultValue: "DEFAULT")
                .getDefaultValue(isRequired: true) ==
                ".`default`"
        )
        #expect(
            ApiParameter.DataType.stringEnumArray(type: stringRef, defaultValues: ["DEFAULT", "ACTIVE"])
                .getDefaultValue(isRequired: true) ==
                "[.`default`, ._1active]"
        )

        let intEnum = ApiTypeSchema.intEnum(
            typeName: "Rank",
            values: [(name: "default", rawValue: 1), (name: nil, rawValue: 2)]
        )
        let intRef = ApiTypeSchema.reference(typeName: "RankRef", dataType: .reference(typeName: "Rank", dataType: intEnum))

        #expect(
            ApiParameter.DataType.intEnumValue(type: intRef, defaultValue: 1)
                .getDefaultValue(isRequired: true) ==
                ".`default`"
        )
        #expect(
            ApiParameter.DataType.intEnumArray(type: intRef, defaultValues: [1, 2])
                .getDefaultValue(isRequired: true) ==
                "[.`default`, .two]"
        )
    }

    @Test func parameterEnumDefaultsRequireResolvedReferences() {
        let unresolvedStringRef = ApiTypeSchema.reference(typeName: "Status")
        let unresolvedIntRef = ApiTypeSchema.reference(typeName: "Rank")

        #expect(throws: (any Error).self) {
            try ApiParameter.query(
                "status",
                .stringEnumValue(type: unresolvedStringRef, defaultValue: "active")
            ).validate()
        }
        #expect(throws: (any Error).self) {
            try ApiParameter.query(
                "rank",
                .intEnumArray(type: unresolvedIntRef, defaultValues: [1])
            ).validate()
        }
    }

    @Test func enumArrayDefaultsDoNotDropUnresolvedValues() {
        let stringEnum = ApiTypeSchema.stringEnum(
            typeName: "Status",
            values: [(name: "active", rawName: "ACTIVE")]
        )
        let intEnum = ApiTypeSchema.intEnum(
            typeName: "Rank",
            values: [(name: nil, rawValue: 1)]
        )

        #expect(
            ApiParameter.DataType.stringEnumArray(type: stringEnum, defaultValues: ["ACTIVE", "MISSING"])
                .getDefaultValue(isRequired: true) == nil
        )
        #expect(
            ApiParameter.DataType.intEnumArray(type: intEnum, defaultValues: [1, 2])
                .getDefaultValue(isRequired: true) == nil
        )
    }

    @Test func dataTypeValidatorValidatesResolvedReferencePayload() {
        let invalidEnum = ApiTypeSchema.stringEnum(
            typeName: "Status",
            values: [(name: "active", rawName: "ACTIVE"), (name: "active", rawName: "ENABLED")]
        )

        #expect(throws: (any Error).self) {
            try ApiTypeSchemaValidator(dataType: invalidEnum.asRef).validate()
        }
    }

    @Test func dataTypeValidatorAllowsEmptyObjectsWithoutFatalError() throws {
        let emptyObject = ApiTypeSchema.object(typeName: "Empty", properties: [])

        try ApiTypeSchemaValidator(dataType: emptyObject).validate()
    }

    @Test func dataTypeGeneratorAllowsEmptyObjectsWithoutFatalError() {
        let output = ApiTypeSchemaGenerator(dataType: .object(typeName: "Empty", properties: []))
            .getSwiftClass(parentClassName: nil, outputWithExtension: false)?
            .asNode()
            .toString()

        #expect(output?.contains("public struct Empty: Codable, Sendable") == true)
        #expect(output?.contains("public init()") == true)
    }

    @Test func dynamicObjectEnumCasesUseSanitizedNames() {
        let payload = ApiTypeSchema.object(typeName: "Payload", properties: [
            .string("value")
        ])
        let dynamicObject = ApiTypeSchema.dynamicObject(
            typeName: "Event",
            objectTypes: [
                (objectTypeName: "default", objectTypeRawName: "default", objectType: payload.asRef),
                (objectTypeName: "1event", objectTypeRawName: "1event", objectType: payload.asRef)
            ]
        )

        ApiTypeNameResolver.shared.push(module: "Shared", types: [payload])
        defer {
            ApiTypeNameResolver.shared.pop()
        }

        let output = ApiTypeSchemaGenerator(dataType: dynamicObject)
            .getSwiftClass(parentClassName: nil, outputWithExtension: false)?
            .asNode()
            .toString()

        #expect(output?.contains("case `default`(Shared.Payload)") == true)
        #expect(output?.contains("case _1event(Shared.Payload)") == true)
        #expect(output?.contains("case .`default`:") == true)
        #expect(output?.contains("return .`default`") == true)
        #expect(output?.contains("case ._1event:") == true)
        #expect(output?.contains("return ._1event") == true)
    }

    @Test func dynamicObjectValidatorRejectsSanitizedCaseDuplicates() {
        let payload = ApiTypeSchema.object(typeName: "Payload", properties: [
            .string("value")
        ])
        let dynamicObject = ApiTypeSchema.dynamicObject(
            typeName: "Event",
            objectTypes: [
                (objectTypeName: "1event", objectTypeRawName: "one", objectType: payload.asRef),
                (objectTypeName: "_1event", objectTypeRawName: "underscore", objectType: payload.asRef)
            ]
        )

        #expect(throws: (any Error).self) {
            try ApiTypeSchemaValidator(dataType: dynamicObject).validate()
        }
    }

    @Test func stringEnumValidatorRejectsSanitizedCaseDuplicates() {
        let status = ApiTypeSchema.stringEnum(
            typeName: "Status",
            values: [
                (name: "1active", rawName: "one"),
                (name: "_1active", rawName: "two")
            ]
        )

        #expect(throws: (any Error).self) {
            try ApiTypeSchemaValidator(dataType: status).validate()
        }
    }

    @Test func stringEnumValidatorRejectsGarbageSentinelDuplicates() {
        let status = ApiTypeSchema.stringEnum(
            typeName: "Status",
            values: [
                (name: "garbage", rawName: "__garbage__")
            ],
            supportGarbage: true
        )

        #expect(throws: (any Error).self) {
            try ApiTypeSchemaValidator(dataType: status).validate()
        }
    }

    @Test func dynamicObjectValidatorRejectsReservedRawNameDuplicates() {
        let payload = ApiTypeSchema.object(typeName: "Payload", properties: [
            .string("value")
        ])
        let dynamicObject = ApiTypeSchema.dynamicObject(
            typeName: "Event",
            objectTypePropertyName: "kind",
            objectDataPropertyName: "kind",
            objectTypes: [
                (objectTypeName: "payload", objectTypeRawName: "payload", objectType: payload)
            ]
        )

        #expect(throws: (any Error).self) {
            try ApiTypeSchemaValidator(dataType: dynamicObject).validate()
        }
    }

    @Test func dynamicObjectValidatorRejectsGarbageSentinelDuplicates() {
        let payload = ApiTypeSchema.object(typeName: "Payload", properties: [
            .string("value")
        ])
        let dynamicObject = ApiTypeSchema.dynamicObject(
            typeName: "Event",
            objectTypes: [
                (objectTypeName: "garbage", objectTypeRawName: "__garbage__", objectType: payload)
            ],
            supportGarbage: true
        )

        #expect(throws: (any Error).self) {
            try ApiTypeSchemaValidator(dataType: dynamicObject).validate()
        }
    }

    @Test func dynamicObjectValidatorRejectsDuplicateNestedTypeDeclarations() {
        let firstPayload = ApiTypeSchema.object(typeName: "Payload", properties: [
            .string("value")
        ])
        let secondPayload = ApiTypeSchema.object(typeName: "Payload", properties: [
            .string("name")
        ])
        let dynamicObject = ApiTypeSchema.dynamicObject(
            typeName: "Event",
            objectTypes: [
                (objectTypeName: "first", objectTypeRawName: "first", objectType: firstPayload),
                (objectTypeName: "second", objectTypeRawName: "second", objectType: secondPayload)
            ]
        )

        #expect(throws: (any Error).self) {
            try ApiTypeSchemaValidator(dataType: dynamicObject).validate()
        }
    }

    @Test func dynamicObjectValidatorRejectsSelfEncodedReservedKeyCollisions() {
        let payload = ApiTypeSchema.object(typeName: "Payload", properties: [
            .string("content_type")
        ])
        let dynamicObject = ApiTypeSchema.dynamicObject(
            typeName: "Event",
            objectDataPropertyName: "__self__",
            objectTypes: [
                (objectTypeName: "payload", objectTypeRawName: "payload", objectType: payload)
            ]
        )

        #expect(throws: (any Error).self) {
            try ApiTypeSchemaValidator(dataType: dynamicObject).validate()
        }
    }

    @Test func dynamicObjectValidatorAllowsSelfEncodedPayloadDataKeyNames() throws {
        let payload = ApiTypeSchema.object(typeName: "Payload", properties: [
            .string("extra")
        ])
        let dynamicObject = ApiTypeSchema.dynamicObject(
            typeName: "Event",
            objectDataPropertyName: "__self__",
            objectTypes: [
                (objectTypeName: "payload", objectTypeRawName: "payload", objectType: payload)
            ]
        )

        try ApiTypeSchemaValidator(dataType: dynamicObject).validate()
    }

    @Test func dynamicObjectValidatorAllowsSelfEncodedExtraDataKeyNames() throws {
        let payload = ApiTypeSchema.object(typeName: "Payload", properties: [
            .string("value")
        ])
        let dynamicObject = ApiTypeSchema.dynamicObject(
            typeName: "Event",
            objectDataPropertyName: "__self__",
            objectTypes: [
                (objectTypeName: "payload", objectTypeRawName: "payload", objectType: payload)
            ],
            extraProperties: [
                .string("extra"),
                .string("__self__", propertyName: "selfValue")
            ]
        )

        try ApiTypeSchemaValidator(dataType: dynamicObject).validate()
    }

    @Test func swiftSyntaxInitOutput() {
        #expect(
            SwiftInit(visibility: .public, properties: []).toString() ==
                """
                public init() {
                }
                """
        )

        let initNode = SwiftInit(
            visibility: .public,
            properties: [
                .init(name: "name", dataType: "String"),
                .init(mutable: false, name: "id", dataType: "UUID"),
                .init(mutable: false, name: "createdAt", dataType: "Date", defaultValue: ".now"),
                .init(name: "limit", dataType: "Int", defaultValue: "20")
            ]
        )

        #expect(
            initNode.toString() ==
                """
                public init(name: String, id: UUID, limit: Int = 20) {
                    self.name = name
                    self.id = id
                    self.limit = limit
                }
                """
        )
    }

    @Test func securedOperationExpandsApiKeyOnce() {
        let operations = [
            ApiOperation.post(
                name: "createUser",
                path: .relative("/users"),
                parameters: [.query("name", .string())],
                requestType: .none
            ),
            ApiOperation.postMultipart(
                name: "uploadUser",
                path: .relative("/users/upload"),
                parameters: [.query("name", .string())],
                multiParts: ["file"]
            ),
            ApiOperation.patch(
                name: "patchUser",
                path: .relative("/users/{id}"),
                parameters: [.query("name", .string())],
                request: .string()
            ),
            ApiOperation.put(
                name: "updateUser",
                path: .relative("/users/{id}"),
                parameters: [.query("name", .string())],
                request: .string()
            ),
            ApiOperation.delete(
                name: "deleteUser",
                path: .relative("/users/{id}"),
                parameters: [.query("name", .string())]
            )
        ]

        for operation in operations {
            #expect(operation.parameters.map(\.propertyName) == ["name"])
            #expect(operation.expandedParameters.map(\.propertyName) == ["name", "apiKey"])
        }
    }

    @Test func optionalSecuredOperationDoesNotSendEmptyApiKey() {
        let operation = ApiOperation.get(
            name: "listUsers",
            path: .relative("/users"),
            security: .optional
        )

        let output = ApiOperationGenerator(operation: operation)
            .swiftExecuteMethodAsyncAwait()
            .toString()

        #expect(output.contains("adaptedRequest.apiKey = await client.apiKey()"))
        #expect(output.contains("if adaptedRequest.apiKey?.isEmpty != false"))
        #expect(!output.contains("?? \"\""))
        #expect(!output.contains(".isNilOrEmpty"))
    }

    @Test func securedOperationKeepsCallerProvidedApiKey() {
        let operation = ApiOperation.get(
            name: "listUsers",
            path: .relative("/users"),
            security: .secured
        )

        let output = ApiOperationGenerator(operation: operation)
            .swiftExecuteMethodAsyncAwait()
            .toString()

        #expect(output.contains("if adaptedRequest.apiKey.isEmpty"))
        #expect(output.contains("adaptedRequest.apiKey = try await client.requireApiKey()"))
        #expect(!output.contains("var adaptedRequest = request\n    adaptedRequest.apiKey = try await client.requireApiKey()"))
    }

    @Test func nilResponseFactoriesUseNoResponseType() {
        let operations = [
            ApiOperation.post(name: "create", path: .relative("/items"), security: .unsecured, request: nil),
            ApiOperation.postMultipart(name: "upload", path: .relative("/items"), security: .unsecured, multiParts: []),
            ApiOperation.patch(name: "patch", path: .relative("/items/{id}"), security: .unsecured, request: .string()),
            ApiOperation.put(name: "put", path: .relative("/items/{id}"), security: .unsecured, request: .string()),
            ApiOperation.delete(name: "delete", path: .relative("/items/{id}"), security: .unsecured)
        ]

        for operation in operations {
            #expect(operation.response.dataType == nil)
            #expect(operation.response.mimeType == "*/*")
        }
    }

    @Test func swiftJsonNilRequestDoesNotSendContentType() {
        let operation = ApiOperation.post(
            name: "archive",
            path: .relative("/items/archive"),
            security: .unsecured,
            request: nil
        )

        let output = ApiOperationGenerator(operation: operation)
            .swiftCode(parentClassName: "", imports: [])
            .toString()

        #expect(!output.contains("request.contentType(mimeType: \"application/json\")"))
        #expect(!output.contains("try request.codableBody(body, encoder: encoder)"))
    }

    @Test func swiftJsonBodyStillSendsContentType() {
        let operation = ApiOperation.post(
            name: "create",
            path: .relative("/items"),
            security: .unsecured,
            request: .string()
        )

        let output = ApiOperationGenerator(operation: operation)
            .swiftCode(parentClassName: "", imports: [])
            .toString()

        #expect(output.contains("request.contentType(mimeType: \"application/json\")"))
        #expect(output.contains("try request.codableBody(body, encoder: encoder)"))
    }

    @Test func typedSwiftOperationsDoNotAcceptNoBodyStatusesForDecoding() {
        let operation = ApiOperation.post(
            name: "create",
            path: .relative("/items"),
            security: .unsecured,
            request: .string(),
            response: .string(),
            acceptableStatuses: [200, 201, 204, 205, 304]
        )

        let output = ApiOperationGenerator(operation: operation)
            .swiftExecuteMethodAsyncAwait()
            .toString()

        #expect(output.contains("validStatusCode: [200, 201]"))
        #expect(!output.contains("204"))
        #expect(!output.contains("205"))
        #expect(!output.contains("304"))
    }

    @Test func typedSwiftOperationsDoNotAcceptInformationalStatusesForDecoding() {
        let operation = ApiOperation.post(
            name: "create",
            path: .relative("/items"),
            security: .unsecured,
            request: .string(),
            response: .string(),
            acceptableStatuses: [100, 102, 200]
        )

        let output = ApiOperationGenerator(operation: operation)
            .swiftExecuteMethodAsyncAwait()
            .toString()

        #expect(output.contains("validStatusCode: [200]"))
        #expect(!output.contains("100"))
        #expect(!output.contains("102"))
    }

    @Test func validatorRejectsTypedSwiftOperationsWithOnlyNoBodyStatuses() {
        let operation = ApiOperation.post(
            name: "create",
            path: .relative("/items"),
            security: .unsecured,
            request: .string(),
            response: .string(),
            acceptableStatuses: [204, 205, 304]
        )

        #expect(throws: (any Error).self) {
            try ApiOperationValidator(operation: operation).validate()
        }
    }

    @Test func validatorRejectsTypedSwiftOperationsWithOnlyInformationalStatuses() {
        let operation = ApiOperation.post(
            name: "create",
            path: .relative("/items"),
            security: .unsecured,
            request: .string(),
            response: .string(),
            acceptableStatuses: [100, 102]
        )

        #expect(throws: (any Error).self) {
            try ApiOperationValidator(operation: operation).validate()
        }
    }

    @Test func rawSwiftOperationsKeepNoBodyStatuses() {
        let operation = ApiOperation.delete(
            name: "delete",
            path: .relative("/items/{id}"),
            security: .unsecured,
            parameters: [.path("id", .string())]
        )

        let output = ApiOperationGenerator(operation: operation)
            .swiftExecuteMethodAsyncAwait()
            .toString()

        #expect(output.contains("validStatusCode: [200, 204, 205]"))
    }

    @Test func multipartValidatorRejectsDuplicateGeneratedSetters() {
        let operation = ApiOperation.postMultipart(
            name: "upload",
            path: .relative("/items"),
            security: .unsecured,
            multiParts: ["file-name", "file_name"]
        )

        #expect(throws: (any Error).self) {
            try ApiOperationValidator(operation: operation).validate()
        }
    }

    @Test func multipartValidatorRejectsEmptyPartNames() {
        let operation = ApiOperation.postMultipart(
            name: "upload",
            path: .relative("/items"),
            security: .unsecured,
            multiParts: [""]
        )

        #expect(throws: (any Error).self) {
            try ApiOperationValidator(operation: operation).validate()
        }
    }

    @Test func operationValidatorRejectsGeneratedRequestMethodNameCollisions() {
        let buildRequestOperation = ApiOperation.get(
            name: "search",
            path: .relative("/items"),
            security: .unsecured,
            parameters: [.query("build_request", .string())]
        )
        let multipartSetterOperation = ApiOperation.postMultipart(
            name: "upload",
            path: .relative("/items"),
            security: .unsecured,
            parameters: [.query("set_body_part_file", .string())],
            multiParts: ["file"]
        )

        #expect(throws: (any Error).self) {
            try ApiOperationValidator(operation: buildRequestOperation).validate()
        }
        #expect(throws: (any Error).self) {
            try ApiOperationValidator(operation: multipartSetterOperation).validate()
        }
    }

    @Test func operationValidatorRejectsCookieHeaderWithCookieParameters() {
        let operation = ApiOperation.get(
            name: "search",
            path: .relative("/items"),
            security: .unsecured,
            parameters: [
                .header("Cookie", .string()),
                .cookie("session", .string())
            ]
        )

        #expect(throws: (any Error).self) {
            try ApiOperationValidator(operation: operation).validate()
        }
    }

    @Test func operationValidatorRejectsCaseInsensitiveDuplicateHeaders() {
        let operation = ApiOperation.get(
            name: "badHeaders",
            path: .relative("/headers"),
            security: .unsecured,
            parameters: [
                .header("X-Trace", .string()),
                .header("x-trace", .string(), propertyName: "trace2")
            ]
        )

        #expect(throws: (any Error).self) {
            try ApiOperationValidator(operation: operation).validate()
        }
    }

    @Test func multipartRequestsDoNotGenerateEquatableConformance() {
        let operation = ApiOperation.postMultipart(
            name: "upload",
            path: .relative("/items"),
            security: .unsecured,
            multiParts: ["file"]
        )

        let output = ApiOperationGenerator(operation: operation)
            .swiftCode(parentClassName: "", imports: [])
            .toString()

        #expect(output.contains("public struct Request: URLRequestConvertible, MultipartBodyConvertible, Sendable"))
        #expect(!output.contains("MultipartBodyConvertible, Equatable"))
    }

    @Test func swiftRequestAccessorsAvoidParameterLocalShadowing() {
        let operation = ApiOperation.postMultipart(
            name: "upload",
            path: .relative("/items/{path}"),
            security: .unsecured,
            parameters: [
                .path("path", .string()),
                .query("values", .string()),
                .header("pathSegmentAllowedCharacters", .string())
            ],
            multiParts: ["file", "metadata"]
        )

        let output = ApiOperationGenerator(operation: operation)
            .swiftCode(parentClassName: "", imports: [])
            .toString()

        #expect(output.contains("let __api0ValuesValue = self.values"))
        #expect(output.contains("let __api0PathSegmentAllowedCharactersValue = self.pathSegmentAllowedCharacters"))
        #expect(output.contains("with: String(self.path).addingPercentEncoding"))
        #expect(output.contains(#"guard body["file"] != nil else"#))
        #expect(output.contains(#"guard body["metadata"] != nil else"#))
    }

    @Test func swiftRequestAccessorsUseDistinctParameterLocalNames() {
        let operation = ApiOperation.get(
            name: "search",
            path: .relative("/search"),
            security: .unsecured,
            parameters: [
                .query("class", .string()),
                .query("_class", .string())
            ]
        )

        let output = ApiOperationGenerator(operation: operation)
            .swiftCode(parentClassName: "", imports: [])
            .toString()

        #expect(output.contains("let __api0ClassValue = self.`class`"))
        #expect(output.contains("let __api1ClassValue = self.Class"))
    }

    @Test func swiftValidatorRejectsTypedJsonResponseWithoutDataType() {
        let operation = ApiOperation(
            name: "nilJson",
            method: .get,
            path: .relative("/nil-json"),
            security: .unsecured,
            parameters: [],
            request: .none,
            response: .json(nil),
            acceptableStatuses: [200],
            extraImports: []
        )

        #expect(throws: (any Error).self) {
            try ApiOperationValidator(operation: operation).validate()
        }
    }

    @Test func operationRequestDropsSendableForClassBody() {
        let body = ApiTypeSchema.object(
            typeName: "CreateItemRequest",
            properties: [.string("name")],
            isValueType: false
        )
        let operation = ApiOperation.post(
            name: "create",
            path: .relative("/items"),
            security: .unsecured,
            request: body
        )

        let output = ApiOperationGenerator(operation: operation)
            .swiftCode(parentClassName: "", imports: [])
            .toString()

        #expect(output.contains("public struct Request: URLRequestConvertible"))
        #expect(!output.contains("public struct Request: URLRequestConvertible, Sendable"))
        #expect(output.contains("public var body: CreateItemRequest"))
    }

    @Test func dynamicObjectDropsSendableForClassPayload() {
        let payload = ApiTypeSchema.object(
            typeName: "EventPayload",
            properties: [.string("name")],
            isValueType: false
        )
        let dynamicObject = ApiTypeSchema.dynamicObject(
            typeName: "Event",
            objectTypes: [
                (objectTypeName: "payload", objectTypeRawName: "payload", objectType: payload)
            ]
        )

        let output = ApiTypeSchemaGenerator(dataType: dynamicObject)
            .getSwiftClass(parentClassName: nil, outputWithExtension: false)?
            .asNode()
            .toString()

        #expect(output?.contains("public enum Event: Codable") == true)
        #expect(output?.contains("public enum Event: Codable, Sendable") == false)
    }

    @Test func immutableRequiredParametersAreInitialized() {
        let operation = ApiOperation.get(
            name: "search",
            path: .relative("/search"),
            security: .unsecured,
            parameters: [
                .query("term", .string(), mutable: false)
            ]
        )

        let output = ApiOperationGenerator(operation: operation)
            .swiftCode(parentClassName: "", imports: [])
            .toString()

        #expect(output.contains("public let term: String"))
        #expect(output.contains("public init(term: String)"))
        #expect(output.contains("self.term = term"))
    }

    @Test func headerParametersUseStringValues() {
        let rank = ApiTypeSchema.intEnum(typeName: "Rank", values: [(name: "one", rawValue: 1)])
        let operation = ApiOperation.get(
            name: "search",
            path: .relative("/search"),
            security: .unsecured,
            parameters: [
                .header("X-Rank", .intEnumValue(type: rank)),
                .header("X-Time", .time)
            ]
        )

        let output = ApiOperationGenerator(operation: operation)
            .swiftCode(parentClassName: "", imports: [])
            .toString()

        #expect(output.contains("values[\"X-Rank\"] = String(describing: __api0XRankValue.rawValue)"))
        #expect(output.contains("values[\"X-Time\"] = String(__api1XTimeValue.formEncodableValue())"))
    }

    @Test func swiftRequestPreservesExplicitAcceptHeader() {
        let operation = ApiOperation.get(
            name: "download",
            path: .relative("/download"),
            security: .unsecured,
            parameters: [
                .header("Accept", .string(), propertyName: "accept")
            ],
            response: .string()
        )

        let output = ApiOperationGenerator(operation: operation)
            .swiftCode(parentClassName: "", imports: [])
            .toString()

        #expect(output.contains("let hasExplicitAccept = httpHeaders.keys.contains {"))
        #expect(output.contains("$0.lowercased() == \"accept\""))
        #expect(output.contains("if !hasExplicitAccept"))
        #expect(output.contains("request.accept(mimeType: \"application/json\")"))
        #expect(output.contains("values[\"Accept\"] = __api0AcceptValue"))
    }

    @Test func cookieParametersEmitSelfContainedCookieHeader() {
        let operation = ApiOperation.get(
            name: "search",
            path: .relative("/search"),
            security: .unsecured,
            parameters: [
                .cookie("session_id", .string(), propertyName: "sessionId")
            ]
        )

        let output = ApiOperationGenerator(operation: operation)
            .swiftCode(parentClassName: "", imports: [])
            .toString()

        #expect(output.contains("public var httpCookies: [String: any FormEncodable]"))
        #expect(output.contains("let cookieAllowedCharacters = CharacterSet.urlQueryAllowed.subtracting"))
        #expect(output.contains("let cookieValues = httpCookies"))
        #expect(output.contains("cookieValues.keys.sorted().compactMap"))
        #expect(output.contains("cookieValues[name]?.formEncodableValue()"))
        #expect(!output.contains("httpCookies[name]"))
        #expect(output.contains("let httpHeaders = self.httpHeaders"))
        #expect(output.contains("values[\"Cookie\"] = cookies"))
        #expect(!output.contains("percentEncodedCookies"))
    }

    @Test func patchableStateCheckShortCircuitsWithoutTemporaryArray() {
        let output = SwiftClass(
            name: "Patch",
            properties: [
                .init(name: "first", dataType: "PatchableValue<String>"),
                .init(name: "second", dataType: "PatchableValue<Int>")
            ]
        ).toString()

        #expect(output.contains("return self.first.isUnmodified &&"))
        #expect(output.contains("self.second.isUnmodified"))
        #expect(!output.contains(".allSatisfy"))
    }

    @Test func patchableClassDeclarationsAreClassSafe() {
        let patchable = SwiftClass(
            name: "Patch",
            protocols: ["Codable"],
            properties: [
                .init(name: "name", dataType: "PatchableValue<String>")
            ],
            isValueType: false
        )
        .toString()

        #expect(patchable.contains("public required init(from decoder: any Decoder) throws"))
        #expect(patchable.contains("public func resetPatchableFields()"))
        #expect(!patchable.contains("public mutating func resetPatchableFields()"))
        #expect(!patchable.contains("Sendable"))
    }

    @Test func swiftClassDeduplicatesDefaultProtocols() {
        let output = SwiftClass(
            name: "User",
            protocols: ["Codable"],
            properties: [
                .init(name: "id", dataType: "String")
            ]
        )
        .toString()

        #expect(output.contains("public struct User: Codable, Sendable"))
        #expect(!output.contains("Codable, Codable"))
    }

    @Test func swiftClassUsesSelfForHashableProperties() {
        let output = SwiftClass(
            name: "HashBox",
            properties: [
                .init(name: "hasher", dataType: "String", hashable: true)
            ]
        )
        .toString()

        #expect(output.contains("hasher.combine(self.hasher)"))
        #expect(!output.contains("hasher.combine(hasher)"))
    }

    @Test func swiftClassUsesIdentityForExplicitClassEquatableHashable() {
        let output = SwiftClass(
            name: "IdentityBox",
            protocols: ["Equatable", "Hashable"],
            properties: [
                .init(name: "name", dataType: "String", equatable: false)
            ],
            isValueType: false
        )
        .toString()

        #expect(output.contains("public class IdentityBox: Codable, Equatable, Hashable"))
        #expect(output.contains("lhs === rhs"))
        #expect(output.contains("hasher.combine(ObjectIdentifier(self))"))
    }

    @Test func swiftClassUsesIdentityEqualityWhenHashUsesIdentity() {
        let output = SwiftClass(
            name: "MixedBox",
            protocols: ["Hashable"],
            properties: [
                .init(name: "name", dataType: "String", equatable: true, hashable: false)
            ],
            isValueType: false
        )
        .toString()

        #expect(output.contains("lhs === rhs"))
        #expect(output.contains("hasher.combine(ObjectIdentifier(self))"))
        #expect(!output.contains("lhs.name == rhs.name"))
    }

    @Test func swiftGeneratedSyntaxParseThrowingWrapsBuilderErrors() {
        #expect(throws: ApiValidationError.self) {
            try SwiftGeneratedSyntax.parseThrowing("test") {
                throw ApiValidationError.failed("boom")
            }
        }
    }

    @Test func patchableClassAvoidsContainerPropertyShadowing() {
        let output = SwiftClass(
            name: "Patch",
            properties: [
                .init(name: "container", dataType: "PatchableValue<String>")
            ]
        )
        .toString()

        #expect(output.contains("var codingContainer = encoder.container(keyedBy: Self.CodingKeys.self)"))
        #expect(output.contains("if !self.container.isUnmodified"))
        #expect(output.contains("self.container = try codingContainer.decode(PatchableValue<String>.self, forKey: .container)"))
        #expect(!output.contains("var container = encoder.container"))
    }

    @Test func patchableDetectionRequiresExactPatchableType() {
        let notPatchable = SwiftClass(
            name: "Patch",
            properties: [
                .init(name: "name", dataType: "NotPatchableValue<String>")
            ]
        )
        .toString()

        #expect(!notPatchable.contains("resetPatchableFields"))
        #expect(!notPatchable.contains(".unmodified"))
    }

    @Test func nullablePatchablePropertiesGenerateNonOptionalUnmodifiedAccessors() {
        let patchable = SwiftClass(
            name: "Patch",
            properties: [
                .init(name: "nickname", dataType: "PatchableValue<String>", nullable: true)
            ]
        )
        .toString()

        #expect(patchable.contains("public var nickname: PatchableValue<String>"))
        #expect(patchable.contains("public init(nickname: PatchableValue<String>)"))
        #expect(!patchable.contains("PatchableValue<String>?"))
        #expect(patchable.contains("if !self.nickname.isUnmodified"))
        #expect(patchable.contains("if codingContainer.contains(.nickname)"))
        #expect(patchable.contains("nickname = .deleted"))
        #expect(patchable.contains("nickname.isUnmodified"))
        #expect(!patchable.contains("nickname?.isUnmodified"))
    }

    @Test func apiPropertyFactoriesPreserveCoreFields() {
        let property = ApiModelProperty.string(
            "raw_name",
            propertyName: "customName",
            initialValue: "seed",
            required: false,
            equatable: true,
            hashable: true
        )

        #expect(property.rawName == "raw_name")
        #expect(property.propertyName == "customName")
        #expect(property.dataType == .string("seed"))
        #expect(!property.required)
        #expect(property.equatable)
        #expect(property.hashable)
    }

    @Test func apiPropertyFactoriesPreserveSpecialDefaults() {
        let url = ApiModelProperty.url("avatar")
        let bool = ApiModelProperty.bool("enabled")
        let binary = ApiModelProperty.binary("payload")

        #expect(url.required)
        #expect(url.dataType == .url(nil))
        #expect(bool.required)
        #expect(bool.dataType == .bool(false))
        #expect(!ApiModelProperty.bool("enabled", required: false).required)
        #expect(binary.required)
        #expect(!binary.equatable)
        #expect(!binary.hashable)
        #expect(binary.dataType == .binary)
    }

    @Test func apiPropertyCopyHelpersPreserveProtocolFlags() {
        let property = ApiModelProperty.string("name", equatable: true, hashable: true)

        #expect(property.unpublished.equatable)
        #expect(property.unpublished.hashable)
        #expect(property.optional.equatable)
        #expect(property.optional.hashable)
        #expect(property.mandatory.equatable)
        #expect(property.mandatory.hashable)
    }

    @Test func restResourcePatchablePropertiesPreserveMetadata() {
        let dataType = ApiTypeSchema.object(typeName: "User", properties: [
            .string("name", required: false, equatable: true, hashable: true).unpublished
        ])
        let resource = ApiRestResource(
            dataType: dataType,
            metadataProperties: []
        )

        guard case let .object(_, properties, _, _, _, _) = resource.patchableDatatype,
              let property = properties.first else {
            Issue.record("Expected patchable object")
            return
        }

        #expect(!property.required)
        #expect(property.equatable)
        #expect(property.hashable)
        #expect(!property.publishedAsField)
    }

    @Test func unpublishedObjectPropertiesAreNotGeneratedAsSwiftFields() {
        let dataType = ApiTypeSchema.object(typeName: "AuditStamp", properties: [
            .uuid("created_by", propertyName: "createdBy"),
            .string("internal_note", propertyName: "internalNote").unpublished
        ])

        let output = ApiTypeSchemaGenerator(dataType: dataType)
            .getSwiftClass(parentClassName: nil, outputWithExtension: false)?
            .asNode()
            .toString()

        #expect(output?.contains("public var createdBy: UUID") == true)
        #expect(output?.contains("public var internalNote") == false)
        #expect(output?.contains("internal_note") == false)
        #expect(output?.contains("public init(createdBy: UUID)") == true)
    }

    @Test func optionalObjectPropertiesPreserveExplicitDefaults() {
        let dataType = ApiTypeSchema.object(typeName: "Profile", properties: [
            .string("nickname", initialValue: "guest", required: false)
        ])

        let output = ApiTypeSchemaGenerator(dataType: dataType)
            .getSwiftClass(parentClassName: nil, outputWithExtension: false)?
            .asNode()
            .toString()

        #expect(output?.contains("public var nickname: String?") == true)
        #expect(output?.contains("public init(nickname: String? = \"guest\")") == true)
    }

    @Test func apiPropertyFactoriesPreserveReferenceAndCollectionTypes() {
        let user = ApiTypeSchema.object(typeName: "User", properties: [])
        let ref = ApiModelProperty.ref("owner", of: user)
        let arrayOfRef = ApiModelProperty.arrayOfRef("owners", of: user)
        let keyed = ApiModelProperty.keyedByString("metadata", valueType: user, valueOptional: true)

        #expect(ref.dataType == user.asRef)
        #expect(arrayOfRef.dataType == .array(user.asRef))
        #expect(keyed.dataType == .keyedByString(user, isOptional: true))
    }

    @Test func apiPropertyFactoriesPreserveEnumMappings() {
        let stringEnum = ApiModelProperty.stringEnum(
            "status",
            typeName: "Status",
            values: ["active"],
            initialValue: "active",
            supportGarbage: true
        )
        let stringEnumWithRawNames = ApiModelProperty.stringEnum(
            "status",
            typeName: "Status",
            values: [(name: "active", rawName: "ACTIVE")]
        )
        let intEnum = ApiModelProperty.intEnum("rank", typeName: "Rank", values: [1], initialValue: 1)
        let intEnumWithNames = ApiModelProperty.intEnum(
            "rank",
            typeName: "Rank",
            values: [(name: "first", rawValue: 1)]
        )

        if case let .stringEnum(typeName, values, initialValue, _, supportGarbage) = stringEnum.dataType {
            #expect(typeName == "Status")
            #expect(values.map(\.name) == ["active"])
            #expect(values.map(\.rawName) == ["active"])
            #expect(initialValue == "active")
            #expect(supportGarbage)
        } else {
            Issue.record("Expected string enum")
        }

        if case let .stringEnum(typeName, values, initialValue, _, supportGarbage) = stringEnumWithRawNames.dataType {
            #expect(typeName == "Status")
            #expect(values.map(\.name) == ["active"])
            #expect(values.map(\.rawName) == ["ACTIVE"])
            #expect(initialValue == nil)
            #expect(!supportGarbage)
        } else {
            Issue.record("Expected string enum")
        }

        if case let .intEnum(typeName, values, initialValue, _) = intEnum.dataType {
            #expect(typeName == "Rank")
            #expect(values.map(\.name) == [nil])
            #expect(values.map(\.rawValue) == [1])
            #expect(initialValue == 1)
        } else {
            Issue.record("Expected int enum")
        }

        if case let .intEnum(typeName, values, initialValue, _) = intEnumWithNames.dataType {
            #expect(typeName == "Rank")
            #expect(values.map(\.name) == ["first"])
            #expect(values.map(\.rawValue) == [1])
            #expect(initialValue == nil)
        } else {
            Issue.record("Expected int enum")
        }
    }

    @Test func modelsExposePublicInitializers() {
        let definition = ApiService(name: "users", operations: [])

        #expect(definition.name == "users")
        #expect(definition.operations.isEmpty)
        #expect(definition.referencedTypes.isEmpty)
    }

    @Test func apiDataTypeSugarHelpersThrowForInvalidReceivers() {
        #expect(throws: ApiValidationError.self) {
            try ApiTypeSchema.string().prepending(properties: [.string("name")])
        }
        #expect(throws: ApiValidationError.self) {
            try ApiTypeSchema.string().appending(properties: [.string("name")])
        }
        #expect(throws: ApiValidationError.self) {
            try ApiTypeSchema.string().combining(with: .string())
        }
        #expect(throws: ApiValidationError.self) {
            try ApiTypeSchema.string().removing(properties: ["name"])
        }
        #expect(throws: ApiValidationError.self) {
            try ApiTypeSchema.string().modifyingProperties { $0 }
        }
        #expect(throws: ApiValidationError.self) {
            try ApiTypeSchema.string().implementing(protocols: ["Codable"])
        }
        #expect(throws: ApiValidationError.self) {
            try ApiTypeSchema.string().renaming(to: "Name")
        }
    }

    @Test func referenceContextPopOnEmptyStackDoesNotCrash() {
        ApiTypeNameResolver.shared.clear()
        ApiTypeNameResolver.shared.pop()
    }

    @Test func operationAdaptersPreserveBodyKinds() {
        let binaryRequest = ApiOperation.post(
            name: "upload",
            path: .relative("/upload"),
            requestType: .binary()
        )
        let typedResponse = ApiOperation.get(
            name: "download",
            path: .relative("/download"),
            response: .string()
        )
        let addedResponse = ApiOperation.get(name: "image", path: .relative("/image"))
            .adaptingResponse { _ in .string() }

        if case .binary = binaryRequest.adaptingRequest({ _ in .string() }).request {} else {
            Issue.record("Expected binary request to remain binary")
        }
        if case .json(.bool) = typedResponse.adaptingResponse({ _ in .bool() }).response {} else {
            Issue.record("Expected JSON response to remain JSON")
        }
        if case .json(.string) = addedResponse.response {} else {
            Issue.record("Expected missing response to become JSON when adapter adds a type")
        }
    }

    @Test func genericReferenceTypeNameKeepsAllArguments() {
        let generic = ApiTypeSchema.genericReference(
            typeName: "Box",
            genericTypes: [
                .string(),
                .array(.int())
            ]
        )

        #expect(generic.typeName == "Box<String, [Int]>")
    }

    @Test func largeUnsignedIntegerEnumNamesDoNotTrap() {
        #expect(UInt64.max.swiftEnumValueDeclaration.isEmpty == false)
    }

    @Test func patchableEncodingOmitsNilOptionalProperties() {
        let output = ApiTypeSchemaGenerator(
            dataType: .object(
                typeName: "Patch",
                properties: [
                    .string("nickname", required: false),
                    ApiModelProperty(rawName: "name", propertyName: "name", dataType: ApiTypeSchema.string().asPatchable)
                ]
            )
        )
        .getSwiftClass(parentClassName: nil, outputWithExtension: false)?
        .asNode()
        .toString()

        #expect(output?.contains("try codingContainer.encodeIfPresent(self.nickname, forKey: .nickname)") == true)
    }

    @Test func restResourceSubOperationsUseProvidedRelativePath() {
        let resource = ApiRestResource(
            dataType: .object(typeName: "User", properties: [.string("name")]),
            operationTypes: [],
            metadataProperties: [],
            subOperations: [
                .get(name: "activate", path: .relative("activation"))
            ]
        )

        let operation = resource.generateOperations(parentPath: "", parentPathParams: []).first
        if case let .relative(path) = operation?.path {
            #expect(path == "/user/{user_id}/activation")
        } else {
            Issue.record("Expected relative sub-operation path")
        }
    }

    @Test func restResourceSubOperationsPreserveSecurity() {
        let resource = ApiRestResource(
            dataType: .object(typeName: "User", properties: [.string("name")]),
            operationTypes: [],
            metadataProperties: [],
            subOperations: [
                .get(name: "activate", path: .relative("activation"), security: .unsecured)
            ]
        )

        let operation = resource.generateOperations(parentPath: "", parentPathParams: []).first

        #expect(operation?.security == .unsecured)
        #expect(operation?.expandedParameters.map(\.propertyName) == ["userId"])
    }

    @Test func restResourceAbsoluteSubOperationsDoNotInheritResourcePathParameter() {
        let resource = ApiRestResource(
            dataType: .object(typeName: "User", properties: [.string("name")]),
            operationTypes: [],
            metadataProperties: [],
            subOperations: [
                .get(name: "external", path: .absolute("https://example.com/users"), security: .unsecured)
            ]
        )

        let operation = resource.generateOperations(parentPath: "", parentPathParams: []).first

        #expect(operation?.expandedParameters.isEmpty == true)
    }

    @Test func dataTypeGeneratorRejectsUnsafeGeneratedFileNames() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: directory)
        }

        let dataType = ApiTypeSchema.object(typeName: "../Escaped", properties: [.string("name")])

        #expect(throws: ApiValidationError.self) {
            try ApiTypeSchemaGenerator(dataType: dataType).write(
                toDirectory: directory,
                extensionName: "",
                fileNamePrefix: "",
                imports: []
            )
        }
    }

    @Test func dynamicObjectExtraPropertiesUseSwiftTypeDeclarations() {
        let owner = ApiTypeSchema.object(typeName: "Owner", properties: [
            .string("name")
        ])
        let payload = ApiTypeSchema.object(typeName: "Payload", properties: [
            .string("value")
        ])
        let dynamicObject = ApiTypeSchema.dynamicObject(
            typeName: "Event",
            objectTypes: [
                (objectTypeName: "payload", objectTypeRawName: "payload", objectType: payload.asRef)
            ],
            extraProperties: [
                .string("note", required: false),
                .ref("owner", of: owner)
            ]
        )

        ApiTypeNameResolver.shared.push(module: "Shared", types: [owner, payload])
        defer {
            ApiTypeNameResolver.shared.pop()
        }

        let output = ApiTypeSchemaGenerator(dataType: dynamicObject)
            .getSwiftClass(parentClassName: nil, outputWithExtension: false)?
            .asNode()
            .toString()

        #expect(output != nil)
        #expect(output?.contains("case payload(String?, Shared.Owner, Shared.Payload)") == true)
        #expect(output?.contains("let note = try container.decodeIfPresent(String.self, forKey: .note)") == true)
        #expect(output?.contains("let owner = try container.decode(Shared.Owner.self, forKey: .owner)") == true)
        #expect(output?.contains("try container.encodeIfPresent(note, forKey: .note)") == true)
        #expect(output?.contains("try container.encode(owner, forKey: .owner)") == true)
    }

    @Test func dynamicObjectExtraPropertiesDoNotCollideWithPayloadEncodeBinding() {
        let payload = ApiTypeSchema.object(typeName: "Payload", properties: [
            .string("id")
        ])
        let dynamicObject = ApiTypeSchema.dynamicObject(
            typeName: "Event",
            objectTypes: [
                (objectTypeName: "payload", objectTypeRawName: "payload", objectType: payload)
            ],
            extraProperties: [
                .string("value"),
                .string("payload")
            ]
        )

        let output = ApiTypeSchemaGenerator(dataType: dynamicObject)
            .getSwiftClass(parentClassName: nil, outputWithExtension: false)?
            .asNode()
            .toString()

        #expect(output?.contains("case let .payload(value, payload, payload1):") == true)
        #expect(output?.contains("try container.encode(payload1, forKey: .extras)") == true)
        #expect(output?.contains("case let .payload(value, payload, value):") == false)
    }

    @Test func dynamicObjectExtraPropertiesDoNotCollideWithGeneratedLocals() {
        let payload = ApiTypeSchema.object(typeName: "Payload", properties: [
            .string("id")
        ])
        let dynamicObject = ApiTypeSchema.dynamicObject(
            typeName: "Event",
            objectTypes: [
                (objectTypeName: "payload", objectTypeRawName: "payload", objectType: payload)
            ],
            extraProperties: [
                .string("container"),
                .string("decoder")
            ]
        )

        let output = ApiTypeSchemaGenerator(dataType: dynamicObject)
            .getSwiftClass(parentClassName: nil, outputWithExtension: false)?
            .asNode()
            .toString()

        #expect(output?.contains("var container1 = encoder.container(keyedBy: CodingKeys.self)") == true)
        #expect(output?.contains("try container1.encode(container, forKey: .container)") == true)
        #expect(output?.contains("let decoder1 = try container1.decode(String.self, forKey: .decoder)") == true)
        #expect(output?.contains("case let .payload(container, decoder, value):") == true)
    }

    @Test func dynamicObjectDictionaryPayloadUsesSwiftTypeDeclaration() {
        let payload = ApiTypeSchema.object(typeName: "Payload", properties: [
            .string("value")
        ])
        let dynamicObject = ApiTypeSchema.dynamicObject(
            typeName: "Event",
            objectTypes: [
                (objectTypeName: "payloads", objectTypeRawName: "payloads", objectType: .keyedByString(payload.asRef))
            ]
        )

        ApiTypeNameResolver.shared.push(module: "Shared", types: [payload])
        defer {
            ApiTypeNameResolver.shared.pop()
        }

        let output = ApiTypeSchemaGenerator(dataType: dynamicObject)
            .getSwiftClass(parentClassName: nil, outputWithExtension: false)?
            .asNode()
            .toString()

        #expect(output?.contains("case payloads([String: Shared.Payload])") == true)
    }

    @Test func dynamicObjectReferenceDataTypesIncludeExtraProperties() {
        let extra = ApiTypeSchema.object(typeName: "Extra", properties: [
            .string("name")
        ])
        let payload = ApiTypeSchema.object(typeName: "Payload", properties: [
            .string("value")
        ])
        let dynamicObject = ApiTypeSchema.dynamicObject(
            typeName: "Event",
            objectTypes: [
                (objectTypeName: "payload", objectTypeRawName: "payload", objectType: payload)
            ],
            extraProperties: [
                .ref("extra", of: extra)
            ]
        )

        #expect(dynamicObject.referenceDataTypes == [extra.asRef])
    }

    @Test func resolvedDynamicObjectReferencesIncludePayloadReferences() {
        let payload = ApiTypeSchema.object(typeName: "Payload", properties: [
            .string("value")
        ])
        let event = ApiTypeSchema.dynamicObject(
            typeName: "Event",
            objectTypes: [
                (objectTypeName: "payload", objectTypeRawName: "payload", objectType: payload.asRef)
            ]
        )

        #expect(event.asRef.referenceDataTypes == [event.asRef, payload.asRef])
    }

    @Test func dynamicObjectRenamingUsesFreshUUID() throws {
        let dynamicObject = ApiTypeSchema.dynamicObject(
            typeName: "Event",
            objectTypes: [
                (
                    objectTypeName: "payload",
                    objectTypeRawName: "payload",
                    objectType: ApiTypeSchema.object(typeName: "Payload", properties: [.string("value")]).asRef
                )
            ]
        )
        let renamed = try dynamicObject.renaming(to: "RenamedEvent")

        #expect(renamed.typeName == "RenamedEvent")
        #expect(renamed.uuid != dynamicObject.uuid)
    }

    @Test func objectValidatorRejectsDuplicateNestedDeclarationsInCollections() {
        let child = ApiTypeSchema.object(typeName: "Child", properties: [
            .string("name")
        ])
        let parent = ApiTypeSchema.object(typeName: "Parent", properties: [
            .object("child", of: child),
            .array("children", of: child)
        ])

        #expect(throws: (any Error).self) {
            try ApiTypeSchemaValidator(dataType: parent).validate()
        }
    }

    @Test func dynamicObjectArrayPayloadDoesNotGenerateIdentifiableConformance() {
        let payload = ApiTypeSchema.object(
            typeName: "Payload",
            properties: [.string("id")],
            protocols: ["Identifiable"]
        )
        let dynamicObject = ApiTypeSchema.dynamicObject(
            typeName: "Event",
            objectTypes: [
                (objectTypeName: "payloads", objectTypeRawName: "payloads", objectType: .array(payload.asRef))
            ]
        )

        let output = ApiTypeSchemaGenerator(dataType: dynamicObject)
            .getSwiftClass(parentClassName: nil, outputWithExtension: false)?
            .asNode()
            .toString()

        #expect(output?.contains("public enum Event: Codable, Sendable, Identifiable") == false)
        #expect(output?.contains("value.id") == false)
    }

    @Test func dynamicObjectIdentifiableDoesNotGenerateIdOnlyEquality() {
        let payload = ApiTypeSchema.object(
            typeName: "Payload",
            properties: [.string("id")],
            protocols: ["Identifiable"]
        )
        let dynamicObject = ApiTypeSchema.dynamicObject(
            typeName: "Event",
            objectTypes: [
                (objectTypeName: "payload", objectTypeRawName: "payload", objectType: payload)
            ]
        )

        let output = ApiTypeSchemaGenerator(dataType: dynamicObject)
            .getSwiftClass(parentClassName: nil, outputWithExtension: false)?
            .asNode()
            .toString()

        #expect(output?.contains("public enum Event: Codable, Sendable, Identifiable") == true)
        #expect(output?.contains("Equatable") == false)
        #expect(output?.contains("Hashable") == false)
        #expect(output?.contains("public var id: String") == true)
        #expect(output?.contains("lhs.id == rhs.id") == false)
        #expect(output?.contains("hasher.combine(id)") == false)
    }

    @Test func packageValidatorRejectsNonReferenceablePackageReferences() {
        let package = ApiPackage(
            name: "Test",
            targetDirUrl: URL(fileURLWithPath: "/tmp"),
            modules: [],
            referencedModules: [],
            references: [.string()],
            commonReferences: [],
            imports: []
        )

        #expect(throws: (any Error).self) {
            try ApiPackageValidator(package: package).validate()
        }
    }

    @Test func packageValidatorAllowsSameReferenceForRequestAndResponse() {
        let user = ApiTypeSchema.object(typeName: "User", properties: [
            .string("name")
        ])
        let operation = ApiOperation.post(
            name: "createUser",
            path: .relative("/users"),
            request: user.asRef,
            response: user.asRef
        )
        let package = ApiPackage(
            name: "Test",
            targetDirUrl: URL(fileURLWithPath: "/tmp"),
            modules: [
                ApiModule(name: "Users", definitions: [
                    ApiService(name: "Users", operations: [operation], references: [user])
                ])
            ],
            referencedModules: [],
            references: [],
            commonReferences: [],
            imports: []
        )

        #expect(throws: Never.self) {
            try ApiPackageValidator(package: package).validate()
        }
    }

    @Test func packageValidatorRejectsMissingNestedResolvedReference() {
        let child = ApiTypeSchema.object(typeName: "Child", properties: [
            .string("name")
        ])
        let parent = ApiTypeSchema.object(typeName: "Parent", properties: [
            .ref("child", of: child)
        ])
        let operation = ApiOperation.get(
            name: "getParent",
            path: .relative("/parents"),
            response: parent.asRef
        )
        let package = ApiPackage(
            name: "Test",
            targetDirUrl: URL(fileURLWithPath: "/tmp"),
            modules: [
                ApiModule(name: "Parents", definitions: [
                    ApiService(name: "Parents", operations: [operation], references: [parent])
                ])
            ],
            referencedModules: [],
            references: [],
            commonReferences: [],
            imports: []
        )

        #expect(throws: (any Error).self) {
            try ApiPackageValidator(package: package).validate()
        }
    }

    @Test func definitionValidatorMatchesStrictReferencesByUUID() {
        let scopedUser = ApiTypeSchema.object(typeName: "User", properties: [
            .string("name")
        ])
        let otherUser = ApiTypeSchema.object(typeName: "User", properties: [
            .string("email")
        ])
        let operation = ApiOperation.get(
            name: "getUser",
            path: .relative("/users"),
            response: otherUser.asRef
        )
        let definition = ApiService(name: "Users", operations: [operation], references: [scopedUser])

        #expect(throws: (any Error).self) {
            try ApiServiceValidator(definition: definition).validate()
        }
    }

    @Test func definitionValidatorAllowsManualReferenceByScopedName() {
        let scopedUser = ApiTypeSchema.object(typeName: "User", properties: [
            .string("name")
        ])
        let operation = ApiOperation.get(
            name: "getUser",
            path: .relative("/users"),
            response: .reference(typeName: "User")
        )
        let definition = ApiService(name: "Users", operations: [operation], references: [scopedUser])

        #expect(throws: Never.self) {
            try ApiServiceValidator(definition: definition).validate()
        }
    }

    @Test func definitionValidatorMatchesDirectParameterTypesByUUID() {
        let scopedStatus = ApiTypeSchema.stringEnum(
            typeName: "Status",
            values: [(name: "a", rawName: "A")]
        )
        let otherStatus = ApiTypeSchema.stringEnum(
            typeName: "Status",
            values: [(name: "b", rawName: "B")]
        )
        let operation = ApiOperation.get(
            name: "listUsers",
            path: .relative("/users"),
            parameters: [
                .query("status", .stringEnumValue(type: otherStatus, defaultValue: "B"))
            ]
        )
        let definition = ApiService(name: "Users", operations: [operation], references: [scopedStatus])

        #expect(throws: (any Error).self) {
            try ApiServiceValidator(definition: definition).validate()
        }
    }

    @Test func packageValidatorRejectsReferencesOnlyDeclaredByReferencedModules() {
        let sharedUser = ApiTypeSchema.object(typeName: "SharedUser", properties: [
            .string("name")
        ])
        let package = ApiPackage(
            name: "TestApi",
            targetDirUrl: URL(fileURLWithPath: "/tmp/generated"),
            modules: [
                ApiModule(name: "Admin", definitions: [
                    ApiService(name: "Users", operations: [
                        ApiOperation.get(
                            name: "getUser",
                            path: .relative("/users"),
                            security: .unsecured,
                            response: sharedUser.asRef
                        )
                    ])
                ])
            ],
            referencedModules: [
                ApiModule(name: "Shared", definitions: [], references: [sharedUser])
            ],
            references: [],
            commonReferences: [],
            imports: []
        )

        #expect(throws: (any Error).self) {
            try ApiPackageValidator(package: package).validate()
        }
    }

    @Test func packageValidatorRejectsInvalidReferencedModuleDefinitions() {
        let duplicateA = ApiService(name: "User API", operations: [])
        let duplicateB = ApiService(name: "User-API", operations: [])
        let package = ApiPackage(
            name: "Test",
            targetDirUrl: URL(fileURLWithPath: "/tmp/generated"),
            modules: [],
            referencedModules: [
                ApiModule(name: "Shared", definitions: [duplicateA, duplicateB])
            ],
            references: [],
            commonReferences: [],
            imports: []
        )

        #expect(throws: ApiValidationError.self) {
            try ApiPackageValidator(package: package).validate()
        }
    }

    @Test func packageValidatorRejectsKeyedByStringReferences() {
        let user = ApiTypeSchema.object(typeName: "User", properties: [
            .string("name")
        ])
        let keyed = ApiTypeSchema.keyedByString(user)
        let package = ApiPackage(
            name: "TestApi",
            targetDirUrl: URL(fileURLWithPath: "/tmp/generated"),
            modules: [],
            referencedModules: [],
            references: [keyed],
            commonReferences: [],
            imports: []
        )

        #expect(keyed.typeName == nil)
        #expect(!keyed.isReferenceable)
        #expect(throws: (any Error).self) {
            try ApiPackageValidator(package: package).validate()
        }
    }

    @Test func pagedResultsGetNextPageIsOnProtocol() {
        let definition = ApiService(
            name: "Users",
            operations: [
                ApiOperation.get(
                    name: "list",
                    path: .relative("/users"),
                    security: .unsecured,
                    response: .genericReference(typeName: "PagedResults", genericTypes: [.string()])
                )
            ]
        )

        let output = ApiServiceGenerator(definition: definition)
            .swiftBodyCode(moduleName: "Admin", imports: [])
            .toString()

        #expect(output.contains("public protocol AdminUsersApiAsyncAwaitProtocol: Sendable"))
        #expect(output.contains("_ currentPage: AdminUsersApi.ListOperation.Response"))
        #expect(output.contains("request: AdminUsersApi.ListOperation.Request"))
        #expect(!output.contains("func getNextPage<T>(_ currentPage: PagedResults<T>)"))
    }

    @Test func pagedResultsGetNextPageCarriesOriginalRequestHeaders() {
        let definition = ApiService(
            name: "Tasks",
            operations: [
                ApiOperation.get(
                    name: "list",
                    path: .relative("/tasks"),
                    security: .unsecured,
                    parameters: [
                        .header("X-Tenant-Id", .string(""), propertyName: "tenantId"),
                        .cookie("session", .string(), propertyName: "session").optional
                    ],
                    response: .genericReference(typeName: "PagedResults", genericTypes: [.string()])
                )
            ]
        )

        let output = ApiServiceGenerator(definition: definition)
            .swiftBodyCode(moduleName: "Tenant", imports: [])
            .toString()

        #expect(output.contains("let httpHeaders: [String: String]"))
        #expect(output.contains("request: TenantTasksApi.ListOperation.Request"))
        #expect(output.contains("request: NextPageRequest(requestPath: next, httpHeaders: request.httpHeaders)"))
    }

    @Test func securedPagedResultsGetNextPageAdaptsRequestBeforeHeaders() {
        let definition = ApiService(
            name: "Users",
            operations: [
                ApiOperation.get(
                    name: "list",
                    path: .relative("/users"),
                    security: .secured,
                    response: .genericReference(typeName: "PagedResults", genericTypes: [.string()])
                )
            ]
        )

        let output = ApiServiceGenerator(definition: definition)
            .swiftBodyCode(moduleName: "Admin", imports: [])
            .toString()

        #expect(output.contains("var adaptedRequest = request"))
        #expect(output.contains("if adaptedRequest.apiKey.isEmpty"))
        #expect(output.contains("adaptedRequest.apiKey = try await client.requireApiKey()"))
        #expect(output.contains("request: NextPageRequest(requestPath: next, httpHeaders: adaptedRequest.httpHeaders)"))
    }

    @Test func pagedResultsGetNextPageUsesOperationAcceptableStatuses() {
        let definition = ApiService(
            name: "Users",
            operations: [
                ApiOperation.get(
                    name: "list",
                    path: .relative("/users"),
                    security: .unsecured,
                    response: .genericReference(typeName: "PagedResults", genericTypes: [.string()]),
                    acceptableStatuses: [200, 206, 204]
                )
            ]
        )

        let output = ApiServiceGenerator(definition: definition)
            .swiftBodyCode(moduleName: "Admin", imports: [])
            .toString()

        #expect(output.contains("validStatusCode: [200, 206]"))
        #expect(!output.contains("validStatusCode: [200]"))
        #expect(!output.contains("204"))
    }

    @Test func pagedResultsGetNextPageDropsInformationalStatuses() {
        let definition = ApiService(
            name: "Users",
            operations: [
                ApiOperation.get(
                    name: "list",
                    path: .relative("/users"),
                    security: .unsecured,
                    response: .genericReference(typeName: "PagedResults", genericTypes: [.string()]),
                    acceptableStatuses: [100, 102, 200]
                )
            ]
        )

        let output = ApiServiceGenerator(definition: definition)
            .swiftBodyCode(moduleName: "Admin", imports: [])
            .toString()

        #expect(output.contains("validStatusCode: [200]"))
        #expect(!output.contains("100"))
        #expect(!output.contains("102"))
    }

    @Test func optionalPagedResultsGetNextPageFillsMissingApiKeyAndKeepsHeaders() {
        let definition = ApiService(
            name: "Reports",
            operations: [
                ApiOperation.get(
                    name: "list",
                    path: .relative("/reports"),
                    security: .optional,
                    parameters: [
                        .header("X-Trace-Id", .string(), propertyName: "traceId").optional
                    ],
                    response: .genericReference(typeName: "PagedResults", genericTypes: [.string()])
                )
            ]
        )

        let output = ApiServiceGenerator(definition: definition)
            .swiftBodyCode(moduleName: "Admin", imports: [])
            .toString()

        #expect(output.contains("var adaptedRequest = request"))
        #expect(output.contains("if adaptedRequest.apiKey?.isEmpty != false"))
        #expect(output.contains("adaptedRequest.apiKey = await client.apiKey()"))
        #expect(output.contains("request: NextPageRequest(requestPath: next, httpHeaders: adaptedRequest.httpHeaders)"))
        #expect(!output.contains(".isNilOrEmpty"))
    }

    @Test func pagedResultsNextPageRequestBuildsGetRequestWithHeaders() {
        let definition = ApiService(
            name: "Tasks",
            operations: [
                ApiOperation.get(
                    name: "list",
                    path: .relative("/tasks"),
                    security: .unsecured,
                    parameters: [
                        .header("X-Tenant-Id", .string(), propertyName: "tenantId")
                    ],
                    response: .genericReference(typeName: "PagedResults", genericTypes: [.string()])
                )
            ]
        )

        let output = ApiServiceGenerator(definition: definition)
            .swiftBodyCode(moduleName: "Tenant", imports: [])
            .toString()

        #expect(output.contains("var request = try URLRequest(url: requestPath, queryParams: nil)"))
        #expect(output.contains("request.httpMethod = \"GET\""))
        #expect(output.contains("let hasExplicitAccept = httpHeaders.keys.contains {"))
        #expect(output.contains("$0.lowercased() == \"accept\""))
        #expect(output.contains("if !hasExplicitAccept"))
        #expect(output.contains("request.accept(mimeType: \"application/json\")"))
        #expect(output.contains("for (key, value) in httpHeaders"))
        #expect(output.contains("request.addHeader(value, name: key)"))
    }

    @Test func unsecuredPagedResultsGetNextPageUsesEmptyHeadersWhenRequestHasNone() {
        let definition = ApiService(
            name: "Users",
            operations: [
                ApiOperation.get(
                    name: "list",
                    path: .relative("/users"),
                    security: .unsecured,
                    response: .genericReference(typeName: "PagedResults", genericTypes: [.string()])
                )
            ]
        )

        let output = ApiServiceGenerator(definition: definition)
            .swiftBodyCode(moduleName: "Admin", imports: [])
            .toString()

        #expect(output.contains("request: NextPageRequest(requestPath: next, httpHeaders: [:])"))
    }

    @Test func packageGeneratorWritesApiModulesForReferencedModules() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer {
            try? FileManager.default.removeItem(at: directory)
        }

        let package = ApiPackage(
            name: "TestApi",
            targetDirUrl: directory,
            modules: [],
            referencedModules: [
                ApiModule(name: "Shared", definitions: [
                    ApiService(name: "Users", operations: [])
                ])
            ],
            references: [],
            commonReferences: [],
            imports: []
        )

        try ApiPackageGenerator(package: package).write()

        let apiModules = directory.appendingPathComponent("ApiModules.generated.swift")
        #expect(FileManager.default.fileExists(atPath: apiModules.path))
        let contents = try String(contentsOf: apiModules, encoding: .utf8)
        #expect(contents.contains("import Combine"))
    }

    @Test func packageGeneratorEmitsRoundTripImportsWithoutBlanketSwiftLintDisables() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer {
            try? FileManager.default.removeItem(at: directory)
        }

        let user = ApiTypeSchema.object(typeName: "User", properties: [
            .string("id")
        ])
        let package = ApiPackage(
            name: "TestApi",
            targetDirUrl: directory,
            modules: [
                ApiModule(name: "Users", definitions: [
                    ApiService(
                        name: "Profile",
                        operations: [
                            .get(
                                name: "get",
                                path: .relative("/profile"),
                                security: .unsecured,
                                response: user.asRef
                            )
                        ],
                        references: [user]
                    )
                ], references: [user])
            ],
            referencedModules: [],
            references: [user],
            commonReferences: [],
            imports: ["RoundTrip", "RoundTripREST"]
        )

        try ApiPackageGenerator(package: package).write()
        try ApiPackageServiceMocksGenerator(package: package).write(url: directory)

        let generatedFiles = try generatedSwiftFiles(in: directory)
        #expect(!generatedFiles.isEmpty)
        for file in generatedFiles {
            let contents = try String(contentsOf: file, encoding: .utf8)
            #expect(contents.contains("import RoundTrip\n"))
            #expect(contents.contains("import RoundTripREST\n"))
            #expect(!contents.hasPrefix("// swiftlint:disable all"))
        }
    }

    @Test func packageGeneratorDoesNotRewriteModuleScopedReferencesInsideDefinitions() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer {
            try? FileManager.default.removeItem(at: directory)
        }

        let status = ApiTypeSchema.stringEnum(typeName: "TenantStatus", values: [
            (name: "active", rawName: "active")
        ])
        let project = ApiTypeSchema.object(typeName: "Project", properties: [
            .ref("status", of: status)
        ])
        let package = ApiPackage(
            name: "TestApi",
            targetDirUrl: directory,
            modules: [
                ApiModule(name: "Tenant", definitions: [
                    ApiService(
                        name: "Projects",
                        operations: [
                            ApiOperation.get(
                                name: "get",
                                path: .relative("/projects/{id}"),
                                security: .unsecured,
                                parameters: [.path("id", .string())],
                                response: project.asRef
                            )
                        ],
                        references: [project, status]
                    )
                ], references: [status])
            ],
            referencedModules: [],
            references: [],
            commonReferences: [],
            imports: []
        )

        try ApiPackageGenerator(package: package).write()

        let sharedStatusFile = directory.appendingPathComponent("Tenant/Shared/TenantApi+TenantStatus.generated.swift")
        let duplicateStatusFile = directory.appendingPathComponent("Tenant/Projects/Models/TenantProjects+TenantStatus.generated.swift")
        let projectFile = directory.appendingPathComponent("Tenant/Projects/Models/TenantProjects+Project.generated.swift")
        let projectOutput = try String(contentsOf: projectFile, encoding: .utf8)

        #expect(FileManager.default.fileExists(atPath: sharedStatusFile.path))
        #expect(!FileManager.default.fileExists(atPath: duplicateStatusFile.path))
        #expect(projectOutput.contains("public var status: TenantApi.TenantStatus"))
    }

    @Test func apiPackageServiceGeneratorEmitsImmutableModules() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: directory)
        }

        let package = ApiPackage(
            name: "TestApi",
            targetDirUrl: directory,
            modules: [
                ApiModule(name: "Users", definitions: [
                    ApiService(name: "Profile", operations: [])
                ])
            ],
            referencedModules: [],
            references: [],
            commonReferences: [],
            imports: []
        )

        try ApiPackageServiceGenerator(package: package).write(url: directory)
        let output = try String(
            contentsOf: directory.appendingPathComponent("ApiModules.generated.swift"),
            encoding: .utf8
        )

        #expect(output.contains("public struct ApiModules: @unchecked Sendable"))
        #expect(!output.contains("because of RestClient"))
        #expect(output.contains("public let usersModule: UsersApiModule"))
        #expect(!output.contains("public var usersModule: UsersApiModule"))
    }

    @Test func operationValidatorRejectsEmptyPathPlaceholders() {
        let operation = ApiOperation.get(
            name: "getUser",
            path: .relative("/users/{}"),
            parameters: [.path("", .string())]
        )

        #expect(throws: (any Error).self) {
            try ApiOperationValidator(operation: operation).validate()
        }
    }

    @Test func operationValidatorRejectsUnmatchedPathBraces() {
        let operation = ApiOperation.get(
            name: "getUser",
            path: .relative("/users/{id"),
            parameters: []
        )

        #expect(throws: (any Error).self) {
            try ApiOperationValidator(operation: operation).validate()
        }
    }

    @Test func operationValidatorRejectsUnmatchedClosingPathBraces() {
        let operation = ApiOperation.get(
            name: "getUser",
            path: .relative("/users/id}"),
            parameters: []
        )

        #expect(throws: (any Error).self) {
            try ApiOperationValidator(operation: operation).validate()
        }
    }

    @Test func operationValidatorRejectsOptionalPathParameters() {
        let operation = ApiOperation.get(
            name: "getUser",
            path: .relative("/users/{id}"),
            parameters: [.path("id", .string()).optional]
        )

        #expect(throws: (any Error).self) {
            try ApiOperationValidator(operation: operation).validate()
        }
    }

    @Test func operationValidatorRejectsPathParametersOnRuntimePaths() {
        let operation = ApiOperation.get(
            name: "getUser",
            path: .runtime,
            parameters: [.path("id", .string())]
        )

        #expect(throws: (any Error).self) {
            try ApiOperationValidator(operation: operation).validate()
        }
    }

    @Test func operationValidatorRejectsPathPlaceholdersInAbsoluteHost() {
        let operation = ApiOperation.get(
            name: "getUser",
            path: .absolute("https://{tenant}.example.com/users"),
            parameters: [.path("tenant", .string())]
        )

        #expect(throws: (any Error).self) {
            try ApiOperationValidator(operation: operation).validate()
        }
    }

    @Test func operationValidatorRejectsPathPlaceholdersInQuery() {
        let operation = ApiOperation.get(
            name: "getUser",
            path: .relative("/users?filter={filter}"),
            parameters: [.path("filter", .string())]
        )

        #expect(throws: (any Error).self) {
            try ApiOperationValidator(operation: operation).validate()
        }
    }

    @Test func operationValidatorRejectsAbsoluteQueryThatLooksLikePathPlaceholder() {
        let operation = ApiOperation.get(
            name: "getUser",
            path: .absolute("https://example.com?next=/users/{id}"),
            parameters: [.path("id", .string())]
        )

        #expect(throws: (any Error).self) {
            try ApiOperationValidator(operation: operation).validate()
        }
    }

    @Test func operationValidatorRejectsPlaceholderSpanningIntoQuery() {
        let operation = ApiOperation.get(
            name: "getUser",
            path: .relative("/users/{id?filter=value}"),
            parameters: [.path("id?filter=value", .string())]
        )

        #expect(throws: (any Error).self) {
            try ApiOperationValidator(operation: operation).validate()
        }
    }

    @Test func operationValidatorRejectsRequestMemberNameCollisions() {
        let body = ApiTypeSchema.object(typeName: "Body", properties: [.string("name")])
        let operation = ApiOperation.post(
            name: "create",
            path: .relative("/items"),
            security: .unsecured,
            parameters: [.query("body", .string())],
            request: body.asRef
        )

        #expect(throws: (any Error).self) {
            try ApiOperationValidator(operation: operation).validate()
        }
    }

    @Test func restResourceOnlyModifiesDirectObjectDataTypes() {
        let item = ApiTypeSchema.object(typeName: "Item", properties: [
            .string("name")
        ])
        let arrayDataType = ApiTypeSchema.array(item)
        let arrayResource = ApiRestResource(
            name: "ItemBatch",
            dataType: arrayDataType,
            operationTypes: [],
            metadataProperties: []
        )

        #expect(arrayResource.identifiedDataType == arrayDataType)
        #expect(arrayResource.patchableDatatype == arrayDataType)

        let keyedDataType = ApiTypeSchema.keyedByString(item)
        let keyedResource = ApiRestResource(
            name: "ItemMap",
            dataType: keyedDataType,
            operationTypes: [],
            metadataProperties: []
        )

        #expect(keyedResource.identifiedDataType == keyedDataType)
        #expect(keyedResource.patchableDatatype == keyedDataType)
    }

    @Test func moduleValidatorRejectsGeneratedDefinitionNameCollisions() {
        let module = ApiModule(name: "Admin", definitions: [
            ApiService(name: "User API", operations: []),
            ApiService(name: "User-API", operations: [])
        ])

        #expect(throws: (any Error).self) {
            try ApiModuleValidator(module: module).validate(globalTypes: [])
        }
    }

    @Test func packageValidatorRejectsGeneratedModuleNameCollisions() {
        let package = ApiPackage(
            name: "TestApi",
            targetDirUrl: URL(fileURLWithPath: "/tmp/generated"),
            modules: [
                ApiModule(name: "Admin Users", definitions: [
                    ApiService(name: "Profiles", operations: [])
                ]),
                ApiModule(name: "Admin-Users", definitions: [
                    ApiService(name: "Profiles", operations: [])
                ])
            ],
            referencedModules: [],
            references: [],
            commonReferences: [],
            imports: []
        )

        #expect(throws: (any Error).self) {
            try ApiPackageValidator(package: package).validate()
        }
    }

    @Test func apiPackageServiceMocksSetUpDoesNotEmitPackageModuleArguments() throws {
        let output = try generatedServiceMocksOutput()

        #expect(output.contains("usersModule = UsersApiModule("))
        #expect(!output.contains("usersModule: usersModule"))
        #expect(!output.contains("emptyModule: emptyModule"))
    }

    @Test func apiPackageServiceMocksDoNotEmitAppSpecificFixtures() throws {
        let output = try generatedServiceMocksOutput()

        #expect(output.contains("open class ApiModulesMockingTestCase: XCTestCase"))
        #expect(!output.contains("SnapshotingTestCase"))
        #expect(!output.contains("SnapshotTesting"))
        #expect(!output.contains("LDBridge"))
        #expect(!output.contains("LanguageManager"))
        #expect(!output.contains("LDServiceProtocolMock"))
    }

    private func generatedServiceMocksOutput() throws -> String {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: directory)
        }

        let package = ApiPackage(
            name: "TestApi",
            targetDirUrl: directory,
            modules: [
                ApiModule(name: "Users", definitions: [
                    ApiService(name: "Profile", operations: [])
                ]),
                ApiModule(name: "Empty", definitions: [])
            ],
            referencedModules: [],
            references: [],
            commonReferences: [],
            imports: []
        )

        try ApiPackageServiceMocksGenerator(package: package).write(url: directory)
        return try String(
            contentsOf: directory.appendingPathComponent("ApiModulesMocks.generated.swift"),
            encoding: .utf8
        )
    }

    private func generatedSwiftFiles(in directory: URL) throws -> [URL] {
        let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey]
        )
        let files = enumerator?.compactMap { $0 as? URL }.filter { url in
            url.pathExtension == "swift"
        } ?? []

        guard !files.isEmpty else {
            throw ApiValidationError.failed("Expected generated Swift files")
        }
        return files
    }
}
