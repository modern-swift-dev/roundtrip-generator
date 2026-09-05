// Generated code. Do not edit.
package com.example.api.admin.group

import com.example.api.ApiRequest
import com.example.api.ApiRequestConvertible
import com.example.api.ApiRequestPath
import com.example.api.admin.group.models.Group
import io.ktor.util.reflect.typeInfo

object CreateOperation {
    data class Request(
        val body: Group,
    ) : ApiRequestConvertible {
        override fun toApiRequest(): ApiRequest =
            ApiRequest(
                method = "POST",
                path = requestPath(),
                queryParameters = queryParameters(),
                headers = headers(),
                body = body,
                bodyType = typeInfo<Group>(),
                contentType = "application/json",
                accept = "application/json",
            )

        private fun requestPath(): ApiRequestPath = ApiRequestPath.Relative(path = "/group")

        private fun queryParameters(): Map<String, String> = emptyMap()

        private fun headers(): Map<String, String> = emptyMap()
    }
}
