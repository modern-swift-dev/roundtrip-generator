import SwiftApiGenerator
import SwiftSyntax
import SwiftSyntaxBuilder

struct SwiftVaporRuntimeEmitter {
    let sourceRoot: String

    func file() -> SwiftVaporGeneratedTextFile {
        SwiftVaporGeneratedTextFile(
            relativePath: "\(sourceRoot)/Generated/Runtime/VaporApiRuntime.generated.swift",
            syntax: SwiftVaporSyntax.sourceFile(
                imports: ["import Foundation", "import Vapor"],
                declarations: [
                    DeclSyntax(generatedResponse),
                    DeclSyntax(generatedResponseConformance),
                    DeclSyntax(generatedResponseEncoder),
                    DeclSyntax(generatedSecurityMiddleware),
                    DeclSyntax(allowAllGeneratedSecurityMiddleware),
                    DeclSyntax(generatedSecurityRequest),
                    DeclSyntax(generatedBodyReader),
                    DeclSyntax(generatedMultipartPart),
                    DeclSyntax(generatedRequestValueParser),
                    DeclSyntax(timelessDate),
                    DeclSyntax(time),
                    DeclSyntax(localizedData),
                    DeclSyntax(localizedDataConformance),
                    DeclSyntax(patchableValue),
                    DeclSyntax(patchableValueConformance),
                    DeclSyntax(keyedDecodingContainer),
                    DeclSyntax(keyedEncodingContainer),
                    DeclSyntax(pagedResults),
                    DeclSyntax(pagedResultsConformance),
                    DeclSyntax(generatedJSONValue)
                ],
            ),
        )
    }

    private var generatedResponse: StructDeclSyntax {
        SwiftGeneratedSyntax.parse("runtime generatedResponse") {
            try StructDeclSyntax("public struct GeneratedResponse<Value>") {
                try VariableDeclSyntax("public var status: HTTPResponseStatus")
                try VariableDeclSyntax("public var headers: HTTPHeaders")
                try VariableDeclSyntax("public var value: Value?")
                try InitializerDeclSyntax(
                    """
                    public init(status: HTTPResponseStatus = .ok, headers: HTTPHeaders = HTTPHeaders(), value: Value) {
                        self.status = status
                        self.headers = headers
                        self.value = value
                    }
                    """,
                )
                try InitializerDeclSyntax(
                    """
                    public init(status: HTTPResponseStatus, headers: HTTPHeaders = HTTPHeaders()) {
                        self.status = status
                        self.headers = headers
                        value = nil
                    }
                    """,
                )
            }
        }
    }

    private var generatedResponseConformance: ExtensionDeclSyntax {
        SwiftGeneratedSyntax.parse("runtime generatedResponseConformance") {
            try ExtensionDeclSyntax("extension GeneratedResponse: Sendable where Value: Sendable") {}
        }
    }

    private var generatedResponseEncoder: EnumDeclSyntax {
        SwiftGeneratedSyntax.parse("runtime generatedResponseEncoder") {
            try EnumDeclSyntax("public enum GeneratedResponseEncoder") {
                try FunctionDeclSyntax(
                    """
                    public static func empty(_ response: GeneratedResponse<Void>, validStatusCodes: [Int]) throws -> Response {
                        try validateStatus(response.status, validStatusCodes: validStatusCodes)
                        return Response(status: response.status, headers: response.headers)
                    }
                    """,
                )
                try FunctionDeclSyntax(
                    """
                    public static func json<Value: Encodable>(_ response: GeneratedResponse<Value>, validStatusCodes: [Int]) throws -> Response {
                        try validateStatus(response.status, validStatusCodes: validStatusCodes)
                        guard isBodyAllowed(for: response.status) else {
                            return Response(status: response.status, headers: response.headers)
                        }
                        guard let value = response.value else {
                            throw Abort(.internalServerError, reason: "Missing response value")
                        }
                        let vaporResponse = Response(status: response.status, headers: response.headers)
                        try vaporResponse.content.encode(value, as: .json)
                        return vaporResponse
                    }
                    """,
                )
                try FunctionDeclSyntax(
                    """
                    public static func binary(_ response: GeneratedResponse<Data>, contentType: String, validStatusCodes: [Int]) throws -> Response {
                        try validateStatus(response.status, validStatusCodes: validStatusCodes)
                        guard isBodyAllowed(for: response.status) else {
                            return Response(status: response.status, headers: response.headers)
                        }
                        guard let value = response.value else {
                            throw Abort(.internalServerError, reason: "Missing response value")
                        }
                        var headers = response.headers
                        headers.replaceOrAdd(name: .contentType, value: contentType)
                        return Response(status: response.status, headers: headers, body: .init(data: value))
                    }
                    """,
                )
                try FunctionDeclSyntax(
                    """
                    private static func validateStatus(_ status: HTTPResponseStatus, validStatusCodes: [Int]) throws {
                        guard validStatusCodes.contains(Int(status.code)) else {
                            throw Abort(.internalServerError, reason: "Unexpected response status: \\(status.code)")
                        }
                    }
                    """,
                )
                try FunctionDeclSyntax(
                    """
                    private static func isBodyAllowed(for status: HTTPResponseStatus) -> Bool {
                        !(100 ..< 200 ~= Int(status.code) || [204, 205, 304].contains(Int(status.code)))
                    }
                    """,
                )
            }
        }
    }

