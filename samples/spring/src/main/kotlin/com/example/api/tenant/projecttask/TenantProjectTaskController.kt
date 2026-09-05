// Generated code. Do not edit.
package com.example.api.tenant.projecttask

import com.example.api.GeneratedResponseEntityEncoder
import com.example.api.GeneratedSecurityMiddleware
import com.example.api.GeneratedSecurityRequest
import com.example.api.IdObject
import com.example.api.PagedResults
import com.example.api.PatchableValue
import com.example.api.tenant.projecttask.models.CompleteTaskRequest
import com.example.api.tenant.projecttask.models.IdTask
import com.example.api.tenant.projecttask.models.IdentifiedTask
import com.example.api.tenant.projecttask.models.PatchedTask
import com.example.api.tenant.projecttask.models.Task
import jakarta.servlet.http.HttpServletRequest
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
class TenantProjectTaskController(
    private val service: TenantProjectTaskService,
    private val security: GeneratedSecurityMiddleware,
) {
    @PostMapping("/project/{project_id}/task", consumes = [MediaType.APPLICATION_JSON_VALUE], produces = [MediaType.APPLICATION_JSON_VALUE])
    suspend fun create(
        servletRequest: HttpServletRequest,
        @RequestHeader("X-Tenant-Id") tenantId: String,
        @PathVariable("project_id") projectId: String,
        @RequestBody body: Task,
    ): ResponseEntity<IdTask> {

        val serviceRequest =
            TenantProjectTaskCreateRequest(
                tenantId = tenantId,
                projectId = projectId,
                body = body,
            )
        val serviceResponse = service.create(serviceRequest)
        return GeneratedResponseEntityEncoder.json(serviceResponse, validStatusCodes = setOf(200, 201))
    }

    @PatchMapping(
        "/project/{project_id}/task/{task_id}",
        consumes = [MediaType.APPLICATION_JSON_VALUE],
        produces = [MediaType.APPLICATION_JSON_VALUE],
    )
    suspend fun patch(
        servletRequest: HttpServletRequest,
        @RequestHeader("X-Tenant-Id") tenantId: String,
        @PathVariable("project_id") projectId: String,
        @PathVariable("task_id") taskId: String,
        @RequestBody body: PatchedTask,
    ): ResponseEntity<IdTask> {

        val serviceRequest =
            TenantProjectTaskPatchRequest(
                tenantId = tenantId,
                projectId = projectId,
                taskId = taskId,
                body = body,
            )
        val serviceResponse = service.patch(serviceRequest)
        return GeneratedResponseEntityEncoder.json(serviceResponse, validStatusCodes = setOf(200))
    }

    @GetMapping("/project/{project_id}/task", produces = [MediaType.APPLICATION_JSON_VALUE])
    suspend fun list(
        servletRequest: HttpServletRequest,
        @RequestHeader("X-Tenant-Id") tenantId: String,
        @PathVariable("project_id") projectId: String,
        @RequestParam("done", required = false) done: Boolean? = null,
    ): ResponseEntity<PagedResults<IdentifiedTask>> {

        val serviceRequest =
            TenantProjectTaskListRequest(
                tenantId = tenantId,
                projectId = projectId,
                done = done,
            )
        val serviceResponse = service.list(serviceRequest)
        return GeneratedResponseEntityEncoder.json(serviceResponse, validStatusCodes = setOf(200))
    }

    @GetMapping("/project/{project_id}/task/{task_id}", produces = [MediaType.APPLICATION_JSON_VALUE])
    suspend fun `get`(
        servletRequest: HttpServletRequest,
        @RequestHeader("X-Tenant-Id") tenantId: String,
        @PathVariable("project_id") projectId: String,
        @PathVariable("task_id") taskId: String,
    ): ResponseEntity<IdentifiedTask> {

        val serviceRequest =
            TenantProjectTaskGetRequest(
                tenantId = tenantId,
                projectId = projectId,
                taskId = taskId,
            )
        val serviceResponse = service.`get`(serviceRequest)
        return GeneratedResponseEntityEncoder.json(serviceResponse, validStatusCodes = setOf(200))
    }

    @PatchMapping(
        "/project/{project_id}/task/{task_id}/complete",
        consumes = [MediaType.APPLICATION_JSON_VALUE],
        produces = [MediaType.APPLICATION_JSON_VALUE],
    )
    suspend fun complete(
        servletRequest: HttpServletRequest,
        @RequestHeader("X-Tenant-Id") tenantId: String,
        @PathVariable("project_id") projectId: String,
        @PathVariable("task_id") taskId: String,
        @RequestParam("notify", required = false) notify: Boolean = true,
        @RequestHeader("Authorization", required = false) apiKey: String? = null,
        @RequestBody body: CompleteTaskRequest,
    ): ResponseEntity<IdObject> {
        val securityRequest = GeneratedSecurityRequest(servletRequest, "Tenant.ProjectTask.Complete")
        security.authorizeOptional(securityRequest)
        val serviceRequest =
            TenantProjectTaskCompleteRequest(
                tenantId = tenantId,
                projectId = projectId,
                taskId = taskId,
                notify = notify,
                apiKey = apiKey,
                body = body,
            )
        val serviceResponse = service.complete(serviceRequest)
        return GeneratedResponseEntityEncoder.json(serviceResponse, validStatusCodes = setOf(200))
    }
}
