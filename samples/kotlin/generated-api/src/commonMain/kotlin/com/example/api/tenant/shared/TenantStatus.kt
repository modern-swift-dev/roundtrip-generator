// Generated code. Do not edit.
package com.example.api.tenant.shared

import com.example.api.Identifiable
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

// Generated code. Modify at your own risk.
@Serializable
enum class TenantStatus(
    val rawValue: String,
) : Identifiable<String> {
    @SerialName("trial")
    Trial("trial"),

    @SerialName("active")
    Active("active"),

    @SerialName("suspended")
    Suspended("suspended"),
    ;

    override val id: String
        get() = rawValue
    companion object {
        fun fromValue(value: String): TenantStatus =
            entries.firstOrNull { it.rawValue == value }
                ?: throw IllegalArgumentException("Unknown TenantStatus value: $value")
    }
}
