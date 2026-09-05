// Generated code. Do not edit.

import {
    ApiClient,
    ApiOperationResult,
    ApiRequest,
    ApiResponse,
    DateInterval,
    LocalizedData,
    MultipartBody,
    PagedResults,
    PatchableValue,
    appendQueryParameter,
    decodePagedResults,
    encodeFormValue,
    makeCookieHeader
} from "./runtime.js";
import type * as Models from "./models.js";
import * as ModelCodecs from "./models.js";

export interface AdminUserCreateRequest {
    body: Models.User;
}

export interface AdminUserUpdateRequest {
    userId: number;
    body: Models.User;
}

export interface AdminUserPatchRequest {
    userId: number;
    body: Models.PatchedUser;
}

export interface AdminUserDeleteRequest {
    userId: number;
}

export interface AdminUserListRequest {
    text?: string | null;
}

export interface AdminUserGetRequest {
    userId: number;
}

export interface AdminRoleCreateRequest {
    body: Models.Role;
}

export interface AdminRoleUpdateRequest {
    roleId: number;
    body: Models.Role;
}

export interface AdminRolePatchRequest {
    roleId: number;
    body: Models.PatchedRole;
}

export interface AdminRoleDeleteRequest {
    roleId: number;
}

export interface AdminRoleListRequest {
    text?: string | null;
}

export interface AdminRoleGetRequest {
    roleId: number;
}

export interface AdminGroupCreateRequest {
    body: Models.Group;
}

export interface AdminGroupUpdateRequest {
    groupId: number;
    body: Models.Group;
}

export interface AdminGroupPatchRequest {
    groupId: number;
    body: Models.PatchedGroup;
}

export interface AdminGroupDeleteRequest {
    groupId: number;
}

export interface AdminGroupListRequest {
    text?: string | null;
}

export interface AdminGroupGetRequest {
    groupId: number;
}

export interface LocationStructureCreateRequest {
    body: Models.Structure;
}

export interface LocationStructureUpdateRequest {
    structureId: number;
    body: Models.Structure;
}

export interface LocationStructurePatchRequest {
    structureId: number;
    body: Models.PatchedStructure;
}

export interface LocationStructureDeleteRequest {
    structureId: number;
}

export interface LocationStructureListRequest {
    text?: string | null;
    type_: Models.StructureType[];
}

export interface LocationStructureGetRequest {
    structureId: number;
}

export interface ShowcaseSampleModelsGetMatrixRequest {
    matrixId: string;
    visible?: boolean | null;
    visibility?: Models.SampleVisibility | null;
    scores?: Models.SampleScore[] | null;
    traceId?: string | null;
    sampleSession?: string | null;
    apiKey?: string | null;
}

export interface ShowcaseSampleModelsCreateNotificationRequest {
    idempotencyKey?: string | null;
    apiKey?: string | null;
    body: Models.NotificationEnvelope;
}

export interface ShowcaseSampleModelsFollowRuntimeUrlRequest {
    requestUrl: string | URL;
    apiKey?: string | null;
}

export interface ShowcaseTransportUploadMultipartRequest {
    compress?: boolean | null;
    apiKey?: string | null;
    body: MultipartBody;
}

export interface ShowcaseTransportUploadFileRequest {
    apiKey?: string | null;
    body: Blob | File;
}

export interface ShowcaseTransportUploadBinaryRequest {
    contentMd5?: string | null;
    apiKey?: string | null;
    body: ArrayBuffer;
}

export interface ShowcaseTransportDeleteWithBodyRequest {
    apiKey?: string | null;
    body: Models.DeleteReceiptRequest;
}

export interface TenantProjectCreateRequest {
    tenantId: string;
    body: Models.Project;
}

export interface TenantProjectUpdateRequest {
    tenantId: string;
    projectId: string;
    body: Models.Project;
}

export interface TenantProjectDeleteRequest {
    tenantId: string;
    projectId: string;
}

export interface TenantProjectListRequest {
    tenantId: string;
    status?: Models.TenantStatus[] | null;
    includeArchived?: boolean | null;
}

export interface TenantProjectGetRequest {
    tenantId: string;
    projectId: string;
}

export interface TenantProjectArchiveRequest {
    tenantId: string;
    projectId: string;
    cascade?: boolean | null;
    apiKey?: string | null;
}

export interface TenantProjectTaskCreateRequest {
    tenantId: string;
    projectId: string;
    body: Models.Task;
}

export interface TenantProjectTaskPatchRequest {
    tenantId: string;
    projectId: string;
    taskId: string;
    body: Models.PatchedTask;
}

export interface TenantProjectTaskListRequest {
    tenantId: string;
    projectId: string;
    done?: boolean | null;
}

export interface TenantProjectTaskGetRequest {
    tenantId: string;
    projectId: string;
    taskId: string;
}

export interface TenantProjectTaskCompleteRequest {
    tenantId: string;
    projectId: string;
    taskId: string;
    notify?: boolean | null;
    apiKey?: string | null;
    body: Models.CompleteTaskRequest;
}

export function buildAdminUserCreateRequest(request: AdminUserCreateRequest): ApiRequest {
    const path = { kind: "relative" as const, path: "/user" };
    const queryParameters: Record<string, string> = {};
    const headers: Record<string, string> = {};
    const body = ModelCodecs.encodeUser(request.body);
    return {
        method: "POST",
        path,
        queryParameters,
        headers,
        body,
        contentType: "application/json",
        accept: "application/json"
    };
}

export function buildAdminUserUpdateRequest(request: AdminUserUpdateRequest): ApiRequest {
    let requestPath = "/user/{user_id}";
    requestPath = requestPath.replace(
        "{user_id}",
        encodeURIComponent(encodeFormValue(request.userId))
    );
    const path = { kind: "relative" as const, path: requestPath };
    const queryParameters: Record<string, string> = {};
    const headers: Record<string, string> = {};
    const body = ModelCodecs.encodeUser(request.body);
    return {
        method: "PUT",
        path,
        queryParameters,
        headers,
        body,
        contentType: "application/json",
        accept: "application/json"
    };
}

export function buildAdminUserPatchRequest(request: AdminUserPatchRequest): ApiRequest {
    let requestPath = "/user/{user_id}";
    requestPath = requestPath.replace(
        "{user_id}",
        encodeURIComponent(encodeFormValue(request.userId))
    );
    const path = { kind: "relative" as const, path: requestPath };
    const queryParameters: Record<string, string> = {};
    const headers: Record<string, string> = {};
    const body = ModelCodecs.encodePatchedUser(request.body);
    return {
        method: "PATCH",
        path,
        queryParameters,
        headers,
        body,
        contentType: "application/json",
        accept: "application/json"
    };
}

