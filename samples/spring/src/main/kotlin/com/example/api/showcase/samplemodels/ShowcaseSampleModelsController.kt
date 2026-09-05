// Generated code. Do not edit.
package com.example.api.showcase.samplemodels

import com.example.api.AuditStamp
import com.example.api.DateInterval
import com.example.api.GeneratedResponseEntityEncoder
import com.example.api.GeneratedSecurityMiddleware
import com.example.api.GeneratedSecurityRequest
import com.example.api.NamedObject
import com.example.api.showcase.samplemodels.models.EmailNotification
import com.example.api.showcase.samplemodels.models.NotificationEnvelope
import com.example.api.showcase.samplemodels.models.PrimitiveMatrix
import com.example.api.showcase.samplemodels.models.PushNotification
import com.example.api.showcase.samplemodels.models.SampleScore
import com.example.api.showcase.shared.SampleVisibility
import jakarta.servlet.http.HttpServletRequest
import org.springframework.http.HttpStatus
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
import org.springframework.web.server.ResponseStatusException

@RestController
class ShowcaseSampleModelsController(
    private val service: ShowcaseSampleModelsService,
    private val security: GeneratedSecurityMiddleware,
) {
    private fun <T> badRequestOnParse(block: () -> T): T =
        try {
            block()
        } catch (exception: Exception) {
            throw ResponseStatusException(HttpStatus.BAD_REQUEST, exception.message, exception)
        }

    @GetMapping("/showcase/matrix/{matrix_id}", produces = [MediaType.APPLICATION_JSON_VALUE])
    suspend fun getMatrix(
        servletRequest: HttpServletRequest,
        @PathVariable("matrix_id") matrixId: String,
        @RequestParam("visible", required = false) visible: Boolean = true,
        @RequestParam("visibility", required = false) visibility: String = "public",
        @RequestParam("scores", required = false) scores: List<Int> = listOf(100),
        @RequestHeader("X-Trace-Id", required = false) traceId: String? = null,
        @CookieValue("sample_session", required = false) sampleSession: String? = null,
        @RequestHeader("Authorization", required = false) apiKey: String? = null,
    ): ResponseEntity<PrimitiveMatrix> {
        val securityRequest = GeneratedSecurityRequest(servletRequest, "Showcase.SampleModels.GetMatrix")
        security.authorizeOptional(securityRequest)
        val serviceRequest =
            ShowcaseSampleModelsGetMatrixRequest(
                matrixId = matrixId,
                visible = visible,
                visibility = this.badRequestOnParse { SampleVisibility.fromValue(visibility) },
                scores = scores.map { this.badRequestOnParse { SampleScore.fromValue(it) } },
                traceId = traceId,
                sampleSession = sampleSession,
                apiKey = apiKey,
            )
        val serviceResponse = service.getMatrix(serviceRequest)
        return GeneratedResponseEntityEncoder.json(serviceResponse, validStatusCodes = setOf(200))
    }

    @PostMapping("/showcase/notifications", consumes = [MediaType.APPLICATION_JSON_VALUE], produces = [MediaType.APPLICATION_JSON_VALUE])
    suspend fun createNotification(
        servletRequest: HttpServletRequest,
        @RequestHeader("Idempotency-Key", required = false) idempotencyKey: String? = null,
        @RequestHeader("Authorization") apiKey: String,
        @RequestBody body: NotificationEnvelope,
    ): ResponseEntity<NotificationEnvelope> {
        val securityRequest = GeneratedSecurityRequest(servletRequest, "Showcase.SampleModels.CreateNotification")
        security.requireAuthorization(securityRequest)
        val serviceRequest =
            ShowcaseSampleModelsCreateNotificationRequest(
                idempotencyKey = idempotencyKey,
                apiKey = apiKey,
                body = body,
            )
        val serviceResponse = service.createNotification(serviceRequest)
        return GeneratedResponseEntityEncoder.json(serviceResponse, validStatusCodes = setOf(200, 201, 202))
    }

    // Skipped followRuntimeUrl: runtime paths cannot be registered by a backend.
}
