// Generated code. Do not edit.
package com.example.api.showcase.shared

import com.example.api.Identifiable
import kotlinx.serialization.KSerializer
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.descriptors.PrimitiveKind
import kotlinx.serialization.descriptors.PrimitiveSerialDescriptor
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder

// Generated code. Modify at your own risk.
@Serializable(with = SampleVisibility.Serializer::class)
enum class SampleVisibility(
    val rawValue: String,
) : Identifiable<String> {
    @SerialName("__garbage__")
    Garbage("__garbage__"),

    @SerialName("public")
    Public("public"),

    @SerialName("internal")
    Internal("internal"),

    @SerialName("private")
    Private("private"),
    ;

    object Serializer : KSerializer<SampleVisibility> {
        override val descriptor: SerialDescriptor =
            PrimitiveSerialDescriptor("SampleVisibility", PrimitiveKind.STRING)

        override fun deserialize(decoder: Decoder): SampleVisibility =
            runCatching {
                SampleVisibility.fromValue(decoder.decodeString())
            }.getOrElse { Garbage }

        override fun serialize(
            encoder: Encoder,
            value: SampleVisibility,
        ) {
            encoder.encodeString(value.rawValue)
        }
    }

    override val id: String
        get() = rawValue

    companion object {
        fun fromValue(value: String): SampleVisibility =
            entries.firstOrNull { it.rawValue == value }
                ?: Garbage
    }
}
