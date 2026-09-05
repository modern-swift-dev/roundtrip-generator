// Generated code. Do not edit.
package com.example.api.admin.group

import com.example.api.GeneratedResponseEntityEncoder
import com.example.api.GeneratedSecurityMiddleware
import com.example.api.GeneratedSecurityRequest
import com.example.api.PagedResults
import com.example.api.PatchableValue
import com.example.api.admin.group.models.Group
import com.example.api.admin.group.models.IdGroup
import com.example.api.admin.group.models.IdentifiedGroup
import com.example.api.admin.group.models.PatchedGroup
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
class AdminGroupController(
    private val service: AdminGroupService,
    private val security: GeneratedSecurityMiddleware,
) {
    @PostMapping("/group", consumes = [MediaType.APPLICATION_JSON_VALUE], produces = [MediaType.APPLICATION_JSON_VALUE])
    suspend fun create(
        servletRequest: HttpServletRequest,
        @RequestBody body: Group,
    ): ResponseEntity<IdGroup> {

        val serviceRequest =
            AdminGroupCreateRequest(
                body = body,
            )
        val serviceResponse = service.create(serviceRequest)
        return GeneratedResponseEntityEncoder.json(serviceResponse, validStatusCodes = setOf(200, 201))
    }

    @PutMapping("/group/{group_id}", consumes = [MediaType.APPLICATION_JSON_VALUE], produces = [MediaType.APPLICATION_JSON_VALUE])
    suspend fun update(
        servletRequest: HttpServletRequest,
        @PathVariable("group_id") groupId: Long,
        @RequestBody body: Group,
    ): ResponseEntity<IdGroup> {

        val serviceRequest =
            AdminGroupUpdateRequest(
                groupId = groupId,
                body = body,
            )
        val serviceResponse = service.update(serviceRequest)
        return GeneratedResponseEntityEncoder.json(serviceResponse, validStatusCodes = setOf(200))
    }

    @PatchMapping("/group/{group_id}", consumes = [MediaType.APPLICATION_JSON_VALUE], produces = [MediaType.APPLICATION_JSON_VALUE])
    suspend fun patch(
        servletRequest: HttpServletRequest,
        @PathVariable("group_id") groupId: Long,
        @RequestBody body: PatchedGroup,
    ): ResponseEntity<IdGroup> {

        val serviceRequest =
            AdminGroupPatchRequest(
                groupId = groupId,
                body = body,
            )
        val serviceResponse = service.patch(serviceRequest)
        return GeneratedResponseEntityEncoder.json(serviceResponse, validStatusCodes = setOf(200))
    }

    @DeleteMapping("/group/{group_id}")
    suspend fun delete(
        servletRequest: HttpServletRequest,
        @PathVariable("group_id") groupId: Long,
    ): ResponseEntity<Unit> {

        val serviceRequest =
            AdminGroupDeleteRequest(
                groupId = groupId,
            )
        val serviceResponse = service.delete(serviceRequest)
        return GeneratedResponseEntityEncoder.empty(serviceResponse, validStatusCodes = setOf(200, 204, 205))
    }

    @GetMapping("/group", produces = [MediaType.APPLICATION_JSON_VALUE])
    suspend fun list(
        servletRequest: HttpServletRequest,
        @RequestParam("text", required = false) text: String? = null,
    ): ResponseEntity<PagedResults<IdentifiedGroup>> {

        val serviceRequest =
            AdminGroupListRequest(
                text = text,
            )
        val serviceResponse = service.list(serviceRequest)
        return GeneratedResponseEntityEncoder.json(serviceResponse, validStatusCodes = setOf(200))
    }

    @GetMapping("/group/{group_id}", produces = [MediaType.APPLICATION_JSON_VALUE])
    suspend fun `get`(
        servletRequest: HttpServletRequest,
        @PathVariable("group_id") groupId: Long,
    ): ResponseEntity<IdentifiedGroup> {

        val serviceRequest =
            AdminGroupGetRequest(
                groupId = groupId,
            )
        val serviceResponse = service.`get`(serviceRequest)
        return GeneratedResponseEntityEncoder.json(serviceResponse, validStatusCodes = setOf(200))
    }
}
