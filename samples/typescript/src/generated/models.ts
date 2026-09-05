// Generated code. Do not edit.


import {
    DateInterval,
    LocalizedData,
    PagedResults,
    PatchableValue,
    JsonDecoder,
    decodeArrayBuffer,
    decodeDate,
    decodePagedResults,
    decodeUrl,
    encodeJsonValue
} from "./runtime.js";

export interface IdObject {
    id: number;
}

export function decodeIdObject(value: unknown): IdObject {
    const object = (value ?? {}) as Record<string, unknown>;
    return {
        id: Number(object["id"]),
    };
}

export function encodeIdObject(value: IdObject): unknown {
    const output: Record<string, unknown> = {};
    output["id"] = encodeJsonValue(value.id);
    return output;
}

export interface NamedObject {
    id: number;
    name: string;
}

export function decodeNamedObject(value: unknown): NamedObject {
    const object = (value ?? {}) as Record<string, unknown>;
    return {
        id: Number(object["id"]),
        name: String(object["name"]),
    };
}

export function encodeNamedObject(value: NamedObject): unknown {
    const output: Record<string, unknown> = {};
    output["id"] = encodeJsonValue(value.id);
    output["name"] = encodeJsonValue(value.name);
    return output;
}

export interface LocalizedNamedObject {
    id: number;
    name: LocalizedData<string>;
}

export function decodeLocalizedNamedObject(value: unknown): LocalizedNamedObject {
    const object = (value ?? {}) as Record<string, unknown>;
    return {
        id: Number(object["id"]),
        name: object["name"] as LocalizedData<string>,
    };
}

export function encodeLocalizedNamedObject(value: LocalizedNamedObject): unknown {
    const output: Record<string, unknown> = {};
    output["id"] = encodeJsonValue(value.id);
    output["name"] = encodeJsonValue(value.name);
    return output;
}

export type StructureType = "plant" | "production_line" | "workstation" | "equipment";

export function decodeStructureType(value: unknown): StructureType {
    const rawValue = String(value);
    switch (rawValue) {
        case "plant":
        case "production_line":
        case "workstation":
        case "equipment":
            return rawValue as StructureType;
        default:
            throw new Error(`Unknown StructureType value: ${String(value)}`);
    }
}

export function encodeStructureType(value: StructureType): unknown {
    return value;
}

export interface AuditStamp {
    createdBy: string;
    createdAt: Date;
    updatedAt?: Date | null;
}

export function decodeAuditStamp(value: unknown): AuditStamp {
    const object = (value ?? {}) as Record<string, unknown>;
    return {
        createdBy: String(object["created_by"]),
        createdAt: decodeDate(object["created_at"]),
        updatedAt: object["updated_at"] == null ? null : decodeDate(object["updated_at"]),
    };
}

export function encodeAuditStamp(value: AuditStamp): unknown {
    const output: Record<string, unknown> = {};
    output["created_by"] = encodeJsonValue(value.createdBy);
    output["created_at"] = encodeJsonValue(value.createdAt);
    if (value.updatedAt !== undefined) {
        output["updated_at"] = value.updatedAt === null ? null : encodeJsonValue(value.updatedAt);
    }
    return output;
}

export interface User {
    firstName: string;
    lastName: string;
    username: string;
    email?: string | null;
    phone?: string | null;
    hireDate?: Date | null;
    birthDate?: Date | null;
    picture?: URL | null;
}

export function decodeUser(value: unknown): User {
    const object = (value ?? {}) as Record<string, unknown>;
    return {
        firstName: String(object["first_name"]),
        lastName: String(object["last_name"]),
        username: String(object["username"]),
        email: object["email"] == null ? null : String(object["email"]),
        phone: object["phone"] == null ? null : String(object["phone"]),
        hireDate: object["hire_date"] == null ? null : decodeDate(object["hire_date"]),
        birthDate: object["birth_date"] == null ? null : decodeDate(object["birth_date"]),
        picture: object["picture"] == null ? null : decodeUrl(object["picture"]),
    };
}

export function encodeUser(value: User): unknown {
    const output: Record<string, unknown> = {};
    output["first_name"] = encodeJsonValue(value.firstName);
    output["last_name"] = encodeJsonValue(value.lastName);
    output["username"] = encodeJsonValue(value.username);
    if (value.email !== undefined) {
        output["email"] = value.email === null ? null : encodeJsonValue(value.email);
    }
    if (value.phone !== undefined) {
        output["phone"] = value.phone === null ? null : encodeJsonValue(value.phone);
    }
    if (value.hireDate !== undefined) {
        output["hire_date"] = value.hireDate === null ? null : encodeJsonValue(value.hireDate);
    }
    if (value.birthDate !== undefined) {
        output["birth_date"] = value.birthDate === null ? null : encodeJsonValue(value.birthDate);
    }
    if (value.picture !== undefined) {
        output["picture"] = value.picture === null ? null : encodeJsonValue(value.picture);
    }
    return output;
}

