import Foundation
import GeneratorModels
import Testing
@testable import TypeScriptApiGenerator

struct TypeScriptProjectLayoutTests {
    @Test func standalonePresetPreservesDefaultOptions() {
        #expect(TypeScriptGeneratorOptions.standaloneProject() == TypeScriptGeneratorOptions())
    }

    @Test func existingProjectPreservesHandwrittenScaffoldingAndWritesOnlySources() throws {
        let output = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: output) }
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        let handwritten = output.appendingPathComponent("package.json")
        try "handwritten project configuration".write(to: handwritten, atomically: true, encoding: .utf8)
        let package = ApiPackage(name: "Example", targetDirUrl: output, modules: [], referencedModules: [], references: [], commonReferences: [], imports: [])
        let generator = TypeScriptApiPackageGenerator(package: package, options: .existingProject())
        let files = try generator.generatedFiles()
        #expect(!files.isEmpty)
        #expect(files.allSatisfy { $0.relativePath.hasPrefix("src/generated/") })
        #expect(!files.contains { $0.relativePath.hasSuffix("configure.swift") || $0.relativePath.hasSuffix("Application.kt") })
        try generator.write()
        #expect(try String(contentsOf: handwritten, encoding: .utf8) == "handwritten project configuration")
        for file in files {
            #expect(FileManager.default.fileExists(atPath: output.appendingPathComponent(file.relativePath).path))
        }
    }

    @Test func existingProjectCanUseSrcDirectly() throws {
        let package = ApiPackage(name: "Example", targetDirUrl: URL(fileURLWithPath: "/unused"), modules: [], referencedModules: [], references: [], commonReferences: [], imports: [])
        let files = try TypeScriptApiPackageGenerator(package: package, options: .existingProject(sourceDirectory: "src")).generatedFiles()
        #expect(files.filter { $0.relativePath == "src/index.ts" }.count == 1)
        #expect(files.allSatisfy { $0.relativePath.hasPrefix("src/") })
    }

    @Test func addingMappingPreservesProjectLayout() {
        let options = TypeScriptGeneratorOptions.existingProject().mapping(.init(apiTypeName: "External", typeScriptType: "External"))
        #expect(options.layout == .existingProject)
    }
}
