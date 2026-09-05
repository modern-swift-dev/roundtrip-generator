// Generated code. Do not edit.
package com.example.api.admin.role

import com.example.api.ApiRequest
import com.example.api.ApiRequestConvertible
import com.example.api.ApiRequestPath
import com.example.api.PatchableValue
import com.example.api.admin.role.models.PatchedRole
import com.example.api.toApiPathSegment
import io.ktor.util.reflect.typeInfo

object PatchOperation {
    data class Request(
        val roleId: Long,
        val body: PatchedRole,
    ) : ApiRequestConvertible {
        override fun toApiRequest(): ApiRequest =
            ApiRequest(
                method = "PATCH",
                path = requestPath(),
                queryParameters = queryParameters(),
                headers = headers(),
                body = body,
                bodyType = typeInfo<PatchedRole>(),
                contentType = "application/json",
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