export interface IdentifiedUser {
    id: number;
    firstName: string;
    lastName: string;
    username: string;
    email?: string | null;
    phone?: string | null;
    hireDate?: Date | null;
    birthDate?: Date | null;
    picture?: URL | null;
    creationDate: Date;
    lastUpdateDate: Date;
}

export function decodeIdentifiedUser(value: unknown): IdentifiedUser {
    const object = (value ?? {}) as Record<string, unknown>;
    return {
        id: Number(object["id"]),
        firstName: String(object["first_name"]),
        lastName: String(object["last_name"]),
        username: String(object["username"]),
        email: object["email"] == null ? null : String(object["email"]),
        phone: object["phone"] == null ? null : String(object["phone"]),
        hireDate: object["hire_date"] == null ? null : decodeDate(object["hire_date"]),
        birthDate: object["birth_date"] == null ? null : decodeDate(object["birth_date"]),
        picture: object["picture"] == null ? null : decodeUrl(object["picture"]),
        creationDate: decodeDate(object["creation_date"]),
        lastUpdateDate: decodeDate(object["last_update_date"]),
    };
}

export function encodeIdentifiedUser(value: IdentifiedUser): unknown {
    const output: Record<string, unknown> = {};
    output["id"] = encodeJsonValue(value.id);
    output["first_name"] = encodeJsonValue(value.firstName);
    output["last_name"] = encodeJsonValue(value.lastName);
    output["username"] = encodeJsonValue(value.username);
    if (value.email !== undefined) {
        output["email"] = value.email === null ? null : encodeJsonValue(value.email);
    }
    if (value.phone !== undefined) {
        output["phone"] = value.phone === null ? null : encodeJsonValue(value.phone);
    }
    if (value.hireDate !== undefined) {
        output["hire_date"] = value.hireDate === null ? null : encodeJsonValue(value.hireDate);
    }
    if (value.birthDate !== undefined) {
        output["birth_date"] = value.birthDate === null ? null : encodeJsonValue(value.birthDate);
    }
    if (value.picture !== undefined) {
        output["picture"] = value.picture === null ? null : encodeJsonValue(value.picture);
    }
    output["creation_date"] = encodeJsonValue(value.creationDate);
    output["last_update_date"] = encodeJsonValue(value.lastUpdateDate);
    return output;
}

export interface IdUser {
    id: number;
}

export function decodeIdUser(value: unknown): IdUser {
    const object = (value ?? {}) as Record<string, unknown>;
    return {
        id: Number(object["id"]),
    };
}

export function encodeIdUser(value: IdUser): unknown {
    const output: Record<string, unknown> = {};
    output["id"] = encodeJsonValue(value.id);
    return output;
}

export interface PatchedUser {
    firstName: PatchableValue<string>;
    lastName: PatchableValue<string>;
    username: PatchableValue<string>;
    email?: PatchableValue<string> | null;
    phone?: PatchableValue<string> | null;
    hireDate?: PatchableValue<Date> | null;
    birthDate?: PatchableValue<Date> | null;
    picture?: PatchableValue<URL> | null;
}

export function decodePatchedUser(value: unknown): PatchedUser {
    const object = (value ?? {}) as Record<string, unknown>;
    return {
        firstName: object["first_name"] as PatchableValue<string>,
        lastName: object["last_name"] as PatchableValue<string>,
        username: object["username"] as PatchableValue<string>,
        email: object["email"] == null ? null : object["email"] as PatchableValue<string>,
        phone: object["phone"] == null ? null : object["phone"] as PatchableValue<string>,
        hireDate: object["hire_date"] == null ? null : object["hire_date"] as PatchableValue<Date>,
        birthDate: object["birth_date"] == null ? null : object["birth_date"] as PatchableValue<Date>,
        picture: object["picture"] == null ? null : object["picture"] as PatchableValue<URL>,
    };
}

