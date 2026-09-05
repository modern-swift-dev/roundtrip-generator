import Foundation
import GeneratorModels
import Testing
@testable import TypeScriptApiGenerator

struct TypeScriptOutputPathTests {
    @Test(arguments: ["src/client", "lib/client"])
    func customDirectoryHasConsistentEntryPoints(directory: String) throws {
        let package = ApiPackage(name: "Example", targetDirUrl: URL(fileURLWithPath: "/unused"), modules: [], referencedModules: [], references: [], commonReferences: [], imports: [])
        let files = try TypeScriptApiPackageGenerator(package: package, options: .init(sourceDirectory: directory)).generatedFiles()
        let rootIndex = try #require(files.first { $0.relativePath == "src/index.ts" })
        #expect(rootIndex.contents.contains(directory == "src/client" ? "./client/index.js" : "../lib/client/index.js"))
        let metadata = try #require(files.first { $0.relativePath == "package.json" })
        let config = try #require(files.first { $0.relativePath == "tsconfig.json" })
        #expect(metadata.contents.contains(directory == "src/client" ? "./dist/index.js" : "./dist/src/index.js"))
        #expect(config.contents.contains("\(directory)/**/*.ts"))
        #expect(config.contents.contains(directory == "src/client" ? #""rootDir": "src""# : #""rootDir": ".""#))
    }

    @Test(.enabled(if: ProcessInfo.processInfo.environment["ROUNDTRIP_TSC_PATH"] != nil), arguments: ["src/client", "lib/client"])
    func customDirectoryCompiles(directory: String) throws {
        let compiler = try #require(ProcessInfo.processInfo.environment["ROUNDTRIP_TSC_PATH"])
        let output = FileManager.default.temporaryDirectory.resolvingSymlinksInPath().appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: output) }
        let package = ApiPackage(name: "Example", targetDirUrl: output, modules: [], referencedModules: [], references: [], commonReferences: [], imports: [])
        for file in try TypeScriptApiPackageGenerator(package: package, options: .init(sourceDirectory: directory)).generatedFiles() {
            try file.write(to: output)
        }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: compiler)
        process.arguments = ["-p", output.appendingPathComponent("tsconfig.json").path]
        try process.run()
        process.waitUntilExit()
        #expect(process.terminationStatus == 0)
        let entry = directory == "src/client" ? "dist/index.js" : "dist/src/index.js"
        #expect(FileManager.default.fileExists(atPath: output.appendingPathComponent(entry).path))
    }

    @Test(arguments: ["src", "package.json", "src/index.ts/client", "src/./client", "src//client", "../client", "src\\client"])
    func rejectsCollidingOrNonCanonicalDirectories(directory: String) {
        let package = ApiPackage(name: "Example", targetDirUrl: URL(fileURLWithPath: "/unused"), modules: [], referencedModules: [], references: [], commonReferences: [], imports: [])
        #expect(throws: TypeScriptGeneratorError.invalidSourceDirectory(directory)) {
            try TypeScriptApiPackageGenerator(package: package, options: .init(sourceDirectory: directory)).generatedFiles()
        }
    }
}
