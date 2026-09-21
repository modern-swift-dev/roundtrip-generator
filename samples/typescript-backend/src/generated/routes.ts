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
    decodeMessage,
    encodeMessage,
    type Message
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

export interface GeneratedRouteOptions<Integration extends GeneratedRequestIntegration = {}> {
    jsonBodyParser?: RequestHandler;
    rawBodyParser?: RequestHandler;
    integration?: Integration;
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
    demoMessagesEcho?: GeneratedOperationBinding;
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


export type DemoMessagesEchoHandler<Bindings extends GeneratedSchemaBindings = {}, Integration extends GeneratedRequestIntegration = {}> = (input: GeneratedHandlerInput<Bindings["demoMessagesEcho"], Message>, context: GeneratedHandlerContext<Integration, "unsecured">) => GeneratedHandlerOutput<Bindings["demoMessagesEcho"], Message>;

export interface GeneratedHandlers<Bindings extends GeneratedSchemaBindings = {}, Integration extends GeneratedRequestIntegration = {}> {
    demoMessagesEcho: DemoMessagesEchoHandler<Bindings, Integration>;
}

export function registerGeneratedRoutes<Bindings extends GeneratedSchemaBindings = {}, Integration extends GeneratedRequestIntegration = {}>(app: Express, handlers: GeneratedHandlers<Bindings, Integration>, bindings?: Bindings, options?: GeneratedRouteOptions<Integration>): void {


        app.post("/messages", ...(options?.integration?.unsecured?.middleware ?? []), generatedRequestContextMiddleware(options?.integration?.unsecured), options?.jsonBodyParser ?? express.raw({ type: "application/json" }), async (request, response, next) => {
            let decodedInput: Message;
            try {
                        decodedInput = decodeMessage(parseJsonBody(request.body));
            } catch (error) {
                next(new GeneratedValidationError("Demo.Messages.Echo", "input", error));
                return;
            }

            let input: GeneratedHandlerInput<Bindings["demoMessagesEcho"], Message>;
            try {
                input = (bindings?.demoMessagesEcho?.input ? bindings.demoMessagesEcho.input.parse(decodedInput) : decodedInput) as GeneratedHandlerInput<Bindings["demoMessagesEcho"], Message>;
            } catch (error) {
                next(error instanceof z.ZodError ? new GeneratedValidationError("Demo.Messages.Echo", "input", error) : error);
                return;
            }

            try {
                const handlerOutput = await handlers.demoMessagesEcho(input, generatedRequestContext<GeneratedHandlerContext<Integration, "unsecured">>(request));
                try {
                    const output = normalizeGeneratedResponse(handlerOutput, 200);
                    validateGeneratedResponseStatus(output.status, [200]);
                                        let publicOutput: GeneratedWireOutput<Bindings["demoMessagesEcho"], Message>;
                                    try {
                                        publicOutput = (bindings?.demoMessagesEcho?.output ? bindings.demoMessagesEcho.output.parse(output.value) : output.value) as GeneratedWireOutput<Bindings["demoMessagesEcho"], Message>;
                                    } catch (error) {
                                        next(error instanceof z.ZodError ? new GeneratedValidationError("Demo.Messages.Echo", "output", error) : error);
                                        return;
                                    }
                                    const body = encodeMessage(publicOutput);
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
                    next(new GeneratedValidationError("Demo.Messages.Echo", "output", error));
                }
            } catch (error) {
                next(error);
            }
        });
}
