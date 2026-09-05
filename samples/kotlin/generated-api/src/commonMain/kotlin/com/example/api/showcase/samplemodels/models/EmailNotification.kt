// Generated code. Do not edit.
package com.example.api.showcase.samplemodels.models

import com.example.api.Identifiable
import kotlinx.serialization.Serializable

// Generated code. Modify at your own risk.
@Serializable
data class EmailNotification(
    override val id: String,
    val subject: String,
    val body: String,
    val recipients: List<String>,
) : Identifiable<String>
