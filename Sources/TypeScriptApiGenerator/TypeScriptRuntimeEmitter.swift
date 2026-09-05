import Foundation

struct TypeScriptRuntimeEmitter {
    func source() -> String {
        """
        // Generated code. Do not edit.

        export type ApiRequestPath =
            | { kind: "relative"; path: string }
            | { kind: "absolute"; url: string }
            | { kind: "runtime"; requestUrl: string | URL };

        export type ApiFileContent = Blob | File | { blob: Blob; fileName?: string; contentType?: string };
        export type MultipartPart = string | Blob | File | ArrayBuffer | ApiFileContent;
        export type MultipartBody = Record<string, MultipartPart>;

        export interface ApiRequest {
            method: string;
            path: ApiRequestPath;
            queryParameters?: Record<string, string>;
            headers?: Record<string, string>;
            body?: unknown;
            contentType?: string | null;
            accept?: string;
        }

        export interface ApiResponse {
            statusCode: number;
            headers: Record<string, string[]>;
            body: ArrayBuffer | null;
            mimeType: string | null;
        }

        export interface ApiOperationResult<T> {
            value: T;
            response: ApiResponse;
        }

        export interface PagedResults<T> {
            results: T[];
            next?: string | null;
            count?: number | null;
        }

        export interface LocalizedData<T> {
            values: Record<string, T>;
        }

        export interface DateInterval {
            start: string;
            end: string;
        }

        export type PatchableValue<T> =
            | { state: "unmodified" }
            | { state: "modified"; value: T | null };

        export type ApiKeyProvider = () => string | null | undefined | Promise<string | null | undefined>;
        export type DefaultHeaderProvider = () => Record<string, string> | Promise<Record<string, string>>;
        export type JsonEncoder<T> = (value: T) => unknown;
        export type JsonDecoder<T> = (value: unknown) => T;

        export interface ApiClientOptions {
            baseUrl?: string | URL;
            apiKey?: string | ApiKeyProvider | null;
            defaultHeaders?: Record<string, string> | DefaultHeaderProvider;
        }

        export class ApiError extends Error {
            constructor(message: string, readonly response?: ApiResponse) {
                super(message);
                this.name = "ApiError";
            }

            static invalidUrl(): ApiError {
                return new ApiError("Invalid URL");
            }

            static missingApiKey(): ApiError {
                return new ApiError("Missing API key");
            }

            static invalidStatus(response: ApiResponse): ApiError {
                return new ApiError(`Invalid HTTP status: ${response.statusCode}`, response);
            }
        }

        export class ApiClient {
            private readonly baseUrl?: string | URL;
            private readonly apiKeyValue?: string | ApiKeyProvider | null;
            private readonly defaultHeaders?: Record<string, string> | DefaultHeaderProvider;

            constructor(options: ApiClientOptions = {}) {
                this.baseUrl = options.baseUrl;
                this.apiKeyValue = options.apiKey;
                this.defaultHeaders = options.defaultHeaders;
            }

            async apiKey(): Promise<string | null> {
                if (typeof this.apiKeyValue === "function") {
                    return (await this.apiKeyValue()) ?? null;
                }
                return this.apiKeyValue ?? null;
            }

            async requireApiKey(): Promise<string> {
                const value = await this.apiKey();
                if (!value || value.length === 0) {
                    throw ApiError.missingApiKey();
                }
                return value;
            }

            async execute(request: ApiRequest, validStatusCodes: number[]): Promise<ApiResponse>;
            async execute<T>(
                request: ApiRequest,
                validStatusCodes: number[],
                decoder: JsonDecoder<T>
            ): Promise<ApiOperationResult<T>>;
            async execute<T>(
                request: ApiRequest,
                validStatusCodes: number[],
                decoder?: JsonDecoder<T>
            ): Promise<ApiResponse | ApiOperationResult<T>> {
                const response = await this.perform(request);
                if (!validStatusCodes.includes(response.statusCode)) {
                    throw ApiError.invalidStatus(response);
                }
                if (!decoder) {
                    return response;
                }
                const value = decoder(await responseJson(response));
                return { value, response };
            }

            async executeBinary(request: ApiRequest, validStatusCodes: number[]): Promise<ApiOperationResult<ArrayBuffer>> {
                const response = await this.perform(request);
                if (!validStatusCodes.includes(response.statusCode)) {
                    throw ApiError.invalidStatus(response);
                }
                return { value: response.body ?? new ArrayBuffer(0), response };
            }

            private async perform(request: ApiRequest): Promise<ApiResponse> {
                const url = buildUrl(request.path, this.baseUrl, request.queryParameters ?? {});
                const headers: Record<string, string> = {
                    ...(await resolveHeaders(this.defaultHeaders)),
                    ...(request.headers ?? {})
                };
                if (request.accept && !hasHeader(headers, "accept")) {
                    headers.Accept = request.accept;
                }

                let body: BodyInit | undefined;
                if (request.body !== undefined && request.body !== null) {
                    if (request.contentType?.toLowerCase().includes("application/json")) {
                        body = JSON.stringify(encodeJsonValue(request.body));
                    } else if (request.body instanceof FormData) {
                        body = request.body;
                    } else if (isMultipartBody(request.body)) {
                        body = multipartFormData(request.body);
                    } else if (request.body instanceof Blob || request.body instanceof ArrayBuffer) {
                        body = request.body;
                    } else {
                        body = JSON.stringify(encodeJsonValue(request.body));
                    }
                    if (request.contentType && !(body instanceof FormData) && !hasHeader(headers, "content-type")) {
                        headers["Content-Type"] = request.contentType;
                    }
                }

                const fetched = await fetch(url, { method: request.method, headers, body });
                const responseHeaders: Record<string, string[]> = {};
                fetched.headers.forEach((value, key) => {
                    responseHeaders[key] = responseHeaders[key] ? [...responseHeaders[key], value] : [value];
                });
                return {
                    statusCode: fetched.status,
                    headers: responseHeaders,
                    body: await fetched.arrayBuffer(),
                    mimeType: fetched.headers.get("content-type")
                };
            }
        }

        export function appendQueryParameter(values: Record<string, string>, key: string, value: unknown): void {
            if (value === null || value === undefined) {
                return;
            }
            if (Array.isArray(value)) {
                if (value.length > 0) {
                    values[key] = value.map(encodeFormValue).join(",");
                }
                return;
            }
            values[key] = encodeFormValue(value);
        }

        export function encodeFormValue(value: unknown): string {
            if (value instanceof Date) {
                return value.toISOString();
            }
            if (value instanceof URL) {
                return value.toString();
            }
            return String(value);
        }

        export function makeCookieHeader(values: Record<string, string>): string | undefined {
            const cookies = Object.entries(values).map(([key, value]) => {
                return `${encodeURIComponent(key)}=${encodeURIComponent(value)}`;
            });
            return cookies.length > 0 ? cookies.join("; ") : undefined;
        }

        export function encodeJsonValue(value: unknown): unknown {
            if (value instanceof Date) {
                return value.toISOString();
            }
            if (value instanceof URL) {
                return value.toString();
            }
            if (value instanceof ArrayBuffer) {
                return arrayBufferToBase64(value);
            }
            if (Array.isArray(value)) {
                return value.map(encodeJsonValue);
            }
            if (value && typeof value === "object") {
                const output: Record<string, unknown> = {};
                Object.entries(value).forEach(([key, item]) => {
                    if (item !== undefined) {
                        output[key] = encodeJsonValue(item);
                    }
                });
                return output;
            }
            return value;
        }

        export function decodeDate(value: unknown): Date {
            return value instanceof Date ? value : new Date(String(value));
        }

        export function decodeUrl(value: unknown): URL {
            return value instanceof URL ? value : new URL(String(value));
        }

        export function decodeArrayBuffer(value: unknown): ArrayBuffer {
            if (value instanceof ArrayBuffer) {
                return value;
            }
            return base64ToArrayBuffer(String(value));
        }

        export function decodePagedResults<T>(value: unknown, decoder: JsonDecoder<T>): PagedResults<T> {
            const object = value as { results?: unknown[]; next?: string | null; count?: number | null };
            return {
                results: (object.results ?? []).map(decoder),
                next: object.next ?? null,
                count: object.count ?? null
            };
        }

        export async function responseJson(response: ApiResponse): Promise<unknown> {
            if (!response.body || response.body.byteLength === 0) {
                return null;
            }
            return JSON.parse(new TextDecoder().decode(response.body));
        }

        function buildUrl(path: ApiRequestPath, baseUrl: string | URL | undefined, query: Record<string, string>): string {
            let url: URL;
            switch (path.kind) {
                case "relative":
                    if (!baseUrl) {
                        throw ApiError.invalidUrl();
                    }
                    url = new URL(path.path, baseUrl);
                    break;
                case "absolute":
                    url = new URL(path.url);
                    break;
                case "runtime":
                    url = new URL(path.requestUrl);
                    break;
            }
            Object.entries(query).forEach(([key, value]) => url.searchParams.set(key, value));
            return url.toString();
        }

        async function resolveHeaders(provider: Record<string, string> | DefaultHeaderProvider | undefined): Promise<Record<string, string>> {
            if (!provider) {
                return {};
            }
            return typeof provider === "function" ? await provider() : provider;
        }

        function hasHeader(headers: Record<string, string>, name: string): boolean {
            const lower = name.toLowerCase();
            return Object.keys(headers).some((key) => key.toLowerCase() === lower);
        }

        function isMultipartBody(value: unknown): value is MultipartBody {
            return !!value && typeof value === "object" && !(value instanceof Blob) && !(value instanceof ArrayBuffer);
        }

        function multipartFormData(body: MultipartBody): FormData {
            const formData = new FormData();
            Object.entries(body).forEach(([name, part]) => {
                if (part instanceof File) {
                    formData.append(name, part, part.name);
                } else if (part instanceof Blob) {
                    formData.append(name, part);
                } else if (part instanceof ArrayBuffer) {
                    formData.append(name, new Blob([part]));
                } else if (typeof part === "object" && part !== null && "blob" in part) {
                    const value = part as { blob: Blob; fileName?: string };
                    formData.append(name, value.blob, value.fileName);
                } else {
                    formData.append(name, String(part));
                }
            });
            return formData;
        }

        export function arrayBufferToBase64(buffer: ArrayBuffer): string {
            const bytes = new Uint8Array(buffer);
            const chunks: string[] = [];
            // Keep arguments bounded and align chunks to complete base64 triplets.
            const chunkSize = 24_576;
            for (let offset = 0; offset < bytes.length; offset += chunkSize) {
                chunks.push(btoa(String.fromCharCode(...bytes.subarray(offset, offset + chunkSize))));
            }
            return chunks.join("");
        }

        export function base64ToArrayBuffer(value: string): ArrayBuffer {
            const binary = atob(value);
            const bytes = new Uint8Array(binary.length);
            for (let index = 0; index < binary.length; index += 1) {
                bytes[index] = binary.charCodeAt(index);
            }
            return bytes.buffer;
        }
        """
    }
}
