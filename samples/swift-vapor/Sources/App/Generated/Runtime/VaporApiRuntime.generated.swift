// Generated code. Do not edit.
import Foundation
import Vapor

public struct GeneratedResponse<Value> {
    public var status: HTTPResponseStatus
    public var headers: HTTPHeaders
    public var value: Value?

    public init(status: HTTPResponseStatus = .ok, headers: HTTPHeaders = HTTPHeaders(), value: Value) {
        self.status = status
        self.headers = headers
        self.value = value
    }

    public init(status: HTTPResponseStatus, headers: HTTPHeaders = HTTPHeaders()) {
        self.status = status
        self.headers = headers
        value = nil
    }
}

extension GeneratedResponse: Sendable where Value: Sendable {}

public enum GeneratedResponseEncoder {
    public static func empty(_ response: GeneratedResponse<Void>, validStatusCodes: [Int]) throws -> Response {
        try validateStatus(response.status, validStatusCodes: validStatusCodes)
        return Response(status: response.status, headers: response.headers)
    }

    public static func json(_ response: GeneratedResponse<some Encodable>, validStatusCodes: [Int]) throws -> Response {
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

    private static func validateStatus(_ status: HTTPResponseStatus, validStatusCodes: [Int]) throws {
        guard validStatusCodes.contains(Int(status.code)) else {
            throw Abort(.internalServerError, reason: "Unexpected response status: \(status.code)")
        }
    }

    private static func isBodyAllowed(for status: HTTPResponseStatus) -> Bool {
        !(100 ..< 200 ~= Int(status.code) || [204, 205, 304].contains(Int(status.code)))
    }
}

public protocol GeneratedSecurityMiddleware: Sendable {
    func requireAuthorization(_ request: GeneratedSecurityRequest) async throws
    func authorizeOptional(_ request: GeneratedSecurityRequest) async throws
}

public struct AllowAllGeneratedSecurityMiddleware: GeneratedSecurityMiddleware {
    public init() {}

    public func requireAuthorization(_: GeneratedSecurityRequest) async throws {}

    public func authorizeOptional(_: GeneratedSecurityRequest) async throws {}
}

public struct GeneratedSecurityRequest: Sendable {
    public var operationID: String
    public var method: String
    public var path: String
    public var headers: [String: String]
    public var cookies: [String: String]

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
}

public enum GeneratedBodyReader {
    public static func data(from request: Request, expectedContentType: String? = nil) throws -> Data {
        try validateContentType(request.headers.first(name: .contentType), expectedContentType: expectedContentType)
        guard var buffer = request.body.data else {
            throw Abort(.badRequest, reason: "Missing request body")
        }
        return buffer.readData(length: buffer.readableBytes) ?? Data()
    }

    private static func validateContentType(_ value: String?, expectedContentType: String?) throws {
        guard let expectedContentType else {
            return
        }
        let actualContentType = value?
            .split(separator: ";", maxSplits: 1)
            .first
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
        guard actualContentType?.caseInsensitiveCompare(expectedContentType) == .orderedSame else {
            throw Abort(.unsupportedMediaType, reason: "Expected Content-Type: \(expectedContentType)")
        }
    }
}

public struct GeneratedMultipartPart: Sendable {
    public var filename: String?
    public var contentType: String?
    public var data: Data

    public init(filename: String?, contentType: String?, data: Data) {
        self.filename = filename
        self.contentType = contentType
        self.data = data
    }

    public init(file: File) {
        var buffer = file.data
        self.init(
            filename: file.filename,
            contentType: file.contentType?.serialize(),
            data: buffer.readData(length: buffer.readableBytes) ?? Data()
        )
    }
}

public enum GeneratedRequestValueParser {
    public static func required<T: LosslessStringConvertible>(_ value: String?, name: String, as _: T.Type) throws -> T {
        guard let value, let parsed = T(value) else {
            throw Abort(.badRequest, reason: "Missing or invalid parameter: \(name)")
        }
        return parsed
    }

    public static func optional<T: LosslessStringConvertible>(_ value: String?, name: String, as type: T.Type) throws -> T? {
        guard let value, !value.isEmpty else {
            return nil
        }
        guard let parsed = T(value) else {
            throw Abort(.badRequest, reason: "Invalid parameter: \(name)")
        }
        return parsed
    }

