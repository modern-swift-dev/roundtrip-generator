// Generated code. Do not edit.
package com.example.api.showcase.transport

import com.example.api.GeneratedResponse
import com.example.api.showcase.transport.models.UploadReceipt
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean
import org.springframework.http.HttpStatus
import org.springframework.stereotype.Service
import org.springframework.web.server.ResponseStatusException

interface ShowcaseTransportService {
    suspend fun uploadMultipart(request: ShowcaseTransportUploadMultipartRequest): GeneratedResponse<UploadReceipt>

    suspend fun uploadFile(request: ShowcaseTransportUploadFileRequest): GeneratedResponse<UploadReceipt>

    suspend fun uploadBinary(request: ShowcaseTransportUploadBinaryRequest): GeneratedResponse<ByteArray>

    suspend fun deleteWithBody(request: ShowcaseTransportDeleteWithBodyRequest): GeneratedResponse<UploadReceipt>
}

@ConditionalOnMissingBean(ShowcaseTransportService::class)
@Service
class NotImplementedShowcaseTransportService : ShowcaseTransportService {
    override suspend fun uploadMultipart(request: ShowcaseTransportUploadMultipartRequest): GeneratedResponse<UploadReceipt> =
        throw ResponseStatusException(HttpStatus.NOT_IMPLEMENTED)

    override suspend fun uploadFile(request: ShowcaseTransportUploadFileRequest): GeneratedResponse<UploadReceipt> =
        throw ResponseStatusException(HttpStatus.NOT_IMPLEMENTED)

    override suspend fun uploadBinary(request: ShowcaseTransportUploadBinaryRequest): GeneratedResponse<ByteArray> =
        throw ResponseStatusException(HttpStatus.NOT_IMPLEMENTED)

    override suspend fun deleteWithBody(request: ShowcaseTransportDeleteWithBodyRequest): GeneratedResponse<UploadReceipt> =
        throw ResponseStatusException(HttpStatus.NOT_IMPLEMENTED)
}
