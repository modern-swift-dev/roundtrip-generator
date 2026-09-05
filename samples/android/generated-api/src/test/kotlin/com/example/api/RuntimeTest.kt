package com.example.api

import kotlinx.coroutines.async
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.delay
import kotlinx.coroutines.runBlocking
import kotlinx.serialization.builtins.serializer
import okhttp3.OkHttpClient
import okhttp3.mockwebserver.MockResponse
import okhttp3.mockwebserver.MockWebServer
import org.junit.After
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Before
import org.junit.Test
import java.util.concurrent.TimeUnit

class RuntimeTest {
    private lateinit var server: MockWebServer
    private lateinit var client: RestClient

    @Before
    fun setUp() {
        server = MockWebServer()
        server.start()
        client =
            createRestClient(
                httpClient = OkHttpClient(),
                baseUrlProvider = BaseUrlProvider { server.url("/api/").toString() },
                apiKeyProvider = ApiKeyProvider { "secret" },
                defaultHttpHeaderProvider = DefaultHttpHeaderProvider { mapOf("x-trace" to "default") },
            )
    }

    @After
    fun tearDown() {
        server.shutdown()
    }

    private fun request(
        method: String = "GET",
        path: ApiRequestPath = ApiRequestPath.Relative("items"),
        headers: Map<String, String> = emptyMap(),
        query: Map<String, String> = emptyMap(),
        body: Any? = null,
        bodyType: kotlinx.serialization.KSerializer<Any?>? = null,
    ): ApiRequestConvertible =
        object : ApiRequestConvertible {
            override fun toApiRequest() = ApiRequest(method, path, query, headers, body, bodyType)
        }

    @Test
    fun declaredErrorStatusDecodesAndPreservesMetadata() =
        runBlocking {
            server.enqueue(
                MockResponse().setResponseCode(409).setHeader("X-Result", "conflict").setBody("\"accepted\""),
            )
            val result =
                client.execute(
                    request(),
                    ApiResponseType("String", "application/json", String.serializer()),
                    setOf(409),
                )
            assertEquals("accepted", result.value)
            assertEquals(409, result.response.statusCode)
            assertEquals(
                listOf("conflict"),
                result.response.headers.entries
                    .first { it.key.equals("X-Result", true) }
                    .value,
            )
            assertArrayEquals("\"accepted\"".toByteArray(), result.response.body)
        }

    @Test
    fun encodesParametersAndExplicitHeadersOverrideIgnoringCase() =
        runBlocking {
            server.enqueue(MockResponse().setBody("ok"))
            client.execute(request(headers = mapOf("X-Trace" to "explicit"), query = mapOf("q" to "a & b")), setOf(200))
            val recorded = server.takeRequest()
            assertEquals("/api/items?q=a%20%26%20b", recorded.path)
            assertEquals(listOf("explicit"), recorded.headers.values("X-Trace"))
            assertNull(recorded.getHeader("Content-Type"))
            assertEquals("a%2Fb%20%C3%A9", "a/b é".toApiPathSegment())
            assertEquals("secret", client.requireApiKey())
        }

    @Test
    fun absoluteAndRuntimeUrlsDoNotUseBaseUrl() =
        runBlocking {
            listOf(
                ApiRequestPath.Absolute(server.url("/absolute").toString()),
                ApiRequestPath.Runtime(server.url("/next?page=2").toString()),
            ).forEach {
                server.enqueue(MockResponse())
                client.execute(request(path = it), setOf(200))
            }
            assertEquals("/absolute", server.takeRequest().path)
            assertEquals("/next?page=2", server.takeRequest().path)
        }

    @Test
    fun jsonBinaryAndMultipartUploadsReportProgress() =
        runBlocking {
            server.enqueue(MockResponse())
            client.execute(request(method = "POST", body = "hello", bodyType = apiBodySerializer<String>()), setOf(200))
            assertEquals("\"hello\"", server.takeRequest().body.readUtf8())
            val progress = mutableListOf<Pair<Long, Long?>>()
            server.enqueue(MockResponse())
            client.upload(
                request(method = "POST", body = byteArrayOf(1, 2, 3)),
                ApiProgress { sent, total ->
                    progress.add(sent to total)
                },
                setOf(200),
            )
            assertArrayEquals(byteArrayOf(1, 2, 3), server.takeRequest().body.readByteArray())
            assertEquals(3L to 3L, progress.last())
            server.enqueue(MockResponse())
            client.postMultipart(
                request(
                    method = "POST",
                    body =
                        MultipartBody(
                            mapOf(
                                "file" to MultipartBody.Part.bytes("payload".toByteArray(), "test.txt"),
                                "metadata" to MultipartBody.Part.text("text"),
                            ),
                        ),
                ),
                null,
                setOf(200),
            )
            val multipart = server.takeRequest()
            assertTrue(multipart.getHeader("Content-Type")!!.startsWith("multipart/form-data; boundary="))
            val content = multipart.body.readUtf8()
            assertTrue(content.contains("filename=\"test.txt\""))
            assertTrue(content.contains("payload"))
            assertTrue(content.contains("text"))
        }

    @Test
    fun unexpectedStatusAndMalformedJsonProduceTypedErrors() =
        runBlocking {
            server.enqueue(MockResponse().setResponseCode(503).setBody("unavailable"))
            try {
                client.execute(request(), setOf(200))
                fail("Expected status error")
            } catch (error: ApiError.UnexpectedStatusCode) {
                assertEquals(503, error.statusCode)
            }
            server.enqueue(MockResponse().setBody("not JSON"))
            try {
                client.execute(
                    request(),
                    ApiResponseType("String", "application/json", String.serializer()),
                    setOf(200),
                )
                fail("Expected decoding error")
            } catch (error: ApiError.Decoding) {
                assertNotNull(error.cause)
            }
        }

    @Test
    fun cancellationDoesNotBecomeApiError() =
        runBlocking {
            server.enqueue(MockResponse().setBody("delayed").setBodyDelay(2, TimeUnit.SECONDS))
            val call = async { client.execute(request(), setOf(200)) }
            delay(100)
            call.cancelAndJoin()
            assertTrue(call.isCancelled)
            server.enqueue(MockResponse().setBody("ok"))
            assertEquals(200, client.execute(request(), setOf(200)).statusCode)
        }

    @Test
    fun missingCredentialsAndInvalidUrlsAreTyped() =
        runBlocking {
            val unauthenticated = createRestClient(OkHttpClient(), BaseUrlProvider { "not a URL" })
            try {
                unauthenticated.requireApiKey()
                fail("Expected credentials error")
            } catch (_: ApiError.ApiKeyRequired) {
                Unit
            }
            try {
                unauthenticated.execute(request(), setOf(200))
                fail("Expected URL error")
            } catch (_: ApiError.InvalidUrl) {
                Unit
            }
        }
}
