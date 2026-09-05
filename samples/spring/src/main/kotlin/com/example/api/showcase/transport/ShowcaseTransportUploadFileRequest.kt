// Generated code. Do not edit.
package com.example.api.showcase.transport

data class ShowcaseTransportUploadFileRequest(
    val apiKey: String,
    val body: ByteArray,
) {
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is ShowcaseTransportUploadFileRequest) return false
        if (apiKey != other.apiKey) return false
        if (!body.contentEquals(other.body)) return false
        return true
    }

    override fun hashCode(): Int {
        var result = apiKey.hashCode()
        result = 31 * result + body.contentHashCode()
        return result
    }
}
