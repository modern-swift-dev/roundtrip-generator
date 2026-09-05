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
import com.example.api.PatchableValue
import com.example.api.RestClient
import com.example.api.StructureType
import com.example.api.apiBodySerializer
import com.example.api.location.structure.models.IdStructure
import com.example.api.location.structure.models.IdentifiedStructure
import com.example.api.location.structure.models.PatchedStructure
import com.example.api.location.structure.models.Structure
import com.example.api.toApiFormValue
import com.example.api.toApiPathSegment
import kotlinx.serialization.serializer

interface LocationStructureApi {
    suspend fun create(
        body: Structure,
    ): ApiOperationResult<IdStructure>

    suspend fun update(
        structureId: Long,
        body: Structure,
    ): ApiOperationResult<IdStructure>

    suspend fun patch(
        structureId: Long,
        body: PatchedStructure,
    ): ApiOperationResult<IdStructure>

    suspend fun delete(
        structureId: Long,
    ): ApiResponse

    suspend fun list(
        text: String? = null,
        type: List<StructureType>,
    ): ApiOperationResult<PagedResults<IdentifiedStructure>>

    suspend fun `get`(
        structureId: Long,
    ): ApiOperationResult<IdentifiedStructure>

    suspend fun getNextPageForListOperation(
        currentPage: PagedResults<IdentifiedStructure>,
        text: String? = null,
        type: List<StructureType>,
    ): ApiOperationResult<PagedResults<IdentifiedStructure>>
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
    override suspend fun create(
        body: Structure,
    ): ApiOperationResult<IdStructure> {
        val request = CreateOperation.Request(body = body)
        return client.execute(
            request = request,
            responseType = ApiResponseType<IdStructure>(typeName = "IdStructure", mimeType = "application/json", serializer = serializer()),
            validStatusCodes = setOf(200, 201),
        )
    }

    override suspend fun update(
        structureId: Long,
        body: Structure,
    ): ApiOperationResult<IdStructure> {
        val request = UpdateOperation.Request(structureId = structureId, body = body)
        return client.execute(
            request = request,
            responseType = ApiResponseType<IdStructure>(typeName = "IdStructure", mimeType = "application/json", serializer = serializer()),
            validStatusCodes = setOf(200),
        )
    }

    override suspend fun patch(
        structureId: Long,
        body: PatchedStructure,
    ): ApiOperationResult<IdStructure> {
        val request = PatchOperation.Request(structureId = structureId, body = body)
        return client.execute(
            request = request,
            responseType = ApiResponseType<IdStructure>(typeName = "IdStructure", mimeType = "application/json", serializer = serializer()),
            validStatusCodes = setOf(200),
        )
    }

    override suspend fun delete(
        structureId: Long,
    ): ApiResponse {
        val request = DeleteOperation.Request(structureId = structureId)
        return client.execute(
            request = request,
            validStatusCodes = setOf(200, 204, 205),
        )
    }

    override suspend fun list(
        text: String?,
        type: List<StructureType>,
    ): ApiOperationResult<PagedResults<IdentifiedStructure>> {
        val request = ListOperation.Request(text = text, type = type)
        return client.execute(
            request = request,
            responseType = ApiResponseType<PagedResults<IdentifiedStructure>>(typeName = "PagedResults<IdentifiedStructure>", mimeType = "application/json", serializer = serializer()),
            validStatusCodes = setOf(200),
        )
    }

    override suspend fun `get`(
        structureId: Long,
    ): ApiOperationResult<IdentifiedStructure> {
        val request = GetOperation.Request(structureId = structureId)
        return client.execute(
            request = request,
            responseType = ApiResponseType<IdentifiedStructure>(typeName = "IdentifiedStructure", mimeType = "application/json", serializer = serializer()),
            validStatusCodes = setOf(200),
        )
    }

    override suspend fun getNextPageForListOperation(
        currentPage: PagedResults<IdentifiedStructure>,
        text: String?,
        type: List<StructureType>,
    ): ApiOperationResult<PagedResults<IdentifiedStructure>> {
        val request = ListOperation.Request(text = text, type = type)
        val next = currentPage.next ?: throw ApiError.InvalidUrl
        return client.execute(
            request = NextPageRequest(
                requestUrl = next,
                headers = request.toApiRequest().headers,
            ),
            responseType = ApiResponseType<PagedResults<IdentifiedStructure>>(typeName = "PagedResults<IdentifiedStructure>", mimeType = "application/json", serializer = serializer()),
            validStatusCodes = setOf(200),
        )
    }
}