export function buildAdminUserDeleteRequest(request: AdminUserDeleteRequest): ApiRequest {
    let requestPath = "/user/{user_id}";
    requestPath = requestPath.replace(
        "{user_id}",
        encodeURIComponent(encodeFormValue(request.userId))
    );
    const path = { kind: "relative" as const, path: requestPath };
    const queryParameters: Record<string, string> = {};
    const headers: Record<string, string> = {};
    const body = undefined;
    return {
        method: "DELETE",
        path,
        queryParameters,
        headers,
        body,
        contentType: null,
        accept: "*/*"
    };
}

export function buildAdminUserListRequest(request: AdminUserListRequest): ApiRequest {
    const path = { kind: "relative" as const, path: "/user" };
    const queryParameters: Record<string, string> = {};
    if (request.text !== undefined && request.text !== null) {
        appendQueryParameter(queryParameters, "text", request.text);
    }
    const headers: Record<string, string> = {};
    const body = undefined;
    return {
        method: "GET",
        path,
        queryParameters,
        headers,
        body,
        contentType: null,
        accept: "application/json"
    };
}

export function buildAdminUserGetRequest(request: AdminUserGetRequest): ApiRequest {
    let requestPath = "/user/{user_id}";
    requestPath = requestPath.replace(
        "{user_id}",
        encodeURIComponent(encodeFormValue(request.userId))
    );
    const path = { kind: "relative" as const, path: requestPath };
    const queryParameters: Record<string, string> = {};
    const headers: Record<string, string> = {};
    const body = undefined;
    return {
        method: "GET",
        path,
        queryParameters,
        headers,
        body,
        contentType: null,
        accept: "application/json"
    };
}

export function buildAdminRoleCreateRequest(request: AdminRoleCreateRequest): ApiRequest {
    const path = { kind: "relative" as const, path: "/role" };
    const queryParameters: Record<string, string> = {};
    const headers: Record<string, string> = {};
    const body = ModelCodecs.encodeRole(request.body);
    return {
        method: "POST",
        path,
        queryParameters,
        headers,
        body,
        contentType: "application/json",
        accept: "application/json"
    };
}

export function buildAdminRoleUpdateRequest(request: AdminRoleUpdateRequest): ApiRequest {
    let requestPath = "/role/{role_id}";
    requestPath = requestPath.replace(
        "{role_id}",
        encodeURIComponent(encodeFormValue(request.roleId))
    );
    const path = { kind: "relative" as const, path: requestPath };
    const queryParameters: Record<string, string> = {};
    const headers: Record<string, string> = {};
    const body = ModelCodecs.encodeRole(request.body);
    return {
        method: "PUT",
        path,
        queryParameters,
        headers,
        body,
        contentType: "application/json",
        accept: "application/json"
    };
}

export function buildAdminRolePatchRequest(request: AdminRolePatchRequest): ApiRequest {
    let requestPath = "/role/{role_id}";
    requestPath = requestPath.replace(
        "{role_id}",
        encodeURIComponent(encodeFormValue(request.roleId))
    );
    const path = { kind: "relative" as const, path: requestPath };
    const queryParameters: Record<string, string> = {};
    const headers: Record<string, string> = {};
    const body = ModelCodecs.encodePatchedRole(request.body);
    return {
        method: "PATCH",
        path,
        queryParameters,
        headers,
        body,
        contentType: "application/json",
        accept: "application/json"
    };
}

export function buildAdminRoleDeleteRequest(request: AdminRoleDeleteRequest): ApiRequest {
    let requestPath = "/role/{role_id}";
    requestPath = requestPath.replace(
        "{role_id}",
        encodeURIComponent(encodeFormValue(request.roleId))
    );
    const path = { kind: "relative" as const, path: requestPath };
    const queryParameters: Record<string, string> = {};
    const headers: Record<string, string> = {};
    const body = undefined;
    return {
        method: "DELETE",
        path,
        queryParameters,
        headers,
        body,
        contentType: null,
        accept: "*/*"
    };
}

export function buildAdminRoleListRequest(request: AdminRoleListRequest): ApiRequest {
    const path = { kind: "relative" as const, path: "/role" };
    const queryParameters: Record<string, string> = {};
    if (request.text !== undefined && request.text !== null) {
        appendQueryParameter(queryParameters, "text", request.text);
    }
    const headers: Record<string, string> = {};
    const body = undefined;
    return {
        method: "GET",
        path,
        queryParameters,
        headers,
        body,
        contentType: null,
        accept: "application/json"
    };
}

export function buildAdminRoleGetRequest(request: AdminRoleGetRequest): ApiRequest {
    let requestPath = "/role/{role_id}";
    requestPath = requestPath.replace(
        "{role_id}",
        encodeURIComponent(encodeFormValue(request.roleId))
    );
    const path = { kind: "relative" as const, path: requestPath };
    const queryParameters: Record<string, string> = {};
    const headers: Record<string, string> = {};
    const body = undefined;
    return {
        method: "GET",
        path,
        queryParameters,
        headers,
        body,
        contentType: null,
        accept: "application/json"
    };
}

export function buildAdminGroupCreateRequest(request: AdminGroupCreateRequest): ApiRequest {
    const path = { kind: "relative" as const, path: "/group" };
    const queryParameters: Record<string, string> = {};
    const headers: Record<string, string> = {};
    const body = ModelCodecs.encodeGroup(request.body);
    return {
        method: "POST",
        path,
        queryParameters,
        headers,
        body,
        contentType: "application/json",
        accept: "application/json"
    };
}

export function buildAdminGroupUpdateRequest(request: AdminGroupUpdateRequest): ApiRequest {
    let requestPath = "/group/{group_id}";
    requestPath = requestPath.replace(
        "{group_id}",
        encodeURIComponent(encodeFormValue(request.groupId))
    );
    const path = { kind: "relative" as const, path: requestPath };
    const queryParameters: Record<string, string> = {};
    const headers: Record<string, string> = {};
    const body = ModelCodecs.encodeGroup(request.body);
    return {
        method: "PUT",
        path,
        queryParameters,
        headers,
        body,
        contentType: "application/json",
        accept: "application/json"
    };
}

export function buildAdminGroupPatchRequest(request: AdminGroupPatchRequest): ApiRequest {
    let requestPath = "/group/{group_id}";
    requestPath = requestPath.replace(
        "{group_id}",
        encodeURIComponent(encodeFormValue(request.groupId))
    );
    const path = { kind: "relative" as const, path: requestPath };
    const queryParameters: Record<string, string> = {};
    const headers: Record<string, string> = {};
    const body = ModelCodecs.encodePatchedGroup(request.body);
    return {
        method: "PATCH",
        path,
        queryParameters,
        headers,
        body,
        contentType: "application/json",
        accept: "application/json"
    };
}

