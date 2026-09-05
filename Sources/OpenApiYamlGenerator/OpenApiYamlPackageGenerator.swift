import Foundation
import GeneratorBuilder
import GeneratorModels

// swiftlint:disable cyclomatic_complexity

public struct OpenApiYamlPackageGenerator {
    public let package: ApiPackage
    public let options: OpenApiYamlGeneratorOptions

    public init(package: ApiPackage, options: OpenApiYamlGeneratorOptions = .init()) {
        self.package = package
        self.options = options
    }

    public func write() throws {
        try generatedFile().write(to: package.targetDirUrl)
    }

    public func generatedFile() -> OpenApiYamlGeneratedTextFile {
        OpenApiYamlGeneratedTextFile(relativePath: options.fileName, contents: render())
    }

    public func generatedFiles() -> [OpenApiYamlGeneratedTextFile] {
        [generatedFile()]
    }

    private func render() -> String {
        var context = OpenApiYamlRenderContext()
        registerComponents(in: &context)

        var yaml = OpenApiYamlWriter()
        yaml.line(OpenApiYamlGeneratedTextFile.managedHeader)
        yaml.line("openapi: 3.1.2")
        yaml.map("info") {
            yaml.scalar("title", options.title ?? package.name)
            yaml.scalar("version", options.version)
        }
        if !options.servers.isEmpty {
            yaml.list("servers", values: options.servers) { server in
                yaml.scalar("url", server)
            }
        }
        yaml.map("paths") {
            renderPaths(&yaml, context: context)
        }
        yaml.map("components") {
            if !context.schemas.isEmpty {
                yaml.map("schemas") {
                    for name in context.schemaOrder {
                        guard let dataType = context.schemas[name] else {
                            continue
                        }
                        yaml.map(OpenApiYamlWriter.quotedKey(name)) {
                            renderSchema(dataType, &yaml, context: &context)
                        }
                    }
                }
            }
            yaml.map("securitySchemes") {
                yaml.map("apiKey") {
                    yaml.scalar("type", "apiKey")
                    yaml.scalar("in", "header")
                    yaml.scalar("name", "Authorization")
                }
            }
        }
        return yaml.output
    }

    private func renderPaths(_ yaml: inout OpenApiYamlWriter, context: OpenApiYamlRenderContext) {
        let grouped = groupedOperations()
        for path in grouped.keys.sorted() {
            guard let operations = grouped[path] else {
                continue
            }
            yaml.map(OpenApiYamlWriter.quotedKey(path)) {
                for item in operations.sorted(by: { $0.operation.name < $1.operation.name }) {
                    yaml.map(item.operation.method.rawValue) {
                        renderOperation(item.operation, operationId: item.operationId, tag: item.tag, &yaml, context: context)
                    }
                }
            }
        }
    }

    private func renderOperation(_ operation: ApiOperation, operationId: String, tag: String, _ yaml: inout OpenApiYamlWriter, context: OpenApiYamlRenderContext) {
        yaml.scalar("operationId", operationId)
        yaml.scalar("summary", operation.name.capitalCased)
        yaml.list("tags", scalars: [tag])
        if operation.path.isRuntime {
            yaml.scalar("x-runtime-url", true)
        }
        switch operation.security {
            case .secured:
                yaml.list("security") {
                    yaml.mapItem {
                        yaml.list("apiKey", scalars: [])
                    }
                }
            case .optional:
                yaml.list("security") {
                    yaml.mapItem {
                        yaml.list("apiKey", scalars: [])
                    }
                    yaml.mapItem {}
                }
            case .unsecured:
                yaml.list("security") {
                    yaml.mapItem {}
                }
        }

        let parameters = operation.expandedParameters
        if !parameters.isEmpty || operation.path.isRuntime {
            yaml.list("parameters") {
                if operation.path.isRuntime {
                    yaml.mapItem {
                        yaml.scalar("name", "runtimeUrl")
                        yaml.scalar("in", "path")
                        yaml.scalar("required", true)
                        yaml.map("schema") {
                            yaml.scalar("type", "string")
                            yaml.scalar("format", "uri")
                        }
                    }
                }
                for parameter in parameters {
                    yaml.mapItem {
                        renderParameter(parameter, &yaml, context: context)
                    }
                }
            }
        }

        renderRequestBody(operation.request, &yaml, context: context)
        yaml.map("responses") {
            for status in operation.acceptableStatuses.sorted() {
                yaml.map(OpenApiYamlWriter.quotedKey("\(status)")) {
                    yaml.scalar("description", HTTPURLResponse.localizedString(forStatusCode: status).capitalized)
                    if status.canCarryResponseBody {
                        renderResponseContent(operation.response, &yaml, context: context)
                    }
                }
            }
        }
    }

