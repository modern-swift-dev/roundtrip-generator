// Generated code. Do not edit.

import express, { type Express, type Request, type RequestHandler, type Response } from "express";
import { z } from "zod";
import {
    base64ToUint8Array,
    isValidBase64,
    isValidCalendarDate,
    isValidISODate,
    isValidLocalTime,
    isValidURL,
    isValidUUID,
    parseParameterArray,
    parseParameterBigInt,
    parseParameterBoolean,
    parseParameterDate,
    parseParameterDateTime,
    parseParameterInteger,
    parseParameterNarrowInteger,
    parseParameterString,
    parseParameterTime,
    parseDate,
    parseDouble,
    parseJsonBody,
    parseNarrowInteger,
    parseURL,
    readRequestParameter,
    generatedResponseHasBody,
    normalizeGeneratedResponse,
    serializeDate,
    serializeURL,
    stringifyJsonResponse,
    validateGeneratedResponseStatus,
    uint8ArrayToBase64
} from "./runtime.js";
import { GeneratedValidationError, type GeneratedResponse } from "./runtime.js";
import {
    decodeLedgerBatch,
    decodePhotoReceipt,
    decodeProfile,
    decodeProfilePatch,
    encodeLedgerBatch,
    encodePhotoReceipt,
    encodeProfile,
    encodeProfilePatch,
    type LedgerBatch,
    type PhotoReceipt,
    type Profile,
    type ProfilePatch
} from "./models.js";

export type GeneratedSchemaBinding<Output = unknown, Input = unknown> = z.ZodType<Output, Input>;

export interface GeneratedOperationBinding<HandlerInput = unknown, HandlerOutput = unknown, WireOutput = unknown> {
    input?: GeneratedSchemaBinding<HandlerInput>;
    output?: GeneratedSchemaBinding<WireOutput, HandlerOutput>;
}

export type GeneratedMaybePromise<Value> = Value | Promise<Value>;

export interface GeneratedRequestPolicy<Context = unknown> {
    readonly middleware?: readonly RequestHandler[];
    context(request: Request, response: Response): GeneratedMaybePromise<Context>;
}

export interface GeneratedRequestIntegration {
    readonly secured?: GeneratedRequestPolicy;
    readonly optional?: GeneratedRequestPolicy;
    readonly unsecured?: GeneratedRequestPolicy;
}

export type GeneratedHandlerContext<Integration, Policy extends keyof GeneratedRequestIntegration> =
    Policy extends keyof Integration
        ? Integration[Policy] extends GeneratedRequestPolicy<infer Context> ? Context : undefined
        : undefined;

export interface GeneratedMultipartOperation {
    readonly id: string;
    readonly requiredParts: readonly string[];
}

export interface GeneratedMultipartAdapter<Part = unknown> {
    readonly middleware: readonly RequestHandler[];
    read(request: Request, response: Response): GeneratedMaybePromise<ReadonlyMap<string, readonly Part[]>>;
}

export type GeneratedMultipartAdapterFactory<Part = unknown> =
    (operation: GeneratedMultipartOperation) => GeneratedMultipartAdapter<Part>;

export interface GeneratedMultipartAdapters {
    futureProfilesUploadProfilePhoto?: GeneratedMultipartAdapterFactory;
}

export type GeneratedMultipartAdapterPart<Factory> =
    NonNullable<Factory> extends GeneratedMultipartAdapterFactory<infer Part> ? Part : never;

export type GeneratedMultipartBody<Part, RequiredPart extends string> = {
    readonly parts: ReadonlyMap<string, readonly Part[]>;
    readonly required: { readonly [Name in RequiredPart]: readonly [Part, ...Part[]] };
};

function generatedRequiredMultipartPart<Part>(parts: ReadonlyMap<string, readonly Part[]>, name: string): readonly [Part, ...Part[]] {
    const values = parts.get(name);
    if (!values || values.length === 0) {
        throw new Error(`Missing multipart part: ${name}`);
    }
    return values as readonly [Part, ...Part[]];
}

