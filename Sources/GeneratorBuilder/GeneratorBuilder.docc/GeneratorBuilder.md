# ``GeneratorBuilder``

Build formatted text from small composable nodes.

## Overview

`GeneratorBuilder` provides the low-level primitives used by the API generator to assemble Swift source files. Types conforming to ``Node`` can render themselves as strings and write those strings to disk.

Use ``Block`` when child nodes should be separated by newlines, ``Line`` when child nodes should be joined by spaces, and ``Concat`` when child nodes should be joined without separators.

```swift
let source = Block {
    "struct User {"
    Indentation {
        Line {
            "let"
            "name:"
            "String"
        }
    }
    "}"
}

source.toString()
```

## Topics

### Core Protocols

- ``Node``
- ``NodeConvertible``
- ``BodyNode``

### Nodes

- ``Block``
- ``Indentation``
- ``Line``
- ``Concat``
- ``NewLine``
- ``TextNode``
- ``NodeList``
