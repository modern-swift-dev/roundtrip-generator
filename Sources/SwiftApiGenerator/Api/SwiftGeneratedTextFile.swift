import Foundation

/// A rendered Swift source file, relative to the output directory.
public struct SwiftGeneratedTextFile: Sendable, Equatable {
    public let relativePath: String
    public let contents: String
}

/// Controls ownership of the Swift generator's destination.
public enum SwiftOutputPolicy: Sendable {
    /// Atomically replace the entire directory. The destination must contain only generated files.
    case replaceDirectory
    /// Preserve handwritten files and replace or remove only marked generated Swift files.
    case replaceManagedFiles
    /// Preserve existing files and fail if any generated path already exists.
    case neverOverwriteExisting
}
