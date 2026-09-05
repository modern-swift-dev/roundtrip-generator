// Generated code. Do not edit.
package com.example.api.location.structure.models

import com.example.api.Identifiable
import com.example.api.StructureType
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlin.time.Instant

// Generated code. Modify at your own risk.
@Serializable
data class IdentifiedStructure(
    override val id: Long,
    val name: String,
    val type: StructureType,
    @SerialName("creation_date")
    val creationDate: Instant,
    @SerialName("last_update_date")
    val lastUpdateDate: Instant,
) : Identifiable<Long>
