// Generated code. Do not edit.
package com.example.api.admin.user

import com.example.api.GeneratedResponse
import com.example.api.PagedResults
import com.example.api.admin.user.models.IdUser
import com.example.api.admin.user.models.IdentifiedUser
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean
import org.springframework.http.HttpStatus
import org.springframework.stereotype.Service
import org.springframework.web.server.ResponseStatusException

interface AdminUserService {
    suspend fun create(request: AdminUserCreateRequest): GeneratedResponse<IdUser>

    suspend fun update(request: AdminUserUpdateRequest): GeneratedResponse<IdUser>

    suspend fun patch(request: AdminUserPatchRequest): GeneratedResponse<IdUser>

    suspend fun delete(request: AdminUserDeleteRequest): GeneratedResponse<Unit>

    suspend fun list(request: AdminUserListRequest): GeneratedResponse<PagedResults<IdentifiedUser>>

    suspend fun `get`(request: AdminUserGetRequest): GeneratedResponse<IdentifiedUser>
}

@ConditionalOnMissingBean(AdminUserService::class)
@Service
class NotImplementedAdminUserService : AdminUserService {
    override suspend fun create(request: AdminUserCreateRequest): GeneratedResponse<IdUser> =
        throw ResponseStatusException(HttpStatus.NOT_IMPLEMENTED)

    override suspend fun update(request: AdminUserUpdateRequest): GeneratedResponse<IdUser> =
        throw ResponseStatusException(HttpStatus.NOT_IMPLEMENTED)

    override suspend fun patch(request: AdminUserPatchRequest): GeneratedResponse<IdUser> =
        throw ResponseStatusException(HttpStatus.NOT_IMPLEMENTED)

    override suspend fun delete(request: AdminUserDeleteRequest): GeneratedResponse<Unit> =
        throw ResponseStatusException(HttpStatus.NOT_IMPLEMENTED)

    override suspend fun list(request: AdminUserListRequest): GeneratedResponse<PagedResults<IdentifiedUser>> =
        throw ResponseStatusException(HttpStatus.NOT_IMPLEMENTED)

    override suspend fun `get`(request: AdminUserGetRequest): GeneratedResponse<IdentifiedUser> =
        throw ResponseStatusException(HttpStatus.NOT_IMPLEMENTED)
}
