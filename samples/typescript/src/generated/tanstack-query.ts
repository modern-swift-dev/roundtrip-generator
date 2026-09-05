// Generated code. Do not edit.

import { mutationOptions, queryOptions } from "@tanstack/react-query";
import type {
    AdminGroupApi,
    AdminGroupCreateRequest,
    AdminGroupDeleteRequest,
    AdminGroupGetRequest,
    AdminGroupListRequest,
    AdminGroupPatchRequest,
    AdminGroupUpdateRequest,
    AdminRoleApi,
    AdminRoleCreateRequest,
    AdminRoleDeleteRequest,
    AdminRoleGetRequest,
    AdminRoleListRequest,
    AdminRolePatchRequest,
    AdminRoleUpdateRequest,
    AdminUserApi,
    AdminUserCreateRequest,
    AdminUserDeleteRequest,
    AdminUserGetRequest,
    AdminUserListRequest,
    AdminUserPatchRequest,
    AdminUserUpdateRequest,
    LocationStructureApi,
    LocationStructureCreateRequest,
    LocationStructureDeleteRequest,
    LocationStructureGetRequest,
    LocationStructureListRequest,
    LocationStructurePatchRequest,
    LocationStructureUpdateRequest,
    ShowcaseSampleModelsApi,
    ShowcaseSampleModelsCreateNotificationRequest,
    ShowcaseSampleModelsFollowRuntimeUrlRequest,
    ShowcaseSampleModelsGetMatrixRequest,
    ShowcaseTransportApi,
    ShowcaseTransportDeleteWithBodyRequest,
    ShowcaseTransportUploadBinaryRequest,
    ShowcaseTransportUploadFileRequest,
    ShowcaseTransportUploadMultipartRequest,
    TenantProjectApi,
    TenantProjectArchiveRequest,
    TenantProjectCreateRequest,
    TenantProjectDeleteRequest,
    TenantProjectGetRequest,
    TenantProjectListRequest,
    TenantProjectTaskApi,
    TenantProjectTaskCompleteRequest,
    TenantProjectTaskCreateRequest,
    TenantProjectTaskGetRequest,
    TenantProjectTaskListRequest,
    TenantProjectTaskPatchRequest,
    TenantProjectUpdateRequest
} from "./operations.js";

export function adminUserCreateMutationOptions(api: AdminUserApi) {
    return mutationOptions({
        mutationKey: ["AdminUserApi", "create"] as const,
        mutationFn: (request: AdminUserCreateRequest) => api.create(request)
    });
}

export function adminUserUpdateMutationOptions(api: AdminUserApi) {
    return mutationOptions({
        mutationKey: ["AdminUserApi", "update"] as const,
        mutationFn: (request: AdminUserUpdateRequest) => api.update(request)
    });
}

export function adminUserPatchMutationOptions(api: AdminUserApi) {
    return mutationOptions({
        mutationKey: ["AdminUserApi", "patch"] as const,
        mutationFn: (request: AdminUserPatchRequest) => api.patch(request)
    });
}

export function adminUserDeleteMutationOptions(api: AdminUserApi) {
    return mutationOptions({
        mutationKey: ["AdminUserApi", "delete_"] as const,
        mutationFn: (request: AdminUserDeleteRequest) => api.delete_(request)
    });
}

export function adminUserListKey(request: AdminUserListRequest) {
    return ["AdminUserApi", "list", request] as const;
}

export function adminUserListQueryOptions(api: AdminUserApi, request: AdminUserListRequest) {
    return queryOptions({
        queryKey: adminUserListKey(request),
        queryFn: () => api.list(request)
    });
}

export function adminUserGetKey(request: AdminUserGetRequest) {
    return ["AdminUserApi", "get_", request] as const;
}

export function adminUserGetQueryOptions(api: AdminUserApi, request: AdminUserGetRequest) {
    return queryOptions({
        queryKey: adminUserGetKey(request),
        queryFn: () => api.get_(request)
    });
}