    private var generatedSecurityMiddleware: ProtocolDeclSyntax {
        SwiftGeneratedSyntax.parse("runtime generatedSecurityMiddleware") {
            try ProtocolDeclSyntax("public protocol GeneratedSecurityMiddleware: Sendable") {
                try FunctionDeclSyntax("func requireAuthorization(_ request: GeneratedSecurityRequest) async throws")
                try FunctionDeclSyntax("func authorizeOptional(_ request: GeneratedSecurityRequest) async throws")
            }
        }
    }

    private var allowAllGeneratedSecurityMiddleware: StructDeclSyntax {
        SwiftGeneratedSyntax.parse("runtime allowAllGeneratedSecurityMiddleware") {
            try StructDeclSyntax("public struct AllowAllGeneratedSecurityMiddleware: GeneratedSecurityMiddleware") {
                try InitializerDeclSyntax("public init() {}")
                try FunctionDeclSyntax("public func requireAuthorization(_: GeneratedSecurityRequest) async throws {}")
                try FunctionDeclSyntax("public func authorizeOptional(_: GeneratedSecurityRequest) async throws {}")
            }
        }
    }

    private var generatedSecurityRequest: StructDeclSyntax {
        SwiftGeneratedSyntax.parse("runtime generatedSecurityRequest") {
            try StructDeclSyntax("public struct GeneratedSecurityRequest: Sendable") {
                try VariableDeclSyntax("public var operationID: String")
                try VariableDeclSyntax("public var method: String")
                try VariableDeclSyntax("public var path: String")
                try VariableDeclSyntax("public var headers: [String: String]")
                try VariableDeclSyntax("public var cookies: [String: String]")
                try InitializerDeclSyntax(
                    """
                    public init(request: Request, operationID: String) {
                        self.operationID = operationID
                        method = request.method.rawValue
                        path = request.url.path
                        var headerValues: [String: String] = [:]
                        for header in request.headers {
                            headerValues[header.name] = header.value
                            headerValues[header.name.lowercased()] = header.value
                        }
                        headers = headerValues
                        cookies = Self.cookieValues(from: request.headers.first(name: .cookie))
                    }
                    """,
                )
                try FunctionDeclSyntax(
                    """
                    private static func cookieValues(from header: String?) -> [String: String] {
                        guard let header else {
                            return [:]
                        }
                        var values: [String: String] = [:]
                        for part in header.split(separator: ";") {
                            let pair = part.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false).map {
                                String($0).trimmingCharacters(in: .whitespacesAndNewlines)
                            }
                            if pair.count == 2 {
                                values[pair[0]] = pair[1]
                            }
                        }
                        return values
                    }
                    """,
                )
            }
        }
    }