export interface GeneratedRouteOptions<Integration extends GeneratedRequestIntegration = {}, Multipart extends GeneratedMultipartAdapters = {}> {
    jsonBodyParser?: RequestHandler;
    rawBodyParser?: RequestHandler;
    integration?: Integration;
    multipart?: Multipart;
}

const generatedRequestContexts = new WeakMap<Request, unknown>();

function generatedRequestContextMiddleware(policy: GeneratedRequestPolicy | undefined): RequestHandler {
    return async (request, response, next) => {
        try {
            const context = policy ? await policy.context(request, response) : undefined;
            if (response.headersSent || response.writableEnded) {
                return;
            }
            generatedRequestContexts.set(request, context);
            next();
        } catch (error) {
            next(error);
        }
    };
}

function generatedRequestContext<Context>(request: Request): Context {
    return generatedRequestContexts.get(request) as Context;
}

export interface GeneratedSchemaBindings {
    futureProfilesGetProfile?: GeneratedOperationBinding<unknown, unknown, Profile>;
    futureProfilesPatchProfile?: GeneratedOperationBinding<unknown, unknown, ProfilePatch>;
    futureProfilesUploadProfilePhoto?: GeneratedOperationBinding<unknown, unknown, PhotoReceipt>;
    futureProfilesProcessLedger?: GeneratedOperationBinding<unknown, unknown, LedgerBatch>;
    futureProfilesRawReceipts?: GeneratedOperationBinding<unknown, unknown, unknown>;
}

export type GeneratedHandlerInput<Binding, Default> = Binding extends { input?: infer Schema }
    ? NonNullable<Schema> extends z.ZodTypeAny ? z.output<NonNullable<Schema>> : Default
    : Default;

export type GeneratedHandlerValue<Binding, Default> = Binding extends { output?: infer Schema }
    ? NonNullable<Schema> extends z.ZodTypeAny ? z.input<NonNullable<Schema>> | Promise<z.input<NonNullable<Schema>>> : Default | Promise<Default>
    : Default | Promise<Default>;

export type GeneratedHandlerOutput<Binding, Default> = GeneratedHandlerValue<Binding, Default>
    | GeneratedResponse<Awaited<GeneratedHandlerValue<Binding, Default>>>
    | Promise<GeneratedResponse<Awaited<GeneratedHandlerValue<Binding, Default>>> | Awaited<GeneratedHandlerValue<Binding, Default>>>;

export type GeneratedWireOutput<Binding, Default> = Binding extends { output?: infer Schema }
    ? NonNullable<Schema> extends z.ZodTypeAny ? z.output<NonNullable<Schema>> : Default
    : Default;