export function adminRoleCreateMutationOptions(api: AdminRoleApi) {
    return mutationOptions({
        mutationKey: ["AdminRoleApi", "create"] as const,
        mutationFn: (request: AdminRoleCreateRequest) => api.create(request)
    });
}

export function adminRoleUpdateMutationOptions(api: AdminRoleApi) {
    return mutationOptions({
        mutationKey: ["AdminRoleApi", "update"] as const,
        mutationFn: (request: AdminRoleUpdateRequest) => api.update(request)
    });
}

export function adminRolePatchMutationOptions(api: AdminRoleApi) {
    return mutationOptions({
        mutationKey: ["AdminRoleApi", "patch"] as const,
        mutationFn: (request: AdminRolePatchRequest) => api.patch(request)
    });
}

export function adminRoleDeleteMutationOptions(api: AdminRoleApi) {
    return mutationOptions({
        mutationKey: ["AdminRoleApi", "delete_"] as const,
        mutationFn: (request: AdminRoleDeleteRequest) => api.delete_(request)
    });
}

export function adminRoleListKey(request: AdminRoleListRequest) {
    return ["AdminRoleApi", "list", request] as const;
}

export function adminRoleListQueryOptions(api: AdminRoleApi, request: AdminRoleListRequest) {
    return queryOptions({
        queryKey: adminRoleListKey(request),
        queryFn: () => api.list(request)
    });
}

export function adminRoleGetKey(request: AdminRoleGetRequest) {
    return ["AdminRoleApi", "get_", request] as const;
}

export function adminRoleGetQueryOptions(api: AdminRoleApi, request: AdminRoleGetRequest) {
    return queryOptions({
        queryKey: adminRoleGetKey(request),
        queryFn: () => api.get_(request)
    });
}

export function adminGroupCreateMutationOptions(api: AdminGroupApi) {
    return mutationOptions({
        mutationKey: ["AdminGroupApi", "create"] as const,
        mutationFn: (request: AdminGroupCreateRequest) => api.create(request)
    });
}

export function adminGroupUpdateMutationOptions(api: AdminGroupApi) {
    return mutationOptions({
        mutationKey: ["AdminGroupApi", "update"] as const,
        mutationFn: (request: AdminGroupUpdateRequest) => api.update(request)
    });
}

export function adminGroupPatchMutationOptions(api: AdminGroupApi) {
    return mutationOptions({
        mutationKey: ["AdminGroupApi", "patch"] as const,
        mutationFn: (request: AdminGroupPatchRequest) => api.patch(request)
    });
}

export function adminGroupDeleteMutationOptions(api: AdminGroupApi) {
    return mutationOptions({
        mutationKey: ["AdminGroupApi", "delete_"] as const,
        mutationFn: (request: AdminGroupDeleteRequest) => api.delete_(request)
    });
}

export function adminGroupListKey(request: AdminGroupListRequest) {
    return ["AdminGroupApi", "list", request] as const;
}

export function adminGroupListQueryOptions(api: AdminGroupApi, request: AdminGroupListRequest) {
    return queryOptions({
        queryKey: adminGroupListKey(request),
        queryFn: () => api.list(request)
    });
}

export function adminGroupGetKey(request: AdminGroupGetRequest) {
    return ["AdminGroupApi", "get_", request] as const;
}

export function adminGroupGetQueryOptions(api: AdminGroupApi, request: AdminGroupGetRequest) {
    return queryOptions({
        queryKey: adminGroupGetKey(request),
        queryFn: () => api.get_(request)
    });
}

export function locationStructureCreateMutationOptions(api: LocationStructureApi) {
    return mutationOptions({
        mutationKey: ["LocationStructureApi", "create"] as const,
        mutationFn: (request: LocationStructureCreateRequest) => api.create(request)
    });
}