    private func renderParameter(_ parameter: ApiParameter, _ yaml: inout OpenApiYamlWriter, context: OpenApiYamlRenderContext) {
        yaml.scalar("name", parameter.rawName)
        yaml.scalar("in", parameter.location.rawValue)
        yaml.scalar("required", parameter.location == .path ? true : parameter.isRequired)
        yaml.map("schema") {
            renderParameterSchema(parameter.dataType, &yaml, context: context)
        }
    }

    private func renderRequestBody(_ request: ApiRequestBody, _ yaml: inout OpenApiYamlWriter, context: OpenApiYamlRenderContext) {
        switch request {
            case .none:
                return
            case let .binary(mimeType):
                yaml.map("requestBody") {
                    yaml.scalar("required", true)
                    yaml.map("content") {
                        yaml.map(OpenApiYamlWriter.quotedKey(mimeType)) {
                            yaml.map("schema") {
                                yaml.scalar("type", "string")
                                yaml.scalar("format", "binary")
                            }
                        }
                    }
                }
            case .file:
                yaml.map("requestBody") {
                    yaml.scalar("required", true)
                    yaml.map("content") {
                        yaml.map("application/octet-stream") {
                            yaml.map("schema") {
                                yaml.scalar("type", "string")
                                yaml.scalar("format", "binary")
                            }
                        }
                    }
                }
            case let .multiPart(parts):
                yaml.map("requestBody") {
                    yaml.scalar("required", true)
                    yaml.map("content") {
                        yaml.map("multipart/form-data") {
                            yaml.map("schema") {
                                yaml.scalar("type", "object")
                                yaml.map("properties") {
                                    for part in parts {
                                        yaml.map(OpenApiYamlWriter.quotedKey(part)) {
                                            yaml.scalar("type", "string")
                                            yaml.scalar("format", "binary")
                                        }
                                    }
                                }
                                yaml.list("required", scalars: parts)
                            }
                        }
                    }
                }
            case let .json(dataType):
                guard let dataType else {
                    return
                }
                var mutableContext = context
                yaml.map("requestBody") {
                    yaml.scalar("required", true)
                    yaml.map("content") {
                        yaml.map("application/json") {
                            yaml.map("schema") {
                                renderSchema(dataType, &yaml, context: &mutableContext)
                            }
                        }
                    }
                }
        }
    }

    private func renderResponseContent(_ response: ApiResponseBody, _ yaml: inout OpenApiYamlWriter, context: OpenApiYamlRenderContext) {
        switch response {
            case .none:
                return
            case let .binary(mimeType):
                yaml.map("content") {
                    yaml.map(OpenApiYamlWriter.quotedKey(mimeType)) {
                        yaml.map("schema") {
                            yaml.scalar("type", "string")
                            yaml.scalar("format", "binary")
                        }
                    }
                }
            case let .json(dataType):
                guard let dataType else {
                    return
                }
                var mutableContext = context
                yaml.map("content") {
                    yaml.map("application/json") {
                        yaml.map("schema") {
                            renderSchema(dataType, &yaml, context: &mutableContext)
                        }
                    }
                }
        }
    }

