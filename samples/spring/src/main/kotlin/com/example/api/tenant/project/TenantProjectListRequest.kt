// Generated code. Do not edit.
package com.example.api.tenant.project

import com.example.api.tenant.shared.TenantStatus

data class TenantProjectListRequest(
    val tenantId: String,
    val status: List<TenantStatus> = listOf(TenantStatus.fromValue("active")),
    val includeArchived: Boolean = false,
)
