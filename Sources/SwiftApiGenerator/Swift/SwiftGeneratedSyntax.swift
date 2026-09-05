import Foundation
import GeneratorModels

package enum SwiftGeneratedSyntax {
    package static func parse<T>(_ context: String, _ build: () throws -> T) -> T {
        do {
            return try parseThrowing(context, build)
        } catch {
            preconditionFailure("Invalid generated Swift \(context) syntax: \(error)")
        }
    }

    static func parseThrowing<T>(_ context: String, _ build: () throws -> T) throws -> T {
        do {
            return try build()
        } catch {
            throw ApiValidationError.failed("Invalid generated Swift \(context) syntax: \(error)")
        }
    }
}
