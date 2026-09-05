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
import com.example.api.RestClient
import com.example.api.admin.role.models.IdRole
import com.example.api.admin.role.models.IdentifiedRole
import com.rickclephas.kmp.nativecoroutines.NativeCoroutines

interface AdminRoleApi {
    @NativeCoroutines
    suspend fun create(request: CreateOperation.Request): ApiOperationResult<IdRole>

    @NativeCoroutines
    suspend fun update(request: UpdateOperation.Request): ApiOperationResult<IdRole>

    @NativeCoroutines
    suspend fun patch(request: PatchOperation.Request): ApiOperationResult<IdRole>

    @NativeCoroutines
    suspend fun delete(request: DeleteOperation.Request): ApiResponse

    @NativeCoroutines
    suspend fun list(request: ListOperation.Request): ApiOperationResult<PagedResults<IdentifiedRole>>

    @NativeCoroutines
    suspend fun `get`(request: GetOperation.Request): ApiOperationResult<IdentifiedRole>

    @NativeCoroutines
    suspend fun getNextPage(currentPage: PagedResults<IdentifiedRole>, request: ListOperation.Request): ApiOperationResult<PagedResults<IdentifiedRole>>
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
    override suspend fun create(request: CreateOperation.Request): ApiOperationResult<IdRole> {
        return client.execute(
            request = request,
            responseType = ApiResponseType<IdRole>(typeName = "IdRole", mimeType = "application/json"),
            validStatusCodes = setOf(200, 201),
        )
    }

    override suspend fun update(request: UpdateOperation.Request): ApiOperationResult<IdRole> {
        return client.execute(
            request = request,
            responseType = ApiResponseType<IdRole>(typeName = "IdRole", mimeType = "application/json"),
            validStatusCodes = setOf(200),
        )
    }

    override suspend fun patch(request: PatchOperation.Request): ApiOperationResult<IdRole> {
        return client.execute(
            request = request,
            responseType = ApiResponseType<IdRole>(typeName = "IdRole", mimeType = "application/json"),
            validStatusCodes = setOf(200),
        )
    }

    override suspend fun delete(request: DeleteOperation.Request): ApiResponse {
        return client.execute(
            request = request,
            validStatusCodes = setOf(200, 204, 205),
        )
    }

    override suspend fun list(request: ListOperation.Request): ApiOperationResult<PagedResults<IdentifiedRole>> {
        return client.execute(
            request = request,
            responseType = ApiResponseType<PagedResults<IdentifiedRole>>(typeName = "PagedResults<IdentifiedRole>", mimeType = "application/json"),
            validStatusCodes = setOf(200),
        )
    }

    override suspend fun `get`(request: GetOperation.Request): ApiOperationResult<IdentifiedRole> {
        return client.execute(
            request = request,
            responseType = ApiResponseType<IdentifiedRole>(typeName = "IdentifiedRole", mimeType = "application/json"),
            validStatusCodes = setOf(200),
        )
    }

    override suspend fun getNextPage(currentPage: PagedResults<IdentifiedRole>, request: ListOperation.Request): ApiOperationResult<PagedResults<IdentifiedRole>> {
        val next = currentPage.next ?: throw ApiError.InvalidUrl
        return client.execute(
            request = NextPageRequest(
                requestUrl = next,
                headers = request.toApiRequest().headers,
            ),
            responseType = ApiResponseType<PagedResults<IdentifiedRole>>(typeName = "PagedResults<IdentifiedRole>", mimeType = "application/json"),
            validStatusCodes = setOf(200),
        )
    }
}
