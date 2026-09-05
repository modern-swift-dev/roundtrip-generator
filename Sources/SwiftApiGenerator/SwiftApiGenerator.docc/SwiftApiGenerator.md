# ``SwiftApiGenerator``

Validate `GeneratorModels` descriptions and generate Swift REST client source files.

## Overview

`SwiftApiGenerator` takes an ``GeneratorModels/ApiPackage`` and writes generated Swift files to the package's `targetDirUrl`.

Use ``ApiGeneratorTool`` as the public entry point:

```swift
import SwiftApiGenerator

let tool = ApiGeneratorTool(package: package)
tool.execute([])
```

Before writing, the generator validates duplicate data-type definitions and operation-level model references. When `targetDirUrl` already exists, its contents are deleted before the new generated files are written.

The generator writes source files only. The generated project's `Package.swift` and external dependencies remain the caller's responsibility.

## Topics

### Entry Point

- ``ApiGeneratorTool``
