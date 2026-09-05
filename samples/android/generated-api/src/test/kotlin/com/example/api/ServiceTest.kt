package com.example.api

import com.example.api.admin.user.AdminUserApi
import com.example.api.admin.user.AdminUserApiService
import com.example.api.showcase.samplemodels.ShowcaseSampleModelsApiService
import com.example.api.showcase.samplemodels.models.PrimitiveMatrix
import com.example.api.showcase.samplemodels.models.SampleScore
import com.example.api.showcase.shared.SampleVisibility
import com.example.api.showcase.transport.ShowcaseTransportApiService
import com.example.api.testing.AdminUserApiMock
import kotlinx.coroutines.runBlocking
import okhttp3.OkHttpClient
import okhttp3.mockwebserver.MockResponse
import okhttp3.mockwebserver.MockWebServer
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.koin.dsl.koinApplication

class ServiceTest {
    private lateinit var server: MockWebServer
    private val httpClient = OkHttpClient()

    @Before fun setUp() {
        server = MockWebServer()
        server.start()
    }

    @After fun tearDown() {
        server.shutdown()
        httpClient.dispatcher.executorService.shutdown()
        httpClient.connectionPool.evictAll()
    }

    private fun client(key: String? = "Bearer provider") =
        createRestClient(
            httpClient = httpClient,
            baseUrlProvider = BaseUrlProvider { server.url("/").toString() },
            apiKeyProvider = ApiKeyProvider { key },
            defaultHttpHeaderProvider = DefaultHttpHeaderProvider { mapOf("X-Trace-Id" to "default") },
        )

    @Test fun namedParametersEncodeWireValuesAndOverrideHeaders() =
        runBlocking {
            server.enqueue(MockResponse().setResponseCode(200).setBody("{}"))
            val service = ShowcaseSampleModelsApiService(client())
            val failure =
                runCatching {
                    service.getMatrix(
                        matrixId = "a/b c",
                        visibility = SampleVisibility.Internal,
                        scores = listOf(SampleScore.Low, SampleScore.High),
                        traceId = "explicit",
                        sampleSession = "session",
                        apiKey = "Bearer explicit",
                    )
                }.exceptionOrNull()
            assertTrue("An incomplete model must fail decoding", failure is ApiError)
            val request = server.takeRequest()
            assertEquals("/showcase/matrix/a%2Fb%20c", request.requestUrl!!.encodedPath)
            assertEquals("true", request.requestUrl!!.queryParameter("visible"))
            assertEquals("internal", request.requestUrl!!.queryParameter("visibility"))
            assertEquals("10,100", request.requestUrl!!.queryParameter("scores"))
            assertEquals("explicit", request.getHeader("X-Trace-Id"))
            assertEquals("Bearer explicit", request.getHeader("Authorization"))
            assertEquals("sample_session=session", request.getHeader("Cookie"))
        }

    @Test fun paginationFollowsNextUrlAndRetainsCredentialsAndMetadata() =
        runBlocking {
            server.enqueue(
                MockResponse()
                    .setResponseCode(
                        200,
                    ).setHeader("X-Page", "second")
                    .setBody("{\"results\":[],\"count\":0}"),
            )
            val next = server.url("/next?cursor=a%2Fb").toString()
            val result =
                ShowcaseSampleModelsApiService(client()).getNextPageForFollowRuntimeUrlOperation(
                    currentPage = PagedResults<PrimitiveMatrix>(results = emptyList(), next = next),
                    requestUrl = server.url("/original").toString(),
                )
            assertTrue(result.value.results.isEmpty())
            assertEquals(0, result.value.count)
            assertEquals(200, result.response.statusCode)
            assertNotNull(result.response.body)
            val request = server.takeRequest()
            assertEquals("/next?cursor=a%2Fb", request.path)
            assertEquals("Bearer provider", request.getHeader("Authorization"))
        }

    @Test fun requiredCredentialsFailBeforeNetwork() =
        runBlocking {
            val failure =
                runCatching {
                    ShowcaseTransportApiService(client(key = null)).uploadBinary(body = byteArrayOf(1, 2))
                }.exceptionOrNull()
            assertSame(ApiError.ApiKeyRequired, failure)
            assertEquals(0, server.requestCount)
        }

    @Test fun bodylessServiceUsesNamedIdAndPreservesStatus() =
        runBlocking {
            server.enqueue(MockResponse().setResponseCode(204))
            val result = AdminUserApiService(client()).delete(userId = 42L)
            assertEquals(204, result.statusCode)
            assertEquals("/user/42", server.takeRequest().path)
        }

    @Test fun mocksRecordNamedArgumentsAndResetHandlers() =
        runBlocking {
            val mock = AdminUserApiMock()
            mock.deleteHandler = { request ->
                assertEquals(42L, request.userId)
                ApiResponse(statusCode = 204)
            }
            assertEquals(204, mock.delete(userId = 42L).statusCode)
            assertEquals(42L, mock.deleteCalls.single().userId)
            mock.resetMock()
            assertTrue(mock.deleteCalls.isEmpty())
            assertTrue(runCatching { mock.delete(userId = 42L) }.isFailure)
        }

    @Test fun koinResolvesServicesAndAggregateFromAppOwnedClient() {
        val application =
            koinApplication {
                modules(apiKoinModule(httpClient, BaseUrlProvider { server.url("/").toString() }))
            }
        try {
            assertSame(httpClient, application.koin.get<OkHttpClient>())
            assertNotNull(application.koin.get<AdminUserApi>())
            assertNotNull(application.koin.get<ApiModules>())
        } finally {
            application.close()
        }
    }
}