export function buildAdminGroupDeleteRequest(request: AdminGroupDeleteRequest): ApiRequest {
    let requestPath = "/group/{group_id}";
    requestPath = requestPath.replace(
        "{group_id}",
        encodeURIComponent(encodeFormValue(request.groupId))
    );
    const path = { kind: "relative" as const, path: requestPath };
    const queryParameters: Record<string, string> = {};
    const headers: Record<string, string> = {};
    const body = undefined;
    return {
        method: "DELETE",
        path,
        queryParameters,
        headers,
        body,
        contentType: null,
        accept: "*/*"
    };
}

export function buildAdminGroupListRequest(request: AdminGroupListRequest): ApiRequest {
    const path = { kind: "relative" as const, path: "/group" };
    const queryParameters: Record<string, string> = {};
    if (request.text !== undefined && request.text !== null) {
        appendQueryParameter(queryParameters, "text", request.text);
    }
    const headers: Record<string, string> = {};
    const body = undefined;
    return {
        method: "GET",
        path,
        queryParameters,
        headers,
        body,
        contentType: null,
        accept: "application/json"
    };
}

export function buildAdminGroupGetRequest(request: AdminGroupGetRequest): ApiRequest {
    let requestPath = "/group/{group_id}";
    requestPath = requestPath.replace(
        "{group_id}",
        encodeURIComponent(encodeFormValue(request.groupId))
    );
    const path = { kind: "relative" as const, path: requestPath };
    const queryParameters: Record<string, string> = {};
    const headers: Record<string, string> = {};
    const body = undefined;
    return {
        method: "GET",
        path,
        queryParameters,
        headers,
        body,
        contentType: null,
        accept: "application/json"
    };
}

export function buildLocationStructureCreateRequest(request: LocationStructureCreateRequest): ApiRequest {
    const path = { kind: "relative" as const, path: "/structure" };
    const queryParameters: Record<string, string> = {};
    const headers: Record<string, string> = {};
    const body = ModelCodecs.encodeStructure(request.body);
    return {
        method: "POST",
        path,
        queryParameters,
        headers,
        body,
        contentType: "application/json",
        accept: "application/json"
    };
}

export function buildLocationStructureUpdateRequest(request: LocationStructureUpdateRequest): ApiRequest {
    let requestPath = "/structure/{structure_id}";
    requestPath = requestPath.replace(
        "{structure_id}",
        encodeURIComponent(encodeFormValue(request.structureId))
    );
    const path = { kind: "relative" as const, path: requestPath };
    const queryParameters: Record<string, string> = {};
    const headers: Record<string, string> = {};
    const body = ModelCodecs.encodeStructure(request.body);
    return {
        method: "PUT",
        path,
        queryParameters,
        headers,
        body,
        contentType: "application/json",
        accept: "application/json"
    };
}

export function buildLocationStructurePatchRequest(request: LocationStructurePatchRequest): ApiRequest {
    let requestPath = "/structure/{structure_id}";
    requestPath = requestPath.replace(
        "{structure_id}",
        encodeURIComponent(encodeFormValue(request.structureId))
    );
    const path = { kind: "relative" as const, path: requestPath };
    const queryParameters: Record<string, string> = {};
    const headers: Record<string, string> = {};
    const body = ModelCodecs.encodePatchedStructure(request.body);
    return {
        method: "PATCH",
        path,
        queryParameters,
        headers,
        body,
        contentType: "application/json",
        accept: "application/json"
    };
}

export function buildLocationStructureDeleteRequest(request: LocationStructureDeleteRequest): ApiRequest {
    let requestPath = "/structure/{structure_id}";
    requestPath = requestPath.replace(
        "{structure_id}",
        encodeURIComponent(encodeFormValue(request.structureId))
    );
    const path = { kind: "relative" as const, path: requestPath };
    const queryParameters: Record<string, string> = {};
    const headers: Record<string, string> = {};
    const body = undefined;
    return {
        method: "DELETE",
        path,
        queryParameters,
        headers,
        body,
        contentType: null,
        accept: "*/*"
    };
}

export function buildLocationStructureListRequest(request: LocationStructureListRequest): ApiRequest {
    const path = { kind: "relative" as const, path: "/structure" };
    const queryParameters: Record<string, string> = {};
    if (request.text !== undefined && request.text !== null) {
        appendQueryParameter(queryParameters, "text", request.text);
    }
    appendQueryParameter(queryParameters, "type", request.type_);
    const headers: Record<string, string> = {};
    const body = undefined;
    return {
        method: "GET",
        path,
        queryParameters,
        headers,
        body,
        contentType: null,
        accept: "application/json"
    };
}

export function buildLocationStructureGetRequest(request: LocationStructureGetRequest): ApiRequest {
    let requestPath = "/structure/{structure_id}";
    requestPath = requestPath.replace(
        "{structure_id}",
        encodeURIComponent(encodeFormValue(request.structureId))
    );
    const path = { kind: "relative" as const, path: requestPath };
    const queryParameters: Record<string, string> = {};
    const headers: Record<string, string> = {};
    const body = undefined;
    return {
        method: "GET",
        path,
        queryParameters,
        headers,
        body,
        contentType: null,
        accept: "application/json"
    };
}

export function buildShowcaseSampleModelsGetMatrixRequest(request: ShowcaseSampleModelsGetMatrixRequest): ApiRequest {
    let requestPath = "/showcase/matrix/{matrix_id}";
    requestPath = requestPath.replace(
        "{matrix_id}",
        encodeURIComponent(encodeFormValue(request.matrixId))
    );
    const path = { kind: "relative" as const, path: requestPath };
    const queryParameters: Record<string, string> = {};
    appendQueryParameter(queryParameters, "visible", (request.visible ?? true));
    appendQueryParameter(queryParameters, "visibility", (request.visibility ?? "public"));
    if ((request.scores ?? [100]) !== undefined && (request.scores ?? [100]) !== null) {
        appendQueryParameter(queryParameters, "scores", (request.scores ?? [100]));
    }
    const headers: Record<string, string> = {};
    if (request.traceId !== undefined && request.traceId !== null) {
        appendQueryParameter(headers, "X-Trace-Id", request.traceId);
    }
    if ((request.apiKey ?? undefined) !== undefined && (request.apiKey ?? undefined) !== null) {
        appendQueryParameter(headers, "Authorization", (request.apiKey ?? undefined));
    }
    const cookies: Record<string, string> = {};
    if (request.sampleSession !== undefined && request.sampleSession !== null) {
        appendQueryParameter(cookies, "sample_session", request.sampleSession);
    }
    const cookieHeader = makeCookieHeader(cookies);
    if (cookieHeader) {
        headers.Cookie = cookieHeader;
    }
    const body = undefined;
    return {
        method: "GET",
        path,
        queryParameters,
        headers,
        body,
        contentType: null,
        accept: "application/json"
    };
}

