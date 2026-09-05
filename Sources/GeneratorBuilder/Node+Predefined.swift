import Foundation

/// A flattened list of child nodes, mostly used as an internal builder structure.
public struct NodeList: Node {
    public var children: [any Node]

    public init(_ children: [any Node]) {
        self.children = children.flatten()
    }

    public func toString() -> String {
        var result = ""
        for child in children {
            result += child.toString()
        }
        return result
    }

    public func asNode() -> any Node {
        self
    }
}

/// Flattens nested ``NodeList`` values inside node arrays.
public extension [Node] {

    func flatten() -> [any Node] {
        var result: [any Node] = []
        result.reserveCapacity(count)
        for item in self {
            if let childList = item as? NodeList {
                result.append(contentsOf: childList.children)
            } else {
                result.append(item)
            }
        }
        return result
    }

}

/// A node that renders a literal string.
public struct TextNode: Node {
    public var text: String

    public init(value text: String) {
        self.text = text
    }

    public func toString() -> String {
        text
    }

    public func asNode() -> any Node {
        self
    }
}

/// Allows string literals to be used as nodes.
extension String: Node {
    public func toString() -> String {
        self
    }

    public func asNode() -> any Node {
        TextNode(value: self)
    }
}

/// A node that joins child nodes with newlines.
public struct Block: Node {

    /// The block content.
    public let content: any Node

    /// Creates a block with a ``NodeBuilder`` closure.
    public init(@NodeBuilder _ nodeBuilder: () -> any Node) {
        content = nodeBuilder()
    }

    public func toString() -> String {
        var result = ""
        if let list = content as? NodeList {
            let childrenText = list.children.flatten().map { item -> String in
                let value = item.toString()
                if value == "\n" {
                    return ""
                }
                return value
            }

            result = childrenText.joined(separator: "\n")
        } else {
            result = content.toString()
        }

        if result == "\n" {
            result = ""
        }

        return result
    }
}

/// A node that joins child nodes with newlines and indents every rendered line.
public struct Indentation: Node {

    /// The content to indent.
    public let content: any Node

    /// Creates an indentation block with a ``NodeBuilder`` closure.
    public init(@NodeBuilder _ nodeBuilder: () -> any Node) {
        content = nodeBuilder()
    }

    /// Renders the indented content.
    public func toString() -> String {
        var text = ""
        if let list = content as? NodeList {
            let childrenText = list.children.flatten().map { item -> String in
                let value = item.toString()
                if value == "\n" {
                    return ""
                }
                return value
            }

            let result = childrenText.joined(separator: "\n")
            text = result
        } else {
            text = content.toString()
        }

        if text == "\n" {
            text = ""
        }

        return text.prepad(1)
    }
}

/// A node that joins child nodes with a single space.
public struct Line: Node {
    public let content: any Node

    public init(@NodeBuilder _ nodeBuilder: () -> any Node) {
        content = nodeBuilder()
    }

    public func toString() -> String {
        var text = ""
        if let list = content as? NodeList {
            let childrenText = list.children.flatten().map { $0.toString() }
            text = childrenText.joined(separator: " ")
        } else {
            text = content.toString()
        }
        return text
    }
}

/// A node that joins child nodes without a separator.
public struct Concat: Node {
    public let content: any Node

    public init(@NodeBuilder _ nodeBuilder: () -> any Node) {
        content = nodeBuilder()
    }

    public func toString() -> String {
        var text = ""
        if let list = content as? NodeList {
            let childrenText = list.children.flatten().map { $0.toString() }
            text = childrenText.joined(separator: "")
        } else {
            text = content.toString()
        }
        return text
    }
}

/// An empty node that creates a blank line inside a ``Block``.
public struct NewLine: Node {
    public init() {}

    public func toString() -> String {
        "\n"
    }
}
