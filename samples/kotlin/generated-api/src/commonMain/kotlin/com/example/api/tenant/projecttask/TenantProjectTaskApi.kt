// Generated code. Do not edit.
package com.example.api.tenant.projecttask

import com.example.api.ApiError
import com.example.api.ApiOperationResult
import com.example.api.ApiRequest
import com.example.api.ApiRequestConvertible
import com.example.api.ApiRequestPath
import com.example.api.ApiResponse
import com.example.api.ApiResponseType
import com.example.api.IdObject
import com.example.api.PagedResults
import com.example.api.RestClient
import com.example.api.tenant.projecttask.models.IdTask
import com.example.api.tenant.projecttask.models.IdentifiedTask
import com.rickclephas.kmp.nativecoroutines.NativeCoroutines

interface TenantProjectTaskApi {
    @NativeCoroutines
    suspend fun create(request: CreateOperation.Request): ApiOperationResult<IdTask>

    @NativeCoroutines
    suspend fun patch(request: PatchOperation.Request): ApiOperationResult<IdTask>

    @NativeCoroutines
    suspend fun list(request: ListOperation.Request): ApiOperationResult<PagedResults<IdentifiedTask>>

    @NativeCoroutines
    suspend fun `get`(request: GetOperation.Request): ApiOperationResult<IdentifiedTask>

    @NativeCoroutines
    suspend fun complete(request: CompleteOperation.Request): ApiOperationResult<IdObject>

    @NativeCoroutines
    suspend fun getNextPage(currentPage: PagedResults<IdentifiedTask>, request: ListOperation.Request): ApiOperationResult<PagedResults<IdentifiedTask>>
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

class TenantProjectTaskApiService(
    private val client: RestClient,
) : TenantProjectTaskApi {
    override suspend fun create(request: CreateOperation.Request): ApiOperationResult<IdTask> {
        return client.execute(
            request = request,
            responseType = ApiResponseType<IdTask>(typeName = "IdTask", mimeType = "application/json"),
            validStatusCodes = setOf(200, 201),
        )
    }

    override suspend fun patch(request: PatchOperation.Request): ApiOperationResult<IdTask> {
        return client.execute(
            request = request,
            responseType = ApiResponseType<IdTask>(typeName = "IdTask", mimeType = "application/json"),
            validStatusCodes = setOf(200),
        )
    }

    override suspend fun list(request: ListOperation.Request): ApiOperationResult<PagedResults<IdentifiedTask>> {
        return client.execute(
            request = request,
            responseType = ApiResponseType<PagedResults<IdentifiedTask>>(typeName = "PagedResults<IdentifiedTask>", mimeType = "application/json"),
            validStatusCodes = setOf(200),
        )
    }

    override suspend fun `get`(request: GetOperation.Request): ApiOperationResult<IdentifiedTask> {
        return client.execute(
            request = request,
            responseType = ApiResponseType<IdentifiedTask>(typeName = "IdentifiedTask", mimeType = "application/json"),
            validStatusCodes = setOf(200),
        )
    }

    override suspend fun complete(request: CompleteOperation.Request): ApiOperationResult<IdObject> {
        val adaptedRequest = request.copy(apiKey = request.apiKey?.takeIf { it.isNotBlank() } ?: client.apiKey())
        return client.execute(
            request = adaptedRequest,
            responseType = ApiResponseType<IdObject>(typeName = "IdObject", mimeType = "application/json"),
            validStatusCodes = setOf(200),
        )
    }

    override suspend fun getNextPage(currentPage: PagedResults<IdentifiedTask>, request: ListOperation.Request): ApiOperationResult<PagedResults<IdentifiedTask>> {
        val next = currentPage.next ?: throw ApiError.InvalidUrl
        return client.execute(
            request = NextPageRequest(
                requestUrl = next,
                headers = request.toApiRequest().headers,
            ),
            responseType = ApiResponseType<PagedResults<IdentifiedTask>>(typeName = "PagedResults<IdentifiedTask>", mimeType = "application/json"),
            validStatusCodes = setOf(200),
        )
    }
}
