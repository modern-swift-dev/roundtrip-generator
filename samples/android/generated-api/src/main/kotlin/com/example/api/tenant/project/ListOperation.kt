// Generated code. Do not edit.
package com.example.api.tenant.project

import com.example.api.ApiRequest
import com.example.api.ApiRequestConvertible
import com.example.api.ApiRequestPath
import com.example.api.tenant.shared.TenantStatus
import com.example.api.toApiFormValue

object ListOperation {
    data class Request(
        val tenantId: String,
        val status: List<TenantStatus>? = listOf(TenantStatus.fromValue("active")),
        val includeArchived: Boolean? = false,
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

        private fun requestPath(): ApiRequestPath = ApiRequestPath.Relative(path = "/project")

        private fun queryParameters(): Map<String, String> {
            val values = mutableMapOf<String, String>()
            status?.takeIf { it.isNotEmpty() }?.let {
                values["status"] = it.joinToString(",") { it.rawValue.toApiFormValue() }
            }
            includeArchived?.let { values["include_archived"] = it.toApiFormValue() }
            return values
        }

        private fun headers(): Map<String, String> {
            val values = mutableMapOf<String, String>()
            values["X-Tenant-Id"] = tenantId.toApiFormValue()
            return values
        }
    }
}
