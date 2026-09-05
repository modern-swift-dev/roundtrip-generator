import Combine
import Foundation
import RoundTrip
import RoundTripREST

/// ☠️☠️☠️ This is generated code, modify at your own risk
public extension AdminUserApi {
    struct PatchedUser: Codable, Sendable {
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

        /// Custom Encoding Method for `PatchableValue` fields
        public func encode(to encoder: any Encoder) throws {
            var codingContainer = encoder.container(keyedBy: Self.CodingKeys.self)
            if !firstName.isUnmodified {
                try codingContainer.encode(firstName, forKey: .firstName)
            }
            if !lastName.isUnmodified {
                try codingContainer.encode(lastName, forKey: .lastName)
            }
            if !username.isUnmodified {
                try codingContainer.encode(username, forKey: .username)
            }
            if !email.isUnmodified {
                try codingContainer.encode(email, forKey: .email)
            }
            if !phone.isUnmodified {
                try codingContainer.encode(phone, forKey: .phone)
            }
            if !hireDate.isUnmodified {
                try codingContainer.encode(hireDate, forKey: .hireDate)
            }
            if !birthDate.isUnmodified {
                try codingContainer.encode(birthDate, forKey: .birthDate)
            }
            if !picture.isUnmodified {
                try codingContainer.encode(picture, forKey: .picture)
            }
        }

        public init(from decoder: any Decoder) throws {
            let codingContainer = try decoder.container(keyedBy: Self.CodingKeys.self)
            if codingContainer.contains(.firstName) {
                if try codingContainer.decodeNil(forKey: .firstName) {
                    firstName = .deleted
                } else {
                    firstName = try codingContainer.decode(PatchableValue<String>.self, forKey: .firstName)
                }
            } else {
                firstName = .unmodified
            }
            if codingContainer.contains(.lastName) {
                if try codingContainer.decodeNil(forKey: .lastName) {
                    lastName = .deleted
                } else {
                    lastName = try codingContainer.decode(PatchableValue<String>.self, forKey: .lastName)
                }
            } else {
                lastName = .unmodified
            }
            if codingContainer.contains(.username) {
                if try codingContainer.decodeNil(forKey: .username) {
                    username = .deleted
                } else {
                    username = try codingContainer.decode(PatchableValue<String>.self, forKey: .username)
                }
            } else {
                username = .unmodified
            }
            if codingContainer.contains(.email) {
                if try codingContainer.decodeNil(forKey: .email) {
                    email = .deleted
                } else {
                    email = try codingContainer.decode(PatchableValue<String>.self, forKey: .email)
                }
            } else {
                email = .unmodified
            }
            if codingContainer.contains(.phone) {
                if try codingContainer.decodeNil(forKey: .phone) {
                    phone = .deleted
                } else {
                    phone = try codingContainer.decode(PatchableValue<String>.self, forKey: .phone)
                }
            } else {
                phone = .unmodified
            }
            if codingContainer.contains(.hireDate) {
                if try codingContainer.decodeNil(forKey: .hireDate) {
                    hireDate = .deleted
                } else {
                    hireDate = try codingContainer.decode(PatchableValue<Date>.self, forKey: .hireDate)
                }
            } else {
                hireDate = .unmodified
            }
            if codingContainer.contains(.birthDate) {
                if try codingContainer.decodeNil(forKey: .birthDate) {
                    birthDate = .deleted
                } else {
                    birthDate = try codingContainer.decode(PatchableValue<Date>.self, forKey: .birthDate)
                }
            } else {
                birthDate = .unmodified
            }
            if codingContainer.contains(.picture) {
                if try codingContainer.decodeNil(forKey: .picture) {
                    picture = .deleted
                } else {
                    picture = try codingContainer.decode(PatchableValue<URL>.self, forKey: .picture)
                }
            } else {
                picture = .unmodified
            }
        }

        /// Reset all patchable fields to `unmodified`
        public mutating func resetPatchableFields() {
            firstName = .unmodified
            lastName = .unmodified
            username = .unmodified
            email = .unmodified
            phone = .unmodified
            hireDate = .unmodified
            birthDate = .unmodified
            picture = .unmodified
        }

        public func isUnmodified() -> Bool {
            firstName.isUnmodified &&
                lastName.isUnmodified &&
                username.isUnmodified &&
                email.isUnmodified &&
                phone.isUnmodified &&
                hireDate.isUnmodified &&
                birthDate.isUnmodified &&
                picture.isUnmodified
        }
    }
}
