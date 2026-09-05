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
            picture: PatchableValue<URL> = .unmodified
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
            if !self.firstName.isUnmodified {
                try codingContainer.encode(self.firstName, forKey: .firstName)
            }
            if !self.lastName.isUnmodified {
                try codingContainer.encode(self.lastName, forKey: .lastName)
            }
            if !self.username.isUnmodified {
                try codingContainer.encode(self.username, forKey: .username)
            }
            if !self.email.isUnmodified {
                try codingContainer.encode(self.email, forKey: .email)
            }
            if !self.phone.isUnmodified {
                try codingContainer.encode(self.phone, forKey: .phone)
            }
            if !self.hireDate.isUnmodified {
                try codingContainer.encode(self.hireDate, forKey: .hireDate)
            }
            if !self.birthDate.isUnmodified {
                try codingContainer.encode(self.birthDate, forKey: .birthDate)
            }
            if !self.picture.isUnmodified {
                try codingContainer.encode(self.picture, forKey: .picture)
            }
        }

        public init(from decoder: any Decoder) throws {
            let codingContainer = try decoder.container(keyedBy: Self.CodingKeys.self)
            if codingContainer.contains(.firstName) {
                if try codingContainer.decodeNil(forKey: .firstName) {
                    self.firstName = .deleted
                } else {
                    self.firstName = try codingContainer.decode(PatchableValue<String>.self, forKey: .firstName)
                }
            } else {
                self.firstName = .unmodified
            }
            if codingContainer.contains(.lastName) {
                if try codingContainer.decodeNil(forKey: .lastName) {
                    self.lastName = .deleted
                } else {
                    self.lastName = try codingContainer.decode(PatchableValue<String>.self, forKey: .lastName)
                }
            } else {
                self.lastName = .unmodified
            }
            if codingContainer.contains(.username) {
                if try codingContainer.decodeNil(forKey: .username) {
                    self.username = .deleted
                } else {
                    self.username = try codingContainer.decode(PatchableValue<String>.self, forKey: .username)
                }
            } else {
                self.username = .unmodified
            }
            if codingContainer.contains(.email) {
                if try codingContainer.decodeNil(forKey: .email) {
                    self.email = .deleted
                } else {
                    self.email = try codingContainer.decode(PatchableValue<String>.self, forKey: .email)
                }
            } else {
                self.email = .unmodified
            }
            if codingContainer.contains(.phone) {
                if try codingContainer.decodeNil(forKey: .phone) {
                    self.phone = .deleted
                } else {
                    self.phone = try codingContainer.decode(PatchableValue<String>.self, forKey: .phone)
                }
            } else {
                self.phone = .unmodified
            }
            if codingContainer.contains(.hireDate) {
                if try codingContainer.decodeNil(forKey: .hireDate) {
                    self.hireDate = .deleted
                } else {
                    self.hireDate = try codingContainer.decode(PatchableValue<Date>.self, forKey: .hireDate)
                }
            } else {
                self.hireDate = .unmodified
            }
            if codingContainer.contains(.birthDate) {
                if try codingContainer.decodeNil(forKey: .birthDate) {
                    self.birthDate = .deleted
                } else {
                    self.birthDate = try codingContainer.decode(PatchableValue<Date>.self, forKey: .birthDate)
                }
            } else {
                self.birthDate = .unmodified
            }
            if codingContainer.contains(.picture) {
                if try codingContainer.decodeNil(forKey: .picture) {
                    self.picture = .deleted
                } else {
                    self.picture = try codingContainer.decode(PatchableValue<URL>.self, forKey: .picture)
                }
            } else {
                self.picture = .unmodified
            }
        }

        /// Reset all patchable fields to `unmodified`
        public mutating func resetPatchableFields() {
            self.firstName = .unmodified
            self.lastName = .unmodified
            self.username = .unmodified
            self.email = .unmodified
            self.phone = .unmodified
            self.hireDate = .unmodified
            self.birthDate = .unmodified
            self.picture = .unmodified
        }

        public func isUnmodified() -> Bool {
            self.firstName.isUnmodified &&
                self.lastName.isUnmodified &&
                self.username.isUnmodified &&
                self.email.isUnmodified &&
                self.phone.isUnmodified &&
                self.hireDate.isUnmodified &&
                self.birthDate.isUnmodified &&
                self.picture.isUnmodified
        }
    }
}
