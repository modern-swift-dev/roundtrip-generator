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
import com.example.api.PatchableValue
import com.example.api.RestClient
import com.example.api.apiBodySerializer
import com.example.api.tenant.projecttask.models.CompleteTaskRequest
import com.example.api.tenant.projecttask.models.IdTask
import com.example.api.tenant.projecttask.models.IdentifiedTask
import com.example.api.tenant.projecttask.models.PatchedTask
import com.example.api.tenant.projecttask.models.Task
import com.example.api.toApiFormValue
import com.example.api.toApiPathSegment
import kotlinx.serialization.serializer

interface TenantProjectTaskApi {
    suspend fun create(
        tenantId: String,
        projectId: String,
        body: Task,
    ): ApiOperationResult<IdTask>

    suspend fun patch(
        tenantId: String,
        projectId: String,
        taskId: String,
        body: PatchedTask,
    ): ApiOperationResult<IdTask>

    suspend fun list(
        tenantId: String,
        projectId: String,
        done: Boolean? = null,
    ): ApiOperationResult<PagedResults<IdentifiedTask>>

    suspend fun `get`(
        tenantId: String,
        projectId: String,
        taskId: String,
    ): ApiOperationResult<IdentifiedTask>

    suspend fun complete(
        tenantId: String,
        projectId: String,
        taskId: String,
        notify: Boolean? = true,
        apiKey: String? = null,
        body: CompleteTaskRequest,
    ): ApiOperationResult<IdObject>

    suspend fun getNextPageForListOperation(
        currentPage: PagedResults<IdentifiedTask>,
        tenantId: String,
        projectId: String,
        done: Boolean? = null,
    ): ApiOperationResult<PagedResults<IdentifiedTask>>
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
    override suspend fun create(
        tenantId: String,
        projectId: String,
        body: Task,
    ): ApiOperationResult<IdTask> {
        val request = CreateOperation.Request(tenantId = tenantId, projectId = projectId, body = body)
        return client.execute(
            request = request,
            responseType = ApiResponseType<IdTask>(typeName = "IdTask", mimeType = "application/json", serializer = serializer()),
            validStatusCodes = setOf(200, 201),
        )
    }

    override suspend fun patch(
        tenantId: String,
        projectId: String,
        taskId: String,
        body: PatchedTask,
    ): ApiOperationResult<IdTask> {
        val request = PatchOperation.Request(tenantId = tenantId, projectId = projectId, taskId = taskId, body = body)
        return client.execute(
            request = request,
            responseType = ApiResponseType<IdTask>(typeName = "IdTask", mimeType = "application/json", serializer = serializer()),
            validStatusCodes = setOf(200),
        )
    }

    override suspend fun list(
        tenantId: String,
        projectId: String,
        done: Boolean?,
    ): ApiOperationResult<PagedResults<IdentifiedTask>> {
        val request = ListOperation.Request(tenantId = tenantId, projectId = projectId, done = done)
        return client.execute(
            request = request,
            responseType = ApiResponseType<PagedResults<IdentifiedTask>>(typeName = "PagedResults<IdentifiedTask>", mimeType = "application/json", serializer = serializer()),
            validStatusCodes = setOf(200),
        )
    }

    override suspend fun `get`(
        tenantId: String,
        projectId: String,
        taskId: String,
    ): ApiOperationResult<IdentifiedTask> {
        val request = GetOperation.Request(tenantId = tenantId, projectId = projectId, taskId = taskId)
        return client.execute(
            request = request,
            responseType = ApiResponseType<IdentifiedTask>(typeName = "IdentifiedTask", mimeType = "application/json", serializer = serializer()),
            validStatusCodes = setOf(200),
        )
    }

    override suspend fun complete(
        tenantId: String,
        projectId: String,
        taskId: String,
        notify: Boolean?,
        apiKey: String?,
        body: CompleteTaskRequest,
    ): ApiOperationResult<IdObject> {
        val request = CompleteOperation.Request(tenantId = tenantId, projectId = projectId, taskId = taskId, notify = notify, apiKey = apiKey, body = body)
        val adaptedRequest = request.copy(apiKey = request.apiKey?.takeIf { it.isNotBlank() } ?: client.apiKey())
        return client.execute(
            request = adaptedRequest,
            responseType = ApiResponseType<IdObject>(typeName = "IdObject", mimeType = "application/json", serializer = serializer()),
            validStatusCodes = setOf(200),
        )
    }

    override suspend fun getNextPageForListOperation(
        currentPage: PagedResults<IdentifiedTask>,
        tenantId: String,
        projectId: String,
        done: Boolean?,
    ): ApiOperationResult<PagedResults<IdentifiedTask>> {
        val request = ListOperation.Request(tenantId = tenantId, projectId = projectId, done = done)
        val next = currentPage.next ?: throw ApiError.InvalidUrl
        return client.execute(
            request = NextPageRequest(
                requestUrl = next,
                headers = request.toApiRequest().headers,
            ),
            responseType = ApiResponseType<PagedResults<IdentifiedTask>>(typeName = "PagedResults<IdentifiedTask>", mimeType = "application/json", serializer = serializer()),
            validStatusCodes = setOf(200),
        )
    }
}
