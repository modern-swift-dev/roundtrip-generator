// Generated code. Do not edit.
import Foundation
import Vapor

public struct AdminUserPatchedUser: Codable, Sendable {
    public var firstName: PatchableValue<String>
    public var lastName: PatchableValue<String>
    public var username: PatchableValue<String>
    public var email: PatchableValue<String>
    public var phone: PatchableValue<String>
    public var hireDate: PatchableValue<Date>
    public var birthDate: PatchableValue<Date>
    public var picture: PatchableValue<URL>

    public init(
        firstName: PatchableValue<String> = .unmodified,
        lastName: PatchableValue<String> = .unmodified,
        username: PatchableValue<String> = .unmodified,
        email: PatchableValue<String> = .unmodified,
        phone: PatchableValue<String> = .unmodified,
        hireDate: PatchableValue<Date> = .unmodified,
        birthDate: PatchableValue<Date> = .unmodified,
        picture: PatchableValue<URL> = .unmodified,
    ) {
        self.firstName = firstName
        self.lastName = lastName
        self.username = username
        self.email = email
        self.phone = phone
        self.hireDate = hireDate
        self.birthDate = birthDate
        self.picture = picture
    }

    public enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
        case username
        case email
        case phone
        case hireDate = "hire_date"
        case birthDate = "birth_date"
        case picture
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        firstName = try container.decodePatchable(PatchableValue<String>.self, forKey: .firstName)
        lastName = try container.decodePatchable(PatchableValue<String>.self, forKey: .lastName)
        username = try container.decodePatchable(PatchableValue<String>.self, forKey: .username)
        email = try container.decodePatchable(PatchableValue<String>.self, forKey: .email)
        phone = try container.decodePatchable(PatchableValue<String>.self, forKey: .phone)
        hireDate = try container.decodePatchable(PatchableValue<Date>.self, forKey: .hireDate)
        birthDate = try container.decodePatchable(PatchableValue<Date>.self, forKey: .birthDate)
        picture = try container.decodePatchable(PatchableValue<URL>.self, forKey: .picture)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodePatchable(firstName, forKey: .firstName)
        try container.encodePatchable(lastName, forKey: .lastName)
        try container.encodePatchable(username, forKey: .username)
        try container.encodePatchable(email, forKey: .email)
        try container.encodePatchable(phone, forKey: .phone)
        try container.encodePatchable(hireDate, forKey: .hireDate)
        try container.encodePatchable(birthDate, forKey: .birthDate)
        try container.encodePatchable(picture, forKey: .picture)
    }
}
