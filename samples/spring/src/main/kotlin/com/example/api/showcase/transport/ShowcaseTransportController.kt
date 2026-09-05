// Generated code. Do not edit.
package com.example.api.showcase.transport

import com.example.api.GeneratedMultipartPart
import com.example.api.GeneratedResponseEntityEncoder
import com.example.api.GeneratedSecurityMiddleware
import com.example.api.GeneratedSecurityRequest
import com.example.api.showcase.transport.models.DeleteReceiptRequest
import com.example.api.showcase.transport.models.UploadReceipt
import jakarta.servlet.http.HttpServletRequest
import jakarta.servlet.http.Part
import org.springframework.http.MediaType
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.CookieValue
import org.springframework.web.bind.annotation.DeleteMapping
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PatchMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.PutMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestHeader
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.RequestPart
import org.springframework.web.bind.annotation.RestController

@RestController
class ShowcaseTransportController(
    private val service: ShowcaseTransportService,
    private val security: GeneratedSecurityMiddleware,
) {
    @PostMapping("/showcase/uploads/multipart", consumes = [MediaType.MULTIPART_FORM_DATA_VALUE], produces = [MediaType.APPLICATION_JSON_VALUE])
    suspend fun uploadMultipart(
        servletRequest: HttpServletRequest,
        @RequestParam("compress", required = false) compress: Boolean = false,
        @RequestHeader("Authorization") apiKey: String,
        @RequestPart("file", required = false) `file`: Part?,
        @RequestPart("metadata", required = false) metadata: Part?,
    ): ResponseEntity<UploadReceipt> {
        val securityRequest = GeneratedSecurityRequest(servletRequest, "Showcase.Transport.UploadMultipart")
        security.requireAuthorization(securityRequest)
        val serviceRequest =
            ShowcaseTransportUploadMultipartRequest(
                compress = compress,
                apiKey = apiKey,
                body = mapOf("file" to `file`?.let(GeneratedMultipartPart::from), "metadata" to metadata?.let(GeneratedMultipartPart::from)),
            )
        val serviceResponse = service.uploadMultipart(serviceRequest)
        return GeneratedResponseEntityEncoder.json(serviceResponse, validStatusCodes = setOf(200, 201))
    }

    @PostMapping("/showcase/uploads/file", consumes = [MediaType.APPLICATION_OCTET_STREAM_VALUE], produces = [MediaType.APPLICATION_JSON_VALUE])
    suspend fun uploadFile(
        servletRequest: HttpServletRequest,
        @RequestHeader("Authorization") apiKey: String,
        @RequestBody body: ByteArray,
    ): ResponseEntity<UploadReceipt> {
        val securityRequest = GeneratedSecurityRequest(servletRequest, "Showcase.Transport.UploadFile")
        security.requireAuthorization(securityRequest)
        val serviceRequest =
            ShowcaseTransportUploadFileRequest(
                apiKey = apiKey,
                body = body,
            )
        val serviceResponse = service.uploadFile(serviceRequest)
        return GeneratedResponseEntityEncoder.json(serviceResponse, validStatusCodes = setOf(200, 201))
    }

    @PostMapping("/showcase/uploads/binary", consumes = [MediaType.APPLICATION_OCTET_STREAM_VALUE], produces = ["application/zip"])
    suspend fun uploadBinary(
        servletRequest: HttpServletRequest,
        @RequestHeader("Content-MD5", required = false) contentMd5: String? = null,
        @RequestHeader("Authorization") apiKey: String,
        @RequestBody body: ByteArray,
    ): ResponseEntity<ByteArray> {
        val securityRequest = GeneratedSecurityRequest(servletRequest, "Showcase.Transport.UploadBinary")
        security.requireAuthorization(securityRequest)
        val serviceRequest =
            ShowcaseTransportUploadBinaryRequest(
                contentMd5 = contentMd5,
                apiKey = apiKey,
                body = body,
            )
        val serviceResponse = service.uploadBinary(serviceRequest)
        return GeneratedResponseEntityEncoder.binary(serviceResponse, MediaType.parseMediaType("application/zip"), validStatusCodes = setOf(200, 202))
    }

    @DeleteMapping("/showcase/uploads", consumes = [MediaType.APPLICATION_JSON_VALUE], produces = [MediaType.APPLICATION_JSON_VALUE])
    suspend fun deleteWithBody(
        servletRequest: HttpServletRequest,
        @RequestHeader("Authorization") apiKey: String,
        @RequestBody body: DeleteReceiptRequest,
    ): ResponseEntity<UploadReceipt> {
        val securityRequest = GeneratedSecurityRequest(servletRequest, "Showcase.Transport.DeleteWithBody")
        security.requireAuthorization(securityRequest)
        val serviceRequest =
            ShowcaseTransportDeleteWithBodyRequest(
                apiKey = apiKey,
                body = body,
            )
        val serviceResponse = service.deleteWithBody(serviceRequest)
        return GeneratedResponseEntityEncoder.json(serviceResponse, validStatusCodes = setOf(200, 202))
    }
}
