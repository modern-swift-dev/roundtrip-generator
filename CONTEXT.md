# API Generation

This context describes a shared API contract and the generation targets that turn it into application-facing artifacts.

## Language

**Backend generation target**:
A reusable generation target for an API's routes, input and output schemas, and integration wiring. Business logic and persistence belong to the consuming application.
_Avoid_: Backend implementation generator

**Reference backend**:
An existing backend whose conventions and behavior define the compatibility requirements for a backend generation target. FutureNXL is the first reference backend.
_Avoid_: Generated backend

**Express backend target**:
The backend generation target that serves generated routes through Express.
_Avoid_: TypeScript backend (now ambiguous)

**Bun backend target**:
The backend generation target that serves generated routes through Bun's native HTTP server, without Express. Running the Express backend target on the Bun runtime is not the Bun backend target.
_Avoid_: Express on Bun

**Reference target**:
A backend generation target whose observable HTTP behavior defines the compatibility requirements for another backend generation target. The Express backend target is the reference target for the Bun backend target.
_Avoid_: Reference backend (that term names an existing backend, not a generation target)

**Backend compatibility**:
The ability to express and implement the reference backend's API capabilities, including payload mappings, input and output handling, and route parameters. Compatibility permits changes to application imports and integration wiring; it does not require identical generated source layout.
_Avoid_: Drop-in replacement

**Wire name**:
The name of a payload field or route parameter in the API contract as transmitted between client and server.
_Avoid_: DTO property name

**Mapped DTO**:
An API payload representation whose properties use the contract's mapped property names. Conversion to and from wire names belongs to generation; conversion to application domain or persistence models belongs to the application.
_Avoid_: Domain model

**Endpoint handler**:
An application-owned function that receives typed, validated endpoint input and returns an output value. Generated routes own input parsing and output validation and serialization. An endpoint handler is portable between the Express and Bun backend targets.
_Avoid_: Express controller
