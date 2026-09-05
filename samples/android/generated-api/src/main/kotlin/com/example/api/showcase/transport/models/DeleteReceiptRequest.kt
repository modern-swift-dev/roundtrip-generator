// Generated code. Do not edit.
package com.example.api.showcase.transport.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

// Generated code. Modify at your own risk.
@Serializable
data class DeleteReceiptRequest(
    @SerialName("upload_ids")
    val uploadIds: List<String>,
    val reason: String? = null,
)
