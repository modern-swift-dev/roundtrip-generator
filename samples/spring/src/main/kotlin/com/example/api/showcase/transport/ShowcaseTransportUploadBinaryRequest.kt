// Generated code. Do not edit.
package com.example.api.showcase.transport

data class ShowcaseTransportUploadBinaryRequest(
    val contentMd5: String?,
    val apiKey: String,
    val body: ByteArray,
) {
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is ShowcaseTransportUploadBinaryRequest) return false
        if (contentMd5 != other.contentMd5) return false
        if (apiKey != other.apiKey) return false
        if (!body.contentEquals(other.body)) return false
        return true
    }

    override fun hashCode(): Int {
        var result = (contentMd5?.hashCode() ?: 0)
        result = 31 * result + apiKey.hashCode()
        result = 31 * result + body.contentHashCode()
        return result
    }
}
