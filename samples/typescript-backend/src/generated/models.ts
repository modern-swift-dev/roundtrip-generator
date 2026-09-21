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

export interface Profile {
    id: string;
    firstName: string;
    biography?: string | null;
    createdAt: Date;
}

export function ProfileWireSchema() {
    return z.object({
        "id": z.string().refine((value) => isValidUUID(value)),
        "first_name": z.string(),
        "biography": z.string().nullable().optional(),
        "created_at": z.string().refine((value) => isValidISODate(value)),
    });
}

export function decodeProfile(value: unknown): Profile {
    const object = ProfileWireSchema().parse(value) as Record<string, unknown>;
    return {
        id: z.string().refine((value) => isValidUUID(value)).parse(object["id"]) as string,
        firstName: z.string().parse(object["first_name"]) as string,
        biography: (object["biography"] == null ? object["biography"] : z.string().parse(object["biography"]) as string),
        createdAt: parseDate(object["created_at"]),
    };
}

export function encodeProfile(value: Profile): unknown {
    return ProfileWireSchema().parse({
        "id": value.id,
        "first_name": value.firstName,
        "biography": (value.biography == null ? value.biography : value.biography),
        "created_at": serializeDate(value.createdAt),
    });
}

export interface ProfilePatch {
    firstName?: { state: "unmodified" } | { state: "modified"; value: string | null };
    biography?: { state: "unmodified" } | { state: "modified"; value: string | null };
}

export function ProfilePatchWireSchema() {
    return z.object({
        "first_name": z.string().nullable().optional(),
        "biography": z.string().nullable().optional(),
    });
}

export function decodeProfilePatch(value: unknown): ProfilePatch {
    const object = ProfilePatchWireSchema().parse(value) as Record<string, unknown>;
    return {
        firstName: (object["first_name"] === undefined ? undefined : (() => { const patchValue = z.string().nullable().parse(object["first_name"]); return { state: "modified", value: patchValue == null ? null : z.string().parse(patchValue) as string }; })()),
        biography: (object["biography"] === undefined ? undefined : (() => { const patchValue = z.string().nullable().parse(object["biography"]); return { state: "modified", value: patchValue == null ? null : z.string().parse(patchValue) as string }; })()),
    };
}

export function encodeProfilePatch(value: ProfilePatch): unknown {
    return ProfilePatchWireSchema().parse({
        "first_name": (value.firstName === undefined || String(value.firstName.state) === "unmodified" ? undefined : (value.firstName.state === "unmodified" ? undefined : value.firstName.value == null ? null : value.firstName.value)),
        "biography": (value.biography === undefined || String(value.biography.state) === "unmodified" ? undefined : (value.biography.state === "unmodified" ? undefined : value.biography.value == null ? null : value.biography.value)),
    });
}

export interface PhotoReceipt {
    profileId: string;
    byteCount: number;
}

export function PhotoReceiptWireSchema() {
    return z.object({
        "profile_id": z.string().refine((value) => isValidUUID(value)),
        "byte_count": z.union([z.number(), z.bigint()]).transform((value) => parseNarrowInteger(value, -2147483648n, 2147483647n)),
    });
}

export function decodePhotoReceipt(value: unknown): PhotoReceipt {
    const object = PhotoReceiptWireSchema().parse(value) as Record<string, unknown>;
    return {
        profileId: z.string().refine((value) => isValidUUID(value)).parse(object["profile_id"]) as string,
        byteCount: z.union([z.number(), z.bigint()]).transform((value) => parseNarrowInteger(value, -2147483648n, 2147483647n)).parse(object["byte_count"]) as number,
    };
}

export function encodePhotoReceipt(value: PhotoReceipt): unknown {
    return PhotoReceiptWireSchema().parse({
        "profile_id": value.profileId,
        "byte_count": value.byteCount,
    });
}

export interface LedgerBatch {
    entries: LedgerEntry[];
    totals: Record<string, bigint>;
}

export function LedgerBatchWireSchema() {
    return z.object({
        "entries": z.array(LedgerEntryWireSchema()),
        "totals": z.record(z.string(), z.bigint().refine((value) => value >= 0n && value <= 18446744073709551615n)),
    });
}

export function decodeLedgerBatch(value: unknown): LedgerBatch {
    const object = LedgerBatchWireSchema().parse(value) as Record<string, unknown>;
    return {
        entries: (object["entries"] as unknown[]).map((item) => decodeLedgerEntry(item)),
        totals: Object.fromEntries(Object.entries(object["totals"] as Record<string, unknown>).map(([key, item]) => [key, z.bigint().refine((value) => value >= 0n && value <= 18446744073709551615n).parse(item) as bigint])) as Record<string, bigint>,
    };
}

export function encodeLedgerBatch(value: LedgerBatch): unknown {
    return LedgerBatchWireSchema().parse({
        "entries": value.entries.map((item) => encodeLedgerEntry(item)),
        "totals": Object.fromEntries(Object.entries(value.totals).map(([key, item]) => [key, item as bigint])),
    });
}

export interface LedgerEntry {
    entryName: string;
    amount: bigint;
    capturedAt: Date;
    evidence: Uint8Array;
}

export function LedgerEntryWireSchema() {
    return z.object({
        "entry_name": z.string(),
        "amount": z.bigint().refine((value) => value >= -9223372036854775808n && value <= 9223372036854775807n),
        "captured_at": z.string().refine((value) => isValidISODate(value)),
        "evidence": z.string().refine((value) => isValidBase64(value)),
    });
}

export function decodeLedgerEntry(value: unknown): LedgerEntry {
    const object = LedgerEntryWireSchema().parse(value) as Record<string, unknown>;
    return {
        entryName: z.string().parse(object["entry_name"]) as string,
        amount: z.bigint().refine((value) => value >= -9223372036854775808n && value <= 9223372036854775807n).parse(object["amount"]) as bigint,
        capturedAt: parseDate(object["captured_at"]),
        evidence: base64ToUint8Array(object["evidence"]),
    };
}

export function encodeLedgerEntry(value: LedgerEntry): unknown {
    return LedgerEntryWireSchema().parse({
        "entry_name": value.entryName,
        "amount": value.amount,
        "captured_at": serializeDate(value.capturedAt),
        "evidence": uint8ArrayToBase64(value.evidence),
    });
}
