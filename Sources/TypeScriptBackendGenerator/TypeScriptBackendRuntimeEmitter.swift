struct TypeScriptBackendRuntimeEmitter {
    func source() -> String {
        """
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
            const format = /^\\d{4}-\\d{2}-\\d{2}T(?:[01]\\d|2[0-3]):[0-5]\\d:[0-5]\\d(?:\\.\\d+)?(?:Z|[+-](?:[01]\\d|2[0-3]):[0-5]\\d)$/;
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
            if (!/^\\d{4}-\\d{2}-\\d{2}$/.test(value)) {
                return false;
            }
            const date = new Date(`${value}T00:00:00.000Z`);
            return Number.isFinite(date.getTime()) && date.toISOString().slice(0, 10) === value;
        }

        export function isValidLocalTime(value: string): boolean {
            return /^(?:[01]\\d|2[0-3]):[0-5]\\d:[0-5]\\d(?:\\.\\d+)?$/.test(value);
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

        type ParameterRequest = {
            params: Record<string, string | undefined>;
            query: unknown;
            get(name: string): string | undefined;
        };

        export function readRequestParameter(
            request: ParameterRequest,
            location: "path" | "query" | "header" | "cookie",
            name: string
        ): string | undefined {
            switch (location) {
                case "path":
                    return request.params[name];
                case "query": {
                    const query = request.query;
                    if (typeof query !== "object" || query === null || Array.isArray(query)) {
                        return undefined;
                    }
                    const value = (query as Record<string, unknown>)[name];
                    if (value === undefined) {
                        return undefined;
                    }
                    if (typeof value === "string") {
                        return value;
                    }
                    if (Array.isArray(value) && value.every((item) => typeof item === "string")) {
                        return (value as string[]).join(",");
                    }
                    throw new Error(`Invalid ${location} parameter: ${name}`);
                }
                case "header":
                    return request.get(name);
                case "cookie":
                    return readCookie(request.get("Cookie"), name);
            }
        }

        function readCookie(header: string | undefined, name: string): string | undefined {
            if (header === undefined) {
                return undefined;
            }
            for (const item of header.split(";")) {
                const separator = item.indexOf("=");
                if (separator < 0) {
                    continue;
                }
                const encodedName = item.slice(0, separator).trim();
                const encodedValue = item.slice(separator + 1).trim();
                let decodedName: string;
                let decodedValue: string;
                try {
                    decodedName = decodeURIComponent(encodedName);
                    decodedValue = decodeURIComponent(encodedValue);
                } catch {
                    throw new Error(`Invalid cookie parameter: ${name}`);
                }
                if (decodedName === name) {
                    return decodedValue;
                }
            }
            return undefined;
        }

        export function parseParameterString(value: string | undefined, name: string, required: boolean): string | undefined {
            if (value === undefined) {
                if (required) {
                    throw new Error(`Missing parameter: ${name}`);
                }
                return undefined;
            }
            return value;
        }

        export function parseParameterArray(value: string | undefined, name: string, required: boolean): string[] | undefined {
            if (value === undefined) {
                if (required) {
                    throw new Error(`Missing parameter: ${name}`);
                }
                return undefined;
            }
            return value === "" ? [] : value.split(",");
        }

        export function parseParameterBoolean(value: string | undefined, name: string, required: boolean): boolean | undefined {
            const text = parseParameterString(value, name, required);
            if (text === undefined) {
                return undefined;
            }
            if (text === "true") {
                return true;
            }
            if (text === "false") {
                return false;
            }
            throw new Error(`Invalid boolean parameter: ${name}`);
        }

        export function parseParameterBigInt(
            value: string | undefined,
            name: string,
            required: boolean,
            minimum?: bigint,
            maximum?: bigint
        ): bigint | undefined {
            const text = parseParameterString(value, name, required);
            if (text === undefined || !/^[+-]?\\d+$/.test(text)) {
                if (text === undefined) {
                    return undefined;
                }
                throw new Error(`Invalid integer parameter: ${name}`);
            }
            try {
                const integer = BigInt(text);
                if ((minimum !== undefined && integer < minimum) || (maximum !== undefined && integer > maximum)) {
                    throw new Error(`Integer parameter is outside the supported range: ${name}`);
                }
                return integer;
            } catch {
                throw new Error(`Invalid integer parameter: ${name}`);
            }
        }

        export function parseParameterNarrowInteger(
            value: string | undefined,
            name: string,
            required: boolean,
            minimum: number,
            maximum: number
        ): number | undefined {
            const text = parseParameterString(value, name, required);
            if (text === undefined) {
                return undefined;
            }
            if (!/^[+-]?\\d+$/.test(text)) {
                throw new Error(`Invalid integer parameter: ${name}`);
            }
            const integer = Number(text);
            if (!Number.isSafeInteger(integer) || integer < minimum || integer > maximum) {
                throw new Error(`Integer parameter is outside the supported range: ${name}`);
            }
            return integer;
        }

        export function parseParameterInteger(value: string | undefined, name: string, required: boolean): number | bigint | undefined {
            const text = parseParameterString(value, name, required);
            if (text === undefined) {
                return undefined;
            }
            if (!/^[+-]?\\d+$/.test(text)) {
                throw new Error(`Invalid integer parameter: ${name}`);
            }
            try {
                const integer = BigInt(text);
                return integer >= BigInt(Number.MIN_SAFE_INTEGER) && integer <= BigInt(Number.MAX_SAFE_INTEGER)
                    ? Number(integer)
                    : integer;
            } catch {
                throw new Error(`Invalid integer parameter: ${name}`);
            }
        }

        export function parseParameterDateTime(value: string | undefined, name: string, required: boolean): Date | undefined {
            const text = parseParameterString(value, name, required);
            return text === undefined ? undefined : parseDate(text);
        }

        export function parseParameterDate(value: string | undefined, name: string, required: boolean): string | undefined {
            const text = parseParameterString(value, name, required);
            if (text !== undefined && !isValidCalendarDate(text)) {
                throw new Error(`Invalid date parameter: ${name}`);
            }
            return text;
        }

        export function parseParameterTime(value: string | undefined, name: string, required: boolean): string | undefined {
            const text = parseParameterString(value, name, required);
            if (text !== undefined && !isValidLocalTime(text)) {
                throw new Error(`Invalid time parameter: ${name}`);
            }
            return text;
        }
        """
    }
}