    private var generatedBodyReader: EnumDeclSyntax {
        SwiftGeneratedSyntax.parse("runtime generatedBodyReader") {
            try EnumDeclSyntax("public enum GeneratedBodyReader") {
                try FunctionDeclSyntax(
                    """
                    public static func data(from request: Request, expectedContentType: String? = nil) throws -> Data {
                        try validateContentType(request.headers.first(name: .contentType), expectedContentType: expectedContentType)
                        guard var buffer = request.body.data else {
                            throw Abort(.badRequest, reason: "Missing request body")
                        }
                        return buffer.readData(length: buffer.readableBytes) ?? Data()
                    }
                    """,
                )
                try FunctionDeclSyntax(
                    """
                    private static func validateContentType(_ value: String?, expectedContentType: String?) throws {
                        guard let expectedContentType else {
                            return
                        }
                        let actualContentType = value?
                            .split(separator: ";", maxSplits: 1)
                            .first
                            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
                        guard actualContentType?.caseInsensitiveCompare(expectedContentType) == .orderedSame else {
                            throw Abort(.unsupportedMediaType, reason: "Expected Content-Type: \\(expectedContentType)")
                        }
                    }
                    """,
                )
            }
        }
    }

    private var generatedMultipartPart: StructDeclSyntax {
        SwiftGeneratedSyntax.parse("runtime generatedMultipartPart") {
            try StructDeclSyntax("public struct GeneratedMultipartPart: Sendable") {
                try VariableDeclSyntax("public var filename: String?")
                try VariableDeclSyntax("public var contentType: String?")
                try VariableDeclSyntax("public var data: Data")
                try InitializerDeclSyntax(
                    """
                    public init(filename: String?, contentType: String?, data: Data) {
                        self.filename = filename
                        self.contentType = contentType
                        self.data = data
                    }
                    """,
                )
                try InitializerDeclSyntax(
                    """
                    public init(file: File) {
                        var buffer = file.data
                        self.init(
                            filename: file.filename,
                            contentType: file.contentType?.serialize(),
                            data: buffer.readData(length: buffer.readableBytes) ?? Data()
                        )
                    }
                    """,
                )
            }
        }
    }

