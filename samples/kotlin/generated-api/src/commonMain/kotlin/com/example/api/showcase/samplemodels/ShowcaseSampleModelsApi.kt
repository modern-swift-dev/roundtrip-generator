// Generated code. Do not edit.
package com.example.api.showcase.samplemodels

import com.example.api.ApiError
import com.example.api.ApiOperationResult
import com.example.api.ApiRequest
import com.example.api.ApiRequestConvertible
import com.example.api.ApiRequestPath
import com.example.api.ApiResponse
import com.example.api.ApiResponseType
import com.example.api.AuditStamp
import com.example.api.DateInterval
import com.example.api.NamedObject
import com.example.api.PagedResults
import com.example.api.RestClient
import com.example.api.showcase.samplemodels.models.EmailNotification
import com.example.api.showcase.samplemodels.models.NotificationEnvelope
import com.example.api.showcase.samplemodels.models.PrimitiveMatrix
import com.example.api.showcase.samplemodels.models.PushNotification
import com.example.api.showcase.samplemodels.models.SampleScore
import com.example.api.showcase.shared.SampleVisibility
import com.rickclephas.kmp.nativecoroutines.NativeCoroutines

interface ShowcaseSampleModelsApi {
    @NativeCoroutines
    suspend fun getMatrix(request: GetMatrixOperation.Request): ApiOperationResult<PrimitiveMatrix>

    @NativeCoroutines
    suspend fun createNotification(
        request: CreateNotificationOperation.Request,
    ): ApiOperationResult<NotificationEnvelope>

    @NativeCoroutines
    suspend fun followRuntimeUrl(
        request: FollowRuntimeUrlOperation.Request,
    ): ApiOperationResult<PagedResults<PrimitiveMatrix>>

    @NativeCoroutines
    suspend fun getNextPage(currentPage: PagedResults<PrimitiveMatrix>, request: FollowRuntimeUrlOperation.Request): ApiOperationResult<PagedResults<PrimitiveMatrix>>
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

class ShowcaseSampleModelsApiService(
    private val client: RestClient,
) : ShowcaseSampleModelsApi {
    override suspend fun getMatrix(request: GetMatrixOperation.Request): ApiOperationResult<PrimitiveMatrix> {
        val adaptedRequest = request.copy(apiKey = request.apiKey?.takeIf { it.isNotBlank() } ?: client.apiKey())
        return client.execute(
            request = adaptedRequest,
            responseType = ApiResponseType<PrimitiveMatrix>(typeName = "PrimitiveMatrix", mimeType = "application/json"),
            validStatusCodes = setOf(200),
        )
    }

    override suspend fun createNotification(
        request: CreateNotificationOperation.Request,
    ): ApiOperationResult<NotificationEnvelope> {
        val adaptedRequest = request.copy(apiKey = request.apiKey?.takeIf { it.isNotBlank() } ?: client.requireApiKey())
        return client.execute(
            request = adaptedRequest,
            responseType = ApiResponseType<NotificationEnvelope>(typeName = "NotificationEnvelope", mimeType = "application/json"),
            validStatusCodes = setOf(200, 201, 202),
        )
    }

    override suspend fun followRuntimeUrl(
        request: FollowRuntimeUrlOperation.Request,
    ): ApiOperationResult<PagedResults<PrimitiveMatrix>> {
        val adaptedRequest = request.copy(apiKey = request.apiKey?.takeIf { it.isNotBlank() } ?: client.apiKey())
        return client.execute(
            request = adaptedRequest,
            responseType = ApiResponseType<PagedResults<PrimitiveMatrix>>(typeName = "PagedResults<PrimitiveMatrix>", mimeType = "application/json"),
            validStatusCodes = setOf(200),
        )
    }

    override suspend fun getNextPage(currentPage: PagedResults<PrimitiveMatrix>, request: FollowRuntimeUrlOperation.Request): ApiOperationResult<PagedResults<PrimitiveMatrix>> {
        val next = currentPage.next ?: throw ApiError.InvalidUrl
        val adaptedRequest = request.copy(apiKey = request.apiKey?.takeIf { it.isNotBlank() } ?: client.apiKey())
        return client.execute(
            request = NextPageRequest(
                requestUrl = next,
                headers = adaptedRequest.toApiRequest().headers,
            ),
            responseType = ApiResponseType<PagedResults<PrimitiveMatrix>>(typeName = "PagedResults<PrimitiveMatrix>", mimeType = "application/json"),
            validStatusCodes = setOf(200),
        )
    }
}
