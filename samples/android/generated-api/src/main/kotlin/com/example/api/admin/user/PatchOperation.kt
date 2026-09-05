// Generated code. Do not edit.
package com.example.api.admin.user

import com.example.api.ApiRequest
import com.example.api.ApiRequestConvertible
import com.example.api.ApiRequestPath
import com.example.api.PatchableValue
import com.example.api.admin.user.models.PatchedUser
import com.example.api.apiBodySerializer
import com.example.api.toApiPathSegment

object PatchOperation {
    data class Request(
        val userId: Long,
        val body: PatchedUser,
    ) : ApiRequestConvertible {
        override fun toApiRequest(): ApiRequest =
            ApiRequest(
                method = "PATCH",
                path = requestPath(),
                queryParameters = queryParameters(),
                headers = headers(),
                body = body,
                bodyType = apiBodySerializer<PatchedUser>(),
                contentType = "application/json",
                accept = "application/json",
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
