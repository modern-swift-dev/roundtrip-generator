// Generated code. Do not edit.
package com.example.api

import jakarta.servlet.http.HttpServletRequest
import jakarta.servlet.http.Part
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.KSerializer
import kotlinx.serialization.Serializable
import kotlinx.serialization.SerializationException
import kotlinx.serialization.descriptors.PrimitiveKind
import kotlinx.serialization.descriptors.PrimitiveSerialDescriptor
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonDecoder
import kotlinx.serialization.json.JsonEncoder
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean
import org.springframework.context.annotation.Configuration
import org.springframework.http.HttpHeaders
import org.springframework.http.HttpStatus
import org.springframework.http.HttpStatusCode
import org.springframework.http.MediaType
import org.springframework.http.ResponseEntity
import org.springframework.http.converter.HttpMessageConverter
import org.springframework.http.converter.json.KotlinSerializationJsonHttpMessageConverter
import org.springframework.stereotype.Component
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer
import kotlin.io.encoding.Base64
import kotlin.io.encoding.ExperimentalEncodingApi

object GeneratedJson {
    val instance: Json =
        Json {
            ignoreUnknownKeys = true
        }
}

@Configuration
class GeneratedSerializationConfiguration : WebMvcConfigurer {
    override fun extendMessageConverters(converters: MutableList<HttpMessageConverter<*>>) {
        converters.add(0, KotlinSerializationJsonHttpMessageConverter(GeneratedJson.instance))
    }
}

data class GeneratedResponse<T>(
    val body: T? = null,
    val status: HttpStatusCode = HttpStatus.OK,
    val headers: HttpHeaders = HttpHeaders(),
)

object GeneratedResponseEntityEncoder {
    private fun headersWithContentType(
        headers: HttpHeaders,
        mediaType: MediaType,
    ): HttpHeaders = HttpHeaders(headers).apply { contentType = mediaType }

    private fun validateStatus(
        response: GeneratedResponse<*>,
        validStatusCodes: Set<Int>,
    ) {
        require(response.status.value() in validStatusCodes) {
            "Unexpected response status ${response.status.value()}; expected one of $validStatusCodes"
        }
    }

    private fun isBodyAllowed(status: HttpStatusCode): Boolean {
        val code = status.value()
        return code !in 100..199 && code != 204 && code != 205 && code != 304
    }

    fun empty(
        response: GeneratedResponse<Unit>,
        validStatusCodes: Set<Int>,
    ): ResponseEntity<Unit> {
        validateStatus(response, validStatusCodes)
        return ResponseEntity
            .status(response.status)
            .headers(response.headers)
            .build()
    }

    fun <T : Any> json(
        response: GeneratedResponse<T>,
        validStatusCodes: Set<Int>,
    ): ResponseEntity<T> {
        validateStatus(response, validStatusCodes)
        if (!isBodyAllowed(response.status)) {
            return ResponseEntity
                .status(response.status)
                .headers(response.headers)
                .build()
        }
        return ResponseEntity
            .status(response.status)
            .headers(response.headers)
            .body(requireNotNull(response.body) { "Missing response body for status ${response.status.value()}" })
    }

    fun binary(
        response: GeneratedResponse<ByteArray>,
        mediaType: MediaType,
        validStatusCodes: Set<Int>,
    ): ResponseEntity<ByteArray> {
        validateStatus(response, validStatusCodes)
        if (!isBodyAllowed(response.status)) {
            return ResponseEntity
                .status(response.status)
                .headers(response.headers)
                .build()
        }
        return ResponseEntity
            .status(response.status)
            .headers(headersWithContentType(response.headers, mediaType))
            .body(requireNotNull(response.body) { "Missing response body for status ${response.status.value()}" })
    }
}

data class GeneratedSecurityRequest(
    val request: HttpServletRequest,
    val operationId: String,
)