export function locationStructureUpdateMutationOptions(api: LocationStructureApi) {
    return mutationOptions({
        mutationKey: ["LocationStructureApi", "update"] as const,
        mutationFn: (request: LocationStructureUpdateRequest) => api.update(request)
    });
}

export function locationStructurePatchMutationOptions(api: LocationStructureApi) {
    return mutationOptions({
        mutationKey: ["LocationStructureApi", "patch"] as const,
        mutationFn: (request: LocationStructurePatchRequest) => api.patch(request)
    });
}

export function locationStructureDeleteMutationOptions(api: LocationStructureApi) {
    return mutationOptions({
        mutationKey: ["LocationStructureApi", "delete_"] as const,
        mutationFn: (request: LocationStructureDeleteRequest) => api.delete_(request)
    });
}

export function locationStructureListKey(request: LocationStructureListRequest) {
    return ["LocationStructureApi", "list", request] as const;
}

export function locationStructureListQueryOptions(api: LocationStructureApi, request: LocationStructureListRequest) {
    return queryOptions({
        queryKey: locationStructureListKey(request),
        queryFn: () => api.list(request)
    });
}

export function locationStructureGetKey(request: LocationStructureGetRequest) {
    return ["LocationStructureApi", "get_", request] as const;
}

export function locationStructureGetQueryOptions(api: LocationStructureApi, request: LocationStructureGetRequest) {
    return queryOptions({
        queryKey: locationStructureGetKey(request),
        queryFn: () => api.get_(request)
    });
}

export function showcaseSampleModelsGetMatrixKey(request: ShowcaseSampleModelsGetMatrixRequest) {
    return ["ShowcaseSampleModelsApi", "getMatrix", request] as const;
}

export function showcaseSampleModelsGetMatrixQueryOptions(api: ShowcaseSampleModelsApi, request: ShowcaseSampleModelsGetMatrixRequest) {
    return queryOptions({
        queryKey: showcaseSampleModelsGetMatrixKey(request),
        queryFn: () => api.getMatrix(request)
    });
}

export function showcaseSampleModelsCreateNotificationMutationOptions(api: ShowcaseSampleModelsApi) {
    return mutationOptions({
        mutationKey: ["ShowcaseSampleModelsApi", "createNotification"] as const,
        mutationFn: (request: ShowcaseSampleModelsCreateNotificationRequest) => api.createNotification(request)
    });
}

export function showcaseSampleModelsFollowRuntimeUrlKey(request: ShowcaseSampleModelsFollowRuntimeUrlRequest) {
    return ["ShowcaseSampleModelsApi", "followRuntimeUrl", request] as const;
}

export function showcaseSampleModelsFollowRuntimeUrlQueryOptions(api: ShowcaseSampleModelsApi, request: ShowcaseSampleModelsFollowRuntimeUrlRequest) {
    return queryOptions({
        queryKey: showcaseSampleModelsFollowRuntimeUrlKey(request),
        queryFn: () => api.followRuntimeUrl(request)
    });
}

export function showcaseTransportUploadMultipartMutationOptions(api: ShowcaseTransportApi) {
    return mutationOptions({
        mutationKey: ["ShowcaseTransportApi", "uploadMultipart"] as const,
        mutationFn: (request: ShowcaseTransportUploadMultipartRequest) => api.uploadMultipart(request)
    });
}

export function showcaseTransportUploadFileMutationOptions(api: ShowcaseTransportApi) {
    return mutationOptions({
        mutationKey: ["ShowcaseTransportApi", "uploadFile"] as const,
        mutationFn: (request: ShowcaseTransportUploadFileRequest) => api.uploadFile(request)
    });
}

export function showcaseTransportUploadBinaryMutationOptions(api: ShowcaseTransportApi) {
    return mutationOptions({
        mutationKey: ["ShowcaseTransportApi", "uploadBinary"] as const,
        mutationFn: (request: ShowcaseTransportUploadBinaryRequest) => api.uploadBinary(request)
    });
}

