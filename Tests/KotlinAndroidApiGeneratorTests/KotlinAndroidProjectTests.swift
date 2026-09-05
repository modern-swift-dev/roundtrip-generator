import Foundation
import GeneratorModels
@testable import KotlinAndroidApiGenerator
import Testing

struct KotlinAndroidProjectTests {
    @Test func keywordBasePackagesFailBeforeWritingKotlin() {
        #expect(throws: KotlinAndroidGeneratorError.invalidBasePackage("org.class.api")) {
            try KotlinAndroidApiPackageGenerator(package: package(), options: .init(basePackage: "org.class.api")).generatedFiles()
        }
    }

    @Test func customProjectCoordinatesAndPackagePathsAreEscaped() throws {
        let options = KotlinAndroidGeneratorOptions(
            basePackage: "org.acme.mobile.v2",
            gradle: .init(
                projectName: "Acme \"Mobile\" $client\nSDK",
                moduleName: "android-client_v2",
                namespace: "org.acme.library",
                group: "org.acme.$group",
                version: "1.0.0\"preview",
                artifactId: "mobile\\client"
            )
        )
        let files = try KotlinAndroidApiPackageGenerator(package: package(), options: options).generatedFiles()
        let settings = try #require(files.first { $0.relativePath == "settings.gradle.kts" })
        #expect(settings.contents.contains(#"rootProject.name = "Acme \"Mobile\" \$client\nSDK""#))
        #expect(settings.contents.contains(#"include(":android-client_v2")"#))
        let module = try #require(files.first { $0.relativePath == "android-client_v2/build.gradle.kts" })
        #expect(module.contents.contains(#"namespace = "org.acme.library""#))
        #expect(module.contents.contains(#"group = "org.acme.\$group""#))
        #expect(module.contents.contains(#"version = "1.0.0\"preview""#))
        #expect(module.contents.contains(#"artifactId = "mobile\\client""#))
        let runtime = try #require(files.first {
            $0.relativePath == "android-client_v2/src/main/kotlin/org/acme/mobile/v2/ApiRuntime.kt"
        })
        #expect(runtime.contents.contains("package org.acme.mobile.v2"))
        let service = try #require(files.first { $0.relativePath.hasSuffix("/CatalogItemsApi.kt") })
        #expect(service.relativePath.hasPrefix("android-client_v2/src/main/kotlin/org/acme/mobile/v2/"))
        #expect(service.contents.contains("import org.acme.mobile.v2.RestClient"))
        #expect(!files.map(\.contents).joined().contains("com.example.api"))
    }

    @Test func disablingAllOptionalSourcesRetainsModelsAndServices() throws {
        let options = KotlinAndroidGeneratorOptions(
            generateRuntime: false,
            generateKoinModule: false,
            generateMocks: false
        )
        let files = try KotlinAndroidApiPackageGenerator(package: package(), options: options).generatedFiles()
        let paths = files.map(\.relativePath)
        #expect(!paths.contains { $0.hasSuffix("/ApiRuntime.kt") })
        #expect(!paths.contains { $0.hasSuffix("/ApiKoinModule.kt") })
        #expect(!paths.contains { $0.hasSuffix("/ApiModulesMocks.kt") })
        #expect(paths.contains { $0.hasSuffix("/CatalogItemsApi.kt") })
        #expect(paths.contains { $0.hasSuffix("/models/Item.kt") })
        let catalog = try #require(files.first { $0.relativePath == "gradle/libs.versions.toml" })
        let module = try #require(files.first { $0.relativePath == "generated-api/build.gradle.kts" })
        #expect(!catalog.contents.contains("koin"))
        #expect(!module.contents.contains("koin"))
    }

    @Test func manifestPermissionAndManagedXmlRespectNeverOverwritePolicy() throws {
        let root = temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let files = KotlinAndroidGradleProjectEmitter().generatedFiles()
        let manifest = try #require(files.first { $0.relativePath.hasSuffix("/AndroidManifest.xml") })
        #expect(manifest.contents.hasPrefix("<!-- Generated code. Do not edit. -->\n"))
        #expect(manifest.contents.contains(#"xmlns:android="http://schemas.android.com/apk/res/android""#))
        #expect(manifest.contents.contains(#"<uses-permission android:name="android.permission.INTERNET" />"#))
        try manifest.write(to: root, overwritePolicy: .neverOverwriteExisting)
        let changed = KotlinAndroidGeneratedTextFile(relativePath: manifest.relativePath, contents: "<!-- Generated code. Do not edit. -->\n<manifest />")
        #expect(throws: KotlinAndroidGeneratedTextFileError.refusingToOverwriteUserFile(manifest.relativePath)) {
            try changed.write(to: root, overwritePolicy: .neverOverwriteExisting)
        }
        #expect(try String(contentsOf: root.appendingPathComponent(manifest.relativePath), encoding: .utf8) == manifest.contents)
    }

    @Test func directorySymlinkContainedInOutputRootCanBeWritten() throws {
        let root = temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let actual = root.appendingPathComponent("actual", isDirectory: true)
        try FileManager.default.createDirectory(at: actual, withIntermediateDirectories: true)
        try FileManager.default.createSymbolicLink(at: root.appendingPathComponent("alias"), withDestinationURL: actual)
        let file = KotlinAndroidGeneratedTextFile(relativePath: "alias/Item.kt", contents: "// Generated code. Do not edit.\nclass Item")
        try file.write(to: root)
        #expect(try String(contentsOf: actual.appendingPathComponent("Item.kt"), encoding: .utf8) == file.contents)
        #expect(try root.appendingPathComponent("alias").resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink == true)
    }

    @Test func generatedLeafSymlinkCannotReplaceAnOutsideManagedSource() throws {
        let root = temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let output = root.appendingPathComponent("output", isDirectory: true)
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        let outside = root.appendingPathComponent("Outside.kt")
        let original = "// Generated code. Do not edit.\nclass Outside\n"
        try original.write(to: outside, atomically: true, encoding: .utf8)
        let link = output.appendingPathComponent("Item.kt")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: outside)
        let file = KotlinAndroidGeneratedTextFile(relativePath: "Item.kt", contents: "// Generated code. Do not edit.\nclass Item")
        #expect(throws: KotlinAndroidGeneratedTextFileError.invalidRelativePath("Item.kt")) {
            try file.write(to: output)
        }
        #expect(try String(contentsOf: outside, encoding: .utf8) == original)
        #expect(try link.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink == true)
    }

    @Test func neverOverwriteRefusesEvenManagedGradleFiles() throws {
        let root = temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let generator = KotlinAndroidApiPackageGenerator(
            package: package(root: root),
            options: .init(gradle: .init(overwritePolicy: .neverOverwriteExisting))
        )
        try generator.write()
        let settingsURL = root.appendingPathComponent("settings.gradle.kts")
        let original = try Data(contentsOf: settingsURL)
        #expect(throws: KotlinAndroidGeneratedTextFileError.refusingToOverwriteUserFile("settings.gradle.kts")) {
            try generator.write()
        }
        #expect(try Data(contentsOf: settingsURL) == original)
    }

    @Test func staleLeafSymlinkCannotDeleteAnOutsideManagedSource() throws {
        let root = temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let output = root.appendingPathComponent("output", isDirectory: true)
        let generator = KotlinAndroidApiPackageGenerator(package: package(root: output))
        try generator.write()
        let outside = root.appendingPathComponent("Outside.kt")
        let original = "// Generated code. Do not edit.\nclass Outside\n"
        try original.write(to: outside, atomically: true, encoding: .utf8)
        let stale = output.appendingPathComponent("generated-api/src/main/kotlin/Stale.kt")
        try FileManager.default.createSymbolicLink(at: stale, withDestinationURL: outside)
        #expect(throws: KotlinAndroidGeneratedTextFileError.self) {
            try generator.write()
        }
        #expect(try String(contentsOf: outside, encoding: .utf8) == original)
        #expect(try stale.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink == true)
    }

    private func temporaryRoot() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("android-project-\(UUID().uuidString)", isDirectory: true)
    }

    private func package(root: URL? = nil) -> ApiPackage {
        let item = ApiTypeSchema.object(typeName: "Item", properties: [.string("name")])
        return ApiPackage(
            name: "AndroidProjectTest",
            targetDirUrl: root ?? temporaryRoot(),
            modules: [
                ApiModule(name: "Catalog", definitions: [
                    ApiService(name: "Items", operations: [
                        .get(name: "get", path: .relative("/items"), security: .unsecured, response: item.asRef)
                    ], references: [item])
                ])
            ],
            referencedModules: [],
            references: [],
            commonReferences: [],
            imports: []
        )
    }
}
