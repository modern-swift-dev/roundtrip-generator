// Generated code. Do not edit.
package com.example.api.admin.role

import com.example.api.ApiRequest
import com.example.api.ApiRequestConvertible
import com.example.api.ApiRequestPath
import com.example.api.admin.role.models.Role
import com.example.api.apiBodySerializer

object CreateOperation {
    data class Request(
        val body: Role,
    ) : ApiRequestConvertible {
        override fun toApiRequest(): ApiRequest =
            ApiRequest(
                method = "POST",
                path = requestPath(),
                queryParameters = queryParameters(),
                headers = headers(),
                body = body,
                bodyType = apiBodySerializer<Role>(),
                contentType = "application/json",
                accept = "application/json",
            )

        private fun requestPath(): ApiRequestPath = ApiRequestPath.Relative(path = "/role")

        private fun queryParameters(): Map<String, String> = emptyMap()

        private fun headers(): Map<String, String> = emptyMap()
    }
}
