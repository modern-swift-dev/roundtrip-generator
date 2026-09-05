// Generated code. Do not edit.
package com.example.api.location.structure

import com.example.api.ApiRequest
import com.example.api.ApiRequestConvertible
import com.example.api.ApiRequestPath
import com.example.api.PatchableValue
import com.example.api.StructureType
import com.example.api.apiBodySerializer
import com.example.api.location.structure.models.PatchedStructure
import com.example.api.toApiPathSegment

object PatchOperation {
    data class Request(
        val structureId: Long,
        val body: PatchedStructure,
    ) : ApiRequestConvertible {
        override fun toApiRequest(): ApiRequest =
            ApiRequest(
                method = "PATCH",
                path = requestPath(),
                queryParameters = queryParameters(),
                headers = headers(),
                body = body,
                bodyType = apiBodySerializer<PatchedStructure>(),
                contentType = "application/json",
                accept = "application/json",
            )

        private fun requestPath(): ApiRequestPath {
            val path =
                "/structure/{structure_id}"
                    .replace("{structure_id}", structureId.toApiPathSegment())
            return ApiRequestPath.Relative(path = path)
        }

        private fun queryParameters(): Map<String, String> = emptyMap()

        private fun headers(): Map<String, String> = emptyMap()
    }
}
