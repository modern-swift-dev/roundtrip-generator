---
status: accepted
---

# Preserve wide integers with bigint and lossless JSON

Use TypeScript `bigint` for exact 64-bit integer handling rather than limiting the backend to JavaScript's safe `number` range. Generated input parsing and output serialization must preserve numeric values on the wire using lossless JSON handling; converting integer values to JSON strings would change the shared API contract.

Map Swift `Int`, `UInt`, `Int64`, and `UInt64` to TypeScript `bigint`. Narrower integer types and floating-point values use `number`, with the declared integer ranges validated.

Integration must parse these request bodies before an ordinary JSON parser can lose precision and serialize output without converting wide integers to `number`. Existing application bootstrap code may need to change its parser wiring.

## Implementation

Implemented by the generated `lossless-json` runtime and `bigint` model codecs, with range validation for narrower integers and exact wire-preserving serialization. The generator suite covers integer boundaries, enum precision, and root numeric bodies; issue #2 is closed.