    private func renderSchema(_ dataType: ApiTypeSchema, _ yaml: inout OpenApiYamlWriter, context: inout OpenApiYamlRenderContext) {
        switch dataType {
            case .uuid:
                yaml.scalar("type", "string")
                yaml.scalar("format", "uuid")
            case let .string(value):
                yaml.scalar("type", "string")
                if let value {
                    yaml.scalar("default", value)
                }
            case let .int(value):
                yaml.scalar("type", "integer")
                yaml.scalar("format", "int64")
                if let value {
                    yaml.scalar("default", value)
                }
            case let .int64(value):
                yaml.scalar("type", "integer")
                yaml.scalar("format", "int64")
                if let value {
                    yaml.scalar("default", value)
                }
            case let .int32(value):
                yaml.scalar("type", "integer")
                yaml.scalar("format", "int32")
                if let value {
                    yaml.scalar("default", value)
                }
            case let .int16(value):
                yaml.scalar("type", "integer")
                if let value {
                    yaml.scalar("default", value)
                }
            case let .int8(value):
                yaml.scalar("type", "integer")
                if let value {
                    yaml.scalar("default", value)
                }
            case let .uint(value):
                yaml.scalar("type", "integer")
                yaml.scalar("format", "int64")
                yaml.scalar("minimum", 0)
                if let value {
                    yaml.scalar("default", value)
                }
            case let .uint64(value):
                yaml.scalar("type", "integer")
                yaml.scalar("format", "int64")
                yaml.scalar("minimum", 0)
                if let value {
                    yaml.scalar("default", value)
                }
            case let .uint32(value):
                yaml.scalar("type", "integer")
                yaml.scalar("format", "int32")
                yaml.scalar("minimum", 0)
                if let value {
                    yaml.scalar("default", value)
                }
            case let .uint16(value):
                yaml.scalar("type", "integer")
                yaml.scalar("minimum", 0)
                if let value {
                    yaml.scalar("default", value)
                }
            case let .uint8(value):
                yaml.scalar("type", "integer")
                yaml.scalar("minimum", 0)
                if let value {
                    yaml.scalar("default", value)
                }
            case let .double(value):
                yaml.scalar("type", "number")
                yaml.scalar("format", "double")
                if let value {
                    yaml.scalar("default", value)
                }
            case .date:
                yaml.scalar("type", "string")
                yaml.scalar("format", "date-time")
            case .timelessDate:
                yaml.scalar("type", "string")
                yaml.scalar("format", "date")
            case .time:
                yaml.scalar("type", "string")
                yaml.scalar("format", "time")
            case let .url(value):
                yaml.scalar("type", "string")
                yaml.scalar("format", "uri")
                if let value {
                    yaml.scalar("default", value.absoluteString)
                }
            case let .bool(value):
                yaml.scalar("type", "boolean")
                yaml.scalar("default", value)
            case .binary:
                yaml.scalar("type", "string")
                yaml.scalar("format", "binary")
            case let .keyedByString(type, _):
                yaml.scalar("type", "object")
                yaml.map("additionalProperties") {
                    renderSchema(type, &yaml, context: &context)
                }
            case let .stringEnum(_, values, initialValue, _, supportGarbage):
                yaml.scalar("type", "string")
                yaml.list("enum", scalars: values.map(\.rawName))
                if let initialValue {
                    yaml.scalar("default", initialValue)
                }
                if supportGarbage {
                    yaml.scalar("x-supports-unknown-values", true)
                }
            case let .intEnum(_, values, initialValue, _):
                yaml.scalar("type", "integer")
                yaml.list("enum", scalars: values.map(\.rawValue))
                if let initialValue {
                    yaml.scalar("default", initialValue)
                }
            case let .array(type):
                yaml.scalar("type", "array")
                yaml.map("items") {
                    renderSchema(type, &yaml, context: &context)
                }
            case let .object(_, properties, _, _, _, _):
                renderObjectSchema(properties: properties, &yaml, context: &context)
            case let .dynamicObject(_, objectTypePropertyName, objectDataPropertyName, _, objectTypes, supportGarbage, _, _, extraProperties):
                yaml.map("discriminator") {
                    yaml.scalar("propertyName", objectTypePropertyName)
                }
                yaml.list("oneOf") {
                    for objectType in objectTypes {
                        yaml.mapItem {
                            yaml.scalar("type", "object")
                            yaml.map("properties") {
                                yaml.map(OpenApiYamlWriter.quotedKey(objectTypePropertyName)) {
                                    yaml.scalar("type", "string")
                                    yaml.list("enum", scalars: [objectType.objectTypeRawName])
                                }
                                yaml.map(OpenApiYamlWriter.quotedKey(objectDataPropertyName)) {
                                    renderSchema(objectType.objectType, &yaml, context: &context)
                                }
                                for property in extraProperties where property.publishedAsField {
                                    yaml.map(OpenApiYamlWriter.quotedKey(property.rawName)) {
                                        renderSchema(property.dataType, &yaml, context: &context)
                                    }
                                }
                            }
                            yaml.list("required", scalars: [objectTypePropertyName, objectDataPropertyName] + extraProperties.filter(\.required).map(\.rawName))
                        }
                    }
                }
                if supportGarbage {
                    yaml.scalar("x-supports-unknown-values", true)
                }
            case let .reference(typeName, _, _, _, dataType):
                if let dataType {
                    context.register(dataType)
                }
                yaml.scalar("$ref", "#/components/schemas/\(context.schemaName(for: typeName))")
            case let .genericReference(typeName, genericTypes):
                let name = context.genericSchemaName(typeName: typeName, genericTypes: genericTypes)
                yaml.scalar("$ref", "#/components/schemas/\(name)")
        }
    }

