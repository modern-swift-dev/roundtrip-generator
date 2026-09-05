// Generated code. Do not edit.
package com.example.api.tenant.project.models

import com.example.api.NamedObject
import com.example.api.tenant.shared.TenantStatus
import kotlinx.serialization.Serializable

// Generated code. Modify at your own risk.
@Serializable
data class Project(
    val name: String,
    val status: TenantStatus,
    val owners: List<NamedObject>,
    val labels: Map<String, String?>,
)
