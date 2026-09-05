// Generated code. Do not edit.
package com.example.api.tenant.project

import com.example.api.NamedObject
import com.example.api.tenant.project.models.Project
import com.example.api.tenant.shared.TenantStatus

data class TenantProjectUpdateRequest(
    val tenantId: String,
    val projectId: String,
    val body: Project,
)
