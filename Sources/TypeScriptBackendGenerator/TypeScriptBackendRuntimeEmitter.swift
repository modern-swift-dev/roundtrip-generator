struct TypeScriptBackendRuntimeEmitter {
    func source() -> String {
        """
        // Generated code. Do not edit.

        import { parse, parseNumberAndBigInt, stringify } from "lossless-json";

        export type BackendHandlerResult<T> = T | Promise<T>;

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
        """
    }
}