    private func renderObjectSchema(properties: [ApiModelProperty], _ yaml: inout OpenApiYamlWriter, context: inout OpenApiYamlRenderContext) {
        let published = properties.filter(\.publishedAsField)
        yaml.scalar("type", "object")
        if !published.isEmpty {
            yaml.map("properties") {
                for property in published {
                    yaml.map(OpenApiYamlWriter.quotedKey(property.rawName)) {
                        renderSchema(property.dataType, &yaml, context: &context)
                    }
                }
            }
            let required = published.filter(\.required).map(\.rawName)
            if !required.isEmpty {
                yaml.list("required", scalars: required)
            }
        }
    }

    private func renderParameterSchema(_ dataType: ApiParameter.DataType, _ yaml: inout OpenApiYamlWriter, context: OpenApiYamlRenderContext) {
        var mutableContext = context
        switch dataType {
            case let .bool(value):
                yaml.scalar("type", "boolean")
                if let value {
                    yaml.scalar("default", value)
                }
            case let .boolArray(values):
                renderArrayParameter(itemsType: "boolean", defaultValues: values, &yaml)
            case let .string(value):
                yaml.scalar("type", "string")
                if let value {
                    yaml.scalar("default", value)
                }
            case let .stringArray(values):
                renderArrayParameter(itemsType: "string", defaultValues: values, &yaml)
            case let .int(value):
                renderIntegerParameter(value, format: "int64", &yaml)
            case let .intArray(values):
                renderIntegerArrayParameter(values, format: "int64", &yaml)
            case let .int16(value):
                renderIntegerParameter(value, format: nil, &yaml)
            case let .int16Array(values):
                renderIntegerArrayParameter(values, format: nil, &yaml)
            case let .int32(value):
                renderIntegerParameter(value, format: "int32", &yaml)
            case let .int32Array(values):
                renderIntegerArrayParameter(values, format: "int32", &yaml)
            case let .int64(value):
                renderIntegerParameter(value, format: "int64", &yaml)
            case let .int64Array(values):
                renderIntegerArrayParameter(values, format: "int64", &yaml)
            case let .uint(value):
                renderUnsignedIntegerParameter(value, format: "int64", &yaml)
            case let .uintArray(values):
                renderUnsignedIntegerArrayParameter(values, format: "int64", &yaml)
            case let .uint16(value):
                renderUnsignedIntegerParameter(value, format: nil, &yaml)
            case let .uint16Array(values):
                renderUnsignedIntegerArrayParameter(values, format: nil, &yaml)
            case let .uint32(value):
                renderUnsignedIntegerParameter(value, format: "int32", &yaml)
            case let .uint32Array(values):
                renderUnsignedIntegerArrayParameter(values, format: "int32", &yaml)
            case let .uint64(value):
                renderUnsignedIntegerParameter(value, format: "int64", &yaml)
            case let .uint64Array(values):
                renderUnsignedIntegerArrayParameter(values, format: "int64", &yaml)
            case let .stringEnumValue(type, defaultValue):
                renderSchema(type, &yaml, context: &mutableContext)
                if let defaultValue {
                    yaml.scalar("default", defaultValue)
                }
            case let .stringEnumArray(type, defaultValues):
                yaml.scalar("type", "array")
                yaml.map("items") {
                    renderSchema(type, &yaml, context: &mutableContext)
                }
                if let defaultValues {
                    yaml.list("default", scalars: defaultValues)
                }
            case let .intEnumValue(type, defaultValue):
                renderSchema(type, &yaml, context: &mutableContext)
                if let defaultValue {
                    yaml.scalar("default", defaultValue)
                }
            case let .intEnumArray(type, defaultValues):
                yaml.scalar("type", "array")
                yaml.map("items") {
                    renderSchema(type, &yaml, context: &mutableContext)
                }
                if let defaultValues {
                    yaml.list("default", scalars: defaultValues)
                }
            case .dateTime:
                yaml.scalar("type", "string")
                yaml.scalar("format", "date-time")
            case .date:
                yaml.scalar("type", "string")
                yaml.scalar("format", "date")
            case .time:
                yaml.scalar("type", "string")
                yaml.scalar("format", "time")
        }
    }

