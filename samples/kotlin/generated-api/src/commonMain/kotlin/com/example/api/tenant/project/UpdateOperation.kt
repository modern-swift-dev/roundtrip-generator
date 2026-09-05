// Generated code. Do not edit.
package com.example.api.tenant.project

import com.example.api.ApiRequest
import com.example.api.ApiRequestConvertible
import com.example.api.ApiRequestPath
import com.example.api.NamedObject
import com.example.api.tenant.project.models.Project
import com.example.api.tenant.shared.TenantStatus
import com.example.api.toApiFormValue
import com.example.api.toApiPathSegment
import io.ktor.util.reflect.typeInfo

object UpdateOperation {
    data class Request(
        val tenantId: String,
        val projectId: String,
        val body: Project,
    ) : ApiRequestConvertible {
        override fun toApiRequest(): ApiRequest =
            ApiRequest(
                method = "PUT",
                path = requestPath(),
                queryParameters = queryParameters(),
                headers = headers(),
                body = body,
                bodyType = typeInfo<Project>(),
                contentType = "application/json",
                accept = "application/json",
            )

        private fun requestPath(): ApiRequestPath {
            val path =
                "/project/{project_id}"
                    .replace("{project_id}", projectId.toApiPathSegment())
            return ApiRequestPath.Relative(path = path)
        }

        private fun queryParameters(): Map<String, String> = emptyMap()

        private fun headers(): Map<String, String> {
            val values = mutableMapOf<String, String>()
            values["X-Tenant-Id"] = tenantId.toApiFormValue()
            return values
        }
    }
}