    public static func requiredString(_ value: String?, name: String) throws -> String {
        guard let value else {
            throw Abort(.badRequest, reason: "Missing parameter: \(name)")
        }
        return value
    }

    public static func optionalString(_ value: String?) -> String? {
        value
    }

    public static func requiredArray<T: LosslessStringConvertible>(_ value: String?, name: String, as type: T.Type) throws -> [T] {
        try split(value, name: name).map { raw in
            guard let parsed = T(raw) else {
                throw Abort(.badRequest, reason: "Invalid parameter: \(name)")
            }
            return parsed
        }
    }

    public static func optionalArray<T: LosslessStringConvertible>(_ value: String?, name: String, as type: T.Type) throws -> [T]? {
        guard let value, !value.isEmpty else {
            return nil
        }
        return try requiredArray(value, name: name, as: type)
    }

    public static func requiredStringArray(_ value: String?, name: String) throws -> [String] {
        try split(value, name: name)
    }

    public static func optionalStringArray(_ value: String?) -> [String]? {
        guard let value, !value.isEmpty else {
            return nil
        }
        return value.split(separator: ",").map(String.init)
    }

    public static func requiredDate(_ value: String?, name: String) throws -> Date {
        guard let value, let parsed = parseDateTime(value) else {
            throw Abort(.badRequest, reason: "Missing or invalid date parameter: \(name)")
        }
        return parsed
    }

    public static func optionalDate(_ value: String?, name: String) throws -> Date? {
        guard let value, !value.isEmpty else {
            return nil
        }
        guard let parsed = parseDateTime(value) else {
            throw Abort(.badRequest, reason: "Invalid date parameter: \(name)")
        }
        return parsed
    }

    public static func requiredDateOnly(_ value: String?, name: String) throws -> Date {
        guard let value, let parsed = dateFormatters.dateOnly(from: value) else {
            throw Abort(.badRequest, reason: "Missing or invalid date parameter: \(name)")
        }
        return parsed
    }

    public static func optionalDateOnly(_ value: String?, name: String) throws -> Date? {
        guard let value, !value.isEmpty else {
            return nil
        }
        guard let parsed = dateFormatters.dateOnly(from: value) else {
            throw Abort(.badRequest, reason: "Invalid date parameter: \(name)")
        }
        return parsed
    }

    public static func requiredTime(_ value: String?, name: String) throws -> Time {
        guard let value, isValidTime(value) else {
            throw Abort(.badRequest, reason: "Missing or invalid time parameter: \(name)")
        }
        return Time(value)
    }

    public static func optionalTime(_ value: String?, name: String) throws -> Time? {
        guard let value, !value.isEmpty else {
            return nil
        }
        guard isValidTime(value) else {
            throw Abort(.badRequest, reason: "Invalid time parameter: \(name)")
        }
        return Time(value)
    }

    public static func requiredStringRawEnum<T: RawRepresentable>(_ value: String?, name: String, as _: T.Type) throws -> T where T.RawValue == String {
        guard let value, let parsed = T(rawValue: value) else {
            throw Abort(.badRequest, reason: "Missing or invalid enum parameter: \(name)")
        }
        return parsed
    }

    public static func optionalStringRawEnum<T: RawRepresentable>(_ value: String?, name: String, as type: T.Type) throws -> T? where T.RawValue == String {
        guard let value, !value.isEmpty else {
            return nil
        }
        return try requiredStringRawEnum(value, name: name, as: type)
    }

    public static func requiredStringRawEnumArray<T: RawRepresentable>(_ value: String?, name: String, as type: T.Type) throws -> [T] where T.RawValue == String {
        try requiredStringArray(value, name: name).map { raw in
            guard let parsed = T(rawValue: raw) else {
                throw Abort(.badRequest, reason: "Invalid enum parameter: \(name)")
            }
            return parsed
        }
    }

    public static func optionalStringRawEnumArray<T: RawRepresentable>(_ value: String?, name: String, as type: T.Type) throws -> [T]? where T.RawValue == String {
        guard let value, !value.isEmpty else {
            return nil
        }
        return try requiredStringRawEnumArray(value, name: name, as: type)
    }