export function encodePatchedUser(value: PatchedUser): unknown {
    const output: Record<string, unknown> = {};
    output["first_name"] = encodeJsonValue(value.firstName);
    output["last_name"] = encodeJsonValue(value.lastName);
    output["username"] = encodeJsonValue(value.username);
    if (value.email !== undefined) {
        output["email"] = value.email === null ? null : encodeJsonValue(value.email);
    }
    if (value.phone !== undefined) {
        output["phone"] = value.phone === null ? null : encodeJsonValue(value.phone);
    }
    if (value.hireDate !== undefined) {
        output["hire_date"] = value.hireDate === null ? null : encodeJsonValue(value.hireDate);
    }
    if (value.birthDate !== undefined) {
        output["birth_date"] = value.birthDate === null ? null : encodeJsonValue(value.birthDate);
    }
    if (value.picture !== undefined) {
        output["picture"] = value.picture === null ? null : encodeJsonValue(value.picture);
    }
    return output;
}

export interface Role {
    name: string;
}

export function decodeRole(value: unknown): Role {
    const object = (value ?? {}) as Record<string, unknown>;
    return {
        name: String(object["name"]),
    };
}

export function encodeRole(value: Role): unknown {
    const output: Record<string, unknown> = {};
    output["name"] = encodeJsonValue(value.name);
    return output;
}

export interface IdentifiedRole {
    id: number;
    name: string;
    creationDate: Date;
    lastUpdateDate: Date;
}

export function decodeIdentifiedRole(value: unknown): IdentifiedRole {
    const object = (value ?? {}) as Record<string, unknown>;
    return {
        id: Number(object["id"]),
        name: String(object["name"]),
        creationDate: decodeDate(object["creation_date"]),
        lastUpdateDate: decodeDate(object["last_update_date"]),
    };
}

export function encodeIdentifiedRole(value: IdentifiedRole): unknown {
    const output: Record<string, unknown> = {};
    output["id"] = encodeJsonValue(value.id);
    output["name"] = encodeJsonValue(value.name);
    output["creation_date"] = encodeJsonValue(value.creationDate);
    output["last_update_date"] = encodeJsonValue(value.lastUpdateDate);
    return output;
}

export interface IdRole {
    id: number;
}

export function decodeIdRole(value: unknown): IdRole {
    const object = (value ?? {}) as Record<string, unknown>;
    return {
        id: Number(object["id"]),
    };
}

export function encodeIdRole(value: IdRole): unknown {
    const output: Record<string, unknown> = {};
    output["id"] = encodeJsonValue(value.id);
    return output;
}

export interface PatchedRole {
    name: PatchableValue<string>;
}

export function decodePatchedRole(value: unknown): PatchedRole {
    const object = (value ?? {}) as Record<string, unknown>;
    return {
        name: object["name"] as PatchableValue<string>,
    };
}

export function encodePatchedRole(value: PatchedRole): unknown {
    const output: Record<string, unknown> = {};
    output["name"] = encodeJsonValue(value.name);
    return output;
}

export interface Group {
    name: string;
}

export function decodeGroup(value: unknown): Group {
    const object = (value ?? {}) as Record<string, unknown>;
    return {
        name: String(object["name"]),
    };
}

export function encodeGroup(value: Group): unknown {
    const output: Record<string, unknown> = {};
    output["name"] = encodeJsonValue(value.name);
    return output;
}

export interface IdentifiedGroup {
    id: number;
    name: string;
    creationDate: Date;
    lastUpdateDate: Date;
}

export function decodeIdentifiedGroup(value: unknown): IdentifiedGroup {
    const object = (value ?? {}) as Record<string, unknown>;
    return {
        id: Number(object["id"]),
        name: String(object["name"]),
        creationDate: decodeDate(object["creation_date"]),
        lastUpdateDate: decodeDate(object["last_update_date"]),
    };
}

export function encodeIdentifiedGroup(value: IdentifiedGroup): unknown {
    const output: Record<string, unknown> = {};
    output["id"] = encodeJsonValue(value.id);
    output["name"] = encodeJsonValue(value.name);
    output["creation_date"] = encodeJsonValue(value.creationDate);
    output["last_update_date"] = encodeJsonValue(value.lastUpdateDate);
    return output;
}

export interface IdGroup {
    id: number;
}

export function decodeIdGroup(value: unknown): IdGroup {
    const object = (value ?? {}) as Record<string, unknown>;
    return {
        id: Number(object["id"]),
    };
}

export function encodeIdGroup(value: IdGroup): unknown {
    const output: Record<string, unknown> = {};
    output["id"] = encodeJsonValue(value.id);
    return output;
}

export interface PatchedGroup {
    name: PatchableValue<string>;
}

export function decodePatchedGroup(value: unknown): PatchedGroup {
    const object = (value ?? {}) as Record<string, unknown>;
    return {
        name: object["name"] as PatchableValue<string>,
    };
}

export function encodePatchedGroup(value: PatchedGroup): unknown {
    const output: Record<string, unknown> = {};
    output["name"] = encodeJsonValue(value.name);
    return output;
}

