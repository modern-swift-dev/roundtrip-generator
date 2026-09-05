// Generated code. Do not edit.
package com.example.api.admin.group.models

import com.example.api.Identifiable
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlin.time.Instant

// Generated code. Modify at your own risk.
@Serializable
data class IdentifiedGroup(
    override val id: Long,
    val name: String,
    @SerialName("creation_date")
    val creationDate: Instant,
    @SerialName("last_update_date")
    val lastUpdateDate: Instant,
) : Identifiable<Long>