    private func renderArrayParameter(itemsType: String, defaultValues: [some Any]?, _ yaml: inout OpenApiYamlWriter) {
        yaml.scalar("type", "array")
        yaml.map("items") {
            yaml.scalar("type", itemsType)
        }
        if let defaultValues {
            yaml.list("default", scalars: defaultValues)
        }
    }

    private func renderIntegerParameter(_ value: (some FixedWidthInteger)?, format: String?, _ yaml: inout OpenApiYamlWriter) {
        yaml.scalar("type", "integer")
        if let format {
            yaml.scalar("format", format)
        }
        if let value {
            yaml.scalar("default", Int64(value))
        }
    }

    private func renderUnsignedIntegerParameter(_ value: (some FixedWidthInteger & UnsignedInteger)?, format: String?, _ yaml: inout OpenApiYamlWriter) {
        yaml.scalar("type", "integer")
        if let format {
            yaml.scalar("format", format)
        }
        yaml.scalar("minimum", 0)
        if let value {
            yaml.scalar("default", UInt64(value))
        }
    }

    private func renderIntegerArrayParameter(_ values: [some FixedWidthInteger]?, format: String?, _ yaml: inout OpenApiYamlWriter) {
        yaml.scalar("type", "array")
        yaml.map("items") {
            yaml.scalar("type", "integer")
            if let format {
                yaml.scalar("format", format)
            }
        }
        if let values {
            yaml.list("default", scalars: values.map { Int64($0) })
        }
    }

    private func renderUnsignedIntegerArrayParameter(_ values: [some FixedWidthInteger & UnsignedInteger]?, format: String?, _ yaml: inout OpenApiYamlWriter) {
        yaml.scalar("type", "array")
        yaml.map("items") {
            yaml.scalar("type", "integer")
            if let format {
                yaml.scalar("format", format)
            }
            yaml.scalar("minimum", 0)
        }
        if let values {
            yaml.list("default", scalars: values.map { UInt64($0) })
        }
    }

    private func groupedOperations() -> [String: [OpenApiYamlOperation]] {
        var result: [String: [OpenApiYamlOperation]] = [:]
        for module in package.modules {
            for definition in module.definitions {
                for operation in definition.operations {
                    let item = OpenApiYamlOperation(
                        moduleName: module.name,
                        definitionName: definition.name,
                        operation: operation
                    )
                    result[openApiPath(for: operation), default: []].append(item)
                }
            }
        }
        return result
    }

    private func openApiPath(for operation: ApiOperation) -> String {
        switch operation.path {
            case let .relative(path):
                return path.hasPrefix("/") ? path : "/\(path)"
            case let .absolute(path):
                guard let components = URLComponents(string: path) else {
                    return path.hasPrefix("/") ? path : "/\(path)"
                }
                var result = components.path.isEmpty ? "/" : components.path
                if let queryItems = components.queryItems, !queryItems.isEmpty {
                    let query = queryItems.map(\.name).joined(separator: ",")
                    result += "{?\(query)}"
                }
                return result
            case .runtime:
                return "/_runtime/{runtimeUrl}"
        }
    }

