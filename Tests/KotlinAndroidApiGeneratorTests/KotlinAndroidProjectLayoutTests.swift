import Foundation
import GeneratorModels
import Testing
@testable import KotlinAndroidApiGenerator

struct KotlinAndroidProjectLayoutTests {
    @Test func standalonePresetPreservesDefaultOptions() {
        #expect(KotlinAndroidGeneratorOptions.standaloneProject() == KotlinAndroidGeneratorOptions())
    }

    @Test func existingProjectPreservesHandwrittenScaffoldingAndWritesOnlySources() throws {
        let output = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: output) }
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        let handwritten = output.appendingPathComponent("settings.gradle.kts")
        try "handwritten project configuration".write(to: handwritten, atomically: true, encoding: .utf8)
        let package = ApiPackage(name: "Example", targetDirUrl: output, modules: [], referencedModules: [], references: [], commonReferences: [], imports: [])
        let generator = KotlinAndroidApiPackageGenerator(package: package, options: .existingProject())
        let files = try generator.generatedFiles()
        #expect(!files.isEmpty)
        #expect(files.allSatisfy { $0.relativePath.hasPrefix("src/main/kotlin/") })
        #expect(!files.contains { $0.relativePath.hasSuffix("configure.swift") || $0.relativePath.hasSuffix("Application.kt") })
        try generator.write()
        #expect(try String(contentsOf: handwritten, encoding: .utf8) == "handwritten project configuration")
        for file in files {
            #expect(FileManager.default.fileExists(atPath: output.appendingPathComponent(file.relativePath).path))
        }
    }

    @Test func addingMappingPreservesProjectLayout() {
        let options = KotlinAndroidGeneratorOptions.existingProject().mapping(.init(apiTypeName: "External", kotlinType: "External"))
        #expect(options.layout == .existingProject)
    }
}