export interface FutureProfilesGetProfileInput {
    profileId: string;
    fields?: string[];
    apiKey: string;
}
export type FutureProfilesGetProfileHandler<Bindings extends GeneratedSchemaBindings = {}, Integration extends GeneratedRequestIntegration = {}, Multipart extends GeneratedMultipartAdapters = {}> = (input: GeneratedHandlerInput<Bindings["futureProfilesGetProfile"], FutureProfilesGetProfileInput>, context: GeneratedHandlerContext<Integration, "secured">) => GeneratedHandlerOutput<Bindings["futureProfilesGetProfile"], Profile>;
export interface FutureProfilesPatchProfileInput {
    profileId: string;
    apiKey: string;
    body: ProfilePatch;
}
export type FutureProfilesPatchProfileHandler<Bindings extends GeneratedSchemaBindings = {}, Integration extends GeneratedRequestIntegration = {}, Multipart extends GeneratedMultipartAdapters = {}> = (input: GeneratedHandlerInput<Bindings["futureProfilesPatchProfile"], FutureProfilesPatchProfileInput>, context: GeneratedHandlerContext<Integration, "secured">) => GeneratedHandlerOutput<Bindings["futureProfilesPatchProfile"], ProfilePatch>;
export interface FutureProfilesUploadProfilePhotoInput<Multipart extends GeneratedMultipartAdapters = {}> {
    profileId: string;
    apiKey: string;
    body: GeneratedMultipartBody<GeneratedMultipartAdapterPart<Multipart["futureProfilesUploadProfilePhoto"]>, "file" | "metadata">;
}
export type FutureProfilesUploadProfilePhotoHandler<Bindings extends GeneratedSchemaBindings = {}, Integration extends GeneratedRequestIntegration = {}, Multipart extends GeneratedMultipartAdapters = {}> = (input: GeneratedHandlerInput<Bindings["futureProfilesUploadProfilePhoto"], FutureProfilesUploadProfilePhotoInput<Multipart>>, context: GeneratedHandlerContext<Integration, "secured">) => GeneratedHandlerOutput<Bindings["futureProfilesUploadProfilePhoto"], PhotoReceipt>;
export interface FutureProfilesProcessLedgerInput {
    profileId: string;
    apiKey: string;
    body: LedgerBatch;
}
export type FutureProfilesProcessLedgerHandler<Bindings extends GeneratedSchemaBindings = {}, Integration extends GeneratedRequestIntegration = {}, Multipart extends GeneratedMultipartAdapters = {}> = (input: GeneratedHandlerInput<Bindings["futureProfilesProcessLedger"], FutureProfilesProcessLedgerInput>, context: GeneratedHandlerContext<Integration, "secured">) => GeneratedHandlerOutput<Bindings["futureProfilesProcessLedger"], LedgerBatch>;

export type FutureProfilesRawReceiptsHandler<Bindings extends GeneratedSchemaBindings = {}, Integration extends GeneratedRequestIntegration = {}, Multipart extends GeneratedMultipartAdapters = {}> = (input: GeneratedHandlerInput<Bindings["futureProfilesRawReceipts"], Uint8Array>, context: GeneratedHandlerContext<Integration, "unsecured">) => GeneratedHandlerOutput<Bindings["futureProfilesRawReceipts"], Uint8Array>;

export interface GeneratedHandlers<Bindings extends GeneratedSchemaBindings = {}, Integration extends GeneratedRequestIntegration = {}, Multipart extends GeneratedMultipartAdapters = {}> {
    futureProfilesGetProfile: FutureProfilesGetProfileHandler<Bindings, Integration, Multipart>;
    futureProfilesPatchProfile: FutureProfilesPatchProfileHandler<Bindings, Integration, Multipart>;
    futureProfilesUploadProfilePhoto: FutureProfilesUploadProfilePhotoHandler<Bindings, Integration, Multipart>;
    futureProfilesProcessLedger: FutureProfilesProcessLedgerHandler<Bindings, Integration, Multipart>;
    futureProfilesRawReceipts: FutureProfilesRawReceiptsHandler<Bindings, Integration, Multipart>;
}

