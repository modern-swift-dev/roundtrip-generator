// Generated code. Do not edit.
package com.example.api.showcase.samplemodels

import com.example.api.ApiRequest
import com.example.api.ApiRequestConvertible
import com.example.api.ApiRequestPath
import com.example.api.apiBodySerializer
import com.example.api.showcase.samplemodels.models.EmailNotification
import com.example.api.showcase.samplemodels.models.NotificationEnvelope
import com.example.api.showcase.samplemodels.models.PushNotification
import com.example.api.showcase.shared.SampleVisibility
import com.example.api.toApiFormValue

object CreateNotificationOperation {
    data class Request(
        val idempotencyKey: String? = null,
        val apiKey: String? = null,
        val body: NotificationEnvelope,
    ) : ApiRequestConvertible {
        override fun toApiRequest(): ApiRequest =
            ApiRequest(
                method = "POST",
                path = requestPath(),
                queryParameters = queryParameters(),
                headers = headers(),
                body = body,
                bodyType = apiBodySerializer<NotificationEnvelope>(),
                contentType = "application/json",
                accept = "application/json",
            )

        private fun requestPath(): ApiRequestPath = ApiRequestPath.Relative(path = "/showcase/notifications")

        private fun queryParameters(): Map<String, String> = emptyMap()

        private fun headers(): Map<String, String> {
            val values = mutableMapOf<String, String>()
            idempotencyKey?.let { values["Idempotency-Key"] = it.toApiFormValue() }
            apiKey?.takeIf { it.isNotBlank() }?.let { values["Authorization"] = it.toApiFormValue() }
            return values
        }
    }
}