    private var generatedRequestValueParser: EnumDeclSyntax {
        SwiftGeneratedSyntax.parse("runtime generatedRequestValueParser") {
            try EnumDeclSyntax("public enum GeneratedRequestValueParser") {
                try FunctionDeclSyntax(
                    """
                    public static func required<T: LosslessStringConvertible>(_ value: String?, name: String, as _: T.Type) throws -> T {
                        guard let value, let parsed = T(value) else {
                            throw Abort(.badRequest, reason: "Missing or invalid parameter: \\(name)")
                        }
                        return parsed
                    }
                    """,
                )
                try FunctionDeclSyntax(
                    """
                    public static func optional<T: LosslessStringConvertible>(_ value: String?, name: String, as type: T.Type) throws -> T? {
                        guard let value, !value.isEmpty else {
                            return nil
                        }
                        guard let parsed = T(value) else {
                            throw Abort(.badRequest, reason: "Invalid parameter: \\(name)")
                        }
                        return parsed
                    }
                    """,
                )
                try FunctionDeclSyntax(
                    """
                    public static func requiredString(_ value: String?, name: String) throws -> String {
                        guard let value else {
                            throw Abort(.badRequest, reason: "Missing parameter: \\(name)")
                        }
                        return value
                    }
                    """,
                )
                try FunctionDeclSyntax(
                    """
                    public static func optionalString(_ value: String?) -> String? {
                        value
                    }
                    """,
                )
                try FunctionDeclSyntax(
                    """
                    public static func requiredArray<T: LosslessStringConvertible>(_ value: String?, name: String, as type: T.Type) throws -> [T] {
                        try split(value, name: name).map { raw in
                            guard let parsed = T(raw) else {
                                throw Abort(.badRequest, reason: "Invalid parameter: \\(name)")
                            }
                            return parsed
                        }
                    }
                    """,
                )
                try FunctionDeclSyntax(
                    """
                    public static func optionalArray<T: LosslessStringConvertible>(_ value: String?, name: String, as type: T.Type) throws -> [T]? {
                        guard let value, !value.isEmpty else {
                            return nil
                        }
                        return try requiredArray(value, name: name, as: type)
                    }
                    """,
                )
                try FunctionDeclSyntax(
                    """
                    public static func requiredStringArray(_ value: String?, name: String) throws -> [String] {
                        try split(value, name: name)
                    }
                    """,
                )
                try FunctionDeclSyntax(
                    """
                    public static func optionalStringArray(_ value: String?) -> [String]? {
                        guard let value, !value.isEmpty else {
                            return nil
                        }
                        return value.split(separator: ",").map(String.init)
                    }
                    """,
                )
                try FunctionDeclSyntax(
                    """
                    public static func requiredDate(_ value: String?, name: String) throws -> Date {
                        guard let value, let parsed = parseDateTime(value) else {
                            throw Abort(.badRequest, reason: "Missing or invalid date parameter: \\(name)")
                        }
                        return parsed
                    }
                    """,
                )
                try FunctionDeclSyntax(
                    """
                    public static func optionalDate(_ value: String?, name: String) throws -> Date? {
                        guard let value, !value.isEmpty else {
                            return nil
                        }
                        guard let parsed = parseDateTime(value) else {
                            throw Abort(.badRequest, reason: "Invalid date parameter: \\(name)")
                        }
                        return parsed
                    }
                    """,
                )
                try FunctionDeclSyntax(
                    """
                    public static func requiredDateOnly(_ value: String?, name: String) throws -> Date {
                        guard let value, let parsed = dateFormatters.dateOnly(from: value) else {
                            throw Abort(.badRequest, reason: "Missing or invalid date parameter: \\(name)")
                        }
                        return parsed
                    }
                    """,
                )
                try FunctionDeclSyntax(
                    """
                    public static func optionalDateOnly(_ value: String?, name: String) throws -> Date? {
                        guard let value, !value.isEmpty else {
                            return nil
                        }
                        guard let parsed = dateFormatters.dateOnly(from: value) else {
                            throw Abort(.badRequest, reason: "Invalid date parameter: \\(name)")
                        }
                        return parsed
                    }
                    """,
                )
                try FunctionDeclSyntax(
                    """
                    public static func requiredTime(_ value: String?, name: String) throws -> Time {
                        guard let value, isValidTime(value) else {
                            throw Abort(.badRequest, reason: "Missing or invalid time parameter: \\(name)")
                        }
                        return Time(value)
                    }
                    """,
                )
                try FunctionDeclSyntax(
                    """
                    public static func optionalTime(_ value: String?, name: String) throws -> Time? {
                        guard let value, !value.isEmpty else {
                            return nil
                        }
                        guard isValidTime(value) else {
                            throw Abort(.badRequest, reason: "Invalid time parameter: \\(name)")
                        }
                        return Time(value)
                    }
                    """,
                )
                try FunctionDeclSyntax(
                    """
                    public static func requiredStringRawEnum<T: RawRepresentable>(_ value: String?, name: String, as _: T.Type) throws -> T where T.RawValue == String {
                        guard let value, let parsed = T(rawValue: value) else {
                            throw Abort(.badRequest, reason: "Missing or invalid enum parameter: \\(name)")
                        }
                        return parsed
                    }
                    """,
                )
                try FunctionDeclSyntax(
                    """
                    public static func optionalStringRawEnum<T: RawRepresentable>(_ value: String?, name: String, as type: T.Type) throws -> T? where T.RawValue == String {
                        guard let value, !value.isEmpty else {
                            return nil
                        }
                        return try requiredStringRawEnum(value, name: name, as: type)
                    }
                    """,
                )
                try FunctionDeclSyntax(
                    """
                    public static func requiredStringRawEnumArray<T: RawRepresentable>(_ value: String?, name: String, as type: T.Type) throws -> [T] where T.RawValue == String {
                        try requiredStringArray(value, name: name).map { raw in
                            guard let parsed = T(rawValue: raw) else {
                                throw Abort(.badRequest, reason: "Invalid enum parameter: \\(name)")
                            }
                            return parsed
                        }
                    }
                    """,
                )
                try FunctionDeclSyntax(
                    """
                    public static func optionalStringRawEnumArray<T: RawRepresentable>(_ value: String?, name: String, as type: T.Type) throws -> [T]? where T.RawValue == String {
                        guard let value, !value.isEmpty else {
                            return nil
                        }
                        return try requiredStringRawEnumArray(value, name: name, as: type)
                    }
                    """,
                )
                try FunctionDeclSyntax(
                    """
                    public static func requiredIntRawEnum<T: RawRepresentable>(_ value: String?, name: String, as _: T.Type) throws -> T where T.RawValue == Int {
                        guard let value, let intValue = Int(value), let parsed = T(rawValue: intValue) else {
                            throw Abort(.badRequest, reason: "Missing or invalid enum parameter: \\(name)")
                        }
                        return parsed
                    }
                    """,
                )
                try FunctionDeclSyntax(
                    """
                    public static func optionalIntRawEnum<T: RawRepresentable>(_ value: String?, name: String, as type: T.Type) throws -> T? where T.RawValue == Int {
                        guard let value, !value.isEmpty else {
                            return nil
                        }
                        return try requiredIntRawEnum(value, name: name, as: type)
                    }
                    """,
                )
                try FunctionDeclSyntax(
                    """
                    public static func requiredIntRawEnumArray<T: RawRepresentable>(_ value: String?, name: String, as type: T.Type) throws -> [T] where T.RawValue == Int {
                        try requiredStringArray(value, name: name).map { raw in
                            guard let rawValue = Int(raw), let parsed = T(rawValue: rawValue) else {
                                throw Abort(.badRequest, reason: "Invalid enum parameter: \\(name)")
                            }
                            return parsed
                        }
                    }
                    """,
                )
                try FunctionDeclSyntax(
                    """
                    public static func optionalIntRawEnumArray<T: RawRepresentable>(_ value: String?, name: String, as type: T.Type) throws -> [T]? where T.RawValue == Int {
                        guard let value, !value.isEmpty else {
                            return nil
                        }
                        return try requiredIntRawEnumArray(value, name: name, as: type)
                    }
                    """,
                )
                try FunctionDeclSyntax(
                    """
                    private static func split(_ value: String?, name: String) throws -> [String] {
                        guard let value else {
                            throw Abort(.badRequest, reason: "Missing parameter: \\(name)")
                        }
                        if value.isEmpty {
                            return []
                        }
                        return value.split(separator: ",").map(String.init)
                    }
                    """,
                )
                try FunctionDeclSyntax(
                    """
                    private static func isValidTime(_ value: String) -> Bool {
                        let parts = value.split(separator: ":", omittingEmptySubsequences: false)
                        guard parts.count == 3,
                              parts.allSatisfy({ $0.count == 2 }),
                              let hour = Int(parts[0]),
                              let minute = Int(parts[1]),
                              let second = Int(parts[2]) else {
                            return false
                        }
                        return (0 ... 23).contains(hour)
                            && (0 ... 59).contains(minute)
                            && (0 ... 59).contains(second)
                    }
                    """,
                )
                try VariableDeclSyntax("private static let dateFormatters = DateFormatters()")
                try FunctionDeclSyntax(
                    """
                    private static func parseDateTime(_ value: String) -> Date? {
                        dateFormatters.dateTime(from: value)
                    }
                    """,
                )
                try ClassDeclSyntax(
                    """
                    // Formatter instances never escape this lock-protected cache.
                    private final class DateFormatters: @unchecked Sendable
                    """,
                ) {
                    try VariableDeclSyntax("private let lock = NSLock()")
                    try VariableDeclSyntax("private let dateTimeFormatter = ISO8601DateFormatter()")
                    try VariableDeclSyntax(
                        """
                        private let fractionalDateTimeFormatter: ISO8601DateFormatter = {
                            let formatter = ISO8601DateFormatter()
                            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                            return formatter
                        }()
                        """,
                    )
                    try VariableDeclSyntax(
                        """
                        private let dateOnlyFormatter: DateFormatter = {
                            let formatter = DateFormatter()
                            formatter.calendar = Calendar(identifier: .iso8601)
                            formatter.locale = Locale(identifier: "en_US_POSIX")
                            formatter.timeZone = TimeZone(secondsFromGMT: 0)
                            formatter.dateFormat = "yyyy-MM-dd"
                            formatter.isLenient = false
                            return formatter
                        }()
                        """,
                    )
                    try FunctionDeclSyntax(
                        """
                        func dateTime(from value: String) -> Date? {
                            lock.lock()
                            defer { lock.unlock() }
                            return dateTimeFormatter.date(from: value) ?? fractionalDateTimeFormatter.date(from: value)
                        }
                        """,
                    )
                    try FunctionDeclSyntax(
                        """
                        func dateOnly(from value: String) -> Date? {
                            lock.lock()
                            defer { lock.unlock() }
                            return dateOnlyFormatter.date(from: value)
                        }
                        """,
                    )
                }
            }
        }
    }

