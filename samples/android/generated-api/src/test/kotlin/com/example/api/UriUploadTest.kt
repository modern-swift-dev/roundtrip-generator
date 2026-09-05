package com.example.api

import android.net.Uri
import kotlinx.coroutines.async
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.runBlocking
import okhttp3.OkHttpClient
import okhttp3.mockwebserver.MockResponse
import okhttp3.mockwebserver.MockWebServer
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import java.io.ByteArrayInputStream
import java.io.FileNotFoundException
import java.io.IOException
import java.io.InputStream
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
class UriUploadTest {
    private val uri = Uri.parse("content://uploads/test")

    private fun request(source: ApiUploadSource): ApiRequestConvertible =
        object : ApiRequestConvertible {
            override fun toApiRequest() = ApiRequest("POST", ApiRequestPath.Relative("upload"), body = source)
        }

    @Test
    fun streamsUnknownLengthUriAndClosesIt() =
        runBlocking {
            val resolver = RuntimeEnvironment.getApplication().contentResolver
            var closed = false
            val stream =
                object : ByteArrayInputStream("URI payload".toByteArray()) {
                    override fun close() {
                        closed = true
                        super.close()
                    }
                }
            shadowOf(resolver).registerInputStream(uri, stream)
            MockWebServer().use { server ->
                server.start()
                server.enqueue(MockResponse())
                val client = createRestClient(OkHttpClient(), BaseUrlProvider { server.url("/").toString() })
                val progress = mutableListOf<Pair<Long, Long?>>()
                client.upload(
                    request(ApiUploadSource.ContentUri(uri, resolver)),
                    ApiProgress { sent, total ->
                        progress.add(sent to total)
                    },
                    setOf(200),
                )
                val recorded = server.takeRequest()
                assertEquals("URI payload", recorded.body.readUtf8())
                assertEquals("chunked", recorded.getHeader("Transfer-Encoding"))
                assertTrue(closed)
                assertEquals(11L to null, progress.last())
            }
        }

    @Test
    fun unavailableUriIsTransportFailure() =
        runBlocking {
            val resolver = RuntimeEnvironment.getApplication().contentResolver
            shadowOf(resolver).registerInputStreamSupplier(uri) { throw FileNotFoundException("Unavailable") }
            MockWebServer().use { server ->
                server.start()
                server.enqueue(MockResponse())
                val client = createRestClient(OkHttpClient(), BaseUrlProvider { server.url("/").toString() })
                try {
                    client.upload(request(ApiUploadSource.ContentUri(uri, resolver)), null, setOf(200))
                    fail("Expected transport failure")
                } catch (error: ApiError.Transport) {
                    assertTrue(generateSequence(error.cause) { it.cause }.any { it is FileNotFoundException })
                }
            }
        }

    @Test
    fun revokedUriPermissionBecomesTypedTransportFailure() =
        runBlocking {
            val resolver = RuntimeEnvironment.getApplication().contentResolver
            shadowOf(resolver).registerInputStreamSupplier(uri) { throw SecurityException("Permission revoked") }
            MockWebServer().use { server ->
                server.start()
                server.enqueue(MockResponse())
                val client = createRestClient(OkHttpClient(), BaseUrlProvider { server.url("/").toString() })
                try {
                    client.upload(request(ApiUploadSource.ContentUri(uri, resolver)), null, setOf(200))
                    fail("Expected transport failure")
                } catch (error: ApiError.Transport) {
                    assertTrue(generateSequence(error.cause) { it.cause }.any { it is SecurityException })
                }
            }
        }

    @Test
    fun readFailureClosesUriStream() =
        runBlocking {
            val resolver = RuntimeEnvironment.getApplication().contentResolver
            var closed = false
            shadowOf(resolver).registerInputStreamSupplier(uri) {
                object : InputStream() {
                    override fun read(): Int = throw IOException("Read failed")

                    override fun close() {
                        closed = true
                    }
                }
            }
            MockWebServer().use { server ->
                server.start()
                server.enqueue(MockResponse())
                val client = createRestClient(OkHttpClient(), BaseUrlProvider { server.url("/").toString() })
                try {
                    client.upload(request(ApiUploadSource.ContentUri(uri, resolver)), null, setOf(200))
                    fail("Expected transport failure")
                } catch (_: ApiError.Transport) {
                    assertTrue(closed)
                }
            }
        }

    @Test
    fun cancellationClosesBlockedUriStream() =
        runBlocking {
            val resolver = RuntimeEnvironment.getApplication().contentResolver
            val reading = CountDownLatch(1)
            val closed = CountDownLatch(1)
            shadowOf(resolver).registerInputStream(
                uri,
                object : InputStream() {
                    override fun read(): Int {
                        reading.countDown()
                        if (!closed.await(5, TimeUnit.SECONDS)) throw IOException("Timed out waiting for cancellation")
                        throw IOException("Closed")
                    }

                    override fun close() {
                        closed.countDown()
                    }
                },
            )
            MockWebServer().use { server ->
                server.start()
                server.enqueue(MockResponse())
                val client = createRestClient(OkHttpClient(), BaseUrlProvider { server.url("/").toString() })
                val upload =
                    async(kotlinx.coroutines.Dispatchers.IO) {
                        client.upload(request(ApiUploadSource.ContentUri(uri, resolver)), null, setOf(200))
                    }
                assertTrue(reading.await(5, TimeUnit.SECONDS))
                upload.cancelAndJoin()
                assertTrue(closed.await(1, TimeUnit.SECONDS))
            }
        }
}
