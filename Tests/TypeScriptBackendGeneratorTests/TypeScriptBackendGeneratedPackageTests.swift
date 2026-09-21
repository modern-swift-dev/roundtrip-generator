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

        let address = ApiTypeSchema.object(
            typeName: "Address",
            properties: [
                .string("street_name", propertyName: "streetName"),
                .bool("verified")
            ],
        )
        let profile = ApiTypeSchema.object(
            typeName: "Profile",
            properties: [
                .ref("address", of: address),
                .arrayOfRef("previous_addresses", propertyName: "previousAddresses", of: address),
                .keyedByString("labels", valueType: .string(), required: false, valueOptional: true),
                .string("nickname", required: false)
            ],
        )
        let state = ApiTypeSchema.stringEnum(
            typeName: "State",
            values: [(name: "inProgress", rawName: "in-progress")],
            initialValue: "inProgress",
            supportGarbage: true,
        )
        let magnitude = ApiTypeSchema.intEnum(
            typeName: "Magnitude",
            values: [
                (name: "small", rawValue: 1),
                (name: "maximum", rawValue: 9_223_372_036_854_775_807)
            ],
        )
        let user = ApiTypeSchema.object(
            typeName: "User",
            properties: [
                .string("display_name", propertyName: "displayName"),
                .bool("active"),
                .double("score"),
                .ref("profile", of: profile),
                .ref("state", of: state),
                .ref("magnitude", of: magnitude),
                .date("created_at", propertyName: "createdAt"),
                .url("website"),
                .binary("payload"),
                .uuid("identifier"),
                .timelessDate("business_date", propertyName: "businessDate"),
                .time("business_time", propertyName: "businessTime"),
                .int64("id"),
                .uint64("count"),
                .int32("attempts")
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
                    ApiService(name: "Users", operations: [operation], references: [user, profile, address, state, magnitude])
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
        try run(["exec", "--", "node", "test.mjs"], in: root)
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
                    assert.equal(input.profile.address.streetName, "Main Street");
                    assert.equal(input.profile.address.verified, true);
                    assert.equal(input.profile.previousAddresses[0].streetName, "Old Street");
                    assert.equal(input.profile.previousAddresses[1].verified, true);
                    assert.deepEqual(input.profile.labels, { primary: "home", secondary: null, extra: "removed" });
                    assert.equal(input.profile.nickname, null);
                    assert.equal(input.state, "in-progress");
                    assert.equal(input.magnitude, 9223372036854775807n);
                    assert.equal(input.createdAt.toISOString(), "2026-09-21T12:34:56.789Z");
                    assert.equal(input.website.toString(), "https://example.com/path");
                    assert.deepEqual(Array.from(input.payload), [1, 2, 3]);
                    assert.equal(input.identifier, "550e8400-e29b-41d4-a716-446655440000");
                    assert.equal(input.businessDate, "2026-09-21");
                    assert.equal(input.businessTime, "12:34:56.789");
                    assert.equal(input.id, 9223372036854775807n);
                    assert.equal(input.count, 18446744073709551615n);
                    assert.equal(input.attempts, 12);
                }
                if (input.score === 1.6) {
                    assert.equal(input.createdAt.toISOString(), "2026-09-21T12:34:56.789Z");
                    assert.equal(input.website.toString(), "https://example.com/path");
                    assert.deepEqual(Array.from(input.payload), [1, 2, 3]);
                    assert.equal(input.id, -9223372036854775808n);
                    assert.equal(input.count, 0n);
                    assert.equal(input.attempts, -2147483648);
                }
                if (input.score === 1.8) {
                    assert.ok(input.magnitude === 1 || input.magnitude === 1n);
                }
                if (input.score === 1.7) {
                    assert.equal(input.profile.nickname, undefined);
                }
                if (input.score === 2) {
                    return { ...input, score: "invalid" };
                }
                if (input.score === 3) {
                    return { ...input, id: 9223372036854775808n };
                }
                if (input.score === 4) {
                    return { ...input, createdAt: new Date("invalid") };
                }
                if (input.score === 5) {
                    return { ...input, website: {} };
                }
                if (input.score === 6) {
                    return { ...input, identifier: "not-a-UUID" };
                }
                if (input.score === 7) {
                    return { ...input, payload: [] };
                }
                if (input.score === 8) {
                    return { ...input, state: "unknown" };
                }
                return { ...input, privateValue: "removed" };
            }
        });
        const server = await new Promise((resolve) => {
            const value = app.listen(0, () => resolve(value));
        });
        const port = server.address().port;
        const url = "http://127.0.0.1:" + port + "/users";
        const body = (score, id, count, attempts, magnitude = "9223372036854775807") =>
            `{"display_name":"Ada","active":true,"score":${score},"profile":{"address":{"street_name":"Main Street","verified":true,"extra":"removed"},"previous_addresses":[{"street_name":"Old Street","verified":false},{"street_name":"New Street","verified":true}],"labels":{"primary":"home","secondary":null,"extra":"removed"},"nickname":null,"extra":"removed"},"state":"in-progress","magnitude":${magnitude},"created_at":"2026-09-21T12:34:56.789Z","website":"https://example.com/path","payload":"AQID","identifier":"550e8400-e29b-41d4-a716-446655440000","business_date":"2026-09-21","business_time":"12:34:56.789","id":${id},"count":${count},"attempts":${attempts}}`;

        const valid = await fetch(url, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: body("1.5", "9223372036854775807", "18446744073709551615", "12").replace("}", ',"undeclared":"removed"}')
        });
        assert.equal(valid.status, 200);
        assert.equal(await valid.text(), '{"display_name":"Ada","active":true,"score":1.5,"profile":{"address":{"street_name":"Main Street","verified":true},"previous_addresses":[{"street_name":"Old Street","verified":false},{"street_name":"New Street","verified":true}],"labels":{"primary":"home","secondary":null,"extra":"removed"},"nickname":null},"state":"in-progress","magnitude":9223372036854775807,"created_at":"2026-09-21T12:34:56.789Z","website":"https://example.com/path","payload":"AQID","identifier":"550e8400-e29b-41d4-a716-446655440000","business_date":"2026-09-21","business_time":"12:34:56.789","id":9223372036854775807,"count":18446744073709551615,"attempts":12}');

        const omittedOptional = await fetch(url, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: body("1.7", "1", "1", "12").replace(',"nickname":null', "")
        });
        assert.equal(omittedOptional.status, 200);
        assert.equal(await omittedOptional.text(), '{"display_name":"Ada","active":true,"score":1.7,"profile":{"address":{"street_name":"Main Street","verified":true},"previous_addresses":[{"street_name":"Old Street","verified":false},{"street_name":"New Street","verified":true}],"labels":{"primary":"home","secondary":null,"extra":"removed"}},"state":"in-progress","magnitude":9223372036854775807,"created_at":"2026-09-21T12:34:56.789Z","website":"https://example.com/path","payload":"AQID","identifier":"550e8400-e29b-41d4-a716-446655440000","business_date":"2026-09-21","business_time":"12:34:56.789","id":1,"count":1,"attempts":12}');

        const safeIntegerEnum = await fetch(url, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: body("1.8", "1", "1", "12", 1)
        });
        assert.equal(safeIntegerEnum.status, 200);
        assert.equal(await safeIntegerEnum.text(), '{"display_name":"Ada","active":true,"score":1.8,"profile":{"address":{"street_name":"Main Street","verified":true},"previous_addresses":[{"street_name":"Old Street","verified":false},{"street_name":"New Street","verified":true}],"labels":{"primary":"home","secondary":null,"extra":"removed"},"nickname":null},"state":"in-progress","magnitude":1,"created_at":"2026-09-21T12:34:56.789Z","website":"https://example.com/path","payload":"AQID","identifier":"550e8400-e29b-41d4-a716-446655440000","business_date":"2026-09-21","business_time":"12:34:56.789","id":1,"count":1,"attempts":12}');

        const signedBoundary = await fetch(url, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: body("1.6", "-9223372036854775808", "0", "-2147483648")
        });
        assert.equal(signedBoundary.status, 200);
        assert.equal(await signedBoundary.text(), '{"display_name":"Ada","active":true,"score":1.6,"profile":{"address":{"street_name":"Main Street","verified":true},"previous_addresses":[{"street_name":"Old Street","verified":false},{"street_name":"New Street","verified":true}],"labels":{"primary":"home","secondary":null,"extra":"removed"},"nickname":null},"state":"in-progress","magnitude":9223372036854775807,"created_at":"2026-09-21T12:34:56.789Z","website":"https://example.com/path","payload":"AQID","identifier":"550e8400-e29b-41d4-a716-446655440000","business_date":"2026-09-21","business_time":"12:34:56.789","id":-9223372036854775808,"count":0,"attempts":-2147483648}');

        const invalidOutput = await fetch(url, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: body("2", "1", "1", "12")
        });
        assert.equal(invalidOutput.status, 500);

        const invalidWideOutput = await fetch(url, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: body("3", "1", "1", "12")
        });
        assert.equal(invalidWideOutput.status, 500);

        const invalidDateOutput = await fetch(url, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: body("4", "1", "1", "12")
        });
        assert.equal(invalidDateOutput.status, 500);

        const invalidUrlOutput = await fetch(url, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: body("5", "1", "1", "12")
        });
        assert.equal(invalidUrlOutput.status, 500);

        const invalidUUIDOutput = await fetch(url, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: body("6", "1", "1", "12")
        });
        assert.equal(invalidUUIDOutput.status, 500);

        const invalidBinaryOutput = await fetch(url, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: body("7", "1", "1", "12")
        });
        assert.equal(invalidBinaryOutput.status, 500);

        const invalidEnumOutput = await fetch(url, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: body("8", "1", "1", "12")
        });
        assert.equal(invalidEnumOutput.status, 500);

        const invalid = await fetch(url, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: body("1.5", "9223372036854775807", "18446744073709551615", "12").replace(',"attempts":12}', "}")
        });
        assert.equal(invalid.status, 400);
        assert.equal(handlerCalls, 11);

        const invalidDate = await fetch(url, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: body("1.5", "1", "1", "12").replace("2026-09-21T12:34:56.789Z", "not-a-date")
        });
        assert.equal(invalidDate.status, 400);

        const invalidCalendarDate = await fetch(url, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: body("1.5", "1", "1", "12").replace("2026-09-21", "2026-02-31")
        });
        assert.equal(invalidCalendarDate.status, 400);

        const invalidUrl = await fetch(url, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: body("1.5", "1", "1", "12").replace("https://example.com/path", "not a url")
        });
        assert.equal(invalidUrl.status, 400);

        const invalidUUID = await fetch(url, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: body("1.5", "1", "1", "12").replace("550e8400-e29b-41d4-a716-446655440000", "not-a-uuid")
        });
        assert.equal(invalidUUID.status, 400);

        const invalidBase64 = await fetch(url, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: body("1.5", "1", "1", "12").replace("AQID", "not-base64")
        });
        assert.equal(invalidBase64.status, 400);

        const invalidEnumInput = await fetch(url, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: body("1.5", "1", "1", "12").replace("in-progress", "unknown")
        });
        assert.equal(invalidEnumInput.status, 400);

        const missingRequiredEnum = await fetch(url, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: body("1.5", "1", "1", "12").replace(',"state":"in-progress"', "")
        });
        assert.equal(missingRequiredEnum.status, 400);

        const wrongEnumType = await fetch(url, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: body("1.5", "1", "1", "12").replace('"magnitude":9223372036854775807', '"magnitude":"9223372036854775807"')
        });
        assert.equal(wrongEnumType.status, 400);

        const negativeUnsigned = await fetch(url, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: body("1.5", "1", "-1", "12")
        });
        assert.equal(negativeUnsigned.status, 400);

        const tooLargeSigned = await fetch(url, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: body("1.5", "9223372036854775808", "1", "12")
        });
        assert.equal(tooLargeSigned.status, 400);

        const narrowOutOfRange = await fetch(url, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: body("1.5", "1", "1", "2147483648")
        });
        assert.equal(narrowOutOfRange.status, 400);

        const fractionalWide = await fetch(url, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: body("1.5", "1.5", "1", "12")
        });
        assert.equal(fractionalWide.status, 400);

        const malformed = await fetch(url, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: "{"
        });
        assert.equal(malformed.status, 400);
        assert.equal(handlerCalls, 11);

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
