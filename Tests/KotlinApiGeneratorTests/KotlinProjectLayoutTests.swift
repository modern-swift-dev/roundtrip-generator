import Foundation
import GeneratorModels
@testable import KotlinApiGenerator
import Testing

struct KotlinProjectLayoutTests {
    @Test func `standalone preset preserves default options`() {
        #expect(KotlinGeneratorOptions.standaloneProject() == KotlinGeneratorOptions())
    }

    @Test func `existing project preserves handwritten scaffolding and writes only sources`() throws {
        let output = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: output) }
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        let handwritten = output.appendingPathComponent("settings.gradle.kts")
        try "handwritten project configuration".write(to: handwritten, atomically: true, encoding: .utf8)
        let package = ApiPackage(name: "Example", targetDirUrl: output, modules: [], referencedModules: [], references: [], commonReferences: [], imports: [])
        let generator = KotlinApiPackageGenerator(package: package, options: .existingProject())
        let files = try generator.generatedFiles()
        #expect(!files.isEmpty)
        #expect(files.allSatisfy { $0.relativePath.hasPrefix("src/commonMain/kotlin/") })
        #expect(!files.contains { $0.relativePath.hasSuffix("configure.swift") || $0.relativePath.hasSuffix("Application.kt") })
        try generator.write()
        #expect(try String(contentsOf: handwritten, encoding: .utf8) == "handwritten project configuration")
        for file in files {
            #expect(FileManager.default.fileExists(atPath: output.appendingPathComponent(file.relativePath).path))
        }
    }

    @Test func `adding mapping preserves project layout`() {
        let options = KotlinGeneratorOptions.existingProject().mapping(.init(apiTypeName: "External", kotlinType: "External"))
        #expect(options.layout == .existingProject)
    }
}
