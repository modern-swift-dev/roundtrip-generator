import Foundation

/// A type that can be converted into a ``Node``.
public protocol NodeConvertible {
    func asNode() -> any Node
}

/// A renderable text node that can be converted to a string or written to disk.
public protocol Node: NodeConvertible {
    /// Builds the node into its string representation.
    func toString() -> String

    /// Writes the rendered string to disk at the specified URL.
    func write(to: URL) throws
}

/// Default node behavior.
public extension Node {
    /// Writes the rendered string to disk.
    func write(to file: URL) throws {
        let data = toString().data(using: .utf8)
        try data?.write(to: file, options: [.atomic])
    }

    /// Returns this value as a node.
    func asNode() -> any Node {
        self
    }
}

/// A node whose content is declared with a ``NodeBuilder`` body.
public protocol BodyNode: Node {
    @NodeBuilder var body: any Node { get }
}

/// Default rendering for body-backed nodes.
public extension BodyNode {
    func toString() -> String {
        body.toString()
    }
}

/// Allows arrays of nodes to be used as node-builder output.
extension Array: NodeConvertible where Element: Node {
    public func asNode() -> any Node {
        NodeList(self)
    }
}
