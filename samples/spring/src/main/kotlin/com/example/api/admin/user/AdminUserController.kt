// Generated code. Do not edit.
package com.example.api.admin.user

import com.example.api.GeneratedResponseEntityEncoder
import com.example.api.GeneratedSecurityMiddleware
import com.example.api.GeneratedSecurityRequest
import com.example.api.PagedResults
import com.example.api.PatchableValue
import com.example.api.admin.user.models.IdUser
import com.example.api.admin.user.models.IdentifiedUser
import com.example.api.admin.user.models.PatchedUser
import com.example.api.admin.user.models.User
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
class AdminUserController(
    private val service: AdminUserService,
    private val security: GeneratedSecurityMiddleware,
) {
    @PostMapping("/user", consumes = [MediaType.APPLICATION_JSON_VALUE], produces = [MediaType.APPLICATION_JSON_VALUE])
    suspend fun create(
        servletRequest: HttpServletRequest,
        @RequestBody body: User,
    ): ResponseEntity<IdUser> {

        val serviceRequest =
            AdminUserCreateRequest(
                body = body,
            )
        val serviceResponse = service.create(serviceRequest)
        return GeneratedResponseEntityEncoder.json(serviceResponse, validStatusCodes = setOf(200, 201))
    }

    @PutMapping("/user/{user_id}", consumes = [MediaType.APPLICATION_JSON_VALUE], produces = [MediaType.APPLICATION_JSON_VALUE])
    suspend fun update(
        servletRequest: HttpServletRequest,
        @PathVariable("user_id") userId: Long,
        @RequestBody body: User,
    ): ResponseEntity<IdUser> {

        val serviceRequest =
            AdminUserUpdateRequest(
                userId = userId,
                body = body,
            )
        val serviceResponse = service.update(serviceRequest)
        return GeneratedResponseEntityEncoder.json(serviceResponse, validStatusCodes = setOf(200))
    }

    @PatchMapping("/user/{user_id}", consumes = [MediaType.APPLICATION_JSON_VALUE], produces = [MediaType.APPLICATION_JSON_VALUE])
    suspend fun patch(
        servletRequest: HttpServletRequest,
        @PathVariable("user_id") userId: Long,
        @RequestBody body: PatchedUser,
    ): ResponseEntity<IdUser> {

        val serviceRequest =
            AdminUserPatchRequest(
                userId = userId,
                body = body,
            )
        val serviceResponse = service.patch(serviceRequest)
        return GeneratedResponseEntityEncoder.json(serviceResponse, validStatusCodes = setOf(200))
    }

    @DeleteMapping("/user/{user_id}")
    suspend fun delete(
        servletRequest: HttpServletRequest,
        @PathVariable("user_id") userId: Long,
    ): ResponseEntity<Unit> {

        val serviceRequest =
            AdminUserDeleteRequest(
                userId = userId,
            )
        val serviceResponse = service.delete(serviceRequest)
        return GeneratedResponseEntityEncoder.empty(serviceResponse, validStatusCodes = setOf(200, 204, 205))
    }

    @GetMapping("/user", produces = [MediaType.APPLICATION_JSON_VALUE])
    suspend fun list(
        servletRequest: HttpServletRequest,
        @RequestParam("text", required = false) text: String? = null,
    ): ResponseEntity<PagedResults<IdentifiedUser>> {

        val serviceRequest =
            AdminUserListRequest(
                text = text,
            )
        val serviceResponse = service.list(serviceRequest)
        return GeneratedResponseEntityEncoder.json(serviceResponse, validStatusCodes = setOf(200))
    }

    @GetMapping("/user/{user_id}", produces = [MediaType.APPLICATION_JSON_VALUE])
    suspend fun `get`(
        servletRequest: HttpServletRequest,
        @PathVariable("user_id") userId: Long,
    ): ResponseEntity<IdentifiedUser> {

        val serviceRequest =
            AdminUserGetRequest(
                userId = userId,
            )
        val serviceResponse = service.`get`(serviceRequest)
        return GeneratedResponseEntityEncoder.json(serviceResponse, validStatusCodes = setOf(200))
    }
}
