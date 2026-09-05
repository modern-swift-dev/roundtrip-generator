import Combine
import Foundation
import os
import RoundTrip
import RoundTripREST

public extension ShowcaseSampleModelsApi {
    enum NotificationEnvelope: Codable, Sendable, Identifiable {
        case garbage
        case email(ShowcaseApi.SampleVisibility, Date?, EmailNotification)
        case push(ShowcaseApi.SampleVisibility, Date?, PushNotification)
        public init(from decoder: Decoder) throws {
            do {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                let contentType = try container.decode(ObjectType.self, forKey: .contentType)
                let visibility = try container.decode(ShowcaseApi.SampleVisibility.self, forKey: .visibility)
                let sentAt = try container.decodeIfPresent(Date.self, forKey: .sentAt)
                switch contentType {
                    case .garbage:
                        self = .garbage
                    case .email:
                        do {
                            self = try .email(visibility, sentAt, NotificationEnvelope.decodeCustomType(container))
                        } catch {
                            self = .garbage
                        }
                    case .push:
                        do {
                            self = try .push(visibility, sentAt, NotificationEnvelope.decodeCustomType(container))
                        } catch {
                            self = .garbage
                        }
                }
            } catch {
                self = .garbage
            }
        }

        /// Encoder to JSON
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

        /// Utility method that allows to decode from `extras`
        private static func decodeCustomType<T: Decodable>(_ container: KeyedDecodingContainer<CodingKeys>) throws -> T {
            if let value = try container.decodeIfPresent(T.self, forKey: .extras) {
                return value
            }

            if let value = try container.decodeIfPresent(T.self, forKey: .extra) {
                return value
            }

            throw CocoaError(.coderInvalidValue)
        }

        /// The coding keys
        public enum CodingKeys: String, CodingKey {
            case contentType = "channel"
            case extras = "payload"
            case extra = "data"
            case visibility
            case sentAt = "sent_at"
        }

        /// The list of supported object types
        public enum ObjectType: String, Codable, CaseIterable, Sendable, Identifiable {
            case garbage = "__garbage__"
            case email
            case push
            public var id: String {
                rawValue
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
    }
}
