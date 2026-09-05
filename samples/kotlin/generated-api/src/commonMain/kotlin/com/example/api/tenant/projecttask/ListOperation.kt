// Generated code. Do not edit.
package com.example.api.tenant.projecttask

import com.example.api.ApiRequest
import com.example.api.ApiRequestConvertible
import com.example.api.ApiRequestPath
import com.example.api.toApiFormValue
import com.example.api.toApiPathSegment

object ListOperation {
    data class Request(
        val tenantId: String,
        val projectId: String,
        val done: Boolean? = null,
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
                "/project/{project_id}/task"
                    .replace("{project_id}", projectId.toApiPathSegment())
            return ApiRequestPath.Relative(path = path)
        }

        private fun queryParameters(): Map<String, String> {
            val values = mutableMapOf<String, String>()
            done?.let { values["done"] = it.toApiFormValue() }
            return values
        }

        private fun headers(): Map<String, String> {
            val values = mutableMapOf<String, String>()
            values["X-Tenant-Id"] = tenantId.toApiFormValue()
            return values
        }
    }
}