export function showcaseTransportDeleteWithBodyMutationOptions(api: ShowcaseTransportApi) {
    return mutationOptions({
        mutationKey: ["ShowcaseTransportApi", "deleteWithBody"] as const,
        mutationFn: (request: ShowcaseTransportDeleteWithBodyRequest) => api.deleteWithBody(request)
    });
}

export function tenantProjectCreateMutationOptions(api: TenantProjectApi) {
    return mutationOptions({
        mutationKey: ["TenantProjectApi", "create"] as const,
        mutationFn: (request: TenantProjectCreateRequest) => api.create(request)
    });
}

export function tenantProjectUpdateMutationOptions(api: TenantProjectApi) {
    return mutationOptions({
        mutationKey: ["TenantProjectApi", "update"] as const,
        mutationFn: (request: TenantProjectUpdateRequest) => api.update(request)
    });
}

export function tenantProjectDeleteMutationOptions(api: TenantProjectApi) {
    return mutationOptions({
        mutationKey: ["TenantProjectApi", "delete_"] as const,
        mutationFn: (request: TenantProjectDeleteRequest) => api.delete_(request)
    });
}

export function tenantProjectListKey(request: TenantProjectListRequest) {
    return ["TenantProjectApi", "list", request] as const;
}

export function tenantProjectListQueryOptions(api: TenantProjectApi, request: TenantProjectListRequest) {
    return queryOptions({
        queryKey: tenantProjectListKey(request),
        queryFn: () => api.list(request)
    });
}

export function tenantProjectGetKey(request: TenantProjectGetRequest) {
    return ["TenantProjectApi", "get_", request] as const;
}

export function tenantProjectGetQueryOptions(api: TenantProjectApi, request: TenantProjectGetRequest) {
    return queryOptions({
        queryKey: tenantProjectGetKey(request),
        queryFn: () => api.get_(request)
    });
}

export function tenantProjectArchiveMutationOptions(api: TenantProjectApi) {
    return mutationOptions({
        mutationKey: ["TenantProjectApi", "archive"] as const,
        mutationFn: (request: TenantProjectArchiveRequest) => api.archive(request)
    });
}

export function tenantProjectTaskCreateMutationOptions(api: TenantProjectTaskApi) {
    return mutationOptions({
        mutationKey: ["TenantProjectTaskApi", "create"] as const,
        mutationFn: (request: TenantProjectTaskCreateRequest) => api.create(request)
    });
}

export function tenantProjectTaskPatchMutationOptions(api: TenantProjectTaskApi) {
    return mutationOptions({
        mutationKey: ["TenantProjectTaskApi", "patch"] as const,
        mutationFn: (request: TenantProjectTaskPatchRequest) => api.patch(request)
    });
}

export function tenantProjectTaskListKey(request: TenantProjectTaskListRequest) {
    return ["TenantProjectTaskApi", "list", request] as const;
}

export function tenantProjectTaskListQueryOptions(api: TenantProjectTaskApi, request: TenantProjectTaskListRequest) {
    return queryOptions({
        queryKey: tenantProjectTaskListKey(request),
        queryFn: () => api.list(request)
    });
}

export function tenantProjectTaskGetKey(request: TenantProjectTaskGetRequest) {
    return ["TenantProjectTaskApi", "get_", request] as const;
}

export function tenantProjectTaskGetQueryOptions(api: TenantProjectTaskApi, request: TenantProjectTaskGetRequest) {
    return queryOptions({
        queryKey: tenantProjectTaskGetKey(request),
        queryFn: () => api.get_(request)
    });
}

export function tenantProjectTaskCompleteMutationOptions(api: TenantProjectTaskApi) {
    return mutationOptions({
        mutationKey: ["TenantProjectTaskApi", "complete"] as const,
        mutationFn: (request: TenantProjectTaskCompleteRequest) => api.complete(request)
    });
}
