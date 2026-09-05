// Generated code. Do not edit.
package com.example.api.tenant.project.models

import com.example.api.NamedObject
import com.example.api.PatchableValue
import com.example.api.tenant.shared.TenantStatus
import kotlinx.serialization.EncodeDefault
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.Serializable

// Generated code. Modify at your own risk.
@OptIn(ExperimentalSerializationApi::class)
@Serializable
data class PatchedProject(
    @EncodeDefault(EncodeDefault.Mode.NEVER)
    var name: PatchableValue<String> = PatchableValue.Unmodified,
    @EncodeDefault(EncodeDefault.Mode.NEVER)
    var status: PatchableValue<TenantStatus> = PatchableValue.Unmodified,
    @EncodeDefault(EncodeDefault.Mode.NEVER)
    var owners: PatchableValue<List<NamedObject>> = PatchableValue.Unmodified,
    @EncodeDefault(EncodeDefault.Mode.NEVER)
    var labels: PatchableValue<Map<String, String?>> = PatchableValue.Unmodified,
) {
    fun resetPatchableFields() {
        name = PatchableValue.Unmodified
        status = PatchableValue.Unmodified
        owners = PatchableValue.Unmodified
        labels = PatchableValue.Unmodified
    }

    fun isUnmodified(): Boolean =
        name == PatchableValue.Unmodified &&
        status == PatchableValue.Unmodified &&
        owners == PatchableValue.Unmodified &&
        labels == PatchableValue.Unmodified
}
