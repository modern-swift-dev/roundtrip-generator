// Generated code. Do not edit.
import Foundation
import Vapor

public enum ShowcaseSampleModelsNotificationEnvelope: Codable, Sendable, Identifiable, Equatable, Hashable {
    case garbage
    case email(ShowcaseSampleVisibility, Date?, ShowcaseSampleModelsEmailNotification)
    case push(ShowcaseSampleVisibility, Date?, ShowcaseSampleModelsPushNotification)

    public init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let contentType = try container.decode(ObjectType.self, forKey: .contentType)
            switch contentType {
                case .garbage:
                    self = .garbage
                case .email:
                    do {
                        let visibility = try container.decode(ShowcaseSampleVisibility.self, forKey: .visibility)
                        let sentAt = try container.decodeIfPresent(Date.self, forKey: .sentAt)
                        self = try .email(visibility, sentAt, Self.decodeCustomType(container))
                    } catch {
                        self = .garbage
                    }
                case .push:
                    do {
                        let visibility = try container.decode(ShowcaseSampleVisibility.self, forKey: .visibility)
                        let sentAt = try container.decodeIfPresent(Date.self, forKey: .sentAt)
                        self = try .push(visibility, sentAt, Self.decodeCustomType(container))
                    } catch {
                        self = .garbage
                    }
            }
        } catch {
            self = .garbage
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(objectType, forKey: .contentType)
        switch self {
            case .garbage:
                break
            case let .email(visibility, sentAt, value):
                try container.encode(visibility, forKey: .visibility)
                try container.encodeIfPresent(sentAt, forKey: .sentAt)
                try container.encode(value, forKey: .extras)
            case let .push(visibility, sentAt, value):
                try container.encode(visibility, forKey: .visibility)
                try container.encodeIfPresent(sentAt, forKey: .sentAt)
                try container.encode(value, forKey: .extras)
        }
    }

    private static func decodeCustomType<T: Decodable>(_ container: KeyedDecodingContainer<CodingKeys>) throws -> T {
        if let value = try container.decodeIfPresent(T.self, forKey: .extras) {
            return value
        }

        if let value = try container.decodeIfPresent(T.self, forKey: .extra) {
            return value
        }

        throw DecodingError.dataCorrupted(
            DecodingError.Context(codingPath: container.codingPath, debugDescription: "Missing object data"),
        )
    }

    public enum CodingKeys: String, CodingKey {
        case contentType = "channel"
        case extras = "payload"
        case extra = "data"
        case visibility
        case sentAt = "sent_at"
    }

    public enum ObjectType: String, Codable, Sendable, CaseIterable, Identifiable {
        case garbage = "__garbage__"
        case email
        case push

        public var id: String {
            rawValue
        }

        public init(from decoder: Decoder) throws {
            do {
                let container = try decoder.singleValueContainer()
                let value = try container.decode(String.self)
                self = Self(rawValue: value) ?? .garbage
            } catch {
                self = .garbage
            }
        }
    }

    public var objectType: ObjectType {
        switch self {
            case .garbage:
                .garbage
            case .email:
                .email
            case .push:
                .push
        }
    }

    public var id: String {
        switch self {
            case .garbage:
                ObjectType.garbage.rawValue
            case let .email(_, _, value):
                "\(ObjectType.email.rawValue)_\(value.id)"
            case let .push(_, _, value):
                "\(ObjectType.push.rawValue)_\(value.id)"
        }
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
            case (.garbage, .garbage):
                true
            case let (.email(lhsExtra0, lhsExtra1, lhsPayload), .email(rhsExtra0, rhsExtra1, rhsPayload)):
                lhsExtra0 == rhsExtra0 && lhsExtra1 == rhsExtra1 && lhsPayload == rhsPayload
            case let (.push(lhsExtra0, lhsExtra1, lhsPayload), .push(rhsExtra0, rhsExtra1, rhsPayload)):
                lhsExtra0 == rhsExtra0 && lhsExtra1 == rhsExtra1 && lhsPayload == rhsPayload
            default:
                false
        }
    }

    public func hash(into hasher: inout Hasher) {
        switch self {
            case .garbage:
                hasher.combine(ObjectType.garbage)
            case let .email(valueExtra0, valueExtra1, valuePayload):
                hasher.combine(ObjectType.email)
                hasher.combine(valueExtra0)
                hasher.combine(valueExtra1)
                hasher.combine(valuePayload)
            case let .push(valueExtra0, valueExtra1, valuePayload):
                hasher.combine(ObjectType.push)
                hasher.combine(valueExtra0)
                hasher.combine(valueExtra1)
                hasher.combine(valuePayload)
        }
    }
}
