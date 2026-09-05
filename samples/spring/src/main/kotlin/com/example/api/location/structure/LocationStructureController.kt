// Generated code. Do not edit.
package com.example.api.location.structure

import com.example.api.GeneratedResponseEntityEncoder
import com.example.api.GeneratedSecurityMiddleware
import com.example.api.GeneratedSecurityRequest
import com.example.api.PagedResults
import com.example.api.PatchableValue
import com.example.api.StructureType
import com.example.api.location.structure.models.IdStructure
import com.example.api.location.structure.models.IdentifiedStructure
import com.example.api.location.structure.models.PatchedStructure
import com.example.api.location.structure.models.Structure
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
class LocationStructureController(
    private val service: LocationStructureService,
    private val security: GeneratedSecurityMiddleware,
) {
    private fun <T> badRequestOnParse(block: () -> T): T =
        try {
            block()
        } catch (exception: Exception) {
            throw ResponseStatusException(HttpStatus.BAD_REQUEST, exception.message, exception)
        }

    @PostMapping("/structure", consumes = [MediaType.APPLICATION_JSON_VALUE], produces = [MediaType.APPLICATION_JSON_VALUE])
    suspend fun create(
        servletRequest: HttpServletRequest,
        @RequestBody body: Structure,
    ): ResponseEntity<IdStructure> {

        val serviceRequest =
            LocationStructureCreateRequest(
                body = body,
            )
        val serviceResponse = service.create(serviceRequest)
        return GeneratedResponseEntityEncoder.json(serviceResponse, validStatusCodes = setOf(200, 201))
    }

    @PutMapping("/structure/{structure_id}", consumes = [MediaType.APPLICATION_JSON_VALUE], produces = [MediaType.APPLICATION_JSON_VALUE])
    suspend fun update(
        servletRequest: HttpServletRequest,
        @PathVariable("structure_id") structureId: Long,
        @RequestBody body: Structure,
    ): ResponseEntity<IdStructure> {

        val serviceRequest =
            LocationStructureUpdateRequest(
                structureId = structureId,
                body = body,
            )
        val serviceResponse = service.update(serviceRequest)
        return GeneratedResponseEntityEncoder.json(serviceResponse, validStatusCodes = setOf(200))
    }

    @PatchMapping("/structure/{structure_id}", consumes = [MediaType.APPLICATION_JSON_VALUE], produces = [MediaType.APPLICATION_JSON_VALUE])
    suspend fun patch(
        servletRequest: HttpServletRequest,
        @PathVariable("structure_id") structureId: Long,
        @RequestBody body: PatchedStructure,
    ): ResponseEntity<IdStructure> {

        val serviceRequest =
            LocationStructurePatchRequest(
                structureId = structureId,
                body = body,
            )
        val serviceResponse = service.patch(serviceRequest)
        return GeneratedResponseEntityEncoder.json(serviceResponse, validStatusCodes = setOf(200))
    }

    @DeleteMapping("/structure/{structure_id}")
    suspend fun delete(
        servletRequest: HttpServletRequest,
        @PathVariable("structure_id") structureId: Long,
    ): ResponseEntity<Unit> {

        val serviceRequest =
            LocationStructureDeleteRequest(
                structureId = structureId,
            )
        val serviceResponse = service.delete(serviceRequest)
        return GeneratedResponseEntityEncoder.empty(serviceResponse, validStatusCodes = setOf(200, 204, 205))
    }

    @GetMapping("/structure", produces = [MediaType.APPLICATION_JSON_VALUE])
    suspend fun list(
        servletRequest: HttpServletRequest,
        @RequestParam("text", required = false) text: String? = null,
        @RequestParam("type") type: List<String>,
    ): ResponseEntity<PagedResults<IdentifiedStructure>> {

        val serviceRequest =
            LocationStructureListRequest(
                text = text,
                type = type.map { this.badRequestOnParse { StructureType.fromValue(it) } },
            )
        val serviceResponse = service.list(serviceRequest)
        return GeneratedResponseEntityEncoder.json(serviceResponse, validStatusCodes = setOf(200))
    }

    @GetMapping("/structure/{structure_id}", produces = [MediaType.APPLICATION_JSON_VALUE])
    suspend fun `get`(
        servletRequest: HttpServletRequest,
        @PathVariable("structure_id") structureId: Long,
    ): ResponseEntity<IdentifiedStructure> {

        val serviceRequest =
            LocationStructureGetRequest(
                structureId = structureId,
            )
        val serviceResponse = service.`get`(serviceRequest)
        return GeneratedResponseEntityEncoder.json(serviceResponse, validStatusCodes = setOf(200))
    }
}
