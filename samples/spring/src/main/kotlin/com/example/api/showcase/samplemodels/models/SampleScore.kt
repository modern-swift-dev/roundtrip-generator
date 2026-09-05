// Generated code. Do not edit.
package com.example.api.showcase.samplemodels.models

import com.example.api.Identifiable
import kotlinx.serialization.KSerializer
import kotlinx.serialization.Serializable
import kotlinx.serialization.descriptors.PrimitiveKind
import kotlinx.serialization.descriptors.PrimitiveSerialDescriptor
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder

// Generated code. Modify at your own risk.
@Serializable(with = SampleScore.Serializer::class)
enum class SampleScore(
    val rawValue: Int,
) : Identifiable<Int> {
    Low(10),

    Medium(50),

    High(100),
    ;

    override val id: Int
        get() = rawValue

    object Serializer : KSerializer<SampleScore> {
        override val descriptor: SerialDescriptor =
            PrimitiveSerialDescriptor("SampleScore", PrimitiveKind.INT)

        override fun deserialize(decoder: Decoder): SampleScore = SampleScore.fromValue(decoder.decodeInt())

        override fun serialize(
            encoder: Encoder,
            value: SampleScore,
        ) {
            encoder.encodeInt(value.rawValue)
        }
    }

    companion object {
        fun fromValue(value: Int): SampleScore =
            entries.firstOrNull { it.rawValue == value }
                ?: throw IllegalArgumentException("Unknown SampleScore value: $value")
    }
}
