// Generated code. Do not edit.
package com.example.api.admin.role

import com.example.api.ApiRequest
import com.example.api.ApiRequestConvertible
import com.example.api.ApiRequestPath
import com.example.api.toApiPathSegment

object GetOperation {
    data class Request(
        val roleId: Long,
    ) : ApiRequestConvertible {
        override fun toApiRequest(): ApiRequest =
            ApiRequest(
                method = "GET",
                path = requestPath(),
                queryParameters = queryParameters(),
                headers = headers(),
                body = null,
                bodyType = null,
                contentType = null,
                accept = "application/json",
            )

        private fun requestPath(): ApiRequestPath {
            val path =
                "/role/{role_id}"
                    .replace("{role_id}", roleId.toApiPathSegment())
            return ApiRequestPath.Relative(path = path)
        }

        private fun queryParameters(): Map<String, String> = emptyMap()

        private fun headers(): Map<String, String> = emptyMap()
    }
}
