// Generated code. Do not edit.
package com.example.api.showcase.transport

import com.example.api.ApiRequest
import com.example.api.ApiRequestConvertible
import com.example.api.ApiRequestPath
import com.example.api.toApiFormValue

object UploadBinaryOperation {
    data class Request(
        val contentMd5: String? = null,
        val apiKey: String? = null,
        val body: ByteArray,
    ) : ApiRequestConvertible {
        override fun equals(other: Any?): Boolean {
            if (this === other) return true
            if (other !is Request) return false
            if (contentMd5 != other.contentMd5) return false
            if (apiKey != other.apiKey) return false
            if (!body.contentEquals(other.body)) return false
            return true
        }

        override fun hashCode(): Int {
            var result = (contentMd5?.hashCode() ?: 0)
            result = 31 * result + (apiKey?.hashCode() ?: 0)
            result = 31 * result + body.contentHashCode()
            return result
        }

        override fun toApiRequest(): ApiRequest =
            ApiRequest(
                method = "POST",
                path = requestPath(),
                queryParameters = queryParameters(),
                headers = headers(),
                body = body,
                bodyType = null,
                contentType = "application/octet-stream",
                accept = "application/zip",
            )

        private fun requestPath(): ApiRequestPath = ApiRequestPath.Relative(path = "/showcase/uploads/binary")

        private fun queryParameters(): Map<String, String> = emptyMap()

        private fun headers(): Map<String, String> {
            val values = mutableMapOf<String, String>()
            contentMd5?.let { values["Content-MD5"] = it.toApiFormValue() }
            apiKey?.takeIf { it.isNotBlank() }?.let { values["Authorization"] = it.toApiFormValue() }
            return values
        }
    }
}
