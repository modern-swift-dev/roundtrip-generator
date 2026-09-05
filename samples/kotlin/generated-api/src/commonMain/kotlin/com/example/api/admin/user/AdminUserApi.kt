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
import com.example.api.RestClient
import com.example.api.admin.user.models.IdUser
import com.example.api.admin.user.models.IdentifiedUser
import com.rickclephas.kmp.nativecoroutines.NativeCoroutines

interface AdminUserApi {
    @NativeCoroutines
    suspend fun create(request: CreateOperation.Request): ApiOperationResult<IdUser>

    @NativeCoroutines
    suspend fun update(request: UpdateOperation.Request): ApiOperationResult<IdUser>

    @NativeCoroutines
    suspend fun patch(request: PatchOperation.Request): ApiOperationResult<IdUser>

    @NativeCoroutines
    suspend fun delete(request: DeleteOperation.Request): ApiResponse

    @NativeCoroutines
    suspend fun list(request: ListOperation.Request): ApiOperationResult<PagedResults<IdentifiedUser>>

    @NativeCoroutines
    suspend fun `get`(request: GetOperation.Request): ApiOperationResult<IdentifiedUser>

    @NativeCoroutines
    suspend fun getNextPage(currentPage: PagedResults<IdentifiedUser>, request: ListOperation.Request): ApiOperationResult<PagedResults<IdentifiedUser>>
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
    override suspend fun create(request: CreateOperation.Request): ApiOperationResult<IdUser> {
        return client.execute(
            request = request,
            responseType = ApiResponseType<IdUser>(typeName = "IdUser", mimeType = "application/json"),
            validStatusCodes = setOf(200, 201),
        )
    }

    override suspend fun update(request: UpdateOperation.Request): ApiOperationResult<IdUser> {
        return client.execute(
            request = request,
            responseType = ApiResponseType<IdUser>(typeName = "IdUser", mimeType = "application/json"),
            validStatusCodes = setOf(200),
        )
    }

    override suspend fun patch(request: PatchOperation.Request): ApiOperationResult<IdUser> {
        return client.execute(
            request = request,
            responseType = ApiResponseType<IdUser>(typeName = "IdUser", mimeType = "application/json"),
            validStatusCodes = setOf(200),
        )
    }

    override suspend fun delete(request: DeleteOperation.Request): ApiResponse {
        return client.execute(
            request = request,
            validStatusCodes = setOf(200, 204, 205),
        )
    }

    override suspend fun list(request: ListOperation.Request): ApiOperationResult<PagedResults<IdentifiedUser>> {
        return client.execute(
            request = request,
            responseType = ApiResponseType<PagedResults<IdentifiedUser>>(typeName = "PagedResults<IdentifiedUser>", mimeType = "application/json"),
            validStatusCodes = setOf(200),
        )
    }

    override suspend fun `get`(request: GetOperation.Request): ApiOperationResult<IdentifiedUser> {
        return client.execute(
            request = request,
            responseType = ApiResponseType<IdentifiedUser>(typeName = "IdentifiedUser", mimeType = "application/json"),
            validStatusCodes = setOf(200),
        )
    }

    override suspend fun getNextPage(currentPage: PagedResults<IdentifiedUser>, request: ListOperation.Request): ApiOperationResult<PagedResults<IdentifiedUser>> {
        val next = currentPage.next ?: throw ApiError.InvalidUrl
        return client.execute(
            request = NextPageRequest(
                requestUrl = next,
                headers = request.toApiRequest().headers,
            ),
            responseType = ApiResponseType<PagedResults<IdentifiedUser>>(typeName = "PagedResults<IdentifiedUser>", mimeType = "application/json"),
            validStatusCodes = setOf(200),
        )
    }
}
