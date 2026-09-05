// Generated code. Do not edit.
package com.example.api.admin.group.models

import com.example.api.PatchableValue
import kotlinx.serialization.EncodeDefault
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.Serializable

// Generated code. Modify at your own risk.
@OptIn(ExperimentalSerializationApi::class)
@Serializable
data class PatchedGroup(
    @EncodeDefault(EncodeDefault.Mode.NEVER)
    var name: PatchableValue<String> = PatchableValue.Unmodified,
) {
    fun resetPatchableFields() {
        name = PatchableValue.Unmodified
    }
    fun isUnmodified(): Boolean =
        name == PatchableValue.Unmodified
}