    private var timelessDate: StructDeclSyntax {
        SwiftGeneratedSyntax.parse("runtime timelessDate") {
            try StructDeclSyntax("public struct TimelessDate: Codable, Sendable, Equatable, Hashable, LosslessStringConvertible") {
                try VariableDeclSyntax("public var description: String")
                try InitializerDeclSyntax(
                    """
                    public init(_ description: String) {
                        self.description = description
                    }
                    """,
                )
                try InitializerDeclSyntax(
                    """
                    public init(from decoder: Decoder) throws {
                        let container = try decoder.singleValueContainer()
                        description = try container.decode(String.self)
                    }
                    """,
                )
                try FunctionDeclSyntax(
                    """
                    public func encode(to encoder: Encoder) throws {
                        var container = encoder.singleValueContainer()
                        try container.encode(description)
                    }
                    """,
                )
            }
        }
    }

    private var time: StructDeclSyntax {
        SwiftGeneratedSyntax.parse("runtime time") {
            try StructDeclSyntax("public struct Time: Codable, Sendable, Equatable, Hashable, LosslessStringConvertible") {
                try VariableDeclSyntax("public var description: String")
                try InitializerDeclSyntax(
                    """
                    public init(_ description: String) {
                        self.description = description
                    }
                    """,
                )
                try InitializerDeclSyntax(
                    """
                    public init(from decoder: Decoder) throws {
                        let container = try decoder.singleValueContainer()
                        description = try container.decode(String.self)
                    }
                    """,
                )
                try FunctionDeclSyntax(
                    """
                    public func encode(to encoder: Encoder) throws {
                        var container = encoder.singleValueContainer()
                        try container.encode(description)
                    }
                    """,
                )
            }
        }
    }

