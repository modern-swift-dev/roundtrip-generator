import Foundation
import GeneratorModels
import Testing
@testable import KotlinAndroidApiGenerator

struct KotlinAndroidOutputCleanupTests {
    @Test func aliasedOutputPreservesCurrentFilesAndRemovesStaleFiles() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let actual = root.appendingPathComponent("actual")
        let alias = root.appendingPathComponent("alias")
        try FileManager.default.createDirectory(at: actual, withIntermediateDirectories: true)
        try FileManager.default.createSymbolicLink(at: alias, withDestinationURL: actual)
        let package = ApiPackage(name: "Example", targetDirUrl: alias, modules: [], referencedModules: [], references: [], commonReferences: [], imports: [])
        let generator = KotlinAndroidApiPackageGenerator(package: package)
        let files = try generator.generatedFiles()
        let source = try #require(files.first { $0.relativePath.hasSuffix(".kt") })
        let stale = alias.appendingPathComponent(source.relativePath).deletingLastPathComponent().appendingPathComponent("Obsolete.kt")
        try FileManager.default.createDirectory(at: stale.deletingLastPathComponent(), withIntermediateDirectories: true)
        try (KotlinAndroidGeneratedTextFile.managedHeader + "\n").write(to: stale, atomically: true, encoding: .utf8)
        try generator.write()
        for file in files {
            #expect(FileManager.default.fileExists(atPath: alias.appendingPathComponent(file.relativePath).path))
        }
        #expect(!FileManager.default.fileExists(atPath: stale.path))
    }
}
