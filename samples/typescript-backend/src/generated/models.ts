// Generated code. Do not edit.

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
    parseNarrowInteger,
    parseURL,
    serializeDate,
    serializeURL,
    uint8ArrayToBase64
} from "./runtime.js";

export interface PagedResults<T> {
    results: T[];
    next?: string | null;
    count?: number | null;
}

export function PagedResultsWireSchema<T extends z.ZodTypeAny>(itemSchema: T) {
    return z.object({
        results: z.array(itemSchema),
        next: z.string().nullable().optional(),
        count: z.union([z.number(), z.bigint()])
            .transform((value) => Number(value))
            .refine((value) => Number.isSafeInteger(value) && value >= 0)
            .nullable()
            .optional()
    });
}

export interface Message {
    messageText: string;
}

export function MessageWireSchema() {
    return z.object({
        "message_text": z.string(),
    });
}

export function decodeMessage(value: unknown): Message {
    const object = MessageWireSchema().parse(value) as Record<string, unknown>;
    return {
        messageText: z.string().parse(object["message_text"]) as string,
    };
}

export function encodeMessage(value: Message): unknown {
    return MessageWireSchema().parse({
        "message_text": value.messageText,
    });
}