    private var localizedData: StructDeclSyntax {
        SwiftGeneratedSyntax.parse("runtime localizedData") {
            try StructDeclSyntax("public struct LocalizedData<Value: Codable>: Codable") {
                try VariableDeclSyntax("public var values: [String: Value]")
                try InitializerDeclSyntax(
                    """
                    public init(values: [String: Value]) {
                        self.values = values
                    }
                    """,
                )
            }
        }
    }

    private var localizedDataConformance: ExtensionDeclSyntax {
        SwiftGeneratedSyntax.parse("runtime localizedDataConformance") {
            try ExtensionDeclSyntax("extension LocalizedData: Sendable where Value: Sendable") {}
        }
    }

    private var patchableValue: EnumDeclSyntax {
        SwiftGeneratedSyntax.parse("runtime patchableValue") {
            try EnumDeclSyntax("public enum PatchableValue<Value: Codable>: Codable") {
                try EnumCaseDeclSyntax("case unmodified")
                try EnumCaseDeclSyntax("case null")
                try EnumCaseDeclSyntax("case value(Value)")
                try VariableDeclSyntax(
                    """
                    public var isUnmodified: Bool {
                        if case .unmodified = self {
                            return true
                        }
                        return false
                    }
                    """,
                )
                try InitializerDeclSyntax(
                    """
                    public init(from decoder: Decoder) throws {
                        let container = try decoder.singleValueContainer()
                        if container.decodeNil() {
                            self = .null
                        } else {
                            self = .value(try container.decode(Value.self))
                        }
                    }
                    """,
                )
                try FunctionDeclSyntax(
                    """
                    public func encode(to encoder: Encoder) throws {
                        var container = encoder.singleValueContainer()
                        switch self {
                            case .unmodified:
                                try container.encodeNil()
                            case .null:
                                try container.encodeNil()
                            case let .value(value):
                                try container.encode(value)
                        }
                    }
                    """,
                )
            }
        }
    }

    private var patchableValueConformance: ExtensionDeclSyntax {
        SwiftGeneratedSyntax.parse("runtime patchableValueConformance") {
            try ExtensionDeclSyntax("extension PatchableValue: Sendable where Value: Sendable") {}
        }
    }

