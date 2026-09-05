import Foundation
import GeneratorBuilder
import GeneratorModels

struct ApiOperationValidator {
    let operation: ApiOperation

    func validate() throws {
        let expandedParameters = operation.expandedParameters
        let paramNames = expandedParameters.map(\.propertyName)
        if Set(paramNames).count != paramNames.count {
            throw ApiValidationError.failed("Duplicate parameter found in operation \(operation.name)")
        }

        let wireNames = expandedParameters.map {
            let rawName = $0.location == .header ? $0.rawName.lowercased() : $0.rawName
            return "\($0.location.rawValue):\(rawName)"
        }
        if Set(wireNames).count != wireNames.count {
            throw ApiValidationError.failed("Duplicate parameter found in operation \(operation.name)")
        }

        let reservedGeneratedNames = generatedRequestMemberNames(parameters: expandedParameters)
        let generatedNameCollisions = Set(paramNames).intersection(reservedGeneratedNames)
        if !generatedNameCollisions.isEmpty {
            throw ApiValidationError.failed("Operation \(operation.name) has parameter names that collide with generated request members: \(generatedNameCollisions.sorted())")
        }

        if expandedParameters.contains(where: { $0.location == .cookie }),
           expandedParameters.contains(where: { $0.location == .header && $0.rawName.caseInsensitiveCompare("Cookie") == .orderedSame }) {
            throw ApiValidationError.failed("Operation \(operation.name) cannot combine Cookie header parameters with cookie parameters")
        }

        guard !operation.acceptableStatuses.isEmpty else {
            throw ApiValidationError.failed("Operation \(operation.name) must have at least one acceptable status")
        }

        guard operation.acceptableStatuses.allSatisfy({ 100 ... 599 ~= $0 }) else {
            throw ApiValidationError.failed("Operation \(operation.name) has invalid acceptable status")
        }

        if operation.response.swiftDecodableDataType != nil {
            let decodableStatuses = operation.acceptableStatuses.filter(Self.statusCodeCanCarryResponseBody)
            guard !decodableStatuses.isEmpty else {
                throw ApiValidationError.failed("Operation \(operation.name) has a typed response but no acceptable status can carry a response body")
            }
        }

        for param in expandedParameters {
            try param.validate()
        }

        try validateURL(parameters: expandedParameters)
        try operation.request.validate()
        try operation.response.validate()
    }

    private static func statusCodeCanCarryResponseBody(_ statusCode: Int) -> Bool {
        !(100 ..< 200 ~= statusCode || statusCode == 204 || statusCode == 205 || statusCode == 304)
    }

    private func generatedRequestMemberNames(parameters: [ApiParameter]) -> Set<String> {
        var names: Set = [
            "buildRequest",
            "requestPath"
        ]
        if operationDeclaresBody {
            names.insert("body")
        }
        if parameters.contains(where: { $0.location == .query }) {
            names.insert("queryParameters")
        }
        if parameters.contains(where: { $0.location == .header || $0.location == .cookie }) {
            names.insert("httpHeaders")
        }
        if parameters.contains(where: { $0.location == .cookie }) {
            names.insert("httpCookies")
        }
        if operation.request.isMultipart {
            names.insert("multiPartBody")
            for partName in operation.request.multiPartNames {
                names.insert("setBodyPart\(partName.capitalCased)")
            }
        }
        return names
    }

    private var operationDeclaresBody: Bool {
        switch operation.request {
            case .binary,
                 .file,
                 .multiPart:
                true
            case let .json(type):
                type != nil
            case .none:
                false
        }
    }

    private func validateURL(parameters: [ApiParameter]) throws {
        switch operation.path {
            case let .relative(path):
                try validatePathPlaceholders(
                    path: path,
                    parameters: parameters,
                    allowedRange: pathComponentRange(inRelativePath: path),
                )
                var effectivePath = ""
                if path.starts(with: "/") {
                    effectivePath = path
                } else {
                    effectivePath = "/" + path
                }

                if !effectivePath.starts(with: "/") {
                    effectivePath = "/\(effectivePath)"
                }

                for param in parameters.filter({ $0.location == .path }) {
                    effectivePath = effectivePath.replacingOccurrences(
                        of: "{\(param.rawName)}",
                        with: "value",
                    )
                }

                guard URL(string: "https://localhost.com\(effectivePath)") != nil else {
                    throw ApiValidationError.failed("Invalid relative url: \(path)")
                }
            case let .absolute(path):
                try validatePathPlaceholders(
                    path: path,
                    parameters: parameters,
                    allowedRange: pathComponentRange(inAbsolutePath: path),
                )
                var effectivePath = path
                for param in parameters.filter({ $0.location == .path }) {
                    effectivePath = effectivePath.replacingOccurrences(
                        of: "{\(param.rawName)}",
                        with: "value",
                    )
                }
                guard let url = URL(string: effectivePath),
                      let scheme = url.scheme,
                      !scheme.isEmpty,
                      let host = url.host,
                      !host.isEmpty else {
                    throw ApiValidationError.failed("Invalid absolute url: \(path)")
                }
            case .runtime:
                guard parameters.allSatisfy({ $0.location != .path }) else {
                    throw ApiValidationError.failed("Runtime urls cannot use path parameters in operation \(operation.name)")
                }
        }
    }

