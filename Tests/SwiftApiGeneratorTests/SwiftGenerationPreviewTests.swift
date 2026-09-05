import Foundation
import GeneratorModels
import SwiftApiGenerator
import Testing

struct SwiftGenerationPreviewTests {
    private func generator(at url: URL) -> ApiPackageGenerator {
        ApiPackageGenerator(package: ApiPackage(
            name: "Example", targetDirUrl: url, modules: [], referencedModules: [],
            references: [.object(typeName: "User", properties: [.string("name")])],
            commonReferences: [], imports: [],
        ))
    }

    @Test func `preview does not create destination and matches write`() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let destination = root.appendingPathComponent("Generated")
        let generator = generator(at: destination)
        let files = try generator.generatedFiles()
        #expect(!files.isEmpty)
        #expect(!FileManager.default.fileExists(atPath: root.path))
        try generator.write()
        for file in files {
            #expect(try String(contentsOf: destination.appendingPathComponent(file.relativePath), encoding: .utf8) == file.contents)
            for module in ["Foundation", "RoundTrip", "RoundTripREST"] {
                #expect(file.contents.contains("import \(module)"))
            }
        }
    }

    @Test func `managed write preserves handwritten files and removes stale sources`() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let generator = generator(at: root)
        try generator.write()
        let handwritten = root.appendingPathComponent("Notes.swift")
        try "// handwritten".write(to: handwritten, atomically: true, encoding: .utf8)
        let stale = root.appendingPathComponent("Old.generated.swift")
        try "// ☠️☠️☠️ This is generated code, modify at your own risk".write(to: stale, atomically: true, encoding: .utf8)
        try generator.write(outputPolicy: .replaceManagedFiles)
        #expect(try String(contentsOf: handwritten, encoding: .utf8) == "// handwritten")
        #expect(!FileManager.default.fileExists(atPath: stale.path))
    }

    @Test func `managed collision leaves destination unchanged`() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let generator = generator(at: root)
        let file = try #require(generator.generatedFiles().first)
        let collision = root.appendingPathComponent(file.relativePath)
        try FileManager.default.createDirectory(at: collision.deletingLastPathComponent(), withIntermediateDirectories: true)
        try "// handwritten".write(to: collision, atomically: true, encoding: .utf8)
        #expect(throws: (any Error).self) { try generator.write(outputPolicy: .replaceManagedFiles) }
        #expect(try String(contentsOf: collision, encoding: .utf8) == "// handwritten")
    }

    @Test func `never overwrite rejects even managed files`() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let generator = generator(at: root)
        try generator.write(outputPolicy: .neverOverwriteExisting)
        let file = try #require(generator.generatedFiles().first)
        let destination = root.appendingPathComponent(file.relativePath)
        let original = try String(contentsOf: destination, encoding: .utf8)
        #expect(throws: (any Error).self) { try generator.write(outputPolicy: .neverOverwriteExisting) }
        #expect(try String(contentsOf: destination, encoding: .utf8) == original)
    }

    @Test func `managed output rejects symlink directories without changing target`() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let output = root.appendingPathComponent("Output")
        let external = root.appendingPathComponent("Handwritten")
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: external, withIntermediateDirectories: true)
        try FileManager.default.createSymbolicLink(at: output.appendingPathComponent("Shared"), withDestinationURL: external)
        #expect(throws: (any Error).self) { try generator(at: output).write(outputPolicy: .replaceManagedFiles) }
        #expect(try FileManager.default.contentsOfDirectory(atPath: external.path).isEmpty)
        #expect(try output.appendingPathComponent("Shared").resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink == true)
    }
}
