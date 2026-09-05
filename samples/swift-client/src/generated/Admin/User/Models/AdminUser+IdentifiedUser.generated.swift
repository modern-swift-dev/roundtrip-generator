import Combine
import Foundation
import RoundTrip
import RoundTripREST

/// ☠️☠️☠️ This is generated code, modify at your own risk
public extension AdminUserApi {
    struct IdentifiedUser: Codable, Sendable, Identifiable {
        public var id: Int64
        public var firstName: String
        public var lastName: String
        public var username: String
        public var email: String?
        public var phone: String?
        public var hireDate: Date?
        public var birthDate: Date?
        public var picture: URL?
        public var creationDate: Date
        public var lastUpdateDate: Date
        public init(
            id: Int64,
            firstName: String,
            lastName: String,
            username: String,
            email: String? = nil,
            phone: String? = nil,
            hireDate: Date? = nil,
            birthDate: Date? = nil,
            picture: URL? = nil,
            creationDate: Date,
            lastUpdateDate: Date,
        ) {
            self.id = id
            self.firstName = firstName
            self.lastName = lastName
            self.username = username
            self.email = email
            self.phone = phone
            self.hireDate = hireDate
            self.birthDate = birthDate
            self.picture = picture
            self.creationDate = creationDate
            self.lastUpdateDate = lastUpdateDate
        }

        public enum CodingKeys: String, CodingKey {
            case id
            case firstName = "first_name"
            case lastName = "last_name"
            case username
            case email
            case phone
            case hireDate = "hire_date"
            case birthDate = "birth_date"
            case picture
            case creationDate = "creation_date"
            case lastUpdateDate = "last_update_date"
        }
    }
}