export interface Structure {
    name: string;
    type_: StructureType;
}

export function decodeStructure(value: unknown): Structure {
    const object = (value ?? {}) as Record<string, unknown>;
    return {
        name: String(object["name"]),
        type_: decodeStructureType(object["type"]),
    };
}

export function encodeStructure(value: Structure): unknown {
    const output: Record<string, unknown> = {};
    output["name"] = encodeJsonValue(value.name);
    output["type"] = encodeStructureType(value.type_);
    return output;
}

export interface IdentifiedStructure {
    id: number;
    name: string;
    type_: StructureType;
    creationDate: Date;
    lastUpdateDate: Date;
}

export function decodeIdentifiedStructure(value: unknown): IdentifiedStructure {
    const object = (value ?? {}) as Record<string, unknown>;
    return {
        id: Number(object["id"]),
        name: String(object["name"]),
        type_: decodeStructureType(object["type"]),
        creationDate: decodeDate(object["creation_date"]),
        lastUpdateDate: decodeDate(object["last_update_date"]),
    };
}

export function encodeIdentifiedStructure(value: IdentifiedStructure): unknown {
    const output: Record<string, unknown> = {};
    output["id"] = encodeJsonValue(value.id);
    output["name"] = encodeJsonValue(value.name);
    output["type"] = encodeStructureType(value.type_);
    output["creation_date"] = encodeJsonValue(value.creationDate);
    output["last_update_date"] = encodeJsonValue(value.lastUpdateDate);
    return output;
}

export interface IdStructure {
    id: number;
}

export function decodeIdStructure(value: unknown): IdStructure {
    const object = (value ?? {}) as Record<string, unknown>;
    return {
        id: Number(object["id"]),
    };
}

export function encodeIdStructure(value: IdStructure): unknown {
    const output: Record<string, unknown> = {};
    output["id"] = encodeJsonValue(value.id);
    return output;
}

export interface PatchedStructure {
    name: PatchableValue<string>;
    type_: PatchableValue<StructureType>;
}

export function decodePatchedStructure(value: unknown): PatchedStructure {
    const object = (value ?? {}) as Record<string, unknown>;
    return {
        name: object["name"] as PatchableValue<string>,
        type_: object["type"] as PatchableValue<StructureType>,
    };
}

export function encodePatchedStructure(value: PatchedStructure): unknown {
    const output: Record<string, unknown> = {};
    output["name"] = encodeJsonValue(value.name);
    output["type"] = encodeJsonValue(value.type_);
    return output;
}

export type SampleVisibility = "public" | "internal" | "private" | "__garbage__";

export function decodeSampleVisibility(value: unknown): SampleVisibility {
    const rawValue = String(value);
    switch (rawValue) {
        case "public":
        case "internal":
        case "private":
            return rawValue as SampleVisibility;
        default:
            return "__garbage__";
    }
}

export function encodeSampleVisibility(value: SampleVisibility): unknown {
    return value;
}

export interface PrimitiveMatrix {
    uuid: string;
    title: string;
    count: number;
    largeCount: number;
    mediumCount: number;
    smallCount: number;
    tinyCount: number;
    unsignedCount: number;
    unsignedLargeCount: number;
    unsignedMediumCount: number;
    unsignedSmallCount: number;
    unsignedTinyCount: number;
    ratio: number;
    enabled: boolean;
    createdAt: Date;
    businessDate: string;
    businessTime: string;
    callbackUrl?: URL | null;
    payload: ArrayBuffer;
    metadata: Record<string, string | null>;
    aliases: string[];
    steps: number[];
    visibility: SampleVisibility;
    score: SampleScore;
    audit: AuditStamp;
    related: NamedObject[];
    externalWindow: DateInterval;
    archived: boolean;
}