export function buildShowcaseSampleModelsCreateNotificationRequest(request: ShowcaseSampleModelsCreateNotificationRequest): ApiRequest {
    const path = { kind: "relative" as const, path: "/showcase/notifications" };
    const queryParameters: Record<string, string> = {};
    const headers: Record<string, string> = {};
    if (request.idempotencyKey !== undefined && request.idempotencyKey !== null) {
        appendQueryParameter(headers, "Idempotency-Key", request.idempotencyKey);
    }
    appendQueryParameter(headers, "Authorization", (request.apiKey ?? undefined));
    const body = ModelCodecs.encodeNotificationEnvelope(request.body);
    return {
        method: "POST",
        path,
        queryParameters,
        headers,
        body,
        contentType: "application/json",
        accept: "application/json"
    };
}

export function buildShowcaseSampleModelsFollowRuntimeUrlRequest(request: ShowcaseSampleModelsFollowRuntimeUrlRequest): ApiRequest {
    const path = { kind: "runtime" as const, requestUrl: request.requestUrl };
    const queryParameters: Record<string, string> = {};
    const headers: Record<string, string> = {};
    if ((request.apiKey ?? undefined) !== undefined && (request.apiKey ?? undefined) !== null) {
        appendQueryParameter(headers, "Authorization", (request.apiKey ?? undefined));
    }
    const body = undefined;
    return {
        method: "GET",
        path,
        queryParameters,
        headers,
        body,
        contentType: null,
        accept: "application/json"
    };
}

export function buildShowcaseTransportUploadMultipartRequest(request: ShowcaseTransportUploadMultipartRequest): ApiRequest {
    const path = { kind: "relative" as const, path: "/showcase/uploads/multipart" };
    const queryParameters: Record<string, string> = {};
    if ((request.compress ?? false) !== undefined && (request.compress ?? false) !== null) {
        appendQueryParameter(queryParameters, "compress", (request.compress ?? false));
    }
    const headers: Record<string, string> = {};
    appendQueryParameter(headers, "Authorization", (request.apiKey ?? undefined));
    const body = request.body;
    return {
        method: "POST",
        path,
        queryParameters,
        headers,
        body,
        contentType: null,
        accept: "application/json"
    };
}

export function buildShowcaseTransportUploadFileRequest(request: ShowcaseTransportUploadFileRequest): ApiRequest {
    const path = { kind: "relative" as const, path: "/showcase/uploads/file" };
    const queryParameters: Record<string, string> = {};
    const headers: Record<string, string> = {};
    appendQueryParameter(headers, "Authorization", (request.apiKey ?? undefined));
    const body = request.body;
    return {
        method: "POST",
        path,
        queryParameters,
        headers,
        body,
        contentType: null,
        accept: "application/json"
    };
}

export function buildShowcaseTransportUploadBinaryRequest(request: ShowcaseTransportUploadBinaryRequest): ApiRequest {
    const path = { kind: "relative" as const, path: "/showcase/uploads/binary" };
    const queryParameters: Record<string, string> = {};
    const headers: Record<string, string> = {};
    if (request.contentMd5 !== undefined && request.contentMd5 !== null) {
        appendQueryParameter(headers, "Content-MD5", request.contentMd5);
    }
    appendQueryParameter(headers, "Authorization", (request.apiKey ?? undefined));
    const body = request.body;
    return {
        method: "POST",
        path,
        queryParameters,
        headers,
        body,
        contentType: "application/octet-stream",
        accept: "application/zip"
    };
}

export function buildShowcaseTransportDeleteWithBodyRequest(request: ShowcaseTransportDeleteWithBodyRequest): ApiRequest {
    const path = { kind: "relative" as const, path: "/showcase/uploads" };
    const queryParameters: Record<string, string> = {};
    const headers: Record<string, string> = {};
    appendQueryParameter(headers, "Authorization", (request.apiKey ?? undefined));
    const body = ModelCodecs.encodeDeleteReceiptRequest(request.body);
    return {
        method: "DELETE",
        path,
        queryParameters,
        headers,
        body,
        contentType: "application/json",
        accept: "application/json"
    };
}

export function buildTenantProjectCreateRequest(request: TenantProjectCreateRequest): ApiRequest {
    const path = { kind: "relative" as const, path: "/project" };
    const queryParameters: Record<string, string> = {};
    const headers: Record<string, string> = {};
    appendQueryParameter(headers, "X-Tenant-Id", request.tenantId);
    const body = ModelCodecs.encodeProject(request.body);
    return {
        method: "POST",
        path,
        queryParameters,
        headers,
        body,
        contentType: "application/json",
        accept: "application/json"
    };
}

export function buildTenantProjectUpdateRequest(request: TenantProjectUpdateRequest): ApiRequest {
    let requestPath = "/project/{project_id}";
    requestPath = requestPath.replace(
        "{project_id}",
        encodeURIComponent(encodeFormValue(request.projectId))
    );
    const path = { kind: "relative" as const, path: requestPath };
    const queryParameters: Record<string, string> = {};
    const headers: Record<string, string> = {};
    appendQueryParameter(headers, "X-Tenant-Id", request.tenantId);
    const body = ModelCodecs.encodeProject(request.body);
    return {
        method: "PUT",
        path,
        queryParameters,
        headers,
        body,
        contentType: "application/json",
        accept: "application/json"
    };
}

export function buildTenantProjectDeleteRequest(request: TenantProjectDeleteRequest): ApiRequest {
    let requestPath = "/project/{project_id}";
    requestPath = requestPath.replace(
        "{project_id}",
        encodeURIComponent(encodeFormValue(request.projectId))
    );
    const path = { kind: "relative" as const, path: requestPath };
    const queryParameters: Record<string, string> = {};
    const headers: Record<string, string> = {};
    appendQueryParameter(headers, "X-Tenant-Id", request.tenantId);
    const body = undefined;
    return {
        method: "DELETE",
        path,
        queryParameters,
        headers,
        body,
        contentType: null,
        accept: "*/*"
    };
}

