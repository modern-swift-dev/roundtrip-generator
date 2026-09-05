// Generated code. Do not edit.
package com.example.api.showcase.transport

import com.example.api.ApiOperationResult
import com.example.api.ApiProgress
import com.example.api.ApiRequest
import com.example.api.ApiRequestConvertible
import com.example.api.ApiRequestPath
import com.example.api.ApiResponse
import com.example.api.ApiResponseType
import com.example.api.ApiUploadSource
import com.example.api.MultipartBody
import com.example.api.RestClient
import com.example.api.apiBodySerializer
import com.example.api.showcase.transport.models.DeleteReceiptRequest
import com.example.api.showcase.transport.models.UploadReceipt
import com.example.api.toApiFormValue
import kotlinx.serialization.serializer

interface ShowcaseTransportApi {
    suspend fun uploadMultipart(
        compress: Boolean? = false,
        apiKey: String? = null,
        body: MultipartBody = MultipartBody(),
        progress: ApiProgress? = null,
    ): ApiOperationResult<UploadReceipt>

    suspend fun uploadFile(
        apiKey: String? = null,
        body: ApiUploadSource,
        progress: ApiProgress? = null,
    ): ApiOperationResult<UploadReceipt>

    suspend fun uploadBinary(
        contentMd5: String? = null,
        apiKey: String? = null,
        body: ByteArray,
        progress: ApiProgress? = null,
    ): ApiResponse

    suspend fun deleteWithBody(
        apiKey: String? = null,
        body: DeleteReceiptRequest,
    ): ApiOperationResult<UploadReceipt>
}


class ShowcaseTransportApiService(
    private val client: RestClient,
) : ShowcaseTransportApi {
    override suspend fun uploadMultipart(
        compress: Boolean?,
        apiKey: String?,
        body: MultipartBody,
        progress: ApiProgress?,
    ): ApiOperationResult<UploadReceipt> {
        val request = UploadMultipartOperation.Request(compress = compress, apiKey = apiKey, body = body)
        val adaptedRequest = request.copy(apiKey = request.apiKey?.takeIf { it.isNotBlank() } ?: client.requireApiKey())
        return client.postMultipart(
            request = adaptedRequest,
            progress = progress,
            responseType = ApiResponseType<UploadReceipt>(typeName = "UploadReceipt", mimeType = "application/json", serializer = serializer()),
            validStatusCodes = setOf(200, 201),
        )
    }

    override suspend fun uploadFile(
        apiKey: String?,
        body: ApiUploadSource,
        progress: ApiProgress?,
    ): ApiOperationResult<UploadReceipt> {
        val request = UploadFileOperation.Request(apiKey = apiKey, body = body)
        val adaptedRequest = request.copy(apiKey = request.apiKey?.takeIf { it.isNotBlank() } ?: client.requireApiKey())
        return client.upload(
            request = adaptedRequest,
            progress = progress,
            responseType = ApiResponseType<UploadReceipt>(typeName = "UploadReceipt", mimeType = "application/json", serializer = serializer()),
            validStatusCodes = setOf(200, 201),
        )
    }

    override suspend fun uploadBinary(
        contentMd5: String?,
        apiKey: String?,
        body: ByteArray,
        progress: ApiProgress?,
    ): ApiResponse {
        val request = UploadBinaryOperation.Request(contentMd5 = contentMd5, apiKey = apiKey, body = body)
        val adaptedRequest = request.copy(apiKey = request.apiKey?.takeIf { it.isNotBlank() } ?: client.requireApiKey())
        return client.upload(
            request = adaptedRequest,
            progress = progress,
            validStatusCodes = setOf(200, 202),
        )
    }

    override suspend fun deleteWithBody(
        apiKey: String?,
        body: DeleteReceiptRequest,
    ): ApiOperationResult<UploadReceipt> {
        val request = DeleteWithBodyOperation.Request(apiKey = apiKey, body = body)
        val adaptedRequest = request.copy(apiKey = request.apiKey?.takeIf { it.isNotBlank() } ?: client.requireApiKey())
        return client.execute(
            request = adaptedRequest,
            responseType = ApiResponseType<UploadReceipt>(typeName = "UploadReceipt", mimeType = "application/json", serializer = serializer()),
            validStatusCodes = setOf(200, 202),
        )
    }
}
