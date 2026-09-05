// Generated code. Do not edit.
package com.example.api.showcase.transport

import com.example.api.ApiOperationResult
import com.example.api.ApiProgress
import com.example.api.ApiResponse
import com.example.api.ApiResponseType
import com.example.api.RestClient
import com.example.api.showcase.transport.models.UploadReceipt
import com.rickclephas.kmp.nativecoroutines.NativeCoroutines

interface ShowcaseTransportApi {
    @NativeCoroutines
    suspend fun uploadMultipart(
        request: UploadMultipartOperation.Request,
        progress: ApiProgress? = null,
    ): ApiOperationResult<UploadReceipt>

    @NativeCoroutines
    suspend fun uploadFile(
        request: UploadFileOperation.Request,
        progress: ApiProgress? = null,
    ): ApiOperationResult<UploadReceipt>

    @NativeCoroutines
    suspend fun uploadBinary(request: UploadBinaryOperation.Request): ApiResponse

    @NativeCoroutines
    suspend fun deleteWithBody(request: DeleteWithBodyOperation.Request): ApiOperationResult<UploadReceipt>
}


class ShowcaseTransportApiService(
    private val client: RestClient,
) : ShowcaseTransportApi {
    override suspend fun uploadMultipart(
        request: UploadMultipartOperation.Request,
        progress: ApiProgress?,
    ): ApiOperationResult<UploadReceipt> {
        val adaptedRequest = request.copy(apiKey = request.apiKey?.takeIf { it.isNotBlank() } ?: client.requireApiKey())
        return client.postMultipart(
            request = adaptedRequest,
            progress = progress,
            responseType = ApiResponseType<UploadReceipt>(typeName = "UploadReceipt", mimeType = "application/json"),
            validStatusCodes = setOf(200, 201),
        )
    }

    override suspend fun uploadFile(
        request: UploadFileOperation.Request,
        progress: ApiProgress?,
    ): ApiOperationResult<UploadReceipt> {
        val adaptedRequest = request.copy(apiKey = request.apiKey?.takeIf { it.isNotBlank() } ?: client.requireApiKey())
        return client.upload(
            request = adaptedRequest,
            progress = progress,
            responseType = ApiResponseType<UploadReceipt>(typeName = "UploadReceipt", mimeType = "application/json"),
            validStatusCodes = setOf(200, 201),
        )
    }

    override suspend fun uploadBinary(request: UploadBinaryOperation.Request): ApiResponse {
        val adaptedRequest = request.copy(apiKey = request.apiKey?.takeIf { it.isNotBlank() } ?: client.requireApiKey())
        return client.execute(
            request = adaptedRequest,
            validStatusCodes = setOf(200, 202),
        )
    }

    override suspend fun deleteWithBody(request: DeleteWithBodyOperation.Request): ApiOperationResult<UploadReceipt> {
        val adaptedRequest = request.copy(apiKey = request.apiKey?.takeIf { it.isNotBlank() } ?: client.requireApiKey())
        return client.execute(
            request = adaptedRequest,
            responseType = ApiResponseType<UploadReceipt>(typeName = "UploadReceipt", mimeType = "application/json"),
            validStatusCodes = setOf(200, 202),
        )
    }
}
