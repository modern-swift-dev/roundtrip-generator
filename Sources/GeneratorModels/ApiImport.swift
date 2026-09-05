import Foundation

public struct ApiImport: ExpressibleByStringLiteral, Sendable, Hashable {
    public let annotation: String?
    public let name: String

    public init(stringLiteral value: String) {
        annotation = nil
        name = value
    }

    public init(
        name: String,
        annotation: String? = nil
    ) {
        self.annotation = annotation
        self.name = name
    }

    public func hash(into hasher: inout Hasher) {
        if let annotation {
            hasher.combine(annotation)
        }
        hasher.combine(name)

    }
}

extension ApiImport: Comparable {
    public static func < (lhs: ApiImport, rhs: ApiImport) -> Bool {
        lhs.name < rhs.name
    }
}