export function buildTenantProjectListRequest(request: TenantProjectListRequest): ApiRequest {
    const path = { kind: "relative" as const, path: "/project" };
    const queryParameters: Record<string, string> = {};
    if ((request.status ?? ["active"]) !== undefined && (request.status ?? ["active"]) !== null) {
        appendQueryParameter(queryParameters, "status", (request.status ?? ["active"]));
    }
    if ((request.includeArchived ?? false) !== undefined && (request.includeArchived ?? false) !== null) {
        appendQueryParameter(queryParameters, "include_archived", (request.includeArchived ?? false));
    }
    const headers: Record<string, string> = {};
    appendQueryParameter(headers, "X-Tenant-Id", request.tenantId);
    const body = undefined;
    return {
        method: "GET",
        path,
        queryParameters,
        headers,
        body,
        contentType: null,
        accept: "application/json"
    };
}

export function buildTenantProjectGetRequest(request: TenantProjectGetRequest): ApiRequest {
    let requestPath = "/project/{project_id}";
    requestPath = requestPath.replace(
        "{project_id}",
        encodeURIComponent(encodeFormValue(request.projectId))
    );
    const path = { kind: "relative" as const, path: requestPath };
    const queryParameters: Record<string, string> = {};
    const headers: Record<string, string> = {};
    appendQueryParameter(headers, "X-Tenant-Id", request.tenantId);
    const body = undefined;
    return {
        method: "GET",
        path,
        queryParameters,
        headers,
        body,
        contentType: null,
        accept: "application/json"
    };
}

export function buildTenantProjectArchiveRequest(request: TenantProjectArchiveRequest): ApiRequest {
    let requestPath = "/project/{project_id}/archive";
    requestPath = requestPath.replace(
        "{project_id}",
        encodeURIComponent(encodeFormValue(request.projectId))
    );
    const path = { kind: "relative" as const, path: requestPath };
    const queryParameters: Record<string, string> = {};
    if ((request.cascade ?? false) !== undefined && (request.cascade ?? false) !== null) {
        appendQueryParameter(queryParameters, "cascade", (request.cascade ?? false));
    }
    const headers: Record<string, string> = {};
    appendQueryParameter(headers, "X-Tenant-Id", request.tenantId);
    appendQueryParameter(headers, "Authorization", (request.apiKey ?? undefined));
    const body = undefined;
    return {
        method: "POST",
        path,
        queryParameters,
        headers,
        body,
        contentType: "application/json",
        accept: "application/json"
    };
}

export function buildTenantProjectTaskCreateRequest(request: TenantProjectTaskCreateRequest): ApiRequest {
    let requestPath = "/project/{project_id}/task";
    requestPath = requestPath.replace(
        "{project_id}",
        encodeURIComponent(encodeFormValue(request.projectId))
    );
    const path = { kind: "relative" as const, path: requestPath };
    const queryParameters: Record<string, string> = {};
    const headers: Record<string, string> = {};
    appendQueryParameter(headers, "X-Tenant-Id", request.tenantId);
    const body = ModelCodecs.encodeTask(request.body);
    return {
        method: "POST",
        path,
        queryParameters,
        headers,
        body,
        contentType: "application/json",
        accept: "application/json"
    };
}

export function buildTenantProjectTaskPatchRequest(request: TenantProjectTaskPatchRequest): ApiRequest {
    let requestPath = "/project/{project_id}/task/{task_id}";
    requestPath = requestPath.replace(
        "{project_id}",
        encodeURIComponent(encodeFormValue(request.projectId))
    );
    requestPath = requestPath.replace(
        "{task_id}",
        encodeURIComponent(encodeFormValue(request.taskId))
    );
    const path = { kind: "relative" as const, path: requestPath };
    const queryParameters: Record<string, string> = {};
    const headers: Record<string, string> = {};
    appendQueryParameter(headers, "X-Tenant-Id", request.tenantId);
    const body = ModelCodecs.encodePatchedTask(request.body);
    return {
        method: "PATCH",
        path,
        queryParameters,
        headers,
        body,
        contentType: "application/json",
        accept: "application/json"
    };
}

export function buildTenantProjectTaskListRequest(request: TenantProjectTaskListRequest): ApiRequest {
    let requestPath = "/project/{project_id}/task";
    requestPath = requestPath.replace(
        "{project_id}",
        encodeURIComponent(encodeFormValue(request.projectId))
    );
    const path = { kind: "relative" as const, path: requestPath };
    const queryParameters: Record<string, string> = {};
    if (request.done !== undefined && request.done !== null) {
        appendQueryParameter(queryParameters, "done", request.done);
    }
    const headers: Record<string, string> = {};
    appendQueryParameter(headers, "X-Tenant-Id", request.tenantId);
    const body = undefined;
    return {
        method: "GET",
        path,
        queryParameters,
        headers,
        body,
        contentType: null,
        accept: "application/json"
    };
}

export function buildTenantProjectTaskGetRequest(request: TenantProjectTaskGetRequest): ApiRequest {
    let requestPath = "/project/{project_id}/task/{task_id}";
    requestPath = requestPath.replace(
        "{project_id}",
        encodeURIComponent(encodeFormValue(request.projectId))
    );
    requestPath = requestPath.replace(
        "{task_id}",
        encodeURIComponent(encodeFormValue(request.taskId))
    );
    const path = { kind: "relative" as const, path: requestPath };
    const queryParameters: Record<string, string> = {};
    const headers: Record<string, string> = {};
    appendQueryParameter(headers, "X-Tenant-Id", request.tenantId);
    const body = undefined;
    return {
        method: "GET",
        path,
        queryParameters,
        headers,
        body,
        contentType: null,
        accept: "application/json"
    };
}

export function buildTenantProjectTaskCompleteRequest(request: TenantProjectTaskCompleteRequest): ApiRequest {
    let requestPath = "/project/{project_id}/task/{task_id}/complete";
    requestPath = requestPath.replace(
        "{project_id}",
        encodeURIComponent(encodeFormValue(request.projectId))
    );
    requestPath = requestPath.replace(
        "{task_id}",
        encodeURIComponent(encodeFormValue(request.taskId))
    );
    const path = { kind: "relative" as const, path: requestPath };
    const queryParameters: Record<string, string> = {};
    if ((request.notify ?? true) !== undefined && (request.notify ?? true) !== null) {
        appendQueryParameter(queryParameters, "notify", (request.notify ?? true));
    }
    const headers: Record<string, string> = {};
    appendQueryParameter(headers, "X-Tenant-Id", request.tenantId);
    if ((request.apiKey ?? undefined) !== undefined && (request.apiKey ?? undefined) !== null) {
        appendQueryParameter(headers, "Authorization", (request.apiKey ?? undefined));
    }
    const body = ModelCodecs.encodeCompleteTaskRequest(request.body);
    return {
        method: "PATCH",
        path,
        queryParameters,
        headers,
        body,
        contentType: "application/json",
        accept: "application/json"
    };
}

