// Generated code. Do not edit.
package com.example.api.location.structure

import com.example.api.ApiRequest
import com.example.api.ApiRequestConvertible
import com.example.api.ApiRequestPath
import com.example.api.toApiPathSegment

object DeleteOperation {
    data class Request(
        val structureId: Long,
    ) : ApiRequestConvertible {
        override fun toApiRequest(): ApiRequest =
            ApiRequest(
                method = "DELETE",
                path = requestPath(),
                queryParameters = queryParameters(),
                headers = headers(),
                body = null,
                bodyType = null,
                contentType = null,
                accept = "*/*",
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
