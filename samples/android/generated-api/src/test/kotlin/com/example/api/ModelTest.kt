package com.example.api

import com.example.api.admin.user.models.PatchedUser
import com.example.api.showcase.samplemodels.models.NotificationEnvelope
import com.example.api.showcase.samplemodels.models.SampleScore
import com.example.api.showcase.shared.SampleVisibility
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class ModelTest {
    private val json = Json { ignoreUnknownKeys = true }

    @Test
    fun enumWireValuesAndUnknownCases() {
        assertEquals("100", json.encodeToString(SampleScore.High))
        assertEquals(SampleScore.High, json.decodeFromString<SampleScore>("100"))
        assertEquals("\"internal\"", json.encodeToString(SampleVisibility.Internal))
        assertEquals(SampleVisibility.Garbage, json.decodeFromString<SampleVisibility>("\"future-value\""))
    }

    @Test
    fun polymorphicAlternatePayloadAndUnknownValueRoundTrip() {
        val known = """{"channel":"email","data":{"id":"1","subject":"Hello","body":"World","recipients":[]}}"""
        val decoded = json.decodeFromString<NotificationEnvelope>(known)
        assertTrue(decoded is NotificationEnvelope.Email)
        assertEquals("email_1", decoded.id)
        assertEquals(decoded, json.decodeFromString<NotificationEnvelope>(json.encodeToString(decoded)))
        val unknown = """{"channel":"future","data":{"extra":42}}"""
        val garbage = json.decodeFromString<NotificationEnvelope>(unknown)
        assertTrue(garbage is NotificationEnvelope.Garbage)
        assertEquals(json.parseToJsonElement(unknown), json.parseToJsonElement(json.encodeToString(garbage)))
    }

    @Test
    fun patchFieldsDistinguishOmissionNullAndValue() {
        val patch = PatchedUser()
        assertTrue(patch.isUnmodified())
        assertEquals("{}", json.encodeToString(patch))
        patch.firstName = PatchableValue.Modified("New")
        patch.phone = PatchableValue.Modified(null)
        assertFalse(patch.isUnmodified())
        assertEquals(
            json.parseToJsonElement("""{"first_name":"New","phone":null}"""),
            json.parseToJsonElement(json.encodeToString(patch)),
        )
        assertEquals(patch, json.decodeFromString<PatchedUser>(json.encodeToString(patch)))
        patch.resetPatchableFields()
        assertEquals("{}", json.encodeToString(patch))
    }

    @Test
    fun binaryJsonUsesBase64AndUploadBytesUseContentEquality() {
        val bytes = byteArrayOf(0, 1, -1)
        assertEquals("\"AAH/\"", json.encodeToString(ByteArrayBase64Serializer, bytes))
        assertArrayEquals(bytes, json.decodeFromString(ByteArrayBase64Serializer, "\"AAH/\""))
        assertEquals(ApiUploadSource.Bytes(bytes), ApiUploadSource.Bytes(bytes.copyOf()))
        assertEquals(ApiUploadSource.Bytes(bytes).hashCode(), ApiUploadSource.Bytes(bytes.copyOf()).hashCode())
    }
}
