// Generated code. Do not edit.
package com.example.api.tenant.project

import com.example.api.ApiRequest
import com.example.api.ApiRequestConvertible
import com.example.api.ApiRequestPath
import com.example.api.toApiFormValue
import com.example.api.toApiPathSegment

object ArchiveOperation {
    data class Request(
        val tenantId: String,
        val projectId: String,
        val cascade: Boolean? = false,
        val apiKey: String? = null,
    ) : ApiRequestConvertible {
        override fun toApiRequest(): ApiRequest =
            ApiRequest(
                method = "POST",
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
                "/project/{project_id}/archive"
                    .replace("{project_id}", projectId.toApiPathSegment())
            return ApiRequestPath.Relative(path = path)
        }

        private fun queryParameters(): Map<String, String> {
            val values = mutableMapOf<String, String>()
            cascade?.let { values["cascade"] = it.toApiFormValue() }
            return values
        }

        private fun headers(): Map<String, String> {
            val values = mutableMapOf<String, String>()
            values["X-Tenant-Id"] = tenantId.toApiFormValue()
            apiKey?.takeIf { it.isNotBlank() }?.let { values["Authorization"] = it.toApiFormValue() }
            return values
        }
    }
}
