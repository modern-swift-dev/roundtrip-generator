import Foundation
import GeneratorBuilder

public class ApiTypeNameResolver: @unchecked Sendable {

    public static let shared: ApiTypeNameResolver = .init()

    private let lock = NSRecursiveLock()
    private struct Scope {
        var namesByID: [UUID: String] = [:]
        var namesByValue: [ApiTypeSchema: String] = [:]

        init(_ values: [ApiTypeSchema: String]) {
            for (type, name) in values {
                if let id = type.uuid {
                    // Preserve the first UUID match in this scope, including aliases.
                    if namesByID[id] == nil {
                        namesByID[id] = name
                    }
                } else {
                    namesByValue[type] = name
                }
            }
        }
    }

    private var stack: [Scope] = []

    public func push(module: String, types: [ApiTypeSchema]) {
        var globalNames: [ApiTypeSchema: String] = [:]
        for ref in types {
            if let typeName = ref.typeName, !typeName.isEmpty {
                let swiftTypeName = typeName.swiftTypeName
                if !module.isEmpty {
                    globalNames[ref] = "\(module).\(swiftTypeName)"
                } else {
                    globalNames[ref] = swiftTypeName
                }
            }
        }
        push(globalNames)
    }

    public func push(_ values: [ApiTypeSchema: String]) {
        lock.withLock {
            stack.append(Scope(values))
        }
    }

    public func withExclusiveAccess<T>(_ work: () throws -> T) rethrows -> T {
        try lock.withLock {
            try work()
        }
    }

    public func pop() {
        lock.withLock {
            guard !stack.isEmpty else {
                return
            }
            stack.removeLast()
        }
    }

    public func clear() {
        lock.withLock {
            stack.removeAll()
        }
    }

    public func scopedName(for dataType: ApiTypeSchema) -> String? {
        lock.withLock {
            let id = dataType.referenceUUID ?? dataType.uuid
            for scope in stack.reversed() {
                if let id, let name = scope.namesByID[id] {
                    return name
                }
                if dataType.uuid == nil, let name = scope.namesByValue[dataType] {
                    return name
                }
            }
            return nil
        }
    }

    public func name(for dataType: ApiTypeSchema) -> String? {
        scopedName(for: dataType) ?? dataType.typeName
    }
}
