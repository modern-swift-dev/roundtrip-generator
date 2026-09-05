// Generated code. Do not edit.
package com.example.api.admin.role

import com.example.api.ApiError
import com.example.api.ApiOperationResult
import com.example.api.ApiRequest
import com.example.api.ApiRequestConvertible
import com.example.api.ApiRequestPath
import com.example.api.ApiResponse
import com.example.api.ApiResponseType
import com.example.api.PagedResults
import com.example.api.PatchableValue
import com.example.api.RestClient
import com.example.api.admin.role.models.IdRole
import com.example.api.admin.role.models.IdentifiedRole
import com.example.api.admin.role.models.PatchedRole
import com.example.api.admin.role.models.Role
import com.example.api.apiBodySerializer
import com.example.api.toApiFormValue
import com.example.api.toApiPathSegment
import kotlinx.serialization.serializer

interface AdminRoleApi {
    suspend fun create(
        body: Role,
    ): ApiOperationResult<IdRole>

    suspend fun update(
        roleId: Long,
        body: Role,
    ): ApiOperationResult<IdRole>

    suspend fun patch(
        roleId: Long,
        body: PatchedRole,
    ): ApiOperationResult<IdRole>

    suspend fun delete(
        roleId: Long,
    ): ApiResponse

    suspend fun list(
        text: String? = null,
    ): ApiOperationResult<PagedResults<IdentifiedRole>>

    suspend fun `get`(
        roleId: Long,
    ): ApiOperationResult<IdentifiedRole>

    suspend fun getNextPageForListOperation(
        currentPage: PagedResults<IdentifiedRole>,
        text: String? = null,
    ): ApiOperationResult<PagedResults<IdentifiedRole>>
}

private data class NextPageRequest(
    val requestUrl: String,
    val headers: Map<String, String>,
) : ApiRequestConvertible {
    override fun toApiRequest(): ApiRequest =
        ApiRequest(
            method = "GET",
            path = ApiRequestPath.Runtime(requestUrl = requestUrl),
            headers = headers,
            accept = "application/json",
        )
}

class AdminRoleApiService(
    private val client: RestClient,
) : AdminRoleApi {
    override suspend fun create(
        body: Role,
    ): ApiOperationResult<IdRole> {
        val request = CreateOperation.Request(body = body)
        return client.execute(
            request = request,
            responseType = ApiResponseType<IdRole>(typeName = "IdRole", mimeType = "application/json", serializer = serializer()),
            validStatusCodes = setOf(200, 201),
        )
    }

    override suspend fun update(
        roleId: Long,
        body: Role,
    ): ApiOperationResult<IdRole> {
        val request = UpdateOperation.Request(roleId = roleId, body = body)
        return client.execute(
            request = request,
            responseType = ApiResponseType<IdRole>(typeName = "IdRole", mimeType = "application/json", serializer = serializer()),
            validStatusCodes = setOf(200),
        )
    }

    override suspend fun patch(
        roleId: Long,
        body: PatchedRole,
    ): ApiOperationResult<IdRole> {
        val request = PatchOperation.Request(roleId = roleId, body = body)
        return client.execute(
            request = request,
            responseType = ApiResponseType<IdRole>(typeName = "IdRole", mimeType = "application/json", serializer = serializer()),
            validStatusCodes = setOf(200),
        )
    }

    override suspend fun delete(
        roleId: Long,
    ): ApiResponse {
        val request = DeleteOperation.Request(roleId = roleId)
        return client.execute(
            request = request,
            validStatusCodes = setOf(200, 204, 205),
        )
    }

    override suspend fun list(
        text: String?,
    ): ApiOperationResult<PagedResults<IdentifiedRole>> {
        val request = ListOperation.Request(text = text)
        return client.execute(
            request = request,
            responseType = ApiResponseType<PagedResults<IdentifiedRole>>(typeName = "PagedResults<IdentifiedRole>", mimeType = "application/json", serializer = serializer()),
            validStatusCodes = setOf(200),
        )
    }

    override suspend fun `get`(
        roleId: Long,
    ): ApiOperationResult<IdentifiedRole> {
        val request = GetOperation.Request(roleId = roleId)
        return client.execute(
            request = request,
            responseType = ApiResponseType<IdentifiedRole>(typeName = "IdentifiedRole", mimeType = "application/json", serializer = serializer()),
            validStatusCodes = setOf(200),
        )
    }

    override suspend fun getNextPageForListOperation(
        currentPage: PagedResults<IdentifiedRole>,
        text: String?,
    ): ApiOperationResult<PagedResults<IdentifiedRole>> {
        val request = ListOperation.Request(text = text)
        val next = currentPage.next ?: throw ApiError.InvalidUrl
        return client.execute(
            request = NextPageRequest(
                requestUrl = next,
                headers = request.toApiRequest().headers,
            ),
            responseType = ApiResponseType<PagedResults<IdentifiedRole>>(typeName = "PagedResults<IdentifiedRole>", mimeType = "application/json", serializer = serializer()),
            validStatusCodes = setOf(200),
        )
    }
}
