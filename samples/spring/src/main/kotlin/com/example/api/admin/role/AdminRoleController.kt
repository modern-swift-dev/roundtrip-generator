// Generated code. Do not edit.
package com.example.api.admin.role

import com.example.api.GeneratedResponseEntityEncoder
import com.example.api.GeneratedSecurityMiddleware
import com.example.api.GeneratedSecurityRequest
import com.example.api.PagedResults
import com.example.api.PatchableValue
import com.example.api.admin.role.models.IdRole
import com.example.api.admin.role.models.IdentifiedRole
import com.example.api.admin.role.models.PatchedRole
import com.example.api.admin.role.models.Role
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
class AdminRoleController(
    private val service: AdminRoleService,
    private val security: GeneratedSecurityMiddleware,
) {
    @PostMapping("/role", consumes = [MediaType.APPLICATION_JSON_VALUE], produces = [MediaType.APPLICATION_JSON_VALUE])
    suspend fun create(
        servletRequest: HttpServletRequest,
        @RequestBody body: Role,
    ): ResponseEntity<IdRole> {

        val serviceRequest =
            AdminRoleCreateRequest(
                body = body,
            )
        val serviceResponse = service.create(serviceRequest)
        return GeneratedResponseEntityEncoder.json(serviceResponse, validStatusCodes = setOf(200, 201))
    }

    @PutMapping("/role/{role_id}", consumes = [MediaType.APPLICATION_JSON_VALUE], produces = [MediaType.APPLICATION_JSON_VALUE])
    suspend fun update(
        servletRequest: HttpServletRequest,
        @PathVariable("role_id") roleId: Long,
        @RequestBody body: Role,
    ): ResponseEntity<IdRole> {

        val serviceRequest =
            AdminRoleUpdateRequest(
                roleId = roleId,
                body = body,
            )
        val serviceResponse = service.update(serviceRequest)
        return GeneratedResponseEntityEncoder.json(serviceResponse, validStatusCodes = setOf(200))
    }

    @PatchMapping("/role/{role_id}", consumes = [MediaType.APPLICATION_JSON_VALUE], produces = [MediaType.APPLICATION_JSON_VALUE])
    suspend fun patch(
        servletRequest: HttpServletRequest,
        @PathVariable("role_id") roleId: Long,
        @RequestBody body: PatchedRole,
    ): ResponseEntity<IdRole> {

        val serviceRequest =
            AdminRolePatchRequest(
                roleId = roleId,
                body = body,
            )
        val serviceResponse = service.patch(serviceRequest)
        return GeneratedResponseEntityEncoder.json(serviceResponse, validStatusCodes = setOf(200))
    }

    @DeleteMapping("/role/{role_id}")
    suspend fun delete(
        servletRequest: HttpServletRequest,
        @PathVariable("role_id") roleId: Long,
    ): ResponseEntity<Unit> {

        val serviceRequest =
            AdminRoleDeleteRequest(
                roleId = roleId,
            )
        val serviceResponse = service.delete(serviceRequest)
        return GeneratedResponseEntityEncoder.empty(serviceResponse, validStatusCodes = setOf(200, 204, 205))
    }

    @GetMapping("/role", produces = [MediaType.APPLICATION_JSON_VALUE])
    suspend fun list(
        servletRequest: HttpServletRequest,
        @RequestParam("text", required = false) text: String? = null,
    ): ResponseEntity<PagedResults<IdentifiedRole>> {

        val serviceRequest =
            AdminRoleListRequest(
                text = text,
            )
        val serviceResponse = service.list(serviceRequest)
        return GeneratedResponseEntityEncoder.json(serviceResponse, validStatusCodes = setOf(200))
    }

    @GetMapping("/role/{role_id}", produces = [MediaType.APPLICATION_JSON_VALUE])
    suspend fun `get`(
        servletRequest: HttpServletRequest,
        @PathVariable("role_id") roleId: Long,
    ): ResponseEntity<IdentifiedRole> {

        val serviceRequest =
            AdminRoleGetRequest(
                roleId = roleId,
            )
        val serviceResponse = service.`get`(serviceRequest)
        return GeneratedResponseEntityEncoder.json(serviceResponse, validStatusCodes = setOf(200))
    }
}
