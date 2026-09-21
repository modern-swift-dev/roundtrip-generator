import Foundation
import GeneratorModels
import Testing
@testable import TypeScriptBackendGenerator

struct TypeScriptBackendGeneratedPackageTests {
    @Test(.enabled(if: ProcessInfo.processInfo.environment["ROUNDTRIP_BACKEND_RUNTIME_TEST"] != nil))
    func generatedPackageCompilesAndServesItsRoute() throws {
        let dumpPath = ProcessInfo.processInfo.environment["ROUNDTRIP_BACKEND_DUMP_PATH"]
        let root = dumpPath.map(URL.init(fileURLWithPath:)) ?? FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer {
            if dumpPath == nil {
                try? FileManager.default.removeItem(at: root)
            }
        }

        let user = ApiTypeSchema.object(
            typeName: "User",
            properties: [
                .string("display_name", propertyName: "displayName"),
                .bool("active"),
                .double("score")
            ],
        )
        let operation = ApiOperation.post(
            name: "create",
            path: .relative("/users"),
            security: .unsecured,
            request: user.asRef,
            response: user.asRef,
            acceptableStatuses: [200],
        )
        let package = ApiPackage(
            name: "Example",
            targetDirUrl: root,
            modules: [
                ApiModule(name: "Admin", definitions: [
                    ApiService(name: "Users", operations: [operation], references: [user])
                ])
            ],
            referencedModules: [],
            references: [],
            commonReferences: [],
            imports: [],
        )

        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        for file in try TypeScriptBackendApiPackageGenerator(package: package).generatedFiles() {
            try file.write(to: root)
        }
        if dumpPath != nil {
            return
        }
        try typeFixture().write(
            to: root.appendingPathComponent("src/handler-fixture.ts"),
            atomically: true,
            encoding: .utf8,
        )
        try runtimeTest().write(to: root.appendingPathComponent("test.mjs"), atomically: true, encoding: .utf8)

        try run(["install", "--ignore-scripts", "--package-lock=false"], in: root)
        try run(["run", "build"], in: root)
        try run(["node", "test.mjs"], in: root)
    }

    private func run(_ arguments: [String], in directory: URL) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["npm"] + arguments
        process.currentDirectoryURL = directory
        let output = Pipe()
        process.standardOutput = output
        process.standardError = output
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            let text = String(data: output.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            throw NSError(domain: "TypeScriptBackendGeneratedPackageTests", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: text])
        }
    }

    private func runtimeTest() -> String {
        """
        import assert from "node:assert/strict";
        import express from "express";
        import { registerGeneratedRoutes } from "./dist/generated/routes.js";

        const app = express();
        let handlerCalls = 0;
        registerGeneratedRoutes(app, {
            adminUsersCreate(input) {
                handlerCalls += 1;
                if (input.score === 1.5) {
                    assert.deepEqual(input, { displayName: "Ada", active: true, score: 1.5 });
                }
                if (input.score === 2) {
                    return { ...input, score: "invalid" };
                }
                return { ...input, privateValue: "removed" };
            }
        });

        const server = await new Promise((resolve) => {
            const value = app.listen(0, () => resolve(value));
        });
        const port = server.address().port;
        const url = "http://127.0.0.1:" + port + "/users";

        const valid = await fetch(url, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: JSON.stringify({
                display_name: "Ada",
                active: true,
                score: 1.5,
                undeclared: "removed"
            })
        });
        assert.equal(valid.status, 200);
        assert.deepEqual(await valid.json(), {
            display_name: "Ada",
            active: true,
            score: 1.5
        });

        const invalidOutput = await fetch(url, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: JSON.stringify({ display_name: "Ada", active: true, score: 2 })
        });
        assert.equal(invalidOutput.status, 500);

        const invalid = await fetch(url, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: JSON.stringify({ display_name: "Ada", active: true })
        });
        assert.equal(invalid.status, 400);
        assert.equal(handlerCalls, 2);

        await new Promise((resolve) => server.close(resolve));
        """
    }

    private func typeFixture() -> String {
        """
        import type { GeneratedHandlers } from "./generated/routes.js";

        const validHandlers: GeneratedHandlers = {
            adminUsersCreate: async (input) => input
        };

        const incompatibleHandlers: GeneratedHandlers = {
            // @ts-expect-error generated handlers reject incompatible output types
            adminUsersCreate: async () => ({ displayName: "Ada", active: true, score: "not-a-number" })
        };

        void validHandlers;
        void incompatibleHandlers;
        """
    }
}