    private func registerComponents(in context: inout OpenApiYamlRenderContext) {
        for dataType in package.commonReferences + package.references {
            context.register(dataType)
        }
        for module in package.referencedModules + package.modules {
            for dataType in module.references {
                context.register(dataType)
            }
            for definition in module.definitions {
                for dataType in definition.referencedTypes {
                    context.register(dataType)
                }
                for operation in definition.operations {
                    if let requestType = operation.request.dataType {
                        context.registerUsed(type: requestType)
                    }
                    if let responseType = operation.response.dataType {
                        context.registerUsed(type: responseType)
                    }
                    for parameter in operation.expandedParameters {
                        context.registerUsed(parameterType: parameter.dataType)
                    }
                }
            }
        }
    }
}

private struct OpenApiYamlRenderContext {
    private(set) var schemas: [String: ApiTypeSchema] = [:]
    private(set) var schemaOrder: [String] = []
    private var visitedTypeIDs: Set<UUID> = []

    mutating func register(_ dataType: ApiTypeSchema) {
        if let name = declaredSchemaName(for: dataType) {
            register(dataType, name: name)
        } else {
            registerNested(in: dataType)
        }
    }

    mutating func registerUsed(type dataType: ApiTypeSchema) {
        switch dataType {
            case let .reference(typeName, _, _, _, nested):
                if let nested {
                    register(nested, name: schemaName(for: typeName))
                } else {
                    registerPlaceholder(typeName: typeName)
                }
            case let .genericReference(typeName, genericTypes):
                registerPlaceholder(typeName: genericSchemaName(typeName: typeName, genericTypes: genericTypes))
                genericTypes.forEach { registerUsed(type: $0) }
            case let .array(type):
                registerUsed(type: type)
            case let .keyedByString(type, _):
                registerUsed(type: type)
            default:
                register(dataType)
        }
    }

    mutating func registerUsed(parameterType: ApiParameter.DataType) {
        switch parameterType {
            case let .stringEnumValue(type, _),
                 let .stringEnumArray(type, _),
                 let .intEnumValue(type, _),
                 let .intEnumArray(type, _):
                registerUsed(type: type)
            default:
                return
        }
    }

    func schemaName(for typeName: String) -> String {
        OpenApiYamlRenderContext.sanitizedSchemaName(typeName)
    }

    func genericSchemaName(typeName: String, genericTypes: [ApiTypeSchema]) -> String {
        let suffix = genericTypes
            .map { declaredSchemaName(for: $0) ?? "Value" }
            .joined()
        return schemaName(for: "\(typeName)\(suffix)")
    }

    private mutating func register(_ dataType: ApiTypeSchema, name: String) {
        if schemas[name] == nil {
            schemaOrder.append(name)
            schemas[name] = dataType
        }
        registerNested(in: dataType)
    }

    private mutating func registerPlaceholder(typeName: String) {
        let name = schemaName(for: typeName)
        if schemas[name] == nil {
            schemaOrder.append(name)
            schemas[name] = .object(typeName: name, properties: [])
        }
    }

    private mutating func registerNested(in dataType: ApiTypeSchema) {
        if let id = dataType.uuid, !visitedTypeIDs.insert(id).inserted {
            return
        }
        switch dataType {
            case let .object(_, properties, _, _, _, _):
                properties.forEach { registerUsed(type: $0.dataType) }
            case let .dynamicObject(_, _, _, _, objectTypes, _, _, _, extraProperties):
                objectTypes.forEach { registerUsed(type: $0.objectType) }
                extraProperties.forEach { registerUsed(type: $0.dataType) }
            case let .array(type),
                 let .keyedByString(type, _):
                registerUsed(type: type)
            case let .reference(typeName, _, _, _, nested):
                if let nested {
                    register(nested, name: schemaName(for: typeName))
                } else {
                    registerPlaceholder(typeName: typeName)
                }
            case let .genericReference(typeName, genericTypes):
                registerPlaceholder(typeName: genericSchemaName(typeName: typeName, genericTypes: genericTypes))
                genericTypes.forEach { registerUsed(type: $0) }
            default:
                return
        }
    }