export interface AdminUserApi {
    create(request: AdminUserCreateRequest): Promise<ApiOperationResult<Models.IdUser>>;
    update(request: AdminUserUpdateRequest): Promise<ApiOperationResult<Models.IdUser>>;
    patch(request: AdminUserPatchRequest): Promise<ApiOperationResult<Models.IdUser>>;
    delete_(request: AdminUserDeleteRequest): Promise<ApiResponse>;
    list(request: AdminUserListRequest): Promise<ApiOperationResult<PagedResults<Models.IdentifiedUser>>>;
    get_(request: AdminUserGetRequest): Promise<ApiOperationResult<Models.IdentifiedUser>>;
}

export class AdminUserApiService implements AdminUserApi {
    constructor(private readonly client: ApiClient) {}

    async create(request: AdminUserCreateRequest): Promise<ApiOperationResult<Models.IdUser>> {

        return this.client.execute(buildAdminUserCreateRequest(request), [200, 201], ModelCodecs.decodeIdUser);
    }

    async update(request: AdminUserUpdateRequest): Promise<ApiOperationResult<Models.IdUser>> {

        return this.client.execute(buildAdminUserUpdateRequest(request), [200], ModelCodecs.decodeIdUser);
    }

    async patch(request: AdminUserPatchRequest): Promise<ApiOperationResult<Models.IdUser>> {

        return this.client.execute(buildAdminUserPatchRequest(request), [200], ModelCodecs.decodeIdUser);
    }

    async delete_(request: AdminUserDeleteRequest): Promise<ApiResponse> {

        return this.client.execute(buildAdminUserDeleteRequest(request), [200, 204, 205]);
    }

    async list(request: AdminUserListRequest): Promise<ApiOperationResult<PagedResults<Models.IdentifiedUser>>> {

        return this.client.execute(buildAdminUserListRequest(request), [200], (value) => decodePagedResults(value, ModelCodecs.decodeIdentifiedUser));
    }

    async get_(request: AdminUserGetRequest): Promise<ApiOperationResult<Models.IdentifiedUser>> {

        return this.client.execute(buildAdminUserGetRequest(request), [200], ModelCodecs.decodeIdentifiedUser);
    }
}

export interface AdminRoleApi {
    create(request: AdminRoleCreateRequest): Promise<ApiOperationResult<Models.IdRole>>;
    update(request: AdminRoleUpdateRequest): Promise<ApiOperationResult<Models.IdRole>>;
    patch(request: AdminRolePatchRequest): Promise<ApiOperationResult<Models.IdRole>>;
    delete_(request: AdminRoleDeleteRequest): Promise<ApiResponse>;
    list(request: AdminRoleListRequest): Promise<ApiOperationResult<PagedResults<Models.IdentifiedRole>>>;
    get_(request: AdminRoleGetRequest): Promise<ApiOperationResult<Models.IdentifiedRole>>;
}

export class AdminRoleApiService implements AdminRoleApi {
    constructor(private readonly client: ApiClient) {}

    async create(request: AdminRoleCreateRequest): Promise<ApiOperationResult<Models.IdRole>> {

        return this.client.execute(buildAdminRoleCreateRequest(request), [200, 201], ModelCodecs.decodeIdRole);
    }

    async update(request: AdminRoleUpdateRequest): Promise<ApiOperationResult<Models.IdRole>> {

        return this.client.execute(buildAdminRoleUpdateRequest(request), [200], ModelCodecs.decodeIdRole);
    }

    async patch(request: AdminRolePatchRequest): Promise<ApiOperationResult<Models.IdRole>> {

        return this.client.execute(buildAdminRolePatchRequest(request), [200], ModelCodecs.decodeIdRole);
    }

    async delete_(request: AdminRoleDeleteRequest): Promise<ApiResponse> {

        return this.client.execute(buildAdminRoleDeleteRequest(request), [200, 204, 205]);
    }

    async list(request: AdminRoleListRequest): Promise<ApiOperationResult<PagedResults<Models.IdentifiedRole>>> {

        return this.client.execute(buildAdminRoleListRequest(request), [200], (value) => decodePagedResults(value, ModelCodecs.decodeIdentifiedRole));
    }

    async get_(request: AdminRoleGetRequest): Promise<ApiOperationResult<Models.IdentifiedRole>> {

        return this.client.execute(buildAdminRoleGetRequest(request), [200], ModelCodecs.decodeIdentifiedRole);
    }
}

export interface AdminGroupApi {
    create(request: AdminGroupCreateRequest): Promise<ApiOperationResult<Models.IdGroup>>;
    update(request: AdminGroupUpdateRequest): Promise<ApiOperationResult<Models.IdGroup>>;
    patch(request: AdminGroupPatchRequest): Promise<ApiOperationResult<Models.IdGroup>>;
    delete_(request: AdminGroupDeleteRequest): Promise<ApiResponse>;
    list(request: AdminGroupListRequest): Promise<ApiOperationResult<PagedResults<Models.IdentifiedGroup>>>;
    get_(request: AdminGroupGetRequest): Promise<ApiOperationResult<Models.IdentifiedGroup>>;
}

export class AdminGroupApiService implements AdminGroupApi {
    constructor(private readonly client: ApiClient) {}

    async create(request: AdminGroupCreateRequest): Promise<ApiOperationResult<Models.IdGroup>> {

        return this.client.execute(buildAdminGroupCreateRequest(request), [200, 201], ModelCodecs.decodeIdGroup);
    }

    async update(request: AdminGroupUpdateRequest): Promise<ApiOperationResult<Models.IdGroup>> {

        return this.client.execute(buildAdminGroupUpdateRequest(request), [200], ModelCodecs.decodeIdGroup);
    }

    async patch(request: AdminGroupPatchRequest): Promise<ApiOperationResult<Models.IdGroup>> {

        return this.client.execute(buildAdminGroupPatchRequest(request), [200], ModelCodecs.decodeIdGroup);
    }

    async delete_(request: AdminGroupDeleteRequest): Promise<ApiResponse> {

        return this.client.execute(buildAdminGroupDeleteRequest(request), [200, 204, 205]);
    }

    async list(request: AdminGroupListRequest): Promise<ApiOperationResult<PagedResults<Models.IdentifiedGroup>>> {

        return this.client.execute(buildAdminGroupListRequest(request), [200], (value) => decodePagedResults(value, ModelCodecs.decodeIdentifiedGroup));
    }

