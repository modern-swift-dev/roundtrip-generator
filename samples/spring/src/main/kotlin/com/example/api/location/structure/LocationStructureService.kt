// Generated code. Do not edit.
package com.example.api.location.structure

import com.example.api.GeneratedResponse
import com.example.api.PagedResults
import com.example.api.StructureType
import com.example.api.location.structure.models.IdStructure
import com.example.api.location.structure.models.IdentifiedStructure
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean
import org.springframework.http.HttpStatus
import org.springframework.stereotype.Service
import org.springframework.web.server.ResponseStatusException

interface LocationStructureService {
    suspend fun create(request: LocationStructureCreateRequest): GeneratedResponse<IdStructure>

    suspend fun update(request: LocationStructureUpdateRequest): GeneratedResponse<IdStructure>

    suspend fun patch(request: LocationStructurePatchRequest): GeneratedResponse<IdStructure>

    suspend fun delete(request: LocationStructureDeleteRequest): GeneratedResponse<Unit>

    suspend fun list(request: LocationStructureListRequest): GeneratedResponse<PagedResults<IdentifiedStructure>>

    suspend fun `get`(request: LocationStructureGetRequest): GeneratedResponse<IdentifiedStructure>
}

@ConditionalOnMissingBean(LocationStructureService::class)
@Service
class NotImplementedLocationStructureService : LocationStructureService {
    override suspend fun create(request: LocationStructureCreateRequest): GeneratedResponse<IdStructure> =
        throw ResponseStatusException(HttpStatus.NOT_IMPLEMENTED)

    override suspend fun update(request: LocationStructureUpdateRequest): GeneratedResponse<IdStructure> =
        throw ResponseStatusException(HttpStatus.NOT_IMPLEMENTED)

    override suspend fun patch(request: LocationStructurePatchRequest): GeneratedResponse<IdStructure> =
        throw ResponseStatusException(HttpStatus.NOT_IMPLEMENTED)

    override suspend fun delete(request: LocationStructureDeleteRequest): GeneratedResponse<Unit> =
        throw ResponseStatusException(HttpStatus.NOT_IMPLEMENTED)

    override suspend fun list(request: LocationStructureListRequest): GeneratedResponse<PagedResults<IdentifiedStructure>> =
        throw ResponseStatusException(HttpStatus.NOT_IMPLEMENTED)

    override suspend fun `get`(request: LocationStructureGetRequest): GeneratedResponse<IdentifiedStructure> =
        throw ResponseStatusException(HttpStatus.NOT_IMPLEMENTED)
}
