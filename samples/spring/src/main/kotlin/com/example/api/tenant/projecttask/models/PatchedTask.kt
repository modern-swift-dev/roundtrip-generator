// Generated code. Do not edit.
package com.example.api.tenant.projecttask.models

import com.example.api.PatchableValue
import kotlinx.serialization.EncodeDefault
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlin.time.Instant

// Generated code. Modify at your own risk.
@OptIn(ExperimentalSerializationApi::class)
@Serializable
data class PatchedTask(
    @EncodeDefault(EncodeDefault.Mode.NEVER)
    var title: PatchableValue<String> = PatchableValue.Unmodified,
    @EncodeDefault(EncodeDefault.Mode.NEVER)
    var details: PatchableValue<String> = PatchableValue.Unmodified,
    @SerialName("due_at")
    @EncodeDefault(EncodeDefault.Mode.NEVER)
    var dueAt: PatchableValue<Instant> = PatchableValue.Unmodified,
    @EncodeDefault(EncodeDefault.Mode.NEVER)
    var done: PatchableValue<Boolean> = PatchableValue.Unmodified,
) {
    fun resetPatchableFields() {
        title = PatchableValue.Unmodified
        details = PatchableValue.Unmodified
        dueAt = PatchableValue.Unmodified
        done = PatchableValue.Unmodified
    }

    fun isUnmodified(): Boolean =
        title == PatchableValue.Unmodified &&
        details == PatchableValue.Unmodified &&
        dueAt == PatchableValue.Unmodified &&
        done == PatchableValue.Unmodified
}