    public static func requiredIntRawEnum<T: RawRepresentable>(_ value: String?, name: String, as _: T.Type) throws -> T where T.RawValue == Int {
        guard let value, let intValue = Int(value), let parsed = T(rawValue: intValue) else {
            throw Abort(.badRequest, reason: "Missing or invalid enum parameter: \(name)")
        }
        return parsed
    }

    public static func optionalIntRawEnum<T: RawRepresentable>(_ value: String?, name: String, as type: T.Type) throws -> T? where T.RawValue == Int {
        guard let value, !value.isEmpty else {
            return nil
        }
        return try requiredIntRawEnum(value, name: name, as: type)
    }

    public static func requiredIntRawEnumArray<T: RawRepresentable>(_ value: String?, name: String, as type: T.Type) throws -> [T] where T.RawValue == Int {
        try requiredStringArray(value, name: name).map { raw in
            guard let rawValue = Int(raw), let parsed = T(rawValue: rawValue) else {
                throw Abort(.badRequest, reason: "Invalid enum parameter: \(name)")
            }
            return parsed
        }
    }

    public static func optionalIntRawEnumArray<T: RawRepresentable>(_ value: String?, name: String, as type: T.Type) throws -> [T]? where T.RawValue == Int {
        guard let value, !value.isEmpty else {
            return nil
        }
        return try requiredIntRawEnumArray(value, name: name, as: type)
    }

    private static func split(_ value: String?, name: String) throws -> [String] {
        guard let value else {
            throw Abort(.badRequest, reason: "Missing parameter: \(name)")
        }
        if value.isEmpty {
            return []
        }
        return value.split(separator: ",").map(String.init)
    }

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

    private static let dateFormatters = DateFormatters()

    private static func parseDateTime(_ value: String) -> Date? {
        dateFormatters.dateTime(from: value)
    }

    // Formatter instances never escape this lock-protected cache.
    private final class DateFormatters: @unchecked Sendable {
        private let lock = NSLock()
        private let dateTimeFormatter = ISO8601DateFormatter()
        private let fractionalDateTimeFormatter: ISO8601DateFormatter = {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            return formatter
        }()
        private let dateOnlyFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.calendar = Calendar(identifier: .iso8601)
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.isLenient = false
            return formatter
        }()

        func dateTime(from value: String) -> Date? {
            lock.lock()
            defer { lock.unlock() }
            return dateTimeFormatter.date(from: value) ?? fractionalDateTimeFormatter.date(from: value)
        }

        func dateOnly(from value: String) -> Date? {
            lock.lock()
            defer { lock.unlock() }
            return dateOnlyFormatter.date(from: value)
        }
    }
}

public struct TimelessDate: Codable, Sendable, Equatable, Hashable, LosslessStringConvertible {
    public var description: String

    public init(_ description: String) {
        self.description = description
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        description = try container.decode(String.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}

public struct Time: Codable, Sendable, Equatable, Hashable, LosslessStringConvertible {
    public var description: String

    public init(_ description: String) {
        self.description = description
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        description = try container.decode(String.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}

public struct LocalizedData<Value: Codable>: Codable {
    public var values: [String: Value]

    public init(values: [String: Value]) {
        self.values = values
    }
}

extension LocalizedData: Sendable where Value: Sendable {}

public enum PatchableValue<Value: Codable>: Codable {
    case unmodified
    case null
    case value(Value)

    public var isUnmodified: Bool {
        if case .unmodified = self {
            return true
        }
        return false
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else {
            self = .value(try container.decode(Value.self))
        }
    }

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
}

extension PatchableValue: Sendable where Value: Sendable {}

public extension KeyedDecodingContainer {
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
}

public extension KeyedEncodingContainer {
    mutating func encodePatchable(
        _ value: PatchableValue<some Codable>,
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
}

public struct PagedResults<Value: Codable>: Codable {
    public var results: [Value]
    public var next: URL?
    public var count: Int?

    public var hasNext: Bool {
        next != nil && !results.isEmpty
    }

    public init(results: [Value], next: URL? = nil, count: Int? = nil) {
        self.results = results
        self.next = next
        self.count = count
    }
}

extension PagedResults: Sendable where Value: Sendable {}

public enum GeneratedJSONValue: Codable, Sendable, Equatable {
    case null
    case bool(Bool)
    case number(Double)
    case string(String)
    case array([GeneratedJSONValue])
    case object([String: GeneratedJSONValue])

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
}
