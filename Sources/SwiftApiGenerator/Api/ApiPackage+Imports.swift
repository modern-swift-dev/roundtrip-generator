import GeneratorModels

extension ApiPackage {
    /// Keep explicitly annotated imports while adding the Swift runtime dependencies.
    var swiftImports: [ApiImport] {
        (imports + ["Foundation", "RoundTrip", "RoundTripREST"]).swiftUniqueImports
    }
}

extension [ApiImport] {
    /// An explicit annotation takes precedence over an automatically added plain import.
    var swiftUniqueImports: [ApiImport] {
        var byName: [String: ApiImport] = [:]
        for value in self {
            if let existing = byName[value.name], existing.annotation != nil || value.annotation == nil {
                continue
            }
            byName[value.name] = value
        }
        return byName.values.sorted()
    }
}
