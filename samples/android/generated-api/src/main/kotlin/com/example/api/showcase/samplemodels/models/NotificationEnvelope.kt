// Generated code. Do not edit.
package com.example.api.showcase.samplemodels.models

import com.example.api.Identifiable
import com.example.api.showcase.shared.SampleVisibility
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.KSerializer
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.SerializationException
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.descriptors.buildClassSerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder
import kotlinx.serialization.json.JsonClassDiscriminator
import kotlinx.serialization.json.JsonDecoder
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonEncoder
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.decodeFromJsonElement
import kotlinx.serialization.json.encodeToJsonElement
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlin.time.Instant

// Generated code. Modify at your own risk.
@OptIn(ExperimentalSerializationApi::class)
@Serializable(with = NotificationEnvelope.Serializer::class)
@JsonClassDiscriminator("channel")
sealed class NotificationEnvelope : Identifiable<String> {
    @SerialName("email")
    @Serializable
    data class Email(
        val visibility: SampleVisibility = SampleVisibility.Public,
        @SerialName("sent_at")
        val sentAt: Instant? = null,
        @SerialName("payload")
        val payload: EmailNotification,
    ) : NotificationEnvelope()

    @SerialName("push")
    @Serializable
    data class Push(
        val visibility: SampleVisibility = SampleVisibility.Public,
        @SerialName("sent_at")
        val sentAt: Instant? = null,
        @SerialName("payload")
        val payload: PushNotification,
    ) : NotificationEnvelope()

    @Serializable
    data class Garbage(
        val raw: JsonElement? = null,
    ) : NotificationEnvelope()
    override val id: String
        get() =
            when (this) {
                is Garbage -> "__garbage__"
                is Email -> "email_" + payload.id.toString()
                is Push -> "push_" + payload.id.toString()
            }

    object Serializer : KSerializer<NotificationEnvelope> {
        override val descriptor: SerialDescriptor = buildClassSerialDescriptor("NotificationEnvelope")

        private fun JsonElement.withoutObjectType(): JsonObject =
            JsonObject(jsonObject.toMutableMap().apply {
                remove("channel")
                val alternatePayload = remove("data")
                if ("payload" !in this && alternatePayload != null) {
                    put("payload", alternatePayload)
                }
            })

        private fun JsonElement.withObjectType(objectType: String): JsonObject =
            JsonObject(jsonObject.toMutableMap().apply {
                put("channel", JsonPrimitive(objectType))
            })

        override fun deserialize(decoder: Decoder): NotificationEnvelope {
            val jsonDecoder = decoder as? JsonDecoder
                ?: throw SerializationException("NotificationEnvelope can only be decoded from JSON")
            val element = jsonDecoder.decodeJsonElement()
            return runCatching {
                val objectType = element.jsonObject["channel"]?.jsonPrimitive?.contentOrNull
                when (objectType) {
                    "email" -> jsonDecoder.json.decodeFromJsonElement(Email.serializer(), element.withoutObjectType())
                    "push" -> jsonDecoder.json.decodeFromJsonElement(Push.serializer(), element.withoutObjectType())
                    else -> Garbage(element)
                }
            }.getOrElse { Garbage(element) }
        }

        override fun serialize(encoder: Encoder, value: NotificationEnvelope) {
            val jsonEncoder = encoder as? JsonEncoder
                ?: throw SerializationException("NotificationEnvelope can only be encoded to JSON")
            when (value) {
                is Email -> jsonEncoder.encodeJsonElement(jsonEncoder.json.encodeToJsonElement(Email.serializer(), value).withObjectType("email"))
                is Push -> jsonEncoder.encodeJsonElement(jsonEncoder.json.encodeToJsonElement(Push.serializer(), value).withObjectType("push"))
                is Garbage -> jsonEncoder.encodeJsonElement(value.raw ?: JsonObject(emptyMap()))
            }
        }
    }
}
