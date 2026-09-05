// Generated code. Do not edit.
package com.example.api.tenant.project

import com.example.api.ApiRequest
import com.example.api.ApiRequestConvertible
import com.example.api.ApiRequestPath
import com.example.api.NamedObject
import com.example.api.apiBodySerializer
import com.example.api.tenant.project.models.Project
import com.example.api.tenant.shared.TenantStatus
import com.example.api.toApiFormValue

object CreateOperation {
    data class Request(
        val tenantId: String,
        val body: Project,
    ) : ApiRequestConvertible {
        override fun toApiRequest(): ApiRequest =
            ApiRequest(
                method = "POST",
                path = requestPath(),
                queryParameters = queryParameters(),
                headers = headers(),
                body = body,
                bodyType = apiBodySerializer<Project>(),
                contentType = "application/json",
                accept = "application/json",
            )

        private fun requestPath(): ApiRequestPath = ApiRequestPath.Relative(path = "/project")

        private fun queryParameters(): Map<String, String> = emptyMap()

        private fun headers(): Map<String, String> {
            val values = mutableMapOf<String, String>()
            values["X-Tenant-Id"] = tenantId.toApiFormValue()
            return values
        }
    }
}
