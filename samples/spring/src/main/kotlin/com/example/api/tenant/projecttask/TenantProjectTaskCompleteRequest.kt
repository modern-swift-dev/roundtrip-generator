// Generated code. Do not edit.
package com.example.api.tenant.projecttask

import com.example.api.tenant.projecttask.models.CompleteTaskRequest

data class TenantProjectTaskCompleteRequest(
    val tenantId: String,
    val projectId: String,
    val taskId: String,
    val notify: Boolean = true,
    val apiKey: String?,
    val body: CompleteTaskRequest,
)
