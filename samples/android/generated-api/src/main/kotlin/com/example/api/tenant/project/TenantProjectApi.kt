// Generated code. Do not edit.
package com.example.api.tenant.project

import com.example.api.ApiOperationResult
import com.example.api.ApiRequest
import com.example.api.ApiRequestConvertible
import com.example.api.ApiRequestPath
import com.example.api.ApiResponse
import com.example.api.ApiResponseType
import com.example.api.IdObject
import com.example.api.NamedObject
import com.example.api.RestClient
import com.example.api.apiBodySerializer
import com.example.api.tenant.project.models.IdProject
import com.example.api.tenant.project.models.IdentifiedProject
import com.example.api.tenant.project.models.Project
import com.example.api.tenant.shared.TenantStatus
import com.example.api.toApiFormValue
import com.example.api.toApiPathSegment
import kotlinx.serialization.serializer

interface TenantProjectApi {
    suspend fun create(
        tenantId: String,
        body: Project,
    ): ApiOperationResult<IdProject>

    suspend fun update(
        tenantId: String,
        projectId: String,
        body: Project,
    ): ApiOperationResult<IdProject>

    suspend fun delete(
        tenantId: String,
        projectId: String,
    ): ApiResponse

    suspend fun list(
        tenantId: String,
        status: List<TenantStatus>? = listOf(TenantStatus.fromValue("active")),
        includeArchived: Boolean? = false,
    ): ApiOperationResult<List<IdentifiedProject>>

    suspend fun `get`(
        tenantId: String,
        projectId: String,
    ): ApiOperationResult<IdentifiedProject>

    suspend fun archive(
        tenantId: String,
        projectId: String,
        cascade: Boolean? = false,
        apiKey: String? = null,
    ): ApiOperationResult<IdObject>
}


class TenantProjectApiService(
    private val client: RestClient,
) : TenantProjectApi {
    override suspend fun create(
        tenantId: String,
        body: Project,
    ): ApiOperationResult<IdProject> {
        val request = CreateOperation.Request(tenantId = tenantId, body = body)
        return client.execute(
            request = request,
            responseType = ApiResponseType<IdProject>(typeName = "IdProject", mimeType = "application/json", serializer = serializer()),
            validStatusCodes = setOf(200, 201),
        )
    }

    override suspend fun update(
        tenantId: String,
        projectId: String,
        body: Project,
    ): ApiOperationResult<IdProject> {
        val request = UpdateOperation.Request(tenantId = tenantId, projectId = projectId, body = body)
        return client.execute(
            request = request,
            responseType = ApiResponseType<IdProject>(typeName = "IdProject", mimeType = "application/json", serializer = serializer()),
            validStatusCodes = setOf(200),
        )
    }

    override suspend fun delete(
        tenantId: String,
        projectId: String,
    ): ApiResponse {
        val request = DeleteOperation.Request(tenantId = tenantId, projectId = projectId)
        return client.execute(
            request = request,
            validStatusCodes = setOf(200, 204, 205),
        )
    }

    override suspend fun list(
        tenantId: String,
        status: List<TenantStatus>?,
        includeArchived: Boolean?,
    ): ApiOperationResult<List<IdentifiedProject>> {
        val request = ListOperation.Request(tenantId = tenantId, status = status, includeArchived = includeArchived)
        return client.execute(
            request = request,
            responseType = ApiResponseType<List<IdentifiedProject>>(typeName = "List<IdentifiedProject>", mimeType = "application/json", serializer = serializer()),
            validStatusCodes = setOf(200),
        )
    }

    override suspend fun `get`(
        tenantId: String,
        projectId: String,
    ): ApiOperationResult<IdentifiedProject> {
        val request = GetOperation.Request(tenantId = tenantId, projectId = projectId)
        return client.execute(
            request = request,
            responseType = ApiResponseType<IdentifiedProject>(typeName = "IdentifiedProject", mimeType = "application/json", serializer = serializer()),
            validStatusCodes = setOf(200),
        )
    }

    override suspend fun archive(
        tenantId: String,
        projectId: String,
        cascade: Boolean?,
        apiKey: String?,
    ): ApiOperationResult<IdObject> {
        val request = ArchiveOperation.Request(tenantId = tenantId, projectId = projectId, cascade = cascade, apiKey = apiKey)
        val adaptedRequest = request.copy(apiKey = request.apiKey?.takeIf { it.isNotBlank() } ?: client.requireApiKey())
        return client.execute(
            request = adaptedRequest,
            responseType = ApiResponseType<IdObject>(typeName = "IdObject", mimeType = "application/json", serializer = serializer()),
            validStatusCodes = setOf(200, 202),
        )
    }
}
