// Generated code. Do not edit.
import Foundation
import Vapor

public struct AdminUserUser: Codable, Sendable {
    public var firstName: String
    public var lastName: String
    public var username: String
    public var email: String?
    public var phone: String?
    public var hireDate: Date?
    public var birthDate: Date?
    public var picture: URL?

    public init(firstName: String, lastName: String, username: String, email: String? = nil, phone: String? = nil, hireDate: Date? = nil, birthDate: Date? = nil, picture: URL? = nil) {
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
}
