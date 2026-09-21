import express, { type Request } from "express";
import { z } from "zod";
import { createApp as createGeneratedApp } from "./app.js";
import { generatedResponse, GeneratedValidationError } from "./generated/runtime.js";
import type {
    GeneratedHandlers,
    GeneratedMultipartAdapterFactory,
    GeneratedRequestPolicy
} from "./generated/routes.js";

type RequestContext = { identity: string; order: string[] };
type Integration = { secured: GeneratedRequestPolicy<RequestContext> };
type UploadedPart = { filename?: string; contentType?: string; bytes: Uint8Array };
type Multipart = { futureProfilesUploadProfilePhoto: GeneratedMultipartAdapterFactory<UploadedPart> };

type DomainProfile = {
    id: string;
    firstName: string;
    biography?: string | null;
    createdAt: Date;
    privateGeometry: string;
    privatePaymentToken: string;
};

type ProfileFailure =
    | { status: 403; code: "FORBIDDEN" }
    | { status: 404; code: "PROFILE_NOT_FOUND" };

class ProfileError extends Error {
    constructor(readonly failure: ProfileFailure) {
        super(failure.code);
    }
}

class UploadError extends Error {}

const profileInput = z.object({
    profileId: z.uuid(),
    fields: z.array(z.enum(["biography", "omit-biography", "invalid-output", "missing"])).optional(),
    apiKey: z.string()
});
const profileOutput = z.object({
    id: z.string(),
    firstName: z.string(),
    biography: z.string().nullable().optional(),
    createdAt: z.date(),
    privateGeometry: z.string(),
    privatePaymentToken: z.string()
}).transform((value) => ({
    id: value.id,
    firstName: value.firstName,
    biography: value.biography,
    createdAt: value.createdAt
}));

const ledgerEntry = z.object({
    entryName: z.string(),
    amount: z.bigint(),
    capturedAt: z.date(),
    evidence: z.instanceof(Uint8Array)
});
const ledgerInput = z.object({
    profileId: z.uuid(),
    apiKey: z.string(),
    body: z.object({ entries: z.array(ledgerEntry), totals: z.record(z.string(), z.bigint()) })
}).transform((value) => ({
    profileId: value.profileId,
    entries: value.body.entries,
    totals: value.body.totals,
    privateBalance: value.body.entries.reduce((sum, entry) => sum + entry.amount, 0n)
}));
const ledgerOutput = z.object({
    profileId: z.string(),
    entries: z.array(ledgerEntry),
    totals: z.record(z.string(), z.bigint()),
    privateBalance: z.bigint()
}).transform((value) => ({ entries: value.entries, totals: value.totals }));

export const bindings = {
    futureProfilesGetProfile: { input: profileInput, output: profileOutput },
    futureProfilesProcessLedger: { input: ledgerInput, output: ledgerOutput }
};

const requestOrder = new WeakMap<Request, string[]>();
export const integration: Integration = {
    secured: {
        middleware: [(request, response, next) => {
            requestOrder.set(request, ["auth"]);
            if (request.get("authorization") !== "Bearer future-user") {
                response.status(401).json({ code: "AUTH_REQUIRED" });
                return;
            }
            next();
        }],
        context: (request) => {
            const order = requestOrder.get(request) ?? [];
            order.push("context");
            return { identity: "future-user", order };
        }
    }
};

