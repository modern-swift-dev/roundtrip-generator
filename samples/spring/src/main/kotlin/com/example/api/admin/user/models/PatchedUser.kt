// Generated code. Do not edit.
package com.example.api.admin.user.models

import com.example.api.PatchableValue
import kotlinx.serialization.EncodeDefault
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlin.time.Instant

// Generated code. Modify at your own risk.
@OptIn(ExperimentalSerializationApi::class)
@Serializable
data class PatchedUser(
    @SerialName("first_name")
    @EncodeDefault(EncodeDefault.Mode.NEVER)
    var firstName: PatchableValue<String> = PatchableValue.Unmodified,
    @SerialName("last_name")
    @EncodeDefault(EncodeDefault.Mode.NEVER)
    var lastName: PatchableValue<String> = PatchableValue.Unmodified,
    @EncodeDefault(EncodeDefault.Mode.NEVER)
    var username: PatchableValue<String> = PatchableValue.Unmodified,
    @EncodeDefault(EncodeDefault.Mode.NEVER)
    var email: PatchableValue<String> = PatchableValue.Unmodified,
    @EncodeDefault(EncodeDefault.Mode.NEVER)
    var phone: PatchableValue<String> = PatchableValue.Unmodified,
    @SerialName("hire_date")
    @EncodeDefault(EncodeDefault.Mode.NEVER)
    var hireDate: PatchableValue<Instant> = PatchableValue.Unmodified,
    @SerialName("birth_date")
    @EncodeDefault(EncodeDefault.Mode.NEVER)
    var birthDate: PatchableValue<Instant> = PatchableValue.Unmodified,
    @EncodeDefault(EncodeDefault.Mode.NEVER)
    var picture: PatchableValue<String> = PatchableValue.Unmodified,
) {
    fun resetPatchableFields() {
        firstName = PatchableValue.Unmodified
        lastName = PatchableValue.Unmodified
        username = PatchableValue.Unmodified
        email = PatchableValue.Unmodified
        phone = PatchableValue.Unmodified
        hireDate = PatchableValue.Unmodified
        birthDate = PatchableValue.Unmodified
        picture = PatchableValue.Unmodified
    }

    fun isUnmodified(): Boolean =
        firstName == PatchableValue.Unmodified &&
        lastName == PatchableValue.Unmodified &&
        username == PatchableValue.Unmodified &&
        email == PatchableValue.Unmodified &&
        phone == PatchableValue.Unmodified &&
        hireDate == PatchableValue.Unmodified &&
        birthDate == PatchableValue.Unmodified &&
        picture == PatchableValue.Unmodified
}
