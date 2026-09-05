import Foundation

public enum ApiValidationError: LocalizedError, Sendable {
    case failed(String)

    var localizedDescription: String {
        switch self {
            case let .failed(msg):
                msg
        }
    }

    public var errorDescription: String? {
        switch self {
            case let .failed(msg):
                msg
        }
    }

    public var failureReason: String? {
        switch self {
            case let .failed(msg):
                msg
        }
    }
}
