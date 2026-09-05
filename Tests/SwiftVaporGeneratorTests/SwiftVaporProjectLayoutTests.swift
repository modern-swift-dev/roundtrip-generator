import Foundation
import GeneratorModels
@testable import SwiftVaporGenerator
import Testing

struct SwiftVaporProjectLayoutTests {
    @Test func `standalone preset preserves default options`() {
        #expect(SwiftVaporGeneratorOptions.standaloneProject() == SwiftVaporGeneratorOptions())
    }

    @Test func `existing project preserves handwritten scaffolding and writes only sources`() throws {
        let output = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: output) }
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        let handwritten = output.appendingPathComponent("Package.swift")
        try "handwritten project configuration".write(to: handwritten, atomically: true, encoding: .utf8)
        let package = ApiPackage(name: "Example", targetDirUrl: output, modules: [], referencedModules: [], references: [], commonReferences: [], imports: [])
        let generator = SwiftVaporApiPackageGenerator(package: package, options: .existingProject())
        let files = try generator.generatedFiles()
        #expect(!files.isEmpty)
        #expect(files.allSatisfy { $0.relativePath.hasPrefix("Sources/App/") })
        #expect(!files.contains { $0.relativePath.hasSuffix("configure.swift") || $0.relativePath.hasSuffix("Application.kt") })
        try generator.write()
        #expect(try String(contentsOf: handwritten, encoding: .utf8) == "handwritten project configuration")
        for file in files {
            #expect(FileManager.default.fileExists(atPath: output.appendingPathComponent(file.relativePath).path))
        }
    }
}
