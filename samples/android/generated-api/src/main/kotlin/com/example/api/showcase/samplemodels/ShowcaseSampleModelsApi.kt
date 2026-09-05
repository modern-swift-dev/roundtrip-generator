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
import com.example.api.apiBodySerializer
import com.example.api.showcase.samplemodels.models.EmailNotification
import com.example.api.showcase.samplemodels.models.NotificationEnvelope
import com.example.api.showcase.samplemodels.models.PrimitiveMatrix
import com.example.api.showcase.samplemodels.models.PushNotification
import com.example.api.showcase.samplemodels.models.SampleScore
import com.example.api.showcase.shared.SampleVisibility
import com.example.api.toApiFormValue
import com.example.api.toApiPathSegment
import com.example.api.toCookieHeader
import kotlinx.serialization.serializer

interface ShowcaseSampleModelsApi {
    suspend fun getMatrix(
        matrixId: String,
        visible: Boolean = true,
        visibility: SampleVisibility = SampleVisibility.fromValue("public"),
        scores: List<SampleScore>? = listOf(SampleScore.fromValue(100)),
        traceId: String? = null,
        sampleSession: String? = null,
        apiKey: String? = null,
    ): ApiOperationResult<PrimitiveMatrix>

    suspend fun createNotification(
        idempotencyKey: String? = null,
        apiKey: String? = null,
        body: NotificationEnvelope,
    ): ApiOperationResult<NotificationEnvelope>

    suspend fun followRuntimeUrl(
        requestUrl: String,
        apiKey: String? = null,
    ): ApiOperationResult<PagedResults<PrimitiveMatrix>>

    suspend fun getNextPageForFollowRuntimeUrlOperation(
        currentPage: PagedResults<PrimitiveMatrix>,
        requestUrl: String,
        apiKey: String? = null,
    ): ApiOperationResult<PagedResults<PrimitiveMatrix>>
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
    override suspend fun getMatrix(
        matrixId: String,
        visible: Boolean,
        visibility: SampleVisibility,
        scores: List<SampleScore>?,
        traceId: String?,
        sampleSession: String?,
        apiKey: String?,
    ): ApiOperationResult<PrimitiveMatrix> {
        val request = GetMatrixOperation.Request(matrixId = matrixId, visible = visible, visibility = visibility, scores = scores, traceId = traceId, sampleSession = sampleSession, apiKey = apiKey)
        val adaptedRequest = request.copy(apiKey = request.apiKey?.takeIf { it.isNotBlank() } ?: client.apiKey())
        return client.execute(
            request = adaptedRequest,
            responseType = ApiResponseType<PrimitiveMatrix>(typeName = "PrimitiveMatrix", mimeType = "application/json", serializer = serializer()),
            validStatusCodes = setOf(200),
        )
    }

    override suspend fun createNotification(
        idempotencyKey: String?,
        apiKey: String?,
        body: NotificationEnvelope,
    ): ApiOperationResult<NotificationEnvelope> {
        val request = CreateNotificationOperation.Request(idempotencyKey = idempotencyKey, apiKey = apiKey, body = body)
        val adaptedRequest = request.copy(apiKey = request.apiKey?.takeIf { it.isNotBlank() } ?: client.requireApiKey())
        return client.execute(
            request = adaptedRequest,
            responseType = ApiResponseType<NotificationEnvelope>(typeName = "NotificationEnvelope", mimeType = "application/json", serializer = serializer()),
            validStatusCodes = setOf(200, 201, 202),
        )
    }

    override suspend fun followRuntimeUrl(
        requestUrl: String,
        apiKey: String?,
    ): ApiOperationResult<PagedResults<PrimitiveMatrix>> {
        val request = FollowRuntimeUrlOperation.Request(requestUrl = requestUrl, apiKey = apiKey)
        val adaptedRequest = request.copy(apiKey = request.apiKey?.takeIf { it.isNotBlank() } ?: client.apiKey())
        return client.execute(
            request = adaptedRequest,
            responseType = ApiResponseType<PagedResults<PrimitiveMatrix>>(typeName = "PagedResults<PrimitiveMatrix>", mimeType = "application/json", serializer = serializer()),
            validStatusCodes = setOf(200),
        )
    }

    override suspend fun getNextPageForFollowRuntimeUrlOperation(
        currentPage: PagedResults<PrimitiveMatrix>,
        requestUrl: String,
        apiKey: String?,
    ): ApiOperationResult<PagedResults<PrimitiveMatrix>> {
        val request = FollowRuntimeUrlOperation.Request(requestUrl = requestUrl, apiKey = apiKey)
        val next = currentPage.next ?: throw ApiError.InvalidUrl
        val adaptedRequest = request.copy(apiKey = request.apiKey?.takeIf { it.isNotBlank() } ?: client.apiKey())
        return client.execute(
            request = NextPageRequest(
                requestUrl = next,
                headers = adaptedRequest.toApiRequest().headers,
            ),
            responseType = ApiResponseType<PagedResults<PrimitiveMatrix>>(typeName = "PagedResults<PrimitiveMatrix>", mimeType = "application/json", serializer = serializer()),
            validStatusCodes = setOf(200),
        )
    }
}
