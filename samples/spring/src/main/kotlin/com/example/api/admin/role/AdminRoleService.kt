// Generated code. Do not edit.
package com.example.api.admin.role

import com.example.api.GeneratedResponse
import com.example.api.PagedResults
import com.example.api.admin.role.models.IdRole
import com.example.api.admin.role.models.IdentifiedRole
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean
import org.springframework.http.HttpStatus
import org.springframework.stereotype.Service
import org.springframework.web.server.ResponseStatusException

interface AdminRoleService {
    suspend fun create(request: AdminRoleCreateRequest): GeneratedResponse<IdRole>

    suspend fun update(request: AdminRoleUpdateRequest): GeneratedResponse<IdRole>

    suspend fun patch(request: AdminRolePatchRequest): GeneratedResponse<IdRole>

    suspend fun delete(request: AdminRoleDeleteRequest): GeneratedResponse<Unit>

    suspend fun list(request: AdminRoleListRequest): GeneratedResponse<PagedResults<IdentifiedRole>>

    suspend fun `get`(request: AdminRoleGetRequest): GeneratedResponse<IdentifiedRole>
}

@ConditionalOnMissingBean(AdminRoleService::class)
@Service
class NotImplementedAdminRoleService : AdminRoleService {
    override suspend fun create(request: AdminRoleCreateRequest): GeneratedResponse<IdRole> =
        throw ResponseStatusException(HttpStatus.NOT_IMPLEMENTED)

    override suspend fun update(request: AdminRoleUpdateRequest): GeneratedResponse<IdRole> =
        throw ResponseStatusException(HttpStatus.NOT_IMPLEMENTED)

    override suspend fun patch(request: AdminRolePatchRequest): GeneratedResponse<IdRole> =
        throw ResponseStatusException(HttpStatus.NOT_IMPLEMENTED)

    override suspend fun delete(request: AdminRoleDeleteRequest): GeneratedResponse<Unit> =
        throw ResponseStatusException(HttpStatus.NOT_IMPLEMENTED)

    override suspend fun list(request: AdminRoleListRequest): GeneratedResponse<PagedResults<IdentifiedRole>> =
        throw ResponseStatusException(HttpStatus.NOT_IMPLEMENTED)

    override suspend fun `get`(request: AdminRoleGetRequest): GeneratedResponse<IdentifiedRole> =
        throw ResponseStatusException(HttpStatus.NOT_IMPLEMENTED)
}
