// Generated code. Do not edit.
package com.example.api.admin.user.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlin.time.Instant

// Generated code. Modify at your own risk.
@Serializable
data class User(
    @SerialName("first_name")
    val firstName: String,
    @SerialName("last_name")
    val lastName: String,
    val username: String,
    val email: String? = null,
    val phone: String? = null,
    @SerialName("hire_date")
    val hireDate: Instant? = null,
    @SerialName("birth_date")
    val birthDate: Instant? = null,
    val picture: String? = null,
)