    private var keyedDecodingContainer: ExtensionDeclSyntax {
        SwiftGeneratedSyntax.parse("runtime keyedDecodingContainer") {
            try ExtensionDeclSyntax("public extension KeyedDecodingContainer") {
                try FunctionDeclSyntax(
                    """
                    func decodePatchable<Value: Codable>(
                        _: PatchableValue<Value>.Type,
                        forKey key: Key
                    ) throws -> PatchableValue<Value> {
                        guard contains(key) else {
                            return .unmodified
                        }
                        if try decodeNil(forKey: key) {
                            return .null
                        }
                        return .value(try decode(Value.self, forKey: key))
                    }
                    """,
                )
            }
        }
    }

    private var keyedEncodingContainer: ExtensionDeclSyntax {
        SwiftGeneratedSyntax.parse("runtime keyedEncodingContainer") {
            try ExtensionDeclSyntax("public extension KeyedEncodingContainer") {
                try FunctionDeclSyntax(
                    """
                    mutating func encodePatchable<Value: Codable>(
                        _ value: PatchableValue<Value>,
                        forKey key: Key
                    ) throws {
                        switch value {
                            case .unmodified:
                                break
                            case .null:
                                try encodeNil(forKey: key)
                            case let .value(value):
                                try encode(value, forKey: key)
                        }
                    }
                    """,
                )
            }
        }
    }

    private var pagedResults: StructDeclSyntax {
        SwiftGeneratedSyntax.parse("runtime pagedResults") {
            try StructDeclSyntax("public struct PagedResults<Value: Codable>: Codable") {
                try VariableDeclSyntax("public var results: [Value]")
                try VariableDeclSyntax("public var next: URL?")
                try VariableDeclSyntax("public var count: Int?")
                try VariableDeclSyntax(
                    """
                    public var hasNext: Bool {
                        next != nil && !results.isEmpty
                    }
                    """,
                )
                try InitializerDeclSyntax(
                    """
                    public init(results: [Value], next: URL? = nil, count: Int? = nil) {
                        self.results = results
                        self.next = next
                        self.count = count
                    }
                    """,
                )
            }
        }
    }

    private var pagedResultsConformance: ExtensionDeclSyntax {
        SwiftGeneratedSyntax.parse("runtime pagedResultsConformance") {
            try ExtensionDeclSyntax("extension PagedResults: Sendable where Value: Sendable") {}
        }
    }

    private var generatedJSONValue: EnumDeclSyntax {
        SwiftGeneratedSyntax.parse("runtime generatedJSONValue") {
            try EnumDeclSyntax("public enum GeneratedJSONValue: Codable, Sendable, Equatable") {
                try EnumCaseDeclSyntax("case null")
                try EnumCaseDeclSyntax("case bool(Bool)")
                try EnumCaseDeclSyntax("case number(Double)")
                try EnumCaseDeclSyntax("case string(String)")
                try EnumCaseDeclSyntax("case array([GeneratedJSONValue])")
                try EnumCaseDeclSyntax("case object([String: GeneratedJSONValue])")
                try InitializerDeclSyntax(
                    """
                    public init(from decoder: Decoder) throws {
                        let container = try decoder.singleValueContainer()
                        if container.decodeNil() {
                            self = .null
                        } else if let value = try? container.decode(Bool.self) {
                            self = .bool(value)
                        } else if let value = try? container.decode(Double.self) {
                            self = .number(value)
                        } else if let value = try? container.decode(String.self) {
                            self = .string(value)
                        } else if let value = try? container.decode([GeneratedJSONValue].self) {
                            self = .array(value)
                        } else {
                            self = .object(try container.decode([String: GeneratedJSONValue].self))
                        }
                    }
                    """,
                )
                try FunctionDeclSyntax(
                    """
                    public func encode(to encoder: Encoder) throws {
                        var container = encoder.singleValueContainer()
                        switch self {
                            case .null:
                                try container.encodeNil()
                            case let .bool(value):
                                try container.encode(value)
                            case let .number(value):
                                try container.encode(value)
                            case let .string(value):
                                try container.encode(value)
                            case let .array(value):
                                try container.encode(value)
                            case let .object(value):
                                try container.encode(value)
                        }
                    }
                    """,
                )
            }
        }
    }
}