    private func validatePathPlaceholders(path: String, parameters: [ApiParameter], allowedRange: Range<String.Index>) throws {
        let placeholders = try pathPlaceholders(in: path)
        guard placeholders.allSatisfy({ placeholder in
            allowedRange.lowerBound <= placeholder.range.lowerBound && placeholder.range.upperBound <= allowedRange.upperBound
        }) else {
            throw ApiValidationError.failed("Path parameters do not match url placeholders in operation \(operation.name)")
        }

        let pathParameters = parameters.filter { $0.location == .path }
        guard pathParameters.allSatisfy(\.isRequired) else {
            throw ApiValidationError.failed("Path parameters must be required in operation \(operation.name)")
        }

        let pathParameterNames = pathParameters.map(\.rawName)
        let placeholderNames = placeholders.map(\.name)
        guard Set(placeholderNames) == Set(pathParameterNames),
              placeholderNames.count == Set(placeholderNames).count,
              pathParameterNames.count == Set(pathParameterNames).count else {
            throw ApiValidationError.failed("Path parameters do not match url placeholders in operation \(operation.name)")
        }
    }

    private func pathPlaceholders(in path: String) throws -> [(name: String, range: Range<String.Index>)] {
        var placeholders: [(name: String, range: Range<String.Index>)] = []
        var current: String?
        var startIndex: String.Index?

        for index in path.indices {
            let character = path[index]
            if character == "{" {
                guard current == nil else {
                    throw ApiValidationError.failed("Path parameters do not match url placeholders in operation \(operation.name)")
                }
                current = ""
                startIndex = index
            } else if character == "}" {
                guard let value = current, !value.isEmpty, let placeholderStartIndex = startIndex else {
                    throw ApiValidationError.failed("Path parameters do not match url placeholders in operation \(operation.name)")
                }
                placeholders.append((value, placeholderStartIndex ..< path.index(after: index)))
                current = nil
                startIndex = nil
            } else if current != nil {
                current?.append(character)
            }
        }

        if current != nil {
            throw ApiValidationError.failed("Path parameters do not match url placeholders in operation \(operation.name)")
        }

        return placeholders
    }

    private func pathComponentRange(inRelativePath path: String) -> Range<String.Index> {
        let end = firstPathBoundary(in: path, from: path.startIndex)
        return path.startIndex ..< end
    }

    private func pathComponentRange(inAbsolutePath path: String) -> Range<String.Index> {
        guard let schemeRange = path.range(of: "://") else {
            return path.startIndex ..< path.startIndex
        }
        let authorityStart = schemeRange.upperBound
        let delimiters: [(index: String.Index, startsPath: Bool)] = [
            path[authorityStart...].firstIndex(of: "/").map { (index: $0, startsPath: true) },
            path[authorityStart...].firstIndex(of: "?").map { (index: $0, startsPath: false) },
            path[authorityStart...].firstIndex(of: "#").map { (index: $0, startsPath: false) }
        ]
        .compactMap(\.self)
        .sorted { $0.index < $1.index }

        guard let firstDelimiter = delimiters.first else {
            return path.endIndex ..< path.endIndex
        }
        guard firstDelimiter.startsPath else {
            return firstDelimiter.index ..< firstDelimiter.index
        }

        let pathStart = firstDelimiter.index
        let pathEnd = firstPathBoundary(in: path, from: pathStart)
        return pathStart ..< pathEnd
    }

    private func firstPathBoundary(in path: String, from start: String.Index) -> String.Index {
        let queryIndex = path[start...].firstIndex(of: "?")
        let fragmentIndex = path[start...].firstIndex(of: "#")
        return [queryIndex, fragmentIndex].compactMap(\.self).min() ?? path.endIndex
    }
}