export function decodePrimitiveMatrix(value: unknown): PrimitiveMatrix {
    const object = (value ?? {}) as Record<string, unknown>;
    return {
        uuid: String(object["uuid"]),
        title: String(object["title"]),
        count: Number(object["count"]),
        largeCount: Number(object["large_count"]),
        mediumCount: Number(object["medium_count"]),
        smallCount: Number(object["small_count"]),
        tinyCount: Number(object["tiny_count"]),
        unsignedCount: Number(object["unsigned_count"]),
        unsignedLargeCount: Number(object["unsigned_large_count"]),
        unsignedMediumCount: Number(object["unsigned_medium_count"]),
        unsignedSmallCount: Number(object["unsigned_small_count"]),
        unsignedTinyCount: Number(object["unsigned_tiny_count"]),
        ratio: Number(object["ratio"]),
        enabled: Boolean(object["enabled"]),
        createdAt: decodeDate(object["created_at"]),
        businessDate: String(object["business_date"]),
        businessTime: String(object["business_time"]),
        callbackUrl: object["callback_url"] == null ? null : decodeUrl(object["callback_url"]),
        payload: decodeArrayBuffer(object["payload"]),
        metadata: Object.fromEntries(Object.entries((object["metadata"] ?? {}) as Record<string, unknown>).map(([key, item]) => [key, item == null ? null : String(item)])),
        aliases: ((object["aliases"] ?? []) as unknown[]).map((item) => String(item)),
        steps: ((object["steps"] ?? []) as unknown[]).map((item) => Number(item)),
        visibility: decodeSampleVisibility(object["visibility"]),
        score: decodeSampleScore(object["score"]),
        audit: decodeAuditStamp(object["audit"]),
        related: ((object["related"] ?? []) as unknown[]).map((item) => decodeNamedObject(item)),
        externalWindow: object["external_window"] as DateInterval,
        archived: Boolean(object["archived"]),
    };
}

export function encodePrimitiveMatrix(value: PrimitiveMatrix): unknown {
    const output: Record<string, unknown> = {};
    output["uuid"] = encodeJsonValue(value.uuid);
    output["title"] = encodeJsonValue(value.title);
    output["count"] = encodeJsonValue(value.count);
    output["large_count"] = encodeJsonValue(value.largeCount);
    output["medium_count"] = encodeJsonValue(value.mediumCount);
    output["small_count"] = encodeJsonValue(value.smallCount);
    output["tiny_count"] = encodeJsonValue(value.tinyCount);
    output["unsigned_count"] = encodeJsonValue(value.unsignedCount);
    output["unsigned_large_count"] = encodeJsonValue(value.unsignedLargeCount);
    output["unsigned_medium_count"] = encodeJsonValue(value.unsignedMediumCount);
    output["unsigned_small_count"] = encodeJsonValue(value.unsignedSmallCount);
    output["unsigned_tiny_count"] = encodeJsonValue(value.unsignedTinyCount);
    output["ratio"] = encodeJsonValue(value.ratio);
    output["enabled"] = encodeJsonValue(value.enabled);
    output["created_at"] = encodeJsonValue(value.createdAt);
    output["business_date"] = encodeJsonValue(value.businessDate);
    output["business_time"] = encodeJsonValue(value.businessTime);
    if (value.callbackUrl !== undefined) {
        output["callback_url"] = value.callbackUrl === null ? null : encodeJsonValue(value.callbackUrl);
    }
    output["payload"] = encodeJsonValue(value.payload);
    output["metadata"] = Object.fromEntries(Object.entries(value.metadata).map(([key, item]) => [key, item == null ? null : encodeJsonValue(item)]));
    output["aliases"] = value.aliases.map((item) => encodeJsonValue(item));
    output["steps"] = value.steps.map((item) => encodeJsonValue(item));
    output["visibility"] = encodeSampleVisibility(value.visibility);
    output["score"] = encodeSampleScore(value.score);
    output["audit"] = encodeAuditStamp(value.audit);
    output["related"] = value.related.map((item) => encodeNamedObject(item));
    output["external_window"] = encodeJsonValue(value.externalWindow);
    output["archived"] = encodeJsonValue(value.archived);
    return output;
}

export type SampleScore = 10 | 50 | 100;

export function decodeSampleScore(value: unknown): SampleScore {
    const rawValue = Number(value);
    switch (rawValue) {
        case 10:
        case 50:
        case 100:
            return rawValue as SampleScore;
        default:
            throw new Error(`Unknown SampleScore value: ${String(value)}`);
    }
}

export function encodeSampleScore(value: SampleScore): unknown {
    return value;
}

export interface EmailNotification {
    id: string;
    subject: string;
    body: string;
    recipients: string[];
}

export function decodeEmailNotification(value: unknown): EmailNotification {
    const object = (value ?? {}) as Record<string, unknown>;
    return {
        id: String(object["id"]),
        subject: String(object["subject"]),
        body: String(object["body"]),
        recipients: ((object["recipients"] ?? []) as unknown[]).map((item) => String(item)),
    };
}

export function encodeEmailNotification(value: EmailNotification): unknown {
    const output: Record<string, unknown> = {};
    output["id"] = encodeJsonValue(value.id);
    output["subject"] = encodeJsonValue(value.subject);
    output["body"] = encodeJsonValue(value.body);
    output["recipients"] = value.recipients.map((item) => encodeJsonValue(item));
    return output;
}

