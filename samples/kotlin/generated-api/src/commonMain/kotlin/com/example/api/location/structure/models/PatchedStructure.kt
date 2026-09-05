// Generated code. Do not edit.
package com.example.api.location.structure.models

import com.example.api.PatchableValue
import com.example.api.StructureType
import kotlinx.serialization.EncodeDefault
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.Serializable

// Generated code. Modify at your own risk.
@OptIn(ExperimentalSerializationApi::class)
@Serializable
data class PatchedStructure(
    @EncodeDefault(EncodeDefault.Mode.NEVER)
    var name: PatchableValue<String> = PatchableValue.Unmodified,
    @EncodeDefault(EncodeDefault.Mode.NEVER)
    var type: PatchableValue<StructureType> = PatchableValue.Unmodified,
) {
    fun resetPatchableFields() {
        name = PatchableValue.Unmodified
        type = PatchableValue.Unmodified
    }
    fun isUnmodified(): Boolean =
        name == PatchableValue.Unmodified &&
        type == PatchableValue.Unmodified
}
