package com.example.api

import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.builtins.MapSerializer
import kotlinx.serialization.builtins.nullable
import kotlinx.serialization.builtins.serializer
import kotlinx.serialization.json.Json
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Test

class PatchableValueSerializerTest {
    @Test
    fun nestedCollectionsRoundTripThroughStreamingAndTreeCodecs() {
        val serializer = PatchableValueSerializer(ListSerializer(MapSerializer(String.serializer(), Int.serializer().nullable)))
        val value = PatchableValue.Modified(List(10_000) { mapOf("value" to it, "missing" to null) })
        val encoded = Json.encodeToString(serializer, value)
        assertEquals(value, Json.decodeFromString(serializer, encoded))
        val tree = Json.encodeToJsonElement(serializer, value)
        assertEquals(value, Json.decodeFromJsonElement(serializer, tree))
        assertEquals(encoded, tree.toString())
    }

    @Test
    fun explicitNullAndUnmodifiedKeepTheirWireRepresentation() {
        val serializer = PatchableValueSerializer(String.serializer())
        assertEquals("null", Json.encodeToString(serializer, PatchableValue.Modified(null)))
        assertEquals("null", Json.encodeToString(serializer, PatchableValue.Unmodified))
        assertEquals(PatchableValue.Modified<String>(null), Json.decodeFromString(serializer, "null"))
    }

    @Test
    fun nullableValueSerializerStillAcceptsNullAndValues() {
        val serializer = PatchableValueSerializer(String.serializer().nullable)
        assertEquals(PatchableValue.Modified<String?>(null), Json.decodeFromString(serializer, "null"))
        assertEquals(PatchableValue.Modified("hello"), Json.decodeFromString(serializer, "\"hello\""))
    }
}
