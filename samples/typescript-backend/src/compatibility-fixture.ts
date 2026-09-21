import { z } from "zod";
import type { GeneratedHandlers, GeneratedSchemaBindings } from "./generated/routes.js";
import { bindings, handlers, integration, multipart } from "./server.js";

type Handlers = GeneratedHandlers<typeof bindings, typeof integration, typeof multipart>;

const checkedHandlers: Handlers = handlers;

const profileHandler: Handlers["futureProfilesGetProfile"] = async (input, context) => ({
    id: input.profileId,
    firstName: context.identity,
    biography: null,
    createdAt: new Date("2026-09-21T12:34:56Z"),
    privateGeometry: "private",
    privatePaymentToken: "private"
});

const ledgerHandler: Handlers["futureProfilesProcessLedger"] = async (input) => {
    const amount: bigint = input.entries[0]?.amount ?? 0n;
    // @ts-expect-error transformed wide integers remain bigint
    const invalidAmount: number = amount;
    void invalidAmount;
    return input;
};

const uploadHandler: Handlers["futureProfilesUploadProfilePhoto"] = async (input) => {
    const bytes: Uint8Array = input.body.required.file[0].bytes;
    // @ts-expect-error multipart adapter values retain their application-owned part type
    const invalidBytes: string = bytes;
    void invalidBytes;
    return { profileId: input.profileId, byteCount: bytes.length };
};

// @ts-expect-error profile output bindings reject incompatible private application values
const incompatibleProfileHandler: Handlers["futureProfilesGetProfile"] = async () => ({
    id: "550E8400-E29B-41D4-A716-446655440000",
    firstName: "Ada",
    createdAt: new Date("2026-09-21T12:34:56Z"),
    privateGeometry: "private",
    privatePaymentToken: 42
});

const incompatibleProfileBinding: GeneratedSchemaBindings = {
    futureProfilesGetProfile: {
        // @ts-expect-error transformed output must match the declared Profile response
        output: z.string().transform((value) => ({ wrong: value }))
    }
};

void checkedHandlers;
void profileHandler;
void ledgerHandler;
void uploadHandler;
void incompatibleProfileHandler;
void incompatibleProfileBinding;
