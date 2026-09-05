import Foundation
import GeneratorBuilder
import GeneratorModels

public struct ApiPackageGenerator {
    public let package: ApiPackage

    public init(package: ApiPackage) {
        self.package = package
    }

    /// Render sources without creating or changing the destination directory.
    public func generatedFiles() throws -> [SwiftGeneratedTextFile] {
        try ApiTypeNameResolver.shared.withExclusiveAccess {
            try ApiPackageValidator(package: package).validate()
            let directory = FileManager.default.temporaryDirectory.resolvingSymlinksInPath().appendingPathComponent(UUID().uuidString)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: directory) }
            try render(to: directory)
            return try Self.sourceURLs(in: directory).map { url in
                guard let rootIndex = url.pathComponents.firstIndex(of: directory.lastPathComponent) else {
                    throw ApiValidationError.failed("Rendered file is outside staging directory: \(url.path)")
                }
                return try SwiftGeneratedTextFile(
                    relativePath: url.pathComponents.dropFirst(rootIndex + 1).joined(separator: "/"),
                    contents: String(contentsOf: url, encoding: .utf8),
                )
            }.sorted { $0.relativePath < $1.relativePath }
        }
    }

    public func write(outputPolicy: SwiftOutputPolicy = .replaceDirectory) throws {
        guard package.targetDirUrl.isFileURL else {
            throw ApiValidationError.failed("Output directory must be a file URL: \(package.targetDirUrl)")
        }
        let files = try generatedFiles()
        let fileManager = FileManager.default
        let destination = package.targetDirUrl
        let parent = destination.deletingLastPathComponent()
        let staging = parent.appendingPathComponent(".\(destination.lastPathComponent).tmp.\(UUID().uuidString)")
        try fileManager.createDirectory(at: parent, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: staging) }

        if outputPolicy != .replaceDirectory, fileManager.fileExists(atPath: destination.path) {
            guard try destination.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink != true else {
                throw ApiValidationError.failed("Managed output directory cannot be a symbolic link: \(destination.path)")
            }
            try fileManager.copyItem(at: destination, to: staging)
            if outputPolicy == .replaceManagedFiles {
                for url in try Self.sourceURLs(in: staging) where try Self.isManaged(url) {
                    try fileManager.removeItem(at: url)
                }
            }
        } else {
            try fileManager.createDirectory(at: staging, withIntermediateDirectories: true)
        }

        for file in files {
            let url = staging.appendingPathComponent(file.relativePath)
            var ancestor = url
            while ancestor.path != staging.path {
                if let values = try? ancestor.resourceValues(forKeys: [.isSymbolicLinkKey]), values.isSymbolicLink == true {
                    throw ApiValidationError.failed("Generated output cannot traverse a symbolic link: \(file.relativePath)")
                }
                ancestor.deleteLastPathComponent()
            }
            guard !fileManager.fileExists(atPath: url.path) else {
                throw ApiValidationError.failed("Generated output collides with an existing file: \(file.relativePath)")
            }
            try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try file.contents.write(to: url, atomically: true, encoding: .utf8)
        }
        if fileManager.fileExists(atPath: destination.path) {
            _ = try fileManager.replaceItemAt(destination, withItemAt: staging)
        } else {
            try fileManager.moveItem(at: staging, to: destination)
        }
    }

    private static func sourceURLs(in directory: URL) throws -> [URL] {
        let keys: [URLResourceKey] = [.isRegularFileKey, .isSymbolicLinkKey]
        var failure: (any Error)?
        guard let enumerator = FileManager.default.enumerator(at: directory, includingPropertiesForKeys: keys, errorHandler: { _, error in
            failure = error
            return false
        }) else {
            return []
        }
        var result: [URL] = []
        for case let url as URL in enumerator {
            let values = try url.resourceValues(forKeys: Set(keys))
            if values.isSymbolicLink == true {
                enumerator.skipDescendants(); continue
            }
            if values.isRegularFile == true {
                result.append(url)
            }
        }
        if let failure {
            throw failure
        }
        return result
    }

    private static func isManaged(_ url: URL) throws -> Bool {
        guard url.lastPathComponent.hasSuffix(".generated.swift") else {
            return false
        }
        return try String(contentsOf: url, encoding: .utf8).contains("// ☠️☠️☠️ This is generated code, modify at your own risk")
    }

    private func render(to tempUrl: URL) throws {
        try ApiModuleGenerator(module: .init(name: "", definitions: [], references: package.references)).write(to: tempUrl, imports: package.swiftImports)

        ApiTypeNameResolver.shared.push(module: "", types: package.references)
        defer { ApiTypeNameResolver.shared.pop() }

        let modulesWithDefinitions = (package.modules + package.referencedModules).filter { !$0.definitions.isEmpty }
        if !package.modules.isEmpty {
            for module in package.modules {
                try ApiModuleGenerator(module: module).write(to: tempUrl, imports: package.swiftImports)
            }
        }

        if package.generateApiModules, !modulesWithDefinitions.isEmpty {
            try ApiPackageServiceGenerator(package: package).write(url: tempUrl)
        }
    }
}
