// Generated code. Do not edit.
package com.example.api.tenant.project

import com.example.api.GeneratedResponse
import com.example.api.IdObject
import com.example.api.NamedObject
import com.example.api.tenant.project.models.IdProject
import com.example.api.tenant.project.models.IdentifiedProject
import com.example.api.tenant.shared.TenantStatus
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean
import org.springframework.http.HttpStatus
import org.springframework.stereotype.Service
import org.springframework.web.server.ResponseStatusException

interface TenantProjectService {
    suspend fun create(request: TenantProjectCreateRequest): GeneratedResponse<IdProject>

    suspend fun update(request: TenantProjectUpdateRequest): GeneratedResponse<IdProject>

    suspend fun delete(request: TenantProjectDeleteRequest): GeneratedResponse<Unit>

    suspend fun list(request: TenantProjectListRequest): GeneratedResponse<List<IdentifiedProject>>

    suspend fun `get`(request: TenantProjectGetRequest): GeneratedResponse<IdentifiedProject>

    suspend fun archive(request: TenantProjectArchiveRequest): GeneratedResponse<IdObject>
}

@ConditionalOnMissingBean(TenantProjectService::class)
@Service
class NotImplementedTenantProjectService : TenantProjectService {
    override suspend fun create(request: TenantProjectCreateRequest): GeneratedResponse<IdProject> =
        throw ResponseStatusException(HttpStatus.NOT_IMPLEMENTED)

    override suspend fun update(request: TenantProjectUpdateRequest): GeneratedResponse<IdProject> =
        throw ResponseStatusException(HttpStatus.NOT_IMPLEMENTED)

    override suspend fun delete(request: TenantProjectDeleteRequest): GeneratedResponse<Unit> =
        throw ResponseStatusException(HttpStatus.NOT_IMPLEMENTED)

    override suspend fun list(request: TenantProjectListRequest): GeneratedResponse<List<IdentifiedProject>> =
        throw ResponseStatusException(HttpStatus.NOT_IMPLEMENTED)

    override suspend fun `get`(request: TenantProjectGetRequest): GeneratedResponse<IdentifiedProject> =
        throw ResponseStatusException(HttpStatus.NOT_IMPLEMENTED)

    override suspend fun archive(request: TenantProjectArchiveRequest): GeneratedResponse<IdObject> =
        throw ResponseStatusException(HttpStatus.NOT_IMPLEMENTED)
}
