import Foundation
@testable import SwiftVaporGenerator
import Testing

struct GeneratedDateParserTests {
    @Test func `cached date parsers preserve results under concurrent requests`() throws {
        let runtime = SwiftVaporRuntimeEmitter(sourceRoot: "Sources/App").file().contents
        let start = try #require(runtime.range(of: "public enum GeneratedRequestValueParser {"))
        let end = try #require(runtime.range(of: "public struct TimelessDate:"))
        let parser = String(runtime[start.lowerBound ..< end.lowerBound])
        let source = """
        import Foundation
        import Dispatch

        enum Status { case badRequest }
        struct Abort: Error {
            init(_ status: Status, reason: String) {}
        }
        public struct Time { public init(_ value: String) {} }

        \(parser)

        let samples = [
            "2026-09-05T12:30:45Z", "2026-09-05T12:30:45.123Z",
            "2026-09-05T12:30:45+02:00", "invalid", "", "2026-09-05"
        ]
        let standard = ISO8601DateFormatter()
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let expected = samples.map { standard.date(from: $0) ?? fractional.date(from: $0) }
        let dateOnly = DateFormatter()
        dateOnly.calendar = Calendar(identifier: .iso8601)
        dateOnly.locale = Locale(identifier: "en_US_POSIX")
        dateOnly.timeZone = TimeZone(secondsFromGMT: 0)
        dateOnly.dateFormat = "yyyy-MM-dd"
        dateOnly.isLenient = false
        let dateSamples = ["2024-02-29", "2025-02-29", "2026-09-05", "invalid", ""]
        let expectedDates = dateSamples.map { dateOnly.date(from: $0) }
        DispatchQueue.concurrentPerform(iterations: 500) { index in
            let i = index % samples.count
            let actual = try? GeneratedRequestValueParser.requiredDate(samples[i], name: "date")
            precondition(actual == expected[i])
            let j = index % dateSamples.count
            let actualDate = try? GeneratedRequestValueParser.requiredDateOnly(dateSamples[j], name: "date")
            precondition(actualDate == expectedDates[j])
        }
        let optionalDate = try GeneratedRequestValueParser.optionalDate(nil, name: "date")
        let optionalDateOnly = try GeneratedRequestValueParser.optionalDateOnly("", name: "date")
        precondition(optionalDate == nil)
        precondition(optionalDateOnly == nil)
        """
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("main.swift")
        try source.write(to: file, atomically: true, encoding: .utf8)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["swift", "-swift-version", "6", file.path]
        let errors = Pipe()
        process.standardError = errors
        try process.run()
        let diagnostics = errors.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        #expect(process.terminationStatus == 0, "\(String(bytes: diagnostics, encoding: .utf8) ?? "Invalid UTF-8 diagnostics")")
    }
}
