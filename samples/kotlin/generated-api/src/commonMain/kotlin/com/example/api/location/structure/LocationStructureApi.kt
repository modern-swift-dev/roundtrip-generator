// Generated code. Do not edit.
package com.example.api.location.structure

import com.example.api.ApiError
import com.example.api.ApiOperationResult
import com.example.api.ApiRequest
import com.example.api.ApiRequestConvertible
import com.example.api.ApiRequestPath
import com.example.api.ApiResponse
import com.example.api.ApiResponseType
import com.example.api.PagedResults
import com.example.api.RestClient
import com.example.api.StructureType
import com.example.api.location.structure.models.IdStructure
import com.example.api.location.structure.models.IdentifiedStructure
import com.rickclephas.kmp.nativecoroutines.NativeCoroutines

interface LocationStructureApi {
    @NativeCoroutines
    suspend fun create(request: CreateOperation.Request): ApiOperationResult<IdStructure>

    @NativeCoroutines
    suspend fun update(request: UpdateOperation.Request): ApiOperationResult<IdStructure>

    @NativeCoroutines
    suspend fun patch(request: PatchOperation.Request): ApiOperationResult<IdStructure>

    @NativeCoroutines
    suspend fun delete(request: DeleteOperation.Request): ApiResponse

    @NativeCoroutines
    suspend fun list(request: ListOperation.Request): ApiOperationResult<PagedResults<IdentifiedStructure>>

    @NativeCoroutines
    suspend fun `get`(request: GetOperation.Request): ApiOperationResult<IdentifiedStructure>

    @NativeCoroutines
    suspend fun getNextPage(currentPage: PagedResults<IdentifiedStructure>, request: ListOperation.Request): ApiOperationResult<PagedResults<IdentifiedStructure>>
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

class LocationStructureApiService(
    private val client: RestClient,
) : LocationStructureApi {
    override suspend fun create(request: CreateOperation.Request): ApiOperationResult<IdStructure> {
        return client.execute(
            request = request,
            responseType = ApiResponseType<IdStructure>(typeName = "IdStructure", mimeType = "application/json"),
            validStatusCodes = setOf(200, 201),
        )
    }

    override suspend fun update(request: UpdateOperation.Request): ApiOperationResult<IdStructure> {
        return client.execute(
            request = request,
            responseType = ApiResponseType<IdStructure>(typeName = "IdStructure", mimeType = "application/json"),
            validStatusCodes = setOf(200),
        )
    }

    override suspend fun patch(request: PatchOperation.Request): ApiOperationResult<IdStructure> {
        return client.execute(
            request = request,
            responseType = ApiResponseType<IdStructure>(typeName = "IdStructure", mimeType = "application/json"),
            validStatusCodes = setOf(200),
        )
    }

    override suspend fun delete(request: DeleteOperation.Request): ApiResponse {
        return client.execute(
            request = request,
            validStatusCodes = setOf(200, 204, 205),
        )
    }

    override suspend fun list(request: ListOperation.Request): ApiOperationResult<PagedResults<IdentifiedStructure>> {
        return client.execute(
            request = request,
            responseType = ApiResponseType<PagedResults<IdentifiedStructure>>(typeName = "PagedResults<IdentifiedStructure>", mimeType = "application/json"),
            validStatusCodes = setOf(200),
        )
    }

    override suspend fun `get`(request: GetOperation.Request): ApiOperationResult<IdentifiedStructure> {
        return client.execute(
            request = request,
            responseType = ApiResponseType<IdentifiedStructure>(typeName = "IdentifiedStructure", mimeType = "application/json"),
            validStatusCodes = setOf(200),
        )
    }

    override suspend fun getNextPage(currentPage: PagedResults<IdentifiedStructure>, request: ListOperation.Request): ApiOperationResult<PagedResults<IdentifiedStructure>> {
        val next = currentPage.next ?: throw ApiError.InvalidUrl
        return client.execute(
            request = NextPageRequest(
                requestUrl = next,
                headers = request.toApiRequest().headers,
            ),
            responseType = ApiResponseType<PagedResults<IdentifiedStructure>>(typeName = "PagedResults<IdentifiedStructure>", mimeType = "application/json"),
            validStatusCodes = setOf(200),
        )
    }
}
