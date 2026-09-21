import Foundation

public enum TypeScriptBackendGeneratedTextFileError: Error, Equatable, LocalizedError {
    case invalidRelativePath(String)
    case refusingToOverwriteUserFile(String)

    public var errorDescription: String? {
        switch self {
            case let .invalidRelativePath(path):
                "Invalid generated TypeScript backend file path: \(path)"
            case let .refusingToOverwriteUserFile(path):
                "Refusing to overwrite user-owned TypeScript backend file: \(path)"
        }
    }
}

public struct TypeScriptBackendGeneratedTextFile: Sendable, Equatable {
    public static let managedHeader = "// Generated code. Do not edit."
    public static let jsonManagedMarker = "\"x-generated\": \"Generated code. Do not edit.\""

    public let relativePath: String
    public let contents: String

    public init(relativePath: String, contents: String) {
        self.relativePath = relativePath
        self.contents = contents
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { String($0).trimmingTrailingHorizontalWhitespace }
            .joined(separator: "\n")
            .trimmingCharacters(in: CharacterSet.newlines)
            + "\n"
    }

    public func write(to directoryURL: URL) throws {
        try write(to: directoryURL, overwritePolicy: .replaceManagedFiles)
    }

    public func write(to directoryURL: URL, overwritePolicy: TypeScriptBackendGeneratedFileOverwritePolicy) throws {
        let components = try validatedPathComponents()
        let fileURL = components.reduce(directoryURL) { $0.appendingPathComponent($1) }
        guard Self.isContained(fileURL, in: directoryURL) else {
            throw TypeScriptBackendGeneratedTextFileError.invalidRelativePath(relativePath)
        }

        if FileManager.default.fileExists(atPath: fileURL.path) {
            switch overwritePolicy {
                case .neverOverwriteExisting:
                    throw TypeScriptBackendGeneratedTextFileError.refusingToOverwriteUserFile(relativePath)
                case .replaceManagedFiles:
                    let existing = (try? String(contentsOf: fileURL, encoding: .utf8)) ?? ""
                    guard Self.hasManagedHeader(in: existing) else {
                        throw TypeScriptBackendGeneratedTextFileError.refusingToOverwriteUserFile(relativePath)
                    }
            }
        }

        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try contents.write(to: fileURL, atomically: true, encoding: .utf8)
    }

    public func validatedPathComponents() throws -> [String] {
        let components = relativePath.split(separator: "/").map(String.init)
        guard !relativePath.hasPrefix("/"), !components.isEmpty, !components.contains("..") else {
            throw TypeScriptBackendGeneratedTextFileError.invalidRelativePath(relativePath)
        }
        return components
    }

    private static func hasManagedHeader(in contents: String) -> Bool {
        if contents.hasPrefix(managedHeader) {
            return true
        }
        return contents
            .split(separator: "\n", omittingEmptySubsequences: false)
            .prefix(24)
            .contains { $0 == managedHeader || $0.contains(jsonManagedMarker) }
    }

    private static func isContained(_ url: URL, in rootURL: URL) -> Bool {
        let rootPath = rootURL.resolvingSymlinksInPath().standardizedFileURL.path
        let path = url.resolvingSymlinksInPath().standardizedFileURL.path
        return path == rootPath || path.hasPrefix(rootPath + "/")
    }
}

private extension String {
    var trimmingTrailingHorizontalWhitespace: String {
        var value = self
        while value.last == " " || value.last == "\t" {
            value.removeLast()
        }
        return value
    }
}