    private func declaredSchemaName(for dataType: ApiTypeSchema) -> String? {
        switch dataType {
            case let .object(typeName, _, _, _, _, _),
                 let .stringEnum(typeName, _, _, _, _),
                 let .intEnum(typeName, _, _, _),
                 let .dynamicObject(typeName, _, _, _, _, _, _, _, _),
                 let .reference(typeName, _, _, _, _):
                schemaName(for: typeName)
            case let .genericReference(typeName, genericTypes):
                genericSchemaName(typeName: typeName, genericTypes: genericTypes)
            default:
                nil
        }
    }

    private static func sanitizedSchemaName(_ typeName: String) -> String {
        let parts = typeName.components(separatedBy: CharacterSet.alphanumerics.inverted)
        let joined = parts.filter { !$0.isEmpty }.map(\.capitalCased).joined()
        return joined.isEmpty ? "Value" : joined
    }
}

private struct OpenApiYamlOperation {
    let moduleName: String
    let definitionName: String
    let operation: ApiOperation

    var tag: String {
        "\(moduleName).\(definitionName)"
    }

    var operationId: String {
        "\(moduleName)\(definitionName)\(operation.name)".capitalCased
    }
}

private final class OpenApiYamlWriter {
    private var lines: [String] = []
    private var indentLevel = 0

    var output: String {
        lines.joined(separator: "\n")
    }

    func line(_ value: String) {
        lines.append("\(indent)\(value)")
    }

    func scalar(_ key: String, _ value: some Any) {
        line("\(key): \(format(value))")
    }

    func map(_ key: String, body: () -> Void) {
        line("\(key):")
        indented(body)
    }

    func list(_ key: String, body: () -> Void) {
        line("\(key):")
        indented(body)
    }

    func list(_ key: String, scalars: [some Any]) {
        if scalars.isEmpty {
            line("\(key): []")
            return
        }
        line("\(key):")
        indented {
            for scalar in scalars {
                line("- \(format(scalar))")
            }
        }
    }

    func list<T>(_ key: String, values: [T], item: (T) -> Void) {
        line("\(key):")
        indented {
            for value in values {
                line("-")
                indented {
                    item(value)
                }
            }
        }
    }

    func mapItem(body: () -> Void) {
        let before = lines.count
        line("-")
        indented(body)
        if lines.count == before + 1 {
            lines[lines.count - 1] = "\(indent)- {}"
        }
    }

    static func quotedKey(_ key: String) -> String {
        if key.range(of: #"^[A-Za-z0-9_.-]+$"#, options: .regularExpression) != nil,
           key.range(of: #"^[0-9]+$"#, options: .regularExpression) == nil,
           key != "true",
           key != "false",
           key != "null" {
            return key
        }
        return quote(key)
    }

    private var indent: String {
        String(repeating: "  ", count: indentLevel)
    }

    private func indented(_ body: () -> Void) {
        indentLevel += 1
        body()
        indentLevel -= 1
    }

    private func format(_ value: some Any) -> String {
        switch value {
            case let value as String:
                Self.quote(value)
            case let value as Bool:
                value ? "true" : "false"
            case let value as Int:
                "\(value)"
            case let value as Int64:
                "\(value)"
            case let value as UInt64:
                "\(value)"
            case let value as Double:
                "\(value)"
            default:
                Self.quote("\(value)")
        }
    }

    private static func quote(_ value: String) -> String {
        let escaped = value
            .replacingOccurrences(of: #"\"#, with: #"\\"#)
            .replacingOccurrences(of: #"""#, with: #"\""#)
        return "\"\(escaped)\""
    }
}

private extension ApiRequestBody {
    var dataType: ApiTypeSchema? {
        switch self {
            case let .json(type):
                type
            case .file:
                .url(nil)
            default:
                nil
        }
    }
}

private extension ApiResponseBody {
    var dataType: ApiTypeSchema? {
        switch self {
            case let .json(type):
                type
            default:
                nil
        }
    }
}

private extension Int {
    var canCarryResponseBody: Bool {
        !(100 ..< 200 ~= self || self == 204 || self == 205 || self == 304)
    }
}
