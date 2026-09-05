// Generated code. Do not edit.
package com.example.api.tenant.projecttask

import com.example.api.PatchableValue
import com.example.api.tenant.projecttask.models.PatchedTask

data class TenantProjectTaskPatchRequest(
    val tenantId: String,
    val projectId: String,
    val taskId: String,
    val body: PatchedTask,
)