export interface PushNotification {
    id: string;
    title: string;
    body: string;
    customData: Record<string, string | null>;
}

export function decodePushNotification(value: unknown): PushNotification {
    const object = (value ?? {}) as Record<string, unknown>;
    return {
        id: String(object["id"]),
        title: String(object["title"]),
        body: String(object["body"]),
        customData: Object.fromEntries(Object.entries((object["custom_data"] ?? {}) as Record<string, unknown>).map(([key, item]) => [key, item == null ? null : String(item)])),
    };
}

export function encodePushNotification(value: PushNotification): unknown {
    const output: Record<string, unknown> = {};
    output["id"] = encodeJsonValue(value.id);
    output["title"] = encodeJsonValue(value.title);
    output["body"] = encodeJsonValue(value.body);
    output["custom_data"] = Object.fromEntries(Object.entries(value.customData).map(([key, item]) => [key, item == null ? null : encodeJsonValue(item)]));
    return output;
}

export type NotificationEnvelope =
    | { objectType: "email"; payload: EmailNotification;
visibility: SampleVisibility;
sentAt?: Date | null; }
    | { objectType: "push"; payload: PushNotification;
visibility: SampleVisibility;
sentAt?: Date | null; }
    | { objectType: "__garbage__"; rawValue: unknown };

export function decodeNotificationEnvelope(value: unknown): NotificationEnvelope {
    const object = (value ?? {}) as Record<string, unknown>;
    const objectType = object["channel"];
    switch (objectType) {
    case "email":
        return {
            objectType: "email",
            payload: decodeEmailNotification((object["payload"] ?? object["data"])),
            visibility: decodeSampleVisibility(object["visibility"]),
            sentAt: object["sent_at"] == null ? null : decodeDate(object["sent_at"]),
        };
    case "push":
        return {
            objectType: "push",
            payload: decodePushNotification((object["payload"] ?? object["data"])),
            visibility: decodeSampleVisibility(object["visibility"]),
            sentAt: object["sent_at"] == null ? null : decodeDate(object["sent_at"]),
        };
        default:
            return { objectType: "__garbage__", rawValue: value };
    }
}

export function encodeNotificationEnvelope(value: NotificationEnvelope): unknown {
    if (value.objectType === "__garbage__") {
        return value.rawValue;
    }
    const output: Record<string, unknown> = {};
    switch (value.objectType) {
    case "email":
        output["channel"] = value.objectType;
        output["visibility"] = encodeSampleVisibility(value.visibility);
        if (value.sentAt !== undefined) {
            output["sent_at"] = value.sentAt === null ? null : encodeJsonValue(value.sentAt);
        }
        output["payload"] = encodeEmailNotification(value.payload);
        return output;
    case "push":
        output["channel"] = value.objectType;
        output["visibility"] = encodeSampleVisibility(value.visibility);
        if (value.sentAt !== undefined) {
            output["sent_at"] = value.sentAt === null ? null : encodeJsonValue(value.sentAt);
        }
        output["payload"] = encodePushNotification(value.payload);
        return output;
    }
}

export interface UploadReceipt {
    uploadId: string;
    bytes: number;
    state: UploadState;
}

export function decodeUploadReceipt(value: unknown): UploadReceipt {
    const object = (value ?? {}) as Record<string, unknown>;
    return {
        uploadId: String(object["upload_id"]),
        bytes: Number(object["bytes"]),
        state: decodeUploadState(object["state"]),
    };
}

export function encodeUploadReceipt(value: UploadReceipt): unknown {
    const output: Record<string, unknown> = {};
    output["upload_id"] = encodeJsonValue(value.uploadId);
    output["bytes"] = encodeJsonValue(value.bytes);
    output["state"] = encodeUploadState(value.state);
    return output;
}

export type UploadState = "queued" | "stored" | "scanned";

export function decodeUploadState(value: unknown): UploadState {
    const rawValue = String(value);
    switch (rawValue) {
        case "queued":
        case "stored":
        case "scanned":
            return rawValue as UploadState;
        default:
            throw new Error(`Unknown UploadState value: ${String(value)}`);
    }
}

export function encodeUploadState(value: UploadState): unknown {
    return value;
}

export interface DeleteReceiptRequest {
    uploadIds: string[];
    reason?: string | null;
}

export function decodeDeleteReceiptRequest(value: unknown): DeleteReceiptRequest {
    const object = (value ?? {}) as Record<string, unknown>;
    return {
        uploadIds: ((object["upload_ids"] ?? []) as unknown[]).map((item) => String(item)),
        reason: object["reason"] == null ? null : String(object["reason"]),
    };
}

