// Generated code. Do not edit.
package com.example.api.tenant.projecttask

import com.example.api.ApiRequest
import com.example.api.ApiRequestConvertible
import com.example.api.ApiRequestPath
import com.example.api.apiBodySerializer
import com.example.api.tenant.projecttask.models.CompleteTaskRequest
import com.example.api.toApiFormValue
import com.example.api.toApiPathSegment

object CompleteOperation {
    data class Request(
        val tenantId: String,
        val projectId: String,
        val taskId: String,
        val notify: Boolean? = true,
        val apiKey: String? = null,
        val body: CompleteTaskRequest,
    ) : ApiRequestConvertible {
        override fun toApiRequest(): ApiRequest =
            ApiRequest(
                method = "PATCH",
                path = requestPath(),
                queryParameters = queryParameters(),
                headers = headers(),
                body = body,
                bodyType = apiBodySerializer<CompleteTaskRequest>(),
                contentType = "application/json",
                accept = "application/json",
            )

        private fun requestPath(): ApiRequestPath {
            val path =
                "/project/{project_id}/task/{task_id}/complete"
                    .replace("{project_id}", projectId.toApiPathSegment())
                    .replace("{task_id}", taskId.toApiPathSegment())
            return ApiRequestPath.Relative(path = path)
        }

        private fun queryParameters(): Map<String, String> {
            val values = mutableMapOf<String, String>()
            notify?.let { values["notify"] = it.toApiFormValue() }
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
