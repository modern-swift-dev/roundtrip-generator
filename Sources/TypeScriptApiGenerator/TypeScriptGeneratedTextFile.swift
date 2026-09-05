import Foundation

public enum TypeScriptGeneratedTextFileError: Error, Equatable, LocalizedError {
    case invalidRelativePath(String)
    case refusingToOverwriteUserFile(String)

    public var errorDescription: String? {
        switch self {
            case let .invalidRelativePath(path):
                "Invalid generated TypeScript file path: \(path)"
            case let .refusingToOverwriteUserFile(path):
                "Refusing to overwrite user-owned TypeScript file: \(path)"
        }
    }
}

public struct TypeScriptGeneratedTextFile: Sendable, Equatable {
    public static let managedHeader = "// Generated code. Do not edit."
    public static let jsonManagedMarker = "\"x-generated\": \"Generated code. Do not edit.\""

    public let relativePath: String
    public let contents: String

    public init(relativePath: String, contents: String) {
        self.relativePath = relativePath
        self.contents = contents.typeScriptGeneratedFileNormalized
    }

    public func write(to directoryURL: URL) throws {
        try write(to: directoryURL, overwritePolicy: .replaceManagedFiles)
    }

    public func write(to directoryURL: URL, overwritePolicy: TypeScriptGeneratedFileOverwritePolicy) throws {
        let components = try validatedPathComponents()
        let fileURL = components.reduce(directoryURL) { partialURL, component in
            partialURL.appendingPathComponent(component)
        }
        guard Self.isContained(fileURL.deletingLastPathComponent(), in: directoryURL) else {
            throw TypeScriptGeneratedTextFileError.invalidRelativePath(relativePath)
        }

        if FileManager.default.fileExists(atPath: fileURL.path) {
            switch overwritePolicy {
                case .neverOverwriteExisting:
                    throw TypeScriptGeneratedTextFileError.refusingToOverwriteUserFile(relativePath)
                case .replaceManagedFiles:
                    let existing = (try? String(contentsOf: fileURL, encoding: .utf8)) ?? ""
                    guard Self.hasManagedHeader(in: existing) else {
                        throw TypeScriptGeneratedTextFileError.refusingToOverwriteUserFile(relativePath)
                    }
            }
        }

        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try contents.data(using: .utf8)?.write(to: fileURL, options: [.atomic])
    }

    func validatedPathComponents() throws -> [String] {
        let components = relativePath.split(separator: "/").map(String.init)
        guard !relativePath.hasPrefix("/"),
              !components.isEmpty,
              !components.contains("..") else {
            throw TypeScriptGeneratedTextFileError.invalidRelativePath(relativePath)
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
    var typeScriptGeneratedFileNormalized: String {
        split(separator: "\n", omittingEmptySubsequences: false)
            .map { String($0).trimmingTrailingHorizontalWhitespace }
            .joined(separator: "\n")
            .ensuringSingleFinalNewline
    }

    var ensuringSingleFinalNewline: String {
        trimmingCharacters(in: CharacterSet.newlines) + "\n"
    }

    var trimmingTrailingHorizontalWhitespace: String {
        var result = self
        while let last = result.last, last == " " || last == "\t" {
            result.removeLast()
        }
        return result
    }
}
