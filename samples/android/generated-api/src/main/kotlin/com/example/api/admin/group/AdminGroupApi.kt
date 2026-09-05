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
import com.example.api.PatchableValue
import com.example.api.RestClient
import com.example.api.admin.group.models.Group
import com.example.api.admin.group.models.IdGroup
import com.example.api.admin.group.models.IdentifiedGroup
import com.example.api.admin.group.models.PatchedGroup
import com.example.api.apiBodySerializer
import com.example.api.toApiFormValue
import com.example.api.toApiPathSegment
import kotlinx.serialization.serializer

interface AdminGroupApi {
    suspend fun create(
        body: Group,
    ): ApiOperationResult<IdGroup>

    suspend fun update(
        groupId: Long,
        body: Group,
    ): ApiOperationResult<IdGroup>

    suspend fun patch(
        groupId: Long,
        body: PatchedGroup,
    ): ApiOperationResult<IdGroup>

    suspend fun delete(
        groupId: Long,
    ): ApiResponse

    suspend fun list(
        text: String? = null,
    ): ApiOperationResult<PagedResults<IdentifiedGroup>>

    suspend fun `get`(
        groupId: Long,
    ): ApiOperationResult<IdentifiedGroup>

    suspend fun getNextPageForListOperation(
        currentPage: PagedResults<IdentifiedGroup>,
        text: String? = null,
    ): ApiOperationResult<PagedResults<IdentifiedGroup>>
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
    override suspend fun create(
        body: Group,
    ): ApiOperationResult<IdGroup> {
        val request = CreateOperation.Request(body = body)
        return client.execute(
            request = request,
            responseType = ApiResponseType<IdGroup>(typeName = "IdGroup", mimeType = "application/json", serializer = serializer()),
            validStatusCodes = setOf(200, 201),
        )
    }

    override suspend fun update(
        groupId: Long,
        body: Group,
    ): ApiOperationResult<IdGroup> {
        val request = UpdateOperation.Request(groupId = groupId, body = body)
        return client.execute(
            request = request,
            responseType = ApiResponseType<IdGroup>(typeName = "IdGroup", mimeType = "application/json", serializer = serializer()),
            validStatusCodes = setOf(200),
        )
    }

    override suspend fun patch(
        groupId: Long,
        body: PatchedGroup,
    ): ApiOperationResult<IdGroup> {
        val request = PatchOperation.Request(groupId = groupId, body = body)
        return client.execute(
            request = request,
            responseType = ApiResponseType<IdGroup>(typeName = "IdGroup", mimeType = "application/json", serializer = serializer()),
            validStatusCodes = setOf(200),
        )
    }

    override suspend fun delete(
        groupId: Long,
    ): ApiResponse {
        val request = DeleteOperation.Request(groupId = groupId)
        return client.execute(
            request = request,
            validStatusCodes = setOf(200, 204, 205),
        )
    }

    override suspend fun list(
        text: String?,
    ): ApiOperationResult<PagedResults<IdentifiedGroup>> {
        val request = ListOperation.Request(text = text)
        return client.execute(
            request = request,
            responseType = ApiResponseType<PagedResults<IdentifiedGroup>>(typeName = "PagedResults<IdentifiedGroup>", mimeType = "application/json", serializer = serializer()),
            validStatusCodes = setOf(200),
        )
    }

    override suspend fun `get`(
        groupId: Long,
    ): ApiOperationResult<IdentifiedGroup> {
        val request = GetOperation.Request(groupId = groupId)
        return client.execute(
            request = request,
            responseType = ApiResponseType<IdentifiedGroup>(typeName = "IdentifiedGroup", mimeType = "application/json", serializer = serializer()),
            validStatusCodes = setOf(200),
        )
    }

    override suspend fun getNextPageForListOperation(
        currentPage: PagedResults<IdentifiedGroup>,
        text: String?,
    ): ApiOperationResult<PagedResults<IdentifiedGroup>> {
        val request = ListOperation.Request(text = text)
        val next = currentPage.next ?: throw ApiError.InvalidUrl
        return client.execute(
            request = NextPageRequest(
                requestUrl = next,
                headers = request.toApiRequest().headers,
            ),
            responseType = ApiResponseType<PagedResults<IdentifiedGroup>>(typeName = "PagedResults<IdentifiedGroup>", mimeType = "application/json", serializer = serializer()),
            validStatusCodes = setOf(200),
        )
    }
}
