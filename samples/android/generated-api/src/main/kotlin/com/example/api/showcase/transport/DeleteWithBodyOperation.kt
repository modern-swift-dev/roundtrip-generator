// Generated code. Do not edit.
package com.example.api.showcase.transport

import com.example.api.ApiRequest
import com.example.api.ApiRequestConvertible
import com.example.api.ApiRequestPath
import com.example.api.apiBodySerializer
import com.example.api.showcase.transport.models.DeleteReceiptRequest
import com.example.api.toApiFormValue

object DeleteWithBodyOperation {
    data class Request(
        val apiKey: String? = null,
        val body: DeleteReceiptRequest,
    ) : ApiRequestConvertible {
        override fun toApiRequest(): ApiRequest =
            ApiRequest(
                method = "DELETE",
                path = requestPath(),
                queryParameters = queryParameters(),
                headers = headers(),
                body = body,
                bodyType = apiBodySerializer<DeleteReceiptRequest>(),
                contentType = "application/json",
                accept = "application/json",
            )

        private fun requestPath(): ApiRequestPath = ApiRequestPath.Relative(path = "/showcase/uploads")

        private fun queryParameters(): Map<String, String> = emptyMap()

        private fun headers(): Map<String, String> {
            val values = mutableMapOf<String, String>()
            apiKey?.takeIf { it.isNotBlank() }?.let { values["Authorization"] = it.toApiFormValue() }
            return values
        }
    }
}