export function registerGeneratedRoutes<Bindings extends GeneratedSchemaBindings = {}, Integration extends GeneratedRequestIntegration = {}, Multipart extends GeneratedMultipartAdapters = {}>(app: Express, handlers: GeneratedHandlers<Bindings, Integration, Multipart>, bindings?: Bindings, options?: GeneratedRouteOptions<Integration, Multipart>): void {

    if (!options?.integration?.secured) { throw new Error("Missing secured request policy"); }
    const multipartAdapter_futureProfilesUploadProfilePhotoFactory = options?.multipart?.futureProfilesUploadProfilePhoto;
    if (!multipartAdapter_futureProfilesUploadProfilePhotoFactory) { throw new Error("Missing multipart adapter for futureProfilesUploadProfilePhoto"); }
    const multipartAdapter_futureProfilesUploadProfilePhoto = multipartAdapter_futureProfilesUploadProfilePhotoFactory({
        id: "Future.Profiles.UploadProfilePhoto",
        requiredParts: ["file", "metadata"]
    }) as GeneratedMultipartAdapter<GeneratedMultipartAdapterPart<Multipart["futureProfilesUploadProfilePhoto"]>>;
        app.get("/profiles/:profile_id", ...(options?.integration?.secured?.middleware ?? []), generatedRequestContextMiddleware(options?.integration?.secured), async (request, response, next) => {

            let decodedInput: FutureProfilesGetProfileInput;
            try {
                        const raw_profileId = readRequestParameter(request, "path", "profile_id");
                    const parsed_profileId = parseParameterString(raw_profileId, "profile_id", true);
                    const raw_fields = readRequestParameter(request, "query", "fields");
                    const parsed_fields = parseParameterArray(raw_fields, "fields", false)?.map((item) => parseParameterString(item, "fields", true));
                    const raw_apiKey = readRequestParameter(request, "header", "Authorization");
                    const parsed_apiKey = parseParameterString(raw_apiKey, "Authorization", true);

                    decodedInput = {
                        profileId: parsed_profileId,
                        fields: parsed_fields,
                        apiKey: parsed_apiKey,
                    } as FutureProfilesGetProfileInput;
            } catch (error) {
                next(new GeneratedValidationError("Future.Profiles.GetProfile", "input", error));
                return;
            }

            let input: GeneratedHandlerInput<Bindings["futureProfilesGetProfile"], FutureProfilesGetProfileInput>;
            try {
                input = (bindings?.futureProfilesGetProfile?.input ? bindings.futureProfilesGetProfile.input.parse(decodedInput) : decodedInput) as GeneratedHandlerInput<Bindings["futureProfilesGetProfile"], FutureProfilesGetProfileInput>;
            } catch (error) {
                next(error instanceof z.ZodError ? new GeneratedValidationError("Future.Profiles.GetProfile", "input", error) : error);
                return;
            }

            try {
                const handlerOutput = await handlers.futureProfilesGetProfile(input, generatedRequestContext<GeneratedHandlerContext<Integration, "secured">>(request));
                try {
                    const output = normalizeGeneratedResponse(handlerOutput, 200);
                    validateGeneratedResponseStatus(output.status, [200]);
                                        let publicOutput: GeneratedWireOutput<Bindings["futureProfilesGetProfile"], Profile>;
                                    try {
                                        publicOutput = (bindings?.futureProfilesGetProfile?.output ? bindings.futureProfilesGetProfile.output.parse(output.value) : output.value) as GeneratedWireOutput<Bindings["futureProfilesGetProfile"], Profile>;
                                    } catch (error) {
                                        next(error instanceof z.ZodError ? new GeneratedValidationError("Future.Profiles.GetProfile", "output", error) : error);
                                        return;
                                    }
                                    const body = encodeProfile(publicOutput);
                                    const responseBody = stringifyJsonResponse(body);
                                    for (const [name, value] of Object.entries(output.headers)) {
                                        response.setHeader(name, value);
                                    }
                                    if (!generatedResponseHasBody(output.status)) {
                                        response.status(output.status).end();
                                        return;
                                    }
                                    response.status(output.status).type("application/json").send(responseBody);
                } catch (error) {
                    next(new GeneratedValidationError("Future.Profiles.GetProfile", "output", error));
                }
            } catch (error) {
                next(error);
            }
        });
        app.patch("/profiles/:profile_id", ...(options?.integration?.secured?.middleware ?? []), generatedRequestContextMiddleware(options?.integration?.secured), options?.jsonBodyParser ?? express.raw({ type: "application/json" }), async (request, response, next) => {

            let decodedInput: FutureProfilesPatchProfileInput;
            try {
                        const raw_profileId = readRequestParameter(request, "path", "profile_id");
                    const parsed_profileId = parseParameterString(raw_profileId, "profile_id", true);
                    const raw_apiKey = readRequestParameter(request, "header", "Authorization");
                    const parsed_apiKey = parseParameterString(raw_apiKey, "Authorization", true);
                    const body = decodeProfilePatch(parseJsonBody(request.body));
                    decodedInput = {
                        profileId: parsed_profileId,
                        apiKey: parsed_apiKey,
                        body,
                    } as FutureProfilesPatchProfileInput;
            } catch (error) {
                next(new GeneratedValidationError("Future.Profiles.PatchProfile", "input", error));
                return;
            }

            let input: GeneratedHandlerInput<Bindings["futureProfilesPatchProfile"], FutureProfilesPatchProfileInput>;
            try {
                input = (bindings?.futureProfilesPatchProfile?.input ? bindings.futureProfilesPatchProfile.input.parse(decodedInput) : decodedInput) as GeneratedHandlerInput<Bindings["futureProfilesPatchProfile"], FutureProfilesPatchProfileInput>;
            } catch (error) {
                next(error instanceof z.ZodError ? new GeneratedValidationError("Future.Profiles.PatchProfile", "input", error) : error);
                return;
            }

            try {
                const handlerOutput = await handlers.futureProfilesPatchProfile(input, generatedRequestContext<GeneratedHandlerContext<Integration, "secured">>(request));
                try {
                    const output = normalizeGeneratedResponse(handlerOutput, 200);
                    validateGeneratedResponseStatus(output.status, [200]);
                                        let publicOutput: GeneratedWireOutput<Bindings["futureProfilesPatchProfile"], ProfilePatch>;
                                    try {
                                        publicOutput = (bindings?.futureProfilesPatchProfile?.output ? bindings.futureProfilesPatchProfile.output.parse(output.value) : output.value) as GeneratedWireOutput<Bindings["futureProfilesPatchProfile"], ProfilePatch>;
                                    } catch (error) {
                                        next(error instanceof z.ZodError ? new GeneratedValidationError("Future.Profiles.PatchProfile", "output", error) : error);
                                        return;
                                    }
                                    const body = encodeProfilePatch(publicOutput);
                                    const responseBody = stringifyJsonResponse(body);
                                    for (const [name, value] of Object.entries(output.headers)) {
                                        response.setHeader(name, value);
                                    }
                                    if (!generatedResponseHasBody(output.status)) {
                                        response.status(output.status).end();
                                        return;
                                    }
                                    response.status(output.status).type("application/json").send(responseBody);
                } catch (error) {
                    next(new GeneratedValidationError("Future.Profiles.PatchProfile", "output", error));
                }
            } catch (error) {
                next(error);
            }
        });
        app.post("/profiles/:profile_id/photo", ...(options?.integration?.secured?.middleware ?? []), generatedRequestContextMiddleware(options?.integration?.secured), ...multipartAdapter_futureProfilesUploadProfilePhoto.middleware, async (request, response, next) => {
                        let multipartParts: ReadonlyMap<string, readonly GeneratedMultipartAdapterPart<Multipart["futureProfilesUploadProfilePhoto"]>[]>;
                    try {
                        multipartParts = await multipartAdapter_futureProfilesUploadProfilePhoto.read(request, response);
                    } catch (error) {
                        next(error);
                        return;
                    }
                    if (response.headersSent || response.writableEnded) {
                        return;
                    }
            let decodedInput: FutureProfilesUploadProfilePhotoInput<Multipart>;
            try {
                        const raw_profileId = readRequestParameter(request, "path", "profile_id");
                    const parsed_profileId = parseParameterString(raw_profileId, "profile_id", true);
                    const raw_apiKey = readRequestParameter(request, "header", "Authorization");
                    const parsed_apiKey = parseParameterString(raw_apiKey, "Authorization", true);
                    const body = {
                        parts: multipartParts,
                        required: {
                                                    "file": generatedRequiredMultipartPart(multipartParts, "file"),
                                                    "metadata": generatedRequiredMultipartPart(multipartParts, "metadata")
                        }
                    } as GeneratedMultipartBody<GeneratedMultipartAdapterPart<Multipart["futureProfilesUploadProfilePhoto"]>, "file" | "metadata">;
                    decodedInput = {
                        profileId: parsed_profileId,
                        apiKey: parsed_apiKey,
                        body,
                    } as FutureProfilesUploadProfilePhotoInput<Multipart>;
            } catch (error) {
                next(new GeneratedValidationError("Future.Profiles.UploadProfilePhoto", "input", error));
                return;
            }

            let input: GeneratedHandlerInput<Bindings["futureProfilesUploadProfilePhoto"], FutureProfilesUploadProfilePhotoInput<Multipart>>;
            try {
                input = (bindings?.futureProfilesUploadProfilePhoto?.input ? bindings.futureProfilesUploadProfilePhoto.input.parse(decodedInput) : decodedInput) as GeneratedHandlerInput<Bindings["futureProfilesUploadProfilePhoto"], FutureProfilesUploadProfilePhotoInput<Multipart>>;
            } catch (error) {
                next(error instanceof z.ZodError ? new GeneratedValidationError("Future.Profiles.UploadProfilePhoto", "input", error) : error);
                return;
            }

            try {
                const handlerOutput = await handlers.futureProfilesUploadProfilePhoto(input, generatedRequestContext<GeneratedHandlerContext<Integration, "secured">>(request));
                try {
                    const output = normalizeGeneratedResponse(handlerOutput, 201);
                    validateGeneratedResponseStatus(output.status, [201]);
                                        let publicOutput: GeneratedWireOutput<Bindings["futureProfilesUploadProfilePhoto"], PhotoReceipt>;
                                    try {
                                        publicOutput = (bindings?.futureProfilesUploadProfilePhoto?.output ? bindings.futureProfilesUploadProfilePhoto.output.parse(output.value) : output.value) as GeneratedWireOutput<Bindings["futureProfilesUploadProfilePhoto"], PhotoReceipt>;
                                    } catch (error) {
                                        next(error instanceof z.ZodError ? new GeneratedValidationError("Future.Profiles.UploadProfilePhoto", "output", error) : error);
                                        return;
                                    }
                                    const body = encodePhotoReceipt(publicOutput);
                                    const responseBody = stringifyJsonResponse(body);
                                    for (const [name, value] of Object.entries(output.headers)) {
                                        response.setHeader(name, value);
                                    }
                                    if (!generatedResponseHasBody(output.status)) {
                                        response.status(output.status).end();
                                        return;
                                    }
                                    response.status(output.status).type("application/json").send(responseBody);
                } catch (error) {
                    next(new GeneratedValidationError("Future.Profiles.UploadProfilePhoto", "output", error));
                }
            } catch (error) {
                next(error);
            }
        });
        app.post("/profiles/:profile_id/ledger", ...(options?.integration?.secured?.middleware ?? []), generatedRequestContextMiddleware(options?.integration?.secured), options?.jsonBodyParser ?? express.raw({ type: "application/json" }), async (request, response, next) => {

            let decodedInput: FutureProfilesProcessLedgerInput;
            try {
                        const raw_profileId = readRequestParameter(request, "path", "profile_id");
                    const parsed_profileId = parseParameterString(raw_profileId, "profile_id", true);
                    const raw_apiKey = readRequestParameter(request, "header", "Authorization");
                    const parsed_apiKey = parseParameterString(raw_apiKey, "Authorization", true);
                    const body = decodeLedgerBatch(parseJsonBody(request.body));
                    decodedInput = {
                        profileId: parsed_profileId,
                        apiKey: parsed_apiKey,
                        body,
                    } as FutureProfilesProcessLedgerInput;
            } catch (error) {
                next(new GeneratedValidationError("Future.Profiles.ProcessLedger", "input", error));
                return;
            }

            let input: GeneratedHandlerInput<Bindings["futureProfilesProcessLedger"], FutureProfilesProcessLedgerInput>;
            try {
                input = (bindings?.futureProfilesProcessLedger?.input ? bindings.futureProfilesProcessLedger.input.parse(decodedInput) : decodedInput) as GeneratedHandlerInput<Bindings["futureProfilesProcessLedger"], FutureProfilesProcessLedgerInput>;
            } catch (error) {
                next(error instanceof z.ZodError ? new GeneratedValidationError("Future.Profiles.ProcessLedger", "input", error) : error);
                return;
            }

            try {
                const handlerOutput = await handlers.futureProfilesProcessLedger(input, generatedRequestContext<GeneratedHandlerContext<Integration, "secured">>(request));
                try {
                    const output = normalizeGeneratedResponse(handlerOutput, 200);
                    validateGeneratedResponseStatus(output.status, [200]);
                                        let publicOutput: GeneratedWireOutput<Bindings["futureProfilesProcessLedger"], LedgerBatch>;
                                    try {
                                        publicOutput = (bindings?.futureProfilesProcessLedger?.output ? bindings.futureProfilesProcessLedger.output.parse(output.value) : output.value) as GeneratedWireOutput<Bindings["futureProfilesProcessLedger"], LedgerBatch>;
                                    } catch (error) {
                                        next(error instanceof z.ZodError ? new GeneratedValidationError("Future.Profiles.ProcessLedger", "output", error) : error);
                                        return;
                                    }
                                    const body = encodeLedgerBatch(publicOutput);
                                    const responseBody = stringifyJsonResponse(body);
                                    for (const [name, value] of Object.entries(output.headers)) {
                                        response.setHeader(name, value);
                                    }
                                    if (!generatedResponseHasBody(output.status)) {
                                        response.status(output.status).end();
                                        return;
                                    }
                                    response.status(output.status).type("application/json").send(responseBody);
                } catch (error) {
                    next(new GeneratedValidationError("Future.Profiles.ProcessLedger", "output", error));
                }
            } catch (error) {
                next(error);
            }
        });
        app.post("/receipts/raw", ...(options?.integration?.unsecured?.middleware ?? []), generatedRequestContextMiddleware(options?.integration?.unsecured), options?.rawBodyParser ?? express.raw({ type: "multipart/form-data" }), async (request, response, next) => {

            let decodedInput: Uint8Array;
            try {
                        if (!(request.body instanceof Uint8Array)) {
                        throw new Error("Invalid raw request body");
                    }
                    decodedInput = request.body;
            } catch (error) {
                next(new GeneratedValidationError("Future.Profiles.RawReceipts", "input", error));
                return;
            }

            let input: GeneratedHandlerInput<Bindings["futureProfilesRawReceipts"], Uint8Array>;
            try {
                input = (bindings?.futureProfilesRawReceipts?.input ? bindings.futureProfilesRawReceipts.input.parse(decodedInput) : decodedInput) as GeneratedHandlerInput<Bindings["futureProfilesRawReceipts"], Uint8Array>;
            } catch (error) {
                next(error instanceof z.ZodError ? new GeneratedValidationError("Future.Profiles.RawReceipts", "input", error) : error);
                return;
            }

            try {
                const handlerOutput = await handlers.futureProfilesRawReceipts(input, generatedRequestContext<GeneratedHandlerContext<Integration, "unsecured">>(request));
                try {
                    const output = normalizeGeneratedResponse(handlerOutput, 200);
                    validateGeneratedResponseStatus(output.status, [200]);
                                        if (!(output.value instanceof Uint8Array)) {
                                        throw new Error("Invalid raw response body");
                                    }
                                    for (const [name, value] of Object.entries(output.headers)) {
                                        response.setHeader(name, value);
                                    }
                                    if (!generatedResponseHasBody(output.status)) {
                                        response.status(output.status).end();
                                        return;
                                    }
                                    response.status(output.status).type("multipart/form-data").send(output.value);
                } catch (error) {
                    next(new GeneratedValidationError("Future.Profiles.RawReceipts", "output", error));
                }
            } catch (error) {
                next(error);
            }
        });
}