data class GeneratedMultipartPart(
    val fileName: String? = null,
    val contentType: String? = null,
    val bytes: ByteArray,
) {
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is GeneratedMultipartPart) return false
        if (fileName != other.fileName) return false
        if (contentType != other.contentType) return false
        if (!bytes.contentEquals(other.bytes)) return false
        return true
    }

    override fun hashCode(): Int {
        var result = fileName?.hashCode() ?: 0
        result = 31 * result + (contentType?.hashCode() ?: 0)
        result = 31 * result + bytes.contentHashCode()
        return result
    }

    companion object {
        fun from(part: Part): GeneratedMultipartPart =
            GeneratedMultipartPart(
                fileName = part.submittedFileName,
                contentType = part.contentType,
                bytes = part.inputStream.use { it.readBytes() },
            )
    }
}

@Serializable
data class PagedResults<T>(
    val results: List<T>,
    val next: String? = null,
    val count: Int? = null,
) {
    val hasNext: Boolean get() = next != null && results.isNotEmpty()
}

@Serializable
data class LocalizedData<T>(
    val values: Map<String, T>,
)

@Serializable
data class DateInterval(
    val start: String,
    val end: String,
)

@OptIn(ExperimentalEncodingApi::class)
object ByteArrayBase64Serializer : KSerializer<ByteArray> {
    override val descriptor: SerialDescriptor =
        PrimitiveSerialDescriptor("ByteArrayBase64", PrimitiveKind.STRING)

    override fun deserialize(decoder: Decoder): ByteArray =
        Base64.Default.decode(decoder.decodeString())

    override fun serialize(encoder: Encoder, value: ByteArray) {
        encoder.encodeString(Base64.Default.encode(value))
    }
}

interface Identifiable<out ID> {
    val id: ID
}

@Serializable(with = PatchableValueSerializer::class)
sealed class PatchableValue<out T> {
    data object Unmodified : PatchableValue<Nothing>()

    data class Modified<T>(
        val value: T?,
    ) : PatchableValue<T>()
}

@OptIn(ExperimentalSerializationApi::class)
class PatchableValueSerializer<T>(
    private val valueSerializer: KSerializer<T>,
) : KSerializer<PatchableValue<T>> {
    override val descriptor: SerialDescriptor = valueSerializer.descriptor

    override fun deserialize(decoder: Decoder): PatchableValue<T> {
        val jsonDecoder =
            decoder as? JsonDecoder
                ?: throw SerializationException("PatchableValue can only be decoded from JSON")
        return if (jsonDecoder.decodeNotNullMark()) {
            PatchableValue.Modified(jsonDecoder.decodeSerializableValue(valueSerializer))
        } else {
            jsonDecoder.decodeNull()
            PatchableValue.Modified(null)
        }
    }

    override fun serialize(
        encoder: Encoder,
        value: PatchableValue<T>,
    ) {
        val jsonEncoder =
            encoder as? JsonEncoder
                ?: throw SerializationException("PatchableValue can only be encoded to JSON")
        when (value) {
            PatchableValue.Unmodified -> jsonEncoder.encodeNull()
            is PatchableValue.Modified -> {
                val modifiedValue = value.value
                if (modifiedValue == null) {
                    jsonEncoder.encodeNull()
                } else {
                    jsonEncoder.encodeSerializableValue(valueSerializer, modifiedValue)
                }
            }
        }
    }
}

interface GeneratedSecurityMiddleware {
    suspend fun requireAuthorization(request: GeneratedSecurityRequest)

    suspend fun authorizeOptional(request: GeneratedSecurityRequest)
}

@ConditionalOnMissingBean(GeneratedSecurityMiddleware::class)
@Component
class AllowAllGeneratedSecurityMiddleware : GeneratedSecurityMiddleware {
    override suspend fun requireAuthorization(request: GeneratedSecurityRequest) = Unit

    override suspend fun authorizeOptional(request: GeneratedSecurityRequest) = Unit
}
