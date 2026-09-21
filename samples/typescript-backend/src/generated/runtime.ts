// Generated code. Do not edit.

import { parse, parseNumberAndBigInt, stringify } from "lossless-json";

export interface GeneratedResponse<T> {
    readonly kind: "generated-response";
    readonly status: number;
    readonly headers: Record<string, string>;
    readonly value: T;
}

export interface GeneratedResponseOptions {
    status?: number;
    headers?: Record<string, string>;
}

export function generatedResponse<T>(value: T, options: GeneratedResponseOptions = {}): GeneratedResponse<T> {
    return {
        kind: "generated-response",
        status: options.status ?? 200,
        headers: options.headers ?? {},
        value
    };
}

export function isGeneratedResponse(value: unknown): value is GeneratedResponse<unknown> {
    if (typeof value !== "object" || value === null) {
        return false;
    }
    const response = value as Partial<GeneratedResponse<unknown>>;
    return response.kind === "generated-response"
        && typeof response.status === "number"
        && typeof response.headers === "object"
        && response.headers !== null
        && "value" in response;
}

export function normalizeGeneratedResponse<T>(value: T | GeneratedResponse<T>, defaultStatus: number): GeneratedResponse<T> {
    return isGeneratedResponse(value) ? value as GeneratedResponse<T> : generatedResponse(value, { status: defaultStatus });
}

export function validateGeneratedResponseStatus(status: number, validStatuses: readonly number[]): void {
    if (!Number.isInteger(status) || !validStatuses.includes(status)) {
        throw new Error(`Unexpected response status: ${status}`);
    }
}

export function generatedResponseHasBody(status: number): boolean {
    return !(status >= 100 && status < 200) && ![204, 205, 304].includes(status);
}

export function parseJsonBody(value: Uint8Array | string): unknown {
    const text = typeof value === "string" ? value : new TextDecoder().decode(value);
    return parse(text, undefined, { parseNumber: parseNumberAndBigInt });
}

export function stringifyJsonResponse(value: unknown): string {
    const text = stringify(value);
    if (text === undefined) {
        throw new Error("Response cannot be represented as JSON");
    }
    return text;
}

export function isValidISODate(value: string): boolean {
    const format = /^\d{4}-\d{2}-\d{2}T(?:[01]\d|2[0-3]):[0-5]\d:[0-5]\d(?:\.\d+)?(?:Z|[+-](?:[01]\d|2[0-3]):[0-5]\d)$/;
    return format.test(value)
        && isValidCalendarDate(value.slice(0, 10))
        && Number.isFinite(Date.parse(value));
}

export function parseDate(value: unknown): Date {
    if (typeof value !== "string" || !isValidISODate(value)) {
        throw new Error("Invalid ISO-8601 date");
    }
    return new Date(value);
}

export function serializeDate(value: Date): string {
    if (!(value instanceof Date) || !Number.isFinite(value.getTime())) {
        throw new Error("Invalid date");
    }
    return value.toISOString();
}

export function isValidURL(value: string): boolean {
    try {
        new URL(value);
        return true;
    } catch {
        return false;
    }
}

export function parseURL(value: unknown): URL {
    if (typeof value !== "string" || !isValidURL(value)) {
        throw new Error("Invalid URL");
    }
    return new URL(value);
}

export function serializeURL(value: URL): string {
    if (!(value instanceof URL)) {
        throw new Error("Invalid URL");
    }
    return value.toString();
}

export function isValidBase64(value: string): boolean {
    return /^(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?$/.test(value);
}

export function base64ToUint8Array(value: unknown): Uint8Array {
    if (typeof value !== "string" || !isValidBase64(value)) {
        throw new Error("Invalid base64 value");
    }
    const binary = atob(value);
    const bytes = new Uint8Array(binary.length);
    for (let index = 0; index < binary.length; index += 1) {
        bytes[index] = binary.charCodeAt(index);
    }
    return bytes;
}

export function uint8ArrayToBase64(value: Uint8Array): string {
    if (!(value instanceof Uint8Array)) {
        throw new Error("Invalid binary value");
    }
    const chunks: string[] = [];
    const chunkSize = 24_576;
    for (let offset = 0; offset < value.length; offset += chunkSize) {
        chunks.push(btoa(String.fromCharCode(...value.subarray(offset, offset + chunkSize))));
    }
    return chunks.join("");
}

export function isValidUUID(value: string): boolean {
    return /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/.test(value);
}

export function isValidCalendarDate(value: string): boolean {
    if (!/^\d{4}-\d{2}-\d{2}$/.test(value)) {
        return false;
    }
    const date = new Date(`${value}T00:00:00.000Z`);
    return Number.isFinite(date.getTime()) && date.toISOString().slice(0, 10) === value;
}

export function isValidLocalTime(value: string): boolean {
    return /^(?:[01]\d|2[0-3]):[0-5]\d:[0-5]\d(?:\.\d+)?$/.test(value);
}

export function parseNarrowInteger(value: number | bigint, minimum: bigint, maximum: bigint): number {
    const integer = typeof value === "bigint" ? value : Number.isSafeInteger(value) ? BigInt(value) : null;
    if (integer === null || integer < minimum || integer > maximum) {
        throw new Error("Integer is outside the supported range");
    }
    return Number(integer);
}

export function parseDouble(value: number | bigint): number {
    if (typeof value === "bigint") {
        const number = Number(value);
        if (!Number.isSafeInteger(number) || BigInt(number) !== value) {
            throw new Error("Integer cannot be represented exactly as a number");
        }
        return number;
    }
    if (!Number.isFinite(value) || (Number.isInteger(value) && !Number.isSafeInteger(value))) {
        throw new Error("Number is outside the supported range");
    }
    return value;
}
