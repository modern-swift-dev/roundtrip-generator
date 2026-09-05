// Generated code. Do not edit.
package com.example.api.admin.group

import com.example.api.GeneratedResponse
import com.example.api.PagedResults
import com.example.api.admin.group.models.IdGroup
import com.example.api.admin.group.models.IdentifiedGroup
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean
import org.springframework.http.HttpStatus
import org.springframework.stereotype.Service
import org.springframework.web.server.ResponseStatusException

interface AdminGroupService {
    suspend fun create(request: AdminGroupCreateRequest): GeneratedResponse<IdGroup>

    suspend fun update(request: AdminGroupUpdateRequest): GeneratedResponse<IdGroup>

    suspend fun patch(request: AdminGroupPatchRequest): GeneratedResponse<IdGroup>

    suspend fun delete(request: AdminGroupDeleteRequest): GeneratedResponse<Unit>

    suspend fun list(request: AdminGroupListRequest): GeneratedResponse<PagedResults<IdentifiedGroup>>

    suspend fun `get`(request: AdminGroupGetRequest): GeneratedResponse<IdentifiedGroup>
}

@ConditionalOnMissingBean(AdminGroupService::class)
@Service
class NotImplementedAdminGroupService : AdminGroupService {
    override suspend fun create(request: AdminGroupCreateRequest): GeneratedResponse<IdGroup> =
        throw ResponseStatusException(HttpStatus.NOT_IMPLEMENTED)

    override suspend fun update(request: AdminGroupUpdateRequest): GeneratedResponse<IdGroup> =
        throw ResponseStatusException(HttpStatus.NOT_IMPLEMENTED)

    override suspend fun patch(request: AdminGroupPatchRequest): GeneratedResponse<IdGroup> =
        throw ResponseStatusException(HttpStatus.NOT_IMPLEMENTED)

    override suspend fun delete(request: AdminGroupDeleteRequest): GeneratedResponse<Unit> =
        throw ResponseStatusException(HttpStatus.NOT_IMPLEMENTED)

    override suspend fun list(request: AdminGroupListRequest): GeneratedResponse<PagedResults<IdentifiedGroup>> =
        throw ResponseStatusException(HttpStatus.NOT_IMPLEMENTED)

    override suspend fun `get`(request: AdminGroupGetRequest): GeneratedResponse<IdentifiedGroup> =
        throw ResponseStatusException(HttpStatus.NOT_IMPLEMENTED)
}