export function encodeDeleteReceiptRequest(value: DeleteReceiptRequest): unknown {
    const output: Record<string, unknown> = {};
    output["upload_ids"] = value.uploadIds.map((item) => encodeJsonValue(item));
    if (value.reason !== undefined) {
        output["reason"] = value.reason === null ? null : encodeJsonValue(value.reason);
    }
    return output;
}

export type TenantStatus = "trial" | "active" | "suspended";

export function decodeTenantStatus(value: unknown): TenantStatus {
    const rawValue = String(value);
    switch (rawValue) {
        case "trial":
        case "active":
        case "suspended":
            return rawValue as TenantStatus;
        default:
            throw new Error(`Unknown TenantStatus value: ${String(value)}`);
    }
}

export function encodeTenantStatus(value: TenantStatus): unknown {
    return value;
}

export interface Project {
    name: string;
    status: TenantStatus;
    owners: NamedObject[];
    labels: Record<string, string | null>;
}

export function decodeProject(value: unknown): Project {
    const object = (value ?? {}) as Record<string, unknown>;
    return {
        name: String(object["name"]),
        status: decodeTenantStatus(object["status"]),
        owners: ((object["owners"] ?? []) as unknown[]).map((item) => decodeNamedObject(item)),
        labels: Object.fromEntries(Object.entries((object["labels"] ?? {}) as Record<string, unknown>).map(([key, item]) => [key, item == null ? null : String(item)])),
    };
}

export function encodeProject(value: Project): unknown {
    const output: Record<string, unknown> = {};
    output["name"] = encodeJsonValue(value.name);
    output["status"] = encodeTenantStatus(value.status);
    output["owners"] = value.owners.map((item) => encodeNamedObject(item));
    output["labels"] = Object.fromEntries(Object.entries(value.labels).map(([key, item]) => [key, item == null ? null : encodeJsonValue(item)]));
    return output;
}

export interface IdentifiedProject {
    id: string;
    name: string;
    status: TenantStatus;
    owners: NamedObject[];
    labels: Record<string, string | null>;
    creationDate: Date;
    lastUpdateDate: Date;
}

export function decodeIdentifiedProject(value: unknown): IdentifiedProject {
    const object = (value ?? {}) as Record<string, unknown>;
    return {
        id: String(object["id"]),
        name: String(object["name"]),
        status: decodeTenantStatus(object["status"]),
        owners: ((object["owners"] ?? []) as unknown[]).map((item) => decodeNamedObject(item)),
        labels: Object.fromEntries(Object.entries((object["labels"] ?? {}) as Record<string, unknown>).map(([key, item]) => [key, item == null ? null : String(item)])),
        creationDate: decodeDate(object["creation_date"]),
        lastUpdateDate: decodeDate(object["last_update_date"]),
    };
}

export function encodeIdentifiedProject(value: IdentifiedProject): unknown {
    const output: Record<string, unknown> = {};
    output["id"] = encodeJsonValue(value.id);
    output["name"] = encodeJsonValue(value.name);
    output["status"] = encodeTenantStatus(value.status);
    output["owners"] = value.owners.map((item) => encodeNamedObject(item));
    output["labels"] = Object.fromEntries(Object.entries(value.labels).map(([key, item]) => [key, item == null ? null : encodeJsonValue(item)]));
    output["creation_date"] = encodeJsonValue(value.creationDate);
    output["last_update_date"] = encodeJsonValue(value.lastUpdateDate);
    return output;
}

export interface IdProject {
    id: string;
}

export function decodeIdProject(value: unknown): IdProject {
    const object = (value ?? {}) as Record<string, unknown>;
    return {
        id: String(object["id"]),
    };
}

export function encodeIdProject(value: IdProject): unknown {
    const output: Record<string, unknown> = {};
    output["id"] = encodeJsonValue(value.id);
    return output;
}

export interface PatchedProject {
    name: PatchableValue<string>;
    status: PatchableValue<TenantStatus>;
    owners: PatchableValue<NamedObject[]>;
    labels: PatchableValue<Record<string, string | null>>;
}

export function decodePatchedProject(value: unknown): PatchedProject {
    const object = (value ?? {}) as Record<string, unknown>;
    return {
        name: object["name"] as PatchableValue<string>,
        status: object["status"] as PatchableValue<TenantStatus>,
        owners: object["owners"] as PatchableValue<NamedObject[]>,
        labels: object["labels"] as PatchableValue<Record<string, string | null>>,
    };
}

