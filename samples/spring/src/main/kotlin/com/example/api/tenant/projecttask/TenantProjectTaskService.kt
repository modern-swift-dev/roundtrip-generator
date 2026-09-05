// Generated code. Do not edit.
package com.example.api.tenant.projecttask

import com.example.api.GeneratedResponse
import com.example.api.IdObject
import com.example.api.PagedResults
import com.example.api.tenant.projecttask.models.IdTask
import com.example.api.tenant.projecttask.models.IdentifiedTask
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean
import org.springframework.http.HttpStatus
import org.springframework.stereotype.Service
import org.springframework.web.server.ResponseStatusException

interface TenantProjectTaskService {
    suspend fun create(request: TenantProjectTaskCreateRequest): GeneratedResponse<IdTask>

    suspend fun patch(request: TenantProjectTaskPatchRequest): GeneratedResponse<IdTask>

    suspend fun list(request: TenantProjectTaskListRequest): GeneratedResponse<PagedResults<IdentifiedTask>>

    suspend fun `get`(request: TenantProjectTaskGetRequest): GeneratedResponse<IdentifiedTask>

    suspend fun complete(request: TenantProjectTaskCompleteRequest): GeneratedResponse<IdObject>
}

@ConditionalOnMissingBean(TenantProjectTaskService::class)
@Service
class NotImplementedTenantProjectTaskService : TenantProjectTaskService {
    override suspend fun create(request: TenantProjectTaskCreateRequest): GeneratedResponse<IdTask> =
        throw ResponseStatusException(HttpStatus.NOT_IMPLEMENTED)

    override suspend fun patch(request: TenantProjectTaskPatchRequest): GeneratedResponse<IdTask> =
        throw ResponseStatusException(HttpStatus.NOT_IMPLEMENTED)

    override suspend fun list(request: TenantProjectTaskListRequest): GeneratedResponse<PagedResults<IdentifiedTask>> =
        throw ResponseStatusException(HttpStatus.NOT_IMPLEMENTED)

    override suspend fun `get`(request: TenantProjectTaskGetRequest): GeneratedResponse<IdentifiedTask> =
        throw ResponseStatusException(HttpStatus.NOT_IMPLEMENTED)

    override suspend fun complete(request: TenantProjectTaskCompleteRequest): GeneratedResponse<IdObject> =
        throw ResponseStatusException(HttpStatus.NOT_IMPLEMENTED)
}
