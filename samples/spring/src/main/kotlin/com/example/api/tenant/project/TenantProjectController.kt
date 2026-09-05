// Generated code. Do not edit.
package com.example.api.tenant.project

import com.example.api.GeneratedResponseEntityEncoder
import com.example.api.GeneratedSecurityMiddleware
import com.example.api.GeneratedSecurityRequest
import com.example.api.IdObject
import com.example.api.NamedObject
import com.example.api.tenant.project.models.IdProject
import com.example.api.tenant.project.models.IdentifiedProject
import com.example.api.tenant.project.models.Project
import com.example.api.tenant.shared.TenantStatus
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
class TenantProjectController(
    private val service: TenantProjectService,
    private val security: GeneratedSecurityMiddleware,
) {
    private fun <T> badRequestOnParse(block: () -> T): T =
        try {
            block()
        } catch (exception: Exception) {
            throw ResponseStatusException(HttpStatus.BAD_REQUEST, exception.message, exception)
        }

    @PostMapping("/project", consumes = [MediaType.APPLICATION_JSON_VALUE], produces = [MediaType.APPLICATION_JSON_VALUE])
    suspend fun create(
        servletRequest: HttpServletRequest,
        @RequestHeader("X-Tenant-Id") tenantId: String,
        @RequestBody body: Project,
    ): ResponseEntity<IdProject> {

        val serviceRequest =
            TenantProjectCreateRequest(
                tenantId = tenantId,
                body = body,
            )
        val serviceResponse = service.create(serviceRequest)
        return GeneratedResponseEntityEncoder.json(serviceResponse, validStatusCodes = setOf(200, 201))
    }

    @PutMapping("/project/{project_id}", consumes = [MediaType.APPLICATION_JSON_VALUE], produces = [MediaType.APPLICATION_JSON_VALUE])
    suspend fun update(
        servletRequest: HttpServletRequest,
        @RequestHeader("X-Tenant-Id") tenantId: String,
        @PathVariable("project_id") projectId: String,
        @RequestBody body: Project,
    ): ResponseEntity<IdProject> {

        val serviceRequest =
            TenantProjectUpdateRequest(
                tenantId = tenantId,
                projectId = projectId,
                body = body,
            )
        val serviceResponse = service.update(serviceRequest)
        return GeneratedResponseEntityEncoder.json(serviceResponse, validStatusCodes = setOf(200))
    }

    @DeleteMapping("/project/{project_id}")
    suspend fun delete(
        servletRequest: HttpServletRequest,
        @RequestHeader("X-Tenant-Id") tenantId: String,
        @PathVariable("project_id") projectId: String,
    ): ResponseEntity<Unit> {

        val serviceRequest =
            TenantProjectDeleteRequest(
                tenantId = tenantId,
                projectId = projectId,
            )
        val serviceResponse = service.delete(serviceRequest)
        return GeneratedResponseEntityEncoder.empty(serviceResponse, validStatusCodes = setOf(200, 204, 205))
    }

    @GetMapping("/project", produces = [MediaType.APPLICATION_JSON_VALUE])
    suspend fun list(
        servletRequest: HttpServletRequest,
        @RequestHeader("X-Tenant-Id") tenantId: String,
        @RequestParam("status", required = false) status: List<String> = listOf("active"),
        @RequestParam("include_archived", required = false) includeArchived: Boolean = false,
    ): ResponseEntity<List<IdentifiedProject>> {

        val serviceRequest =
            TenantProjectListRequest(
                tenantId = tenantId,
                status = status.map { this.badRequestOnParse { TenantStatus.fromValue(it) } },
                includeArchived = includeArchived,
            )
        val serviceResponse = service.list(serviceRequest)
        return GeneratedResponseEntityEncoder.json(serviceResponse, validStatusCodes = setOf(200))
    }

    @GetMapping("/project/{project_id}", produces = [MediaType.APPLICATION_JSON_VALUE])
    suspend fun `get`(
        servletRequest: HttpServletRequest,
        @RequestHeader("X-Tenant-Id") tenantId: String,
        @PathVariable("project_id") projectId: String,
    ): ResponseEntity<IdentifiedProject> {

        val serviceRequest =
            TenantProjectGetRequest(
                tenantId = tenantId,
                projectId = projectId,
            )
        val serviceResponse = service.`get`(serviceRequest)
        return GeneratedResponseEntityEncoder.json(serviceResponse, validStatusCodes = setOf(200))
    }

    @PostMapping("/project/{project_id}/archive", produces = [MediaType.APPLICATION_JSON_VALUE])
    suspend fun archive(
        servletRequest: HttpServletRequest,
        @RequestHeader("X-Tenant-Id") tenantId: String,
        @PathVariable("project_id") projectId: String,
        @RequestParam("cascade", required = false) cascade: Boolean = false,
        @RequestHeader("Authorization") apiKey: String,
    ): ResponseEntity<IdObject> {
        val securityRequest = GeneratedSecurityRequest(servletRequest, "Tenant.Project.Archive")
        security.requireAuthorization(securityRequest)
        val serviceRequest =
            TenantProjectArchiveRequest(
                tenantId = tenantId,
                projectId = projectId,
                cascade = cascade,
                apiKey = apiKey,
            )
        val serviceResponse = service.archive(serviceRequest)
        return GeneratedResponseEntityEncoder.json(serviceResponse, validStatusCodes = setOf(200, 202))
    }
}
