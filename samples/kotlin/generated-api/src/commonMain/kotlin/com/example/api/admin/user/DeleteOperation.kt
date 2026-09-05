// Generated code. Do not edit.
package com.example.api.admin.user

import com.example.api.ApiRequest
import com.example.api.ApiRequestConvertible
import com.example.api.ApiRequestPath
import com.example.api.toApiPathSegment

object DeleteOperation {
    data class Request(
        val userId: Long,
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
                "/user/{user_id}"
                    .replace("{user_id}", userId.toApiPathSegment())
            return ApiRequestPath.Relative(path = path)
        }

        private fun queryParameters(): Map<String, String> = emptyMap()

        private fun headers(): Map<String, String> = emptyMap()
    }
}