    async get_(request: AdminGroupGetRequest): Promise<ApiOperationResult<Models.IdentifiedGroup>> {

        return this.client.execute(buildAdminGroupGetRequest(request), [200], ModelCodecs.decodeIdentifiedGroup);
    }
}

export interface LocationStructureApi {
    create(request: LocationStructureCreateRequest): Promise<ApiOperationResult<Models.IdStructure>>;
    update(request: LocationStructureUpdateRequest): Promise<ApiOperationResult<Models.IdStructure>>;
    patch(request: LocationStructurePatchRequest): Promise<ApiOperationResult<Models.IdStructure>>;
    delete_(request: LocationStructureDeleteRequest): Promise<ApiResponse>;
    list(request: LocationStructureListRequest): Promise<ApiOperationResult<PagedResults<Models.IdentifiedStructure>>>;
    get_(request: LocationStructureGetRequest): Promise<ApiOperationResult<Models.IdentifiedStructure>>;
}

export class LocationStructureApiService implements LocationStructureApi {
    constructor(private readonly client: ApiClient) {}

    async create(request: LocationStructureCreateRequest): Promise<ApiOperationResult<Models.IdStructure>> {

        return this.client.execute(buildLocationStructureCreateRequest(request), [200, 201], ModelCodecs.decodeIdStructure);
    }

    async update(request: LocationStructureUpdateRequest): Promise<ApiOperationResult<Models.IdStructure>> {

        return this.client.execute(buildLocationStructureUpdateRequest(request), [200], ModelCodecs.decodeIdStructure);
    }

    async patch(request: LocationStructurePatchRequest): Promise<ApiOperationResult<Models.IdStructure>> {

        return this.client.execute(buildLocationStructurePatchRequest(request), [200], ModelCodecs.decodeIdStructure);
    }

    async delete_(request: LocationStructureDeleteRequest): Promise<ApiResponse> {

        return this.client.execute(buildLocationStructureDeleteRequest(request), [200, 204, 205]);
    }

    async list(request: LocationStructureListRequest): Promise<ApiOperationResult<PagedResults<Models.IdentifiedStructure>>> {

        return this.client.execute(buildLocationStructureListRequest(request), [200], (value) => decodePagedResults(value, ModelCodecs.decodeIdentifiedStructure));
    }

    async get_(request: LocationStructureGetRequest): Promise<ApiOperationResult<Models.IdentifiedStructure>> {

        return this.client.execute(buildLocationStructureGetRequest(request), [200], ModelCodecs.decodeIdentifiedStructure);
    }
}

export interface ShowcaseSampleModelsApi {
    getMatrix(request: ShowcaseSampleModelsGetMatrixRequest): Promise<ApiOperationResult<Models.PrimitiveMatrix>>;
    createNotification(request: ShowcaseSampleModelsCreateNotificationRequest): Promise<ApiOperationResult<Models.NotificationEnvelope>>;
    followRuntimeUrl(request: ShowcaseSampleModelsFollowRuntimeUrlRequest): Promise<ApiOperationResult<PagedResults<Models.PrimitiveMatrix>>>;
}

export class ShowcaseSampleModelsApiService implements ShowcaseSampleModelsApi {
    constructor(private readonly client: ApiClient) {}

    async getMatrix(request: ShowcaseSampleModelsGetMatrixRequest): Promise<ApiOperationResult<Models.PrimitiveMatrix>> {
        const adaptedRequest = { ...request, apiKey: request.apiKey || await this.client.apiKey() || undefined };
        return this.client.execute(buildShowcaseSampleModelsGetMatrixRequest(adaptedRequest), [200], ModelCodecs.decodePrimitiveMatrix);
    }

    async createNotification(request: ShowcaseSampleModelsCreateNotificationRequest): Promise<ApiOperationResult<Models.NotificationEnvelope>> {
        const adaptedRequest = { ...request, apiKey: request.apiKey || await this.client.requireApiKey() };
        return this.client.execute(buildShowcaseSampleModelsCreateNotificationRequest(adaptedRequest), [200, 201, 202], ModelCodecs.decodeNotificationEnvelope);
    }

    async followRuntimeUrl(request: ShowcaseSampleModelsFollowRuntimeUrlRequest): Promise<ApiOperationResult<PagedResults<Models.PrimitiveMatrix>>> {
        const adaptedRequest = { ...request, apiKey: request.apiKey || await this.client.apiKey() || undefined };
        return this.client.execute(buildShowcaseSampleModelsFollowRuntimeUrlRequest(adaptedRequest), [200], (value) => decodePagedResults(value, ModelCodecs.decodePrimitiveMatrix));
    }
}

export interface ShowcaseTransportApi {
    uploadMultipart(request: ShowcaseTransportUploadMultipartRequest): Promise<ApiOperationResult<Models.UploadReceipt>>;
    uploadFile(request: ShowcaseTransportUploadFileRequest): Promise<ApiOperationResult<Models.UploadReceipt>>;
    uploadBinary(request: ShowcaseTransportUploadBinaryRequest): Promise<ApiOperationResult<ArrayBuffer>>;
    deleteWithBody(request: ShowcaseTransportDeleteWithBodyRequest): Promise<ApiOperationResult<Models.UploadReceipt>>;
}

export class ShowcaseTransportApiService implements ShowcaseTransportApi {
    constructor(private readonly client: ApiClient) {}

    async uploadMultipart(request: ShowcaseTransportUploadMultipartRequest): Promise<ApiOperationResult<Models.UploadReceipt>> {
        const adaptedRequest = { ...request, apiKey: request.apiKey || await this.client.requireApiKey() };
        return this.client.execute(buildShowcaseTransportUploadMultipartRequest(adaptedRequest), [200, 201], ModelCodecs.decodeUploadReceipt);
    }

    async uploadFile(request: ShowcaseTransportUploadFileRequest): Promise<ApiOperationResult<Models.UploadReceipt>> {
        const adaptedRequest = { ...request, apiKey: request.apiKey || await this.client.requireApiKey() };
        return this.client.execute(buildShowcaseTransportUploadFileRequest(adaptedRequest), [200, 201], ModelCodecs.decodeUploadReceipt);
    }

    async uploadBinary(request: ShowcaseTransportUploadBinaryRequest): Promise<ApiOperationResult<ArrayBuffer>> {
        const adaptedRequest = { ...request, apiKey: request.apiKey || await this.client.requireApiKey() };
        return this.client.executeBinary(buildShowcaseTransportUploadBinaryRequest(adaptedRequest), [200, 202]);
    }

