// Generated code. Do not edit.
package com.example.api.admin.user

import com.example.api.ApiRequest
import com.example.api.ApiRequestConvertible
import com.example.api.ApiRequestPath
import com.example.api.toApiFormValue

object ListOperation {
    data class Request(
        val text: String? = null,
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

        private fun requestPath(): ApiRequestPath = ApiRequestPath.Relative(path = "/user")

        private fun queryParameters(): Map<String, String> {
            val values = mutableMapOf<String, String>()
            text?.let { values["text"] = it.toApiFormValue() }
            return values
        }

        private fun headers(): Map<String, String> = emptyMap()
    }
}
