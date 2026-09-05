// Generated code. Do not edit.
package com.example.api.showcase.samplemodels

import com.example.api.showcase.samplemodels.models.EmailNotification
import com.example.api.showcase.samplemodels.models.NotificationEnvelope
import com.example.api.showcase.samplemodels.models.PushNotification
import com.example.api.showcase.shared.SampleVisibility

data class ShowcaseSampleModelsCreateNotificationRequest(
    val idempotencyKey: String?,
    val apiKey: String,
    val body: NotificationEnvelope,
)