export function encodePatchedProject(value: PatchedProject): unknown {
    const output: Record<string, unknown> = {};
    output["name"] = encodeJsonValue(value.name);
    output["status"] = encodeJsonValue(value.status);
    output["owners"] = encodeJsonValue(value.owners);
    output["labels"] = encodeJsonValue(value.labels);
    return output;
}

export interface Task {
    title: string;
    details?: string | null;
    dueAt?: Date | null;
    done: boolean;
}

export function decodeTask(value: unknown): Task {
    const object = (value ?? {}) as Record<string, unknown>;
    return {
        title: String(object["title"]),
        details: object["details"] == null ? null : String(object["details"]),
        dueAt: object["due_at"] == null ? null : decodeDate(object["due_at"]),
        done: Boolean(object["done"]),
    };
}

export function encodeTask(value: Task): unknown {
    const output: Record<string, unknown> = {};
    output["title"] = encodeJsonValue(value.title);
    if (value.details !== undefined) {
        output["details"] = value.details === null ? null : encodeJsonValue(value.details);
    }
    if (value.dueAt !== undefined) {
        output["due_at"] = value.dueAt === null ? null : encodeJsonValue(value.dueAt);
    }
    output["done"] = encodeJsonValue(value.done);
    return output;
}

export interface IdentifiedTask {
    id: string;
    title: string;
    details?: string | null;
    dueAt?: Date | null;
    done: boolean;
    creationDate: Date;
    lastUpdateDate: Date;
}

export function decodeIdentifiedTask(value: unknown): IdentifiedTask {
    const object = (value ?? {}) as Record<string, unknown>;
    return {
        id: String(object["id"]),
        title: String(object["title"]),
        details: object["details"] == null ? null : String(object["details"]),
        dueAt: object["due_at"] == null ? null : decodeDate(object["due_at"]),
        done: Boolean(object["done"]),
        creationDate: decodeDate(object["creation_date"]),
        lastUpdateDate: decodeDate(object["last_update_date"]),
    };
}

export function encodeIdentifiedTask(value: IdentifiedTask): unknown {
    const output: Record<string, unknown> = {};
    output["id"] = encodeJsonValue(value.id);
    output["title"] = encodeJsonValue(value.title);
    if (value.details !== undefined) {
        output["details"] = value.details === null ? null : encodeJsonValue(value.details);
    }
    if (value.dueAt !== undefined) {
        output["due_at"] = value.dueAt === null ? null : encodeJsonValue(value.dueAt);
    }
    output["done"] = encodeJsonValue(value.done);
    output["creation_date"] = encodeJsonValue(value.creationDate);
    output["last_update_date"] = encodeJsonValue(value.lastUpdateDate);
    return output;
}

export interface IdTask {
    id: string;
}

export function decodeIdTask(value: unknown): IdTask {
    const object = (value ?? {}) as Record<string, unknown>;
    return {
        id: String(object["id"]),
    };
}

export function encodeIdTask(value: IdTask): unknown {
    const output: Record<string, unknown> = {};
    output["id"] = encodeJsonValue(value.id);
    return output;
}

export interface PatchedTask {
    title: PatchableValue<string>;
    details?: PatchableValue<string> | null;
    dueAt?: PatchableValue<Date> | null;
    done: PatchableValue<boolean>;
}

export function decodePatchedTask(value: unknown): PatchedTask {
    const object = (value ?? {}) as Record<string, unknown>;
    return {
        title: object["title"] as PatchableValue<string>,
        details: object["details"] == null ? null : object["details"] as PatchableValue<string>,
        dueAt: object["due_at"] == null ? null : object["due_at"] as PatchableValue<Date>,
        done: object["done"] as PatchableValue<boolean>,
    };
}

export function encodePatchedTask(value: PatchedTask): unknown {
    const output: Record<string, unknown> = {};
    output["title"] = encodeJsonValue(value.title);
    if (value.details !== undefined) {
        output["details"] = value.details === null ? null : encodeJsonValue(value.details);
    }
    if (value.dueAt !== undefined) {
        output["due_at"] = value.dueAt === null ? null : encodeJsonValue(value.dueAt);
    }
    output["done"] = encodeJsonValue(value.done);
    return output;
}

export interface CompleteTaskRequest {
    completedAt: Date;
}

export function decodeCompleteTaskRequest(value: unknown): CompleteTaskRequest {
    const object = (value ?? {}) as Record<string, unknown>;
    return {
        completedAt: decodeDate(object["completed_at"]),
    };
}

export function encodeCompleteTaskRequest(value: CompleteTaskRequest): unknown {
    const output: Record<string, unknown> = {};
    output["completed_at"] = encodeJsonValue(value.completedAt);
    return output;
}
