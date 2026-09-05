// Generated code. Do not edit.
package com.example.api.showcase.transport.models

import com.example.api.Identifiable
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

// Generated code. Modify at your own risk.
@Serializable
data class UploadReceipt(
    @SerialName("upload_id")
    val uploadId: String,
    val bytes: Long,
    val state: UploadState = UploadState.Queued,
) {
    // Generated code. Modify at your own risk.
    @Serializable
    enum class UploadState(
        val rawValue: String,
    ) : Identifiable<String> {
        @SerialName("queued")
        Queued("queued"),

        @SerialName("stored")
        Stored("stored"),

        @SerialName("scanned")
        Scanned("scanned"),
        ;

        override val id: String
            get() = rawValue

        companion object {
            fun fromValue(value: String): UploadState =
                entries.firstOrNull { it.rawValue == value }
                    ?: throw IllegalArgumentException("Unknown UploadState value: $value")
        }
    }
}
