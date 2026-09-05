// Generated code. Do not edit.
package com.example.api.showcase.samplemodels.models

import com.example.api.Identifiable
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

// Generated code. Modify at your own risk.
@Serializable
data class PushNotification(
    override val id: String,
    val title: String,
    val body: String,
    @SerialName("custom_data")
    val customData: Map<String, String?>,
) : Identifiable<String>
