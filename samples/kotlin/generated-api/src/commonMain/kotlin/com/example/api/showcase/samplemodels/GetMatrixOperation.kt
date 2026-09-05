// Generated code. Do not edit.
package com.example.api.showcase.samplemodels

import com.example.api.ApiRequest
import com.example.api.ApiRequestConvertible
import com.example.api.ApiRequestPath
import com.example.api.showcase.samplemodels.models.SampleScore
import com.example.api.showcase.shared.SampleVisibility
import com.example.api.toApiFormValue
import com.example.api.toApiPathSegment
import com.example.api.toCookieHeader

object GetMatrixOperation {
    data class Request(
        val matrixId: String,
        val visible: Boolean = true,
        val visibility: SampleVisibility = SampleVisibility.fromValue("public"),
        val scores: List<SampleScore>? = listOf(SampleScore.fromValue(100)),
        val traceId: String? = null,
        val sampleSession: String? = null,
        val apiKey: String? = null,
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
                "/showcase/matrix/{matrix_id}"
                    .replace("{matrix_id}", matrixId.toApiPathSegment())
            return ApiRequestPath.Relative(path = path)
        }

        private fun queryParameters(): Map<String, String> {
            val values = mutableMapOf<String, String>()
            values["visible"] = visible.toApiFormValue()
            values["visibility"] = visibility.rawValue.toApiFormValue()
            scores?.takeIf { it.isNotEmpty() }?.let {
                values["scores"] = it.joinToString(",") { it.rawValue.toApiFormValue() }
            }
            return values
        }

        private fun headers(): Map<String, String> {
            val values = mutableMapOf<String, String>()
            traceId?.let { values["X-Trace-Id"] = it.toApiFormValue() }
            apiKey?.takeIf { it.isNotBlank() }?.let { values["Authorization"] = it.toApiFormValue() }
            val cookies = mutableMapOf<String, String>()
            sampleSession?.let { cookies["sample_session"] = it.toApiFormValue() }
            cookies.toCookieHeader()?.let { values["Cookie"] = it }
            return values
        }
    }
}
