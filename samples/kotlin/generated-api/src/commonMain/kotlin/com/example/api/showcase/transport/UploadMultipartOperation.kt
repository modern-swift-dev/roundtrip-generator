// Generated code. Do not edit.
package com.example.api.showcase.transport

import com.example.api.ApiRequest
import com.example.api.ApiRequestConvertible
import com.example.api.ApiRequestPath
import com.example.api.MultipartBody
import com.example.api.toApiFormValue

object UploadMultipartOperation {
    data class Request(
        val compress: Boolean? = false,
        val apiKey: String? = null,
        val body: MultipartBody = MultipartBody(),
    ) : ApiRequestConvertible {
        fun withFile(part: MultipartBody.Part): Request =
            copy(body = body.copy(parts = body.parts + ("file" to part)))

        fun withMetadata(part: MultipartBody.Part): Request =
            copy(body = body.copy(parts = body.parts + ("metadata" to part)))

        override fun toApiRequest(): ApiRequest =
            ApiRequest(
                method = "POST",
                path = requestPath(),
                queryParameters = queryParameters(),
                headers = headers(),
                body = body,
                bodyType = null,
                contentType = null,
                accept = "application/json",
            )

        private fun requestPath(): ApiRequestPath = ApiRequestPath.Relative(path = "/showcase/uploads/multipart")

        private fun queryParameters(): Map<String, String> {
            val values = mutableMapOf<String, String>()
            compress?.let { values["compress"] = it.toApiFormValue() }
            return values
        }

        private fun headers(): Map<String, String> {
            val values = mutableMapOf<String, String>()
            apiKey?.takeIf { it.isNotBlank() }?.let { values["Authorization"] = it.toApiFormValue() }
            return values
        }
    }
}
