// Generated code. Do not edit.
package com.example.api.tenant.project.models

import com.example.api.Identifiable
import com.example.api.NamedObject
import com.example.api.tenant.shared.TenantStatus
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlin.time.Instant

// Generated code. Modify at your own risk.
@Serializable
data class IdentifiedProject(
    override val id: String,
    val name: String,
    val status: TenantStatus,
    val owners: List<NamedObject>,
    val labels: Map<String, String?>,
    @SerialName("creation_date")
    val creationDate: Instant,
    @SerialName("last_update_date")
    val lastUpdateDate: Instant,
) : Identifiable<String>
