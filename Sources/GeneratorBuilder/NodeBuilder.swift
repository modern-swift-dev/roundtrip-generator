import Foundation

/// A block node builder, which will add a new line between each sub-node
@resultBuilder public struct NodeBuilder {

    private static func makeNodeList(components: [any NodeConvertible]) -> any Node {
        NodeList(components.map { $0.asNode() })
    }

    public static func buildBlock(_ components: any NodeConvertible...) -> any Node {
        makeNodeList(components: components)
    }

    public static func buildBlock(_ component: any NodeConvertible) -> any Node {
        component.asNode()
    }

    public static func buildOptional(_ component: (any NodeConvertible)?) -> any Node {
        guard let component else {
            return NodeList([])
        }
        return component.asNode()
    }

    public static func buildEither(first component: any NodeConvertible) -> any Node {
        component.asNode()
    }

    public static func buildEither(second component: any NodeConvertible) -> any Node {
        component.asNode()
    }

    public static func buildLimitedAvailability(_ component: any NodeConvertible) -> any Node {
        component.asNode()
    }

    public static func buildArray(_ components: [any Node]) -> any Node {
        makeNodeList(components: components)
    }

    public static func buildExpression(_ expression: any NodeConvertible) -> any Node {
        expression.asNode()
    }

    public static func buildExpression(_ expression: any Node) -> any Node {
        expression
    }

    public static func buildFinalResult(_ component: any Node) -> any Node {
        component
    }

    public static func buildFinalResult(_ component: any NodeConvertible) -> any Node {
        component.asNode()
    }
}
