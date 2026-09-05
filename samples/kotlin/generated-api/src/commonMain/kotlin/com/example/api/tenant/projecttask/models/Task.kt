// Generated code. Do not edit.
package com.example.api.tenant.projecttask.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlin.time.Instant

// Generated code. Modify at your own risk.
@Serializable
data class Task(
    val title: String,
    val details: String? = null,
    @SerialName("due_at")
    val dueAt: Instant? = null,
    val done: Boolean = false,
)
