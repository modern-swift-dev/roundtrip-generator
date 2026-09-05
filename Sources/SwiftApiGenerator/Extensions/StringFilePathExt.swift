import Foundation
import GeneratorModels

extension String {
    func safeFilePathComponent(allowEmpty: Bool = false) throws -> String {
        if isEmpty, allowEmpty {
            return self
        }

        guard !isEmpty,
              self != ".",
              self != "..",
              !contains("/"),
              !contains("\\"),
              !contains("\0") else {
            throw ApiValidationError.failed("Invalid generated file path component: \(self)")
        }

        return self
    }
}
