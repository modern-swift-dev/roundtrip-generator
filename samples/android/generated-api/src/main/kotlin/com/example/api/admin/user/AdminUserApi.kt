// Generated code. Do not edit.
package com.example.api.admin.user

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
import com.example.api.admin.user.models.IdUser
import com.example.api.admin.user.models.IdentifiedUser
import com.example.api.admin.user.models.PatchedUser
import com.example.api.admin.user.models.User
import com.example.api.apiBodySerializer
import com.example.api.toApiFormValue
import com.example.api.toApiPathSegment
import kotlinx.serialization.serializer

interface AdminUserApi {
    suspend fun create(
        body: User,
    ): ApiOperationResult<IdUser>

    suspend fun update(
        userId: Long,
        body: User,
    ): ApiOperationResult<IdUser>

    suspend fun patch(
        userId: Long,
        body: PatchedUser,
    ): ApiOperationResult<IdUser>

    suspend fun delete(
        userId: Long,
    ): ApiResponse

    suspend fun list(
        text: String? = null,
    ): ApiOperationResult<PagedResults<IdentifiedUser>>

    suspend fun `get`(
        userId: Long,
    ): ApiOperationResult<IdentifiedUser>

    suspend fun getNextPageForListOperation(
        currentPage: PagedResults<IdentifiedUser>,
        text: String? = null,
    ): ApiOperationResult<PagedResults<IdentifiedUser>>
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

class AdminUserApiService(
    private val client: RestClient,
) : AdminUserApi {
    override suspend fun create(
        body: User,
    ): ApiOperationResult<IdUser> {
        val request = CreateOperation.Request(body = body)
        return client.execute(
            request = request,
            responseType = ApiResponseType<IdUser>(typeName = "IdUser", mimeType = "application/json", serializer = serializer()),
            validStatusCodes = setOf(200, 201),
        )
    }

    override suspend fun update(
        userId: Long,
        body: User,
    ): ApiOperationResult<IdUser> {
        val request = UpdateOperation.Request(userId = userId, body = body)
        return client.execute(
            request = request,
            responseType = ApiResponseType<IdUser>(typeName = "IdUser", mimeType = "application/json", serializer = serializer()),
            validStatusCodes = setOf(200),
        )
    }

    override suspend fun patch(
        userId: Long,
        body: PatchedUser,
    ): ApiOperationResult<IdUser> {
        val request = PatchOperation.Request(userId = userId, body = body)
        return client.execute(
            request = request,
            responseType = ApiResponseType<IdUser>(typeName = "IdUser", mimeType = "application/json", serializer = serializer()),
            validStatusCodes = setOf(200),
        )
    }

    override suspend fun delete(
        userId: Long,
    ): ApiResponse {
        val request = DeleteOperation.Request(userId = userId)
        return client.execute(
            request = request,
            validStatusCodes = setOf(200, 204, 205),
        )
    }

    override suspend fun list(
        text: String?,
    ): ApiOperationResult<PagedResults<IdentifiedUser>> {
        val request = ListOperation.Request(text = text)
        return client.execute(
            request = request,
            responseType = ApiResponseType<PagedResults<IdentifiedUser>>(typeName = "PagedResults<IdentifiedUser>", mimeType = "application/json", serializer = serializer()),
            validStatusCodes = setOf(200),
        )
    }

    override suspend fun `get`(
        userId: Long,
    ): ApiOperationResult<IdentifiedUser> {
        val request = GetOperation.Request(userId = userId)
        return client.execute(
            request = request,
            responseType = ApiResponseType<IdentifiedUser>(typeName = "IdentifiedUser", mimeType = "application/json", serializer = serializer()),
            validStatusCodes = setOf(200),
        )
    }

    override suspend fun getNextPageForListOperation(
        currentPage: PagedResults<IdentifiedUser>,
        text: String?,
    ): ApiOperationResult<PagedResults<IdentifiedUser>> {
        val request = ListOperation.Request(text = text)
        val next = currentPage.next ?: throw ApiError.InvalidUrl
        return client.execute(
            request = NextPageRequest(
                requestUrl = next,
                headers = request.toApiRequest().headers,
            ),
            responseType = ApiResponseType<PagedResults<IdentifiedUser>>(typeName = "PagedResults<IdentifiedUser>", mimeType = "application/json", serializer = serializer()),
            validStatusCodes = setOf(200),
        )
    }
}
