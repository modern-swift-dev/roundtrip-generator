// Generated code. Do not edit.
package com.example.api.admin.group

import com.example.api.ApiError
import com.example.api.ApiOperationResult
import com.example.api.ApiRequest
import com.example.api.ApiRequestConvertible
import com.example.api.ApiRequestPath
import com.example.api.ApiResponse
import com.example.api.ApiResponseType
import com.example.api.PagedResults
import com.example.api.RestClient
import com.example.api.admin.group.models.IdGroup
import com.example.api.admin.group.models.IdentifiedGroup
import com.rickclephas.kmp.nativecoroutines.NativeCoroutines

interface AdminGroupApi {
    @NativeCoroutines
    suspend fun create(request: CreateOperation.Request): ApiOperationResult<IdGroup>

    @NativeCoroutines
    suspend fun update(request: UpdateOperation.Request): ApiOperationResult<IdGroup>

    @NativeCoroutines
    suspend fun patch(request: PatchOperation.Request): ApiOperationResult<IdGroup>

    @NativeCoroutines
    suspend fun delete(request: DeleteOperation.Request): ApiResponse

    @NativeCoroutines
    suspend fun list(request: ListOperation.Request): ApiOperationResult<PagedResults<IdentifiedGroup>>

    @NativeCoroutines
    suspend fun `get`(request: GetOperation.Request): ApiOperationResult<IdentifiedGroup>

    @NativeCoroutines
    suspend fun getNextPage(currentPage: PagedResults<IdentifiedGroup>, request: ListOperation.Request): ApiOperationResult<PagedResults<IdentifiedGroup>>
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

class AdminGroupApiService(
    private val client: RestClient,
) : AdminGroupApi {
    override suspend fun create(request: CreateOperation.Request): ApiOperationResult<IdGroup> {
        return client.execute(
            request = request,
            responseType = ApiResponseType<IdGroup>(typeName = "IdGroup", mimeType = "application/json"),
            validStatusCodes = setOf(200, 201),
        )
    }

    override suspend fun update(request: UpdateOperation.Request): ApiOperationResult<IdGroup> {
        return client.execute(
            request = request,
            responseType = ApiResponseType<IdGroup>(typeName = "IdGroup", mimeType = "application/json"),
            validStatusCodes = setOf(200),
        )
    }

    override suspend fun patch(request: PatchOperation.Request): ApiOperationResult<IdGroup> {
        return client.execute(
            request = request,
            responseType = ApiResponseType<IdGroup>(typeName = "IdGroup", mimeType = "application/json"),
            validStatusCodes = setOf(200),
        )
    }

    override suspend fun delete(request: DeleteOperation.Request): ApiResponse {
        return client.execute(
            request = request,
            validStatusCodes = setOf(200, 204, 205),
        )
    }

    override suspend fun list(request: ListOperation.Request): ApiOperationResult<PagedResults<IdentifiedGroup>> {
        return client.execute(
            request = request,
            responseType = ApiResponseType<PagedResults<IdentifiedGroup>>(typeName = "PagedResults<IdentifiedGroup>", mimeType = "application/json"),
            validStatusCodes = setOf(200),
        )
    }

    override suspend fun `get`(request: GetOperation.Request): ApiOperationResult<IdentifiedGroup> {
        return client.execute(
            request = request,
            responseType = ApiResponseType<IdentifiedGroup>(typeName = "IdentifiedGroup", mimeType = "application/json"),
            validStatusCodes = setOf(200),
        )
    }

    override suspend fun getNextPage(currentPage: PagedResults<IdentifiedGroup>, request: ListOperation.Request): ApiOperationResult<PagedResults<IdentifiedGroup>> {
        val next = currentPage.next ?: throw ApiError.InvalidUrl
        return client.execute(
            request = NextPageRequest(
                requestUrl = next,
                headers = request.toApiRequest().headers,
            ),
            responseType = ApiResponseType<PagedResults<IdentifiedGroup>>(typeName = "PagedResults<IdentifiedGroup>", mimeType = "application/json"),
            validStatusCodes = setOf(200),
        )
    }
}