function parseMultipart(request: Request): ReadonlyMap<string, readonly UploadedPart[]> {
    const contentType = request.get("content-type") ?? "";
    const boundaryMatch = /boundary=(?:"([^"]+)"|([^;]+))/.exec(contentType);
    if (!boundaryMatch || !(request.body instanceof Uint8Array)) {
        throw new UploadError("Missing multipart body or boundary");
    }
    const boundary = boundaryMatch[1] ?? boundaryMatch[2];
    const source = Buffer.from(request.body).toString("latin1");
    const parts = new Map<string, UploadedPart[]>();
    for (let section of source.split(`--${boundary}`).slice(1)) {
        if (section.startsWith("--")) break;
        if (section.startsWith("\r\n")) section = section.slice(2);
        if (section.endsWith("\r\n")) section = section.slice(0, -2);
        const separator = section.indexOf("\r\n\r\n");
        if (separator < 0) continue;
        const headers = section.slice(0, separator);
        const disposition = /content-disposition:\s*form-data;([^\r\n]*)/i.exec(headers)?.[1] ?? "";
        const name = /(?:^\s*|;\s*)name="([^"]+)"/i.exec(disposition)?.[1];
        if (!name) continue;
        const filename = /(?:^\s*|;\s*)filename="([^"]*)"/i.exec(disposition)?.[1];
        const partContentType = /content-type:\s*([^\r\n]+)/i.exec(headers)?.[1];
        const part: UploadedPart = {
            filename: filename || undefined,
            contentType: partContentType,
            bytes: Uint8Array.from(Buffer.from(section.slice(separator + 4), "latin1"))
        };
        parts.set(name, [...(parts.get(name) ?? []), part]);
    }
    return parts;
}

export const multipart: Multipart = {
    futureProfilesUploadProfilePhoto: ({ id, requiredParts }) => {
        if (id !== "Future.Profiles.UploadProfilePhoto" || requiredParts.join(",") !== "file,metadata") {
            throw new Error("Unexpected multipart operation metadata");
        }
        return {
            middleware: [
                express.raw({ type: "multipart/form-data", limit: "1mb" }),
                (request, _response, next) => {
                    requestOrder.get(request)?.push("upload");
                    next();
                }
            ],
            read: (request) => {
                const parts = parseMultipart(request);
                if (parts.get("file")?.[0]?.contentType !== "image/png") {
                    throw new UploadError("Only PNG profile photos are accepted");
                }
                return parts;
            }
        };
    }
};

export const handlers: GeneratedHandlers<typeof bindings, Integration, Multipart> = {
    futureProfilesGetProfile: async (input, context) => {
        if (context.identity !== "future-user") throw new ProfileError({ status: 403, code: "FORBIDDEN" });
        if (input.fields?.includes("missing")) throw new ProfileError({ status: 404, code: "PROFILE_NOT_FOUND" });
        return generatedResponse<DomainProfile>({
            id: input.fields?.includes("invalid-output") ? "not-a-uuid" : input.profileId,
            firstName: "Ada",
            biography: input.fields?.includes("omit-biography") ? undefined : null,
            createdAt: new Date("2026-09-21T12:34:56Z"),
            privateGeometry: "POLYGON(private)",
            privatePaymentToken: "payment-secret"
        }, { status: 200, headers: { "x-profile-owner": context.identity } });
    },
    futureProfilesPatchProfile: async (input) => input.body,
    futureProfilesUploadProfilePhoto: async (input, context) => {
        context.order.push("handler");
        const file = input.body.required.file[0];
        const metadata = input.body.required.metadata[0];
        if (new TextDecoder().decode(metadata.bytes) !== "profile") {
            throw new UploadError("Invalid profile metadata");
        }
        return generatedResponse({ profileId: input.profileId, byteCount: file.bytes.length }, {
            status: 201,
            headers: { "x-profile-owner": context.identity, "x-middleware-order": context.order.join(",") }
        });
    },
    futureProfilesProcessLedger: async (input, context) => {
        if (context.identity !== "future-user") throw new ProfileError({ status: 403, code: "FORBIDDEN" });
        return input;
    },
    futureProfilesRawReceipts: async (input) => input
};

export function createApp() {
    const app = createGeneratedApp(handlers, bindings, { integration, multipart });
    app.use((error: unknown, _request: Request, response: express.Response, _next: express.NextFunction) => {
        if (error instanceof ProfileError) {
            response.status(error.failure.status).json({ code: error.failure.code });
            return;
        }
        if (error instanceof UploadError) {
            response.status(415).json({ code: "UPLOAD_REJECTED" });
            return;
        }
        if (error instanceof GeneratedValidationError) {
            response.status(error.phase === "input" ? 400 : 500).json({ code: `GENERATED_${error.phase.toUpperCase()}` });
            return;
        }
        response.status(500).json({ code: "UNEXPECTED" });
    });
    return app;
}
