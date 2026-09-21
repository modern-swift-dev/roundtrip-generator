// Generated code. Do not edit.

import express, { type Express, type RequestHandler } from "express";
import { z } from "zod";
import {
    base64ToUint8Array,
    isValidBase64,
    isValidCalendarDate,
    isValidISODate,
    isValidLocalTime,
    isValidURL,
    isValidUUID,
    parseDate,
    parseDouble,
    parseJsonBody,
    parseNarrowInteger,
    parseURL,
    serializeDate,
    serializeURL,
    stringifyJsonResponse,
    uint8ArrayToBase64
} from "./runtime.js";
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

export interface GeneratedRouteOptions {
    jsonBodyParser?: RequestHandler;
}

export interface GeneratedSchemaBindings {
    demoMessagesEcho?: GeneratedOperationBinding;
}

export type GeneratedHandlerInput<Binding, Default> = Binding extends { input?: infer Schema }
    ? NonNullable<Schema> extends z.ZodTypeAny ? z.output<NonNullable<Schema>> : Default
    : Default;

export type GeneratedHandlerOutput<Binding, Default> = Binding extends { output?: infer Schema }
    ? NonNullable<Schema> extends z.ZodTypeAny ? z.input<NonNullable<Schema>> | Promise<z.input<NonNullable<Schema>>> : Default | Promise<Default>
    : Default | Promise<Default>;

export type GeneratedWireOutput<Binding, Default> = Binding extends { output?: infer Schema }
    ? NonNullable<Schema> extends z.ZodTypeAny ? z.output<NonNullable<Schema>> : Default
    : Default;

export type DemoMessagesEchoHandler<Bindings extends GeneratedSchemaBindings = {}> = (input: GeneratedHandlerInput<Bindings["demoMessagesEcho"], Message>) => GeneratedHandlerOutput<Bindings["demoMessagesEcho"], Message>;

export interface GeneratedHandlers<Bindings extends GeneratedSchemaBindings = {}> {
    demoMessagesEcho: DemoMessagesEchoHandler<Bindings>;
}

export function registerGeneratedRoutes<Bindings extends GeneratedSchemaBindings = {}>(app: Express, handlers: GeneratedHandlers<Bindings>, bindings?: Bindings, options?: GeneratedRouteOptions): void {

        app.post("/messages", options?.jsonBodyParser ?? express.raw({ type: "application/json" }), async (request, response, next) => {
            let input: GeneratedHandlerInput<Bindings["demoMessagesEcho"], Message>;
            try {
                const decodedInput = decodeMessage(parseJsonBody(request.body));
                input = (bindings?.demoMessagesEcho?.input ? bindings.demoMessagesEcho.input.parse(decodedInput) : decodedInput) as GeneratedHandlerInput<Bindings["demoMessagesEcho"], Message>;
            } catch {
                response.status(400).json({ error: "Invalid request" });
                return;
            }

            try {
                const output = await handlers.demoMessagesEcho(input);
                const publicOutput = (bindings?.demoMessagesEcho?.output ? bindings.demoMessagesEcho.output.parse(output) : output) as GeneratedWireOutput<Bindings["demoMessagesEcho"], Message>;
                const body = encodeMessage(publicOutput);
                response.status(200).type("application/json").send(stringifyJsonResponse(body));
            } catch (error) {
                next(error);
            }
        });
}
