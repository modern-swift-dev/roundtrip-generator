// Generated code. Do not edit.
package com.example.api.tenant.projecttask

import com.example.api.ApiRequest
import com.example.api.ApiRequestConvertible
import com.example.api.ApiRequestPath
import com.example.api.PatchableValue
import com.example.api.apiBodySerializer
import com.example.api.tenant.projecttask.models.PatchedTask
import com.example.api.toApiFormValue
import com.example.api.toApiPathSegment

object PatchOperation {
    data class Request(
        val tenantId: String,
        val projectId: String,
        val taskId: String,
        val body: PatchedTask,
    ) : ApiRequestConvertible {
        override fun toApiRequest(): ApiRequest =
            ApiRequest(
                method = "PATCH",
                path = requestPath(),
                queryParameters = queryParameters(),
                headers = headers(),
                body = body,
                bodyType = apiBodySerializer<PatchedTask>(),
                contentType = "application/json",
                accept = "application/json",
            )

        private fun requestPath(): ApiRequestPath {
            val path =
                "/project/{project_id}/task/{task_id}"
                    .replace("{project_id}", projectId.toApiPathSegment())
                    .replace("{task_id}", taskId.toApiPathSegment())
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
