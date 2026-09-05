// Generated code. Do not edit.
package com.example.api.showcase.samplemodels.models

import com.example.api.AuditStamp
import com.example.api.ByteArrayBase64Serializer
import com.example.api.DateInterval
import com.example.api.NamedObject
import com.example.api.showcase.shared.SampleVisibility
import kotlinx.datetime.LocalDate
import kotlinx.datetime.LocalTime
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlin.time.Instant

// Generated code. Modify at your own risk.
@Serializable
data class PrimitiveMatrix(
    val uuid: String,
    val title: String = "Untitled",
    val count: Int = 1,
    @SerialName("large_count")
    val largeCount: Long = 1L,
    @SerialName("medium_count")
    val mediumCount: Int = 1,
    @SerialName("small_count")
    val smallCount: Short = 1,
    @SerialName("tiny_count")
    val tinyCount: Byte = 1,
    @SerialName("unsigned_count")
    val unsignedCount: UInt = 1u,
    @SerialName("unsigned_large_count")
    val unsignedLargeCount: ULong = 1uL,
    @SerialName("unsigned_medium_count")
    val unsignedMediumCount: UInt = 1u,
    @SerialName("unsigned_small_count")
    val unsignedSmallCount: UShort = 1u,
    @SerialName("unsigned_tiny_count")
    val unsignedTinyCount: UByte = 1u,
    val ratio: Double = 0.5,
    val enabled: Boolean = true,
    @SerialName("created_at")
    val createdAt: Instant,
    @SerialName("business_date")
    val businessDate: LocalDate,
    @SerialName("business_time")
    val businessTime: LocalTime,
    @SerialName("callback_url")
    val callbackUrl: String? = null,
    @Serializable(with = ByteArrayBase64Serializer::class)
    val payload: ByteArray,
    val metadata: Map<String, String?>,
    val aliases: List<String>,
    val steps: List<Int>,
    val visibility: SampleVisibility = SampleVisibility.Public,
    val score: SampleScore = SampleScore.Medium,
    val audit: AuditStamp,
    val related: List<NamedObject>,
    @SerialName("external_window")
    val externalWindow: DateInterval,
    val archived: Boolean = false,
) {
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is PrimitiveMatrix) return false
        if (uuid != other.uuid) return false
        if (title != other.title) return false
        if (count != other.count) return false
        if (largeCount != other.largeCount) return false
        if (mediumCount != other.mediumCount) return false
        if (smallCount != other.smallCount) return false
        if (tinyCount != other.tinyCount) return false
        if (unsignedCount != other.unsignedCount) return false
        if (unsignedLargeCount != other.unsignedLargeCount) return false
        if (unsignedMediumCount != other.unsignedMediumCount) return false
        if (unsignedSmallCount != other.unsignedSmallCount) return false
        if (unsignedTinyCount != other.unsignedTinyCount) return false
        if (ratio != other.ratio) return false
        if (enabled != other.enabled) return false
        if (createdAt != other.createdAt) return false
        if (businessDate != other.businessDate) return false
        if (businessTime != other.businessTime) return false
        if (callbackUrl != other.callbackUrl) return false
        if (!payload.contentEquals(other.payload)) return false
        if (metadata != other.metadata) return false
        if (aliases != other.aliases) return false
        if (steps != other.steps) return false
        if (visibility != other.visibility) return false
        if (score != other.score) return false
        if (audit != other.audit) return false
        if (related != other.related) return false
        if (externalWindow != other.externalWindow) return false
        if (archived != other.archived) return false
        return true
    }

    override fun hashCode(): Int {
        var result = uuid.hashCode()
        result = 31 * result + title.hashCode()
        result = 31 * result + count.hashCode()
        result = 31 * result + largeCount.hashCode()
        result = 31 * result + mediumCount.hashCode()
        result = 31 * result + smallCount.hashCode()
        result = 31 * result + tinyCount.hashCode()
        result = 31 * result + unsignedCount.hashCode()
        result = 31 * result + unsignedLargeCount.hashCode()
        result = 31 * result + unsignedMediumCount.hashCode()
        result = 31 * result + unsignedSmallCount.hashCode()
        result = 31 * result + unsignedTinyCount.hashCode()
        result = 31 * result + ratio.hashCode()
        result = 31 * result + enabled.hashCode()
        result = 31 * result + createdAt.hashCode()
        result = 31 * result + businessDate.hashCode()
        result = 31 * result + businessTime.hashCode()
        result = 31 * result + (callbackUrl?.hashCode() ?: 0)
        result = 31 * result + payload.contentHashCode()
        result = 31 * result + metadata.hashCode()
        result = 31 * result + aliases.hashCode()
        result = 31 * result + steps.hashCode()
        result = 31 * result + visibility.hashCode()
        result = 31 * result + score.hashCode()
        result = 31 * result + audit.hashCode()
        result = 31 * result + related.hashCode()
        result = 31 * result + externalWindow.hashCode()
        result = 31 * result + archived.hashCode()
        return result
    }
}
