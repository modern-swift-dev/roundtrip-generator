// Generated code. Do not edit.
package com.example.api.tenant.project

import com.example.api.ApiOperationResult
import com.example.api.ApiResponse
import com.example.api.ApiResponseType
import com.example.api.IdObject
import com.example.api.NamedObject
import com.example.api.RestClient
import com.example.api.tenant.project.models.IdProject
import com.example.api.tenant.project.models.IdentifiedProject
import com.example.api.tenant.shared.TenantStatus
import com.rickclephas.kmp.nativecoroutines.NativeCoroutines

interface TenantProjectApi {
    @NativeCoroutines
    suspend fun create(request: CreateOperation.Request): ApiOperationResult<IdProject>

    @NativeCoroutines
    suspend fun update(request: UpdateOperation.Request): ApiOperationResult<IdProject>

    @NativeCoroutines
    suspend fun delete(request: DeleteOperation.Request): ApiResponse

    @NativeCoroutines
    suspend fun list(request: ListOperation.Request): ApiOperationResult<List<IdentifiedProject>>

    @NativeCoroutines
    suspend fun `get`(request: GetOperation.Request): ApiOperationResult<IdentifiedProject>

    @NativeCoroutines
    suspend fun archive(request: ArchiveOperation.Request): ApiOperationResult<IdObject>
}


class TenantProjectApiService(
    private val client: RestClient,
) : TenantProjectApi {
    override suspend fun create(request: CreateOperation.Request): ApiOperationResult<IdProject> {
        return client.execute(
            request = request,
            responseType = ApiResponseType<IdProject>(typeName = "IdProject", mimeType = "application/json"),
            validStatusCodes = setOf(200, 201),
        )
    }

    override suspend fun update(request: UpdateOperation.Request): ApiOperationResult<IdProject> {
        return client.execute(
            request = request,
            responseType = ApiResponseType<IdProject>(typeName = "IdProject", mimeType = "application/json"),
            validStatusCodes = setOf(200),
        )
    }

    override suspend fun delete(request: DeleteOperation.Request): ApiResponse {
        return client.execute(
            request = request,
            validStatusCodes = setOf(200, 204, 205),
        )
    }

    override suspend fun list(request: ListOperation.Request): ApiOperationResult<List<IdentifiedProject>> {
        return client.execute(
            request = request,
            responseType = ApiResponseType<List<IdentifiedProject>>(typeName = "List<IdentifiedProject>", mimeType = "application/json"),
            validStatusCodes = setOf(200),
        )
    }

    override suspend fun `get`(request: GetOperation.Request): ApiOperationResult<IdentifiedProject> {
        return client.execute(
            request = request,
            responseType = ApiResponseType<IdentifiedProject>(typeName = "IdentifiedProject", mimeType = "application/json"),
            validStatusCodes = setOf(200),
        )
    }

    override suspend fun archive(request: ArchiveOperation.Request): ApiOperationResult<IdObject> {
        val adaptedRequest = request.copy(apiKey = request.apiKey?.takeIf { it.isNotBlank() } ?: client.requireApiKey())
        return client.execute(
            request = adaptedRequest,
            responseType = ApiResponseType<IdObject>(typeName = "IdObject", mimeType = "application/json"),
            validStatusCodes = setOf(200, 202),
        )
    }
}