    async deleteWithBody(request: ShowcaseTransportDeleteWithBodyRequest): Promise<ApiOperationResult<Models.UploadReceipt>> {
        const adaptedRequest = { ...request, apiKey: request.apiKey || await this.client.requireApiKey() };
        return this.client.execute(buildShowcaseTransportDeleteWithBodyRequest(adaptedRequest), [200, 202], ModelCodecs.decodeUploadReceipt);
    }
}

export interface TenantProjectApi {
    create(request: TenantProjectCreateRequest): Promise<ApiOperationResult<Models.IdProject>>;
    update(request: TenantProjectUpdateRequest): Promise<ApiOperationResult<Models.IdProject>>;
    delete_(request: TenantProjectDeleteRequest): Promise<ApiResponse>;
    list(request: TenantProjectListRequest): Promise<ApiOperationResult<Models.IdentifiedProject[]>>;
    get_(request: TenantProjectGetRequest): Promise<ApiOperationResult<Models.IdentifiedProject>>;
    archive(request: TenantProjectArchiveRequest): Promise<ApiOperationResult<Models.IdObject>>;
}

export class TenantProjectApiService implements TenantProjectApi {
    constructor(private readonly client: ApiClient) {}

    async create(request: TenantProjectCreateRequest): Promise<ApiOperationResult<Models.IdProject>> {

        return this.client.execute(buildTenantProjectCreateRequest(request), [200, 201], ModelCodecs.decodeIdProject);
    }

    async update(request: TenantProjectUpdateRequest): Promise<ApiOperationResult<Models.IdProject>> {

        return this.client.execute(buildTenantProjectUpdateRequest(request), [200], ModelCodecs.decodeIdProject);
    }

    async delete_(request: TenantProjectDeleteRequest): Promise<ApiResponse> {

        return this.client.execute(buildTenantProjectDeleteRequest(request), [200, 204, 205]);
    }

    async list(request: TenantProjectListRequest): Promise<ApiOperationResult<Models.IdentifiedProject[]>> {

        return this.client.execute(buildTenantProjectListRequest(request), [200], (value) => ((value ?? []) as unknown[]).map(ModelCodecs.decodeIdentifiedProject));
    }

    async get_(request: TenantProjectGetRequest): Promise<ApiOperationResult<Models.IdentifiedProject>> {

        return this.client.execute(buildTenantProjectGetRequest(request), [200], ModelCodecs.decodeIdentifiedProject);
    }

    async archive(request: TenantProjectArchiveRequest): Promise<ApiOperationResult<Models.IdObject>> {
        const adaptedRequest = { ...request, apiKey: request.apiKey || await this.client.requireApiKey() };
        return this.client.execute(buildTenantProjectArchiveRequest(adaptedRequest), [200, 202], ModelCodecs.decodeIdObject);
    }
}

export interface TenantProjectTaskApi {
    create(request: TenantProjectTaskCreateRequest): Promise<ApiOperationResult<Models.IdTask>>;
    patch(request: TenantProjectTaskPatchRequest): Promise<ApiOperationResult<Models.IdTask>>;
    list(request: TenantProjectTaskListRequest): Promise<ApiOperationResult<PagedResults<Models.IdentifiedTask>>>;
    get_(request: TenantProjectTaskGetRequest): Promise<ApiOperationResult<Models.IdentifiedTask>>;
    complete(request: TenantProjectTaskCompleteRequest): Promise<ApiOperationResult<Models.IdObject>>;
}

export class TenantProjectTaskApiService implements TenantProjectTaskApi {
    constructor(private readonly client: ApiClient) {}

    async create(request: TenantProjectTaskCreateRequest): Promise<ApiOperationResult<Models.IdTask>> {

        return this.client.execute(buildTenantProjectTaskCreateRequest(request), [200, 201], ModelCodecs.decodeIdTask);
    }

    async patch(request: TenantProjectTaskPatchRequest): Promise<ApiOperationResult<Models.IdTask>> {

        return this.client.execute(buildTenantProjectTaskPatchRequest(request), [200], ModelCodecs.decodeIdTask);
    }

    async list(request: TenantProjectTaskListRequest): Promise<ApiOperationResult<PagedResults<Models.IdentifiedTask>>> {

        return this.client.execute(buildTenantProjectTaskListRequest(request), [200], (value) => decodePagedResults(value, ModelCodecs.decodeIdentifiedTask));
    }

    async get_(request: TenantProjectTaskGetRequest): Promise<ApiOperationResult<Models.IdentifiedTask>> {

        return this.client.execute(buildTenantProjectTaskGetRequest(request), [200], ModelCodecs.decodeIdentifiedTask);
    }

    async complete(request: TenantProjectTaskCompleteRequest): Promise<ApiOperationResult<Models.IdObject>> {
        const adaptedRequest = { ...request, apiKey: request.apiKey || await this.client.apiKey() || undefined };
        return this.client.execute(buildTenantProjectTaskCompleteRequest(adaptedRequest), [200], ModelCodecs.decodeIdObject);
    }
}

export class AdminApiModule {
    userApi: AdminUserApi;
    roleApi: AdminRoleApi;
    groupApi: AdminGroupApi;

    constructor(client: ApiClient) {
        this.userApi = new AdminUserApiService(client);
        this.roleApi = new AdminRoleApiService(client);
        this.groupApi = new AdminGroupApiService(client);
    }
}

export class LocationApiModule {
    structureApi: LocationStructureApi;

    constructor(client: ApiClient) {
        this.structureApi = new LocationStructureApiService(client);
    }
}

export class ShowcaseApiModule {
    sampleModelsApi: ShowcaseSampleModelsApi;
    transportApi: ShowcaseTransportApi;

    constructor(client: ApiClient) {
        this.sampleModelsApi = new ShowcaseSampleModelsApiService(client);
        this.transportApi = new ShowcaseTransportApiService(client);
    }
}

export class TenantApiModule {
    projectApi: TenantProjectApi;
    projectTaskApi: TenantProjectTaskApi;

    constructor(client: ApiClient) {
        this.projectApi = new TenantProjectApiService(client);
        this.projectTaskApi = new TenantProjectTaskApiService(client);
    }
}

export class ApiModules {
    adminModule: AdminApiModule;
    locationModule: LocationApiModule;
    showcaseModule: ShowcaseApiModule;
    tenantModule: TenantApiModule;

    constructor(client: ApiClient) {
        this.adminModule = new AdminApiModule(client);
        this.locationModule = new LocationApiModule(client);
        this.showcaseModule = new ShowcaseApiModule(client);
        this.tenantModule = new TenantApiModule(client);
    }
}
