import Foundation
import GeneratorBuilder

struct KotlinAndroidRuntimeEmitter {
    func kotlinCode(packageName: String? = nil) -> any Node {
        KotlinAndroidFileEmitter.renderNode(
            packageName: packageName,
            imports: [
                "android.content.ContentResolver",
                "android.net.Uri",
                "java.io.File",
                "java.io.IOException",
                "java.io.InputStream",
                "kotlinx.coroutines.CancellationException",
                "kotlinx.coroutines.Dispatchers",
                "kotlinx.coroutines.runInterruptible",
                "kotlinx.coroutines.withContext",
                "kotlinx.serialization.serializer",
                "okhttp3.OkHttpClient",
                "okhttp3.HttpUrl.Companion.toHttpUrlOrNull",
                "okhttp3.MediaType.Companion.toMediaType",
                "okhttp3.RequestBody",
                "okhttp3.RequestBody.Companion.toRequestBody",
                "okhttp3.ResponseBody",
                "okio.BufferedSink",
                "okio.ForwardingSink",
                "okio.buffer",
                "okio.source",
                "retrofit2.Response",
                "retrofit2.Retrofit",
                "retrofit2.http.Body",
                "retrofit2.http.GET",
                "retrofit2.http.HEAD",
                "retrofit2.http.HTTP",
                "retrofit2.http.HeaderMap",
                "retrofit2.http.Url",
                "kotlin.io.encoding.Base64",
                "kotlin.io.encoding.ExperimentalEncodingApi",
                "kotlin.time.Instant",
                "kotlinx.coroutines.flow.MutableSharedFlow",
                "kotlinx.coroutines.flow.SharedFlow",
                "kotlinx.serialization.ExperimentalSerializationApi",
                "kotlinx.serialization.KSerializer",
                "kotlinx.serialization.SerializationException",
                "kotlinx.serialization.Serializable",
                "kotlinx.serialization.descriptors.PrimitiveKind",
                "kotlinx.serialization.descriptors.PrimitiveSerialDescriptor",
                "kotlinx.serialization.descriptors.SerialDescriptor",
                "kotlinx.serialization.encoding.Decoder",
                "kotlinx.serialization.encoding.Encoder",
                "kotlinx.serialization.encodeToString",
                "kotlinx.datetime.LocalDate",
                "kotlinx.datetime.LocalTime",
                "kotlinx.serialization.json.Json",
                "kotlinx.serialization.json.JsonDecoder",
                "kotlinx.serialization.json.JsonEncoder"
            ],
            body: runtimeDeclaration
        )
    }

    private var runtimeDeclaration: String {
        """
        sealed interface ApiRequestPath {
            data class Relative(
                val path: String,
            ) : ApiRequestPath

            data class Absolute(
                val url: String,
            ) : ApiRequestPath

            data class Runtime(
                val requestUrl: String,
            ) : ApiRequestPath
        }

        data class ApiFileContent(
            val bytes: ByteArray = byteArrayOf(),
            val source: ApiUploadSource = ApiUploadSource.Bytes(bytes),
            val fileName: String? = null,
            val contentType: String = "application/octet-stream",
        ) {
            override fun equals(other: Any?): Boolean {
                if (this === other) return true
                if (other !is ApiFileContent) return false
                if (!bytes.contentEquals(other.bytes)) return false
                if (source != other.source) return false
                if (fileName != other.fileName) return false
                if (contentType != other.contentType) return false
                return true
            }

            override fun hashCode(): Int {
                var result = bytes.contentHashCode()
                result = 31 * result + source.hashCode()
                result = 31 * result + (fileName?.hashCode() ?: 0)
                result = 31 * result + contentType.hashCode()
                return result
            }
        }

        data class ApiRequest(
            val method: String,
            val path: ApiRequestPath,
            val queryParameters: Map<String, String> = emptyMap(),
            val headers: Map<String, String> = emptyMap(),
            val body: Any? = null,
            val bodyType: KSerializer<Any?>? = null,
            val contentType: String? = null,
            val accept: String = "*/*",
        ) {
            override fun equals(other: Any?): Boolean {
                if (this === other) return true
                if (other !is ApiRequest) return false
                if (method != other.method) return false
                if (path != other.path) return false
                if (queryParameters != other.queryParameters) return false
                if (headers != other.headers) return false
                if (!bodyContentEquals(other.body)) return false
                if (bodyType != other.bodyType) return false
                if (contentType != other.contentType) return false
                if (accept != other.accept) return false
                return true
            }

            override fun hashCode(): Int {
                var result = method.hashCode()
                result = 31 * result + path.hashCode()
                result = 31 * result + queryParameters.hashCode()
                result = 31 * result + headers.hashCode()
                result = 31 * result + bodyContentHashCode()
                result = 31 * result + (bodyType?.hashCode() ?: 0)
                result = 31 * result + (contentType?.hashCode() ?: 0)
                result = 31 * result + accept.hashCode()
                return result
            }

            private fun bodyContentEquals(otherBody: Any?): Boolean {
                val currentBody = body
                return if (currentBody is ByteArray && otherBody is ByteArray) {
                    currentBody.contentEquals(otherBody)
                } else {
                    currentBody == otherBody
                }
            }

            private fun bodyContentHashCode(): Int {
                val currentBody = body
                return if (currentBody is ByteArray) {
                    currentBody.contentHashCode()
                } else {
                    currentBody?.hashCode() ?: 0
                }
            }
        }

        interface ApiRequestConvertible {
            fun toApiRequest(): ApiRequest
        }

        data class ApiResponse(
            val statusCode: Int,
            val headers: Map<String, List<String>> = emptyMap(),
            val body: ByteArray? = null,
            val mimeType: String? = null,
        ) {
            val is200: Boolean get() = statusCode == 200
            val is201: Boolean get() = statusCode == 201
            val is20x: Boolean get() = statusCode in 200..299
            val is304: Boolean get() = statusCode == 304
            val is400: Boolean get() = statusCode == 400
            val is401: Boolean get() = statusCode == 401
            val is403: Boolean get() = statusCode == 403
            val is404: Boolean get() = statusCode == 404
            val is50x: Boolean get() = statusCode in 500..599

            override fun equals(other: Any?): Boolean {
                if (this === other) return true
                if (other !is ApiResponse) return false
                if (statusCode != other.statusCode) return false
                if (headers != other.headers) return false
                if (mimeType != other.mimeType) return false
                val otherBody = other.body
                if (body == null) {
                    if (otherBody != null) return false
                } else if (otherBody == null || !body.contentEquals(otherBody)) return false
                return true
            }

            override fun hashCode(): Int {
                var result = statusCode
                result = 31 * result + headers.hashCode()
                result = 31 * result + (mimeType?.hashCode() ?: 0)
                result = 31 * result + (body?.contentHashCode() ?: 0)
                return result
            }
        }

        data class ApiOperationResult<T>(
            val value: T,
            val response: ApiResponse,
        ) {
            override fun equals(other: Any?): Boolean {
                if (this === other) return true
                if (other !is ApiOperationResult<*>) return false
                if (!valueContentEquals(other.value)) return false
                if (response != other.response) return false
                return true
            }

            override fun hashCode(): Int {
                var result = valueContentHashCode()
                result = 31 * result + response.hashCode()
                return result
            }

            private fun valueContentEquals(otherValue: Any?): Boolean {
                val currentValue = value
                return if (currentValue is ByteArray && otherValue is ByteArray) {
                    currentValue.contentEquals(otherValue)
                } else {
                    currentValue == otherValue
                }
            }

            private fun valueContentHashCode(): Int {
                val currentValue = value
                return if (currentValue is ByteArray) {
                    currentValue.contentHashCode()
                } else {
                    currentValue?.hashCode() ?: 0
                }
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

            override fun serialize(encoder: Encoder, value: PatchableValue<T>) {
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

        data class ApiResponseType<T>(
            val typeName: String,
            val mimeType: String,
            val serializer: KSerializer<T>,
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

        fun interface ApiKeyProvider {
            suspend fun apiKey(): String?
        }

        fun interface BaseUrlProvider {
            suspend fun baseUrl(): String
        }

        fun interface DefaultHttpHeaderProvider {
            suspend fun headers(): Map<String, String>
        }

        interface BodyCodec {
            suspend fun <T> decode(
                response: ApiResponse,
                responseType: ApiResponseType<T>,
            ): T
        }

        sealed class ApiError(message: String, cause: Throwable? = null) : Exception(message, cause) {
            data object ApiKeyRequired : ApiError("API key is required")
            data object InvalidUrl : ApiError("Invalid URL")
            data object RequestEncodingFailed : ApiError("Request encoding failed")
            class InvalidRequest(cause: Throwable) : ApiError("Invalid request", cause)
            class Transport(cause: Throwable) : ApiError("HTTP transport failed", cause)
            class Decoding(cause: Throwable) : ApiError("Response decoding failed", cause)
            data class UnexpectedStatusCode(val statusCode: Int, val response: ApiResponse? = null) : ApiError("Unexpected HTTP status $statusCode")
        }

        fun interface ApiProgress {
            fun update(
                bytesSent: Long,
                totalBytes: Long?,
            )
        }

        data class MultipartBody(
            val parts: Map<String, Part> = emptyMap(),
        ) {
            data class Part(
                val fileName: String? = null,
                val contentType: String? = null,
                val bytes: ByteArray = byteArrayOf(),
                val source: ApiUploadSource = ApiUploadSource.Bytes(bytes),
            ) {
                override fun equals(other: Any?): Boolean {
                    if (this === other) return true
                    if (other !is Part) return false
                    if (source != other.source) return false
                    if (fileName != other.fileName) return false
                    if (contentType != other.contentType) return false
                    if (!bytes.contentEquals(other.bytes)) return false
                    return true
                }

                override fun hashCode(): Int {
                    var result = source.hashCode()
                    result = 31 * result + (fileName?.hashCode() ?: 0)
                    result = 31 * result + (contentType?.hashCode() ?: 0)
                    result = 31 * result + bytes.contentHashCode()
                    return result
                }

                companion object {
                    fun bytes(
                        bytes: ByteArray,
                        fileName: String? = null,
                        contentType: String? = null,
                    ): Part =
                        Part(
                            fileName = fileName,
                            contentType = contentType,
                            bytes = bytes,
                        )

                    fun text(
                        value: String,
                        fileName: String? = null,
                        contentType: String = "text/plain",
                    ): Part =
                        Part(
                            fileName = fileName,
                            contentType = contentType,
                            bytes = value.encodeToByteArray(),
                        )

                    fun <T> json(
                        value: T,
                        serializer: KSerializer<T>,
                        fileName: String? = null,
                        contentType: String = "application/json",
                        json: Json = Json,
                    ): Part =
                        Part(
                            fileName = fileName,
                            contentType = contentType,
                            bytes = json.encodeToString(serializer, value).encodeToByteArray(),
                        )
                }
            }
        }

        interface RestClient {
            val errors: SharedFlow<ApiError>

            suspend fun apiKey(): String?

            suspend fun requireApiKey(): String

            suspend fun execute(
                request: ApiRequestConvertible,
                validStatusCodes: Set<Int>,
            ): ApiResponse

            suspend fun <T> execute(
                request: ApiRequestConvertible,
                responseType: ApiResponseType<T>,
                validStatusCodes: Set<Int>,
            ): ApiOperationResult<T>

            suspend fun <T> upload(
                request: ApiRequestConvertible,
                progress: ApiProgress?,
                responseType: ApiResponseType<T>,
                validStatusCodes: Set<Int>,
            ): ApiOperationResult<T>

            suspend fun upload(
                request: ApiRequestConvertible,
                progress: ApiProgress?,
                validStatusCodes: Set<Int>,
            ): ApiResponse

            suspend fun <T> postMultipart(
                request: ApiRequestConvertible,
                progress: ApiProgress?,
                responseType: ApiResponseType<T>,
                validStatusCodes: Set<Int>,
            ): ApiOperationResult<T>

            suspend fun postMultipart(
                request: ApiRequestConvertible,
                progress: ApiProgress?,
                validStatusCodes: Set<Int>,
            ): ApiResponse
        }

        @Suppress("UNCHECKED_CAST")
        inline fun <reified T> apiBodySerializer(): KSerializer<Any?> = serializer<T>() as KSerializer<Any?>

        sealed interface ApiUploadSource {
            data class Bytes(val bytes: ByteArray) : ApiUploadSource {
                override fun equals(other: Any?): Boolean = other is Bytes && bytes.contentEquals(other.bytes)
                override fun hashCode(): Int = bytes.contentHashCode()
            }
            data class FileSource(val file: File) : ApiUploadSource
            data class ContentUri(val uri: Uri, val contentResolver: ContentResolver) : ApiUploadSource
        }

        internal interface RetrofitTransport {
            @GET
            suspend fun get(@Url url: String, @HeaderMap headers: Map<String, String>): Response<ResponseBody>

            @HEAD
            suspend fun head(@Url url: String, @HeaderMap headers: Map<String, String>): Response<ResponseBody>

            @HTTP(method = "POST", hasBody = true)
            suspend fun post(@Url url: String, @HeaderMap headers: Map<String, String>, @Body body: RequestBody): Response<ResponseBody>

            @HTTP(method = "PUT", hasBody = true)
            suspend fun put(@Url url: String, @HeaderMap headers: Map<String, String>, @Body body: RequestBody): Response<ResponseBody>

            @HTTP(method = "PATCH", hasBody = true)
            suspend fun patch(@Url url: String, @HeaderMap headers: Map<String, String>, @Body body: RequestBody): Response<ResponseBody>

            @HTTP(method = "DELETE", hasBody = true)
            suspend fun delete(@Url url: String, @HeaderMap headers: Map<String, String>, @Body body: RequestBody): Response<ResponseBody>

            @HTTP(method = "OPTIONS", hasBody = true)
            suspend fun options(@Url url: String, @HeaderMap headers: Map<String, String>, @Body body: RequestBody): Response<ResponseBody>
        }

        class JsonBodyCodec(private val json: Json = Json { ignoreUnknownKeys = true }) : BodyCodec {
            override suspend fun <T> decode(response: ApiResponse, responseType: ApiResponseType<T>): T =
                json.decodeFromString(responseType.serializer, response.body?.decodeToString() ?: "")
        }

        fun createRestClient(
            httpClient: OkHttpClient,
            baseUrlProvider: BaseUrlProvider,
            apiKeyProvider: ApiKeyProvider = ApiKeyProvider { null },
            defaultHttpHeaderProvider: DefaultHttpHeaderProvider = DefaultHttpHeaderProvider { emptyMap() },
            json: Json = Json { ignoreUnknownKeys = true },
        ): RestClient = RetrofitRestClient(httpClient, baseUrlProvider, apiKeyProvider, defaultHttpHeaderProvider = defaultHttpHeaderProvider, json = json)

        class RetrofitRestClient(
            httpClient: OkHttpClient,
            private val baseUrlProvider: BaseUrlProvider,
            private val apiKeyProvider: ApiKeyProvider = ApiKeyProvider { null },
            bodyCodec: BodyCodec? = null,
            private val defaultHttpHeaderProvider: DefaultHttpHeaderProvider = DefaultHttpHeaderProvider { emptyMap() },
            private val errorFlow: MutableSharedFlow<ApiError> = MutableSharedFlow(extraBufferCapacity = 64),
            private val json: Json = Json { ignoreUnknownKeys = true },
        ) : RestClient {
            private val bodyCodec: BodyCodec = bodyCodec ?: JsonBodyCodec(json)
            private val transport = Retrofit.Builder()
                .baseUrl("https://localhost/")
                .client(httpClient)
                .build()
                .create(RetrofitTransport::class.java)

            override val errors: SharedFlow<ApiError> = errorFlow

            override suspend fun apiKey(): String? = apiKeyProvider.apiKey()?.takeIf { it.isNotBlank() }

            override suspend fun requireApiKey(): String = apiKey() ?: throwError(ApiError.ApiKeyRequired)

            override suspend fun execute(
                request: ApiRequestConvertible,
                validStatusCodes: Set<Int>,
            ): ApiResponse = executeRaw(request.toApiRequest(), validStatusCodes)

            override suspend fun <T> execute(
                request: ApiRequestConvertible,
                responseType: ApiResponseType<T>,
                validStatusCodes: Set<Int>,
            ): ApiOperationResult<T> {
                val response = executeRaw(request.toApiRequest(), validStatusCodes)
                return ApiOperationResult(decode(response, responseType), response)
            }

            override suspend fun upload(
                request: ApiRequestConvertible,
                progress: ApiProgress?,
                validStatusCodes: Set<Int>,
            ): ApiResponse = executeRaw(request.toApiRequest(), validStatusCodes, progress)

            override suspend fun <T> upload(
                request: ApiRequestConvertible,
                progress: ApiProgress?,
                responseType: ApiResponseType<T>,
                validStatusCodes: Set<Int>,
            ): ApiOperationResult<T> {
                val response = upload(request, progress, validStatusCodes)
                return ApiOperationResult(decode(response, responseType), response)
            }

            override suspend fun postMultipart(
                request: ApiRequestConvertible,
                progress: ApiProgress?,
                validStatusCodes: Set<Int>,
            ): ApiResponse = executeRaw(request.toApiRequest(), validStatusCodes, progress)

            override suspend fun <T> postMultipart(
                request: ApiRequestConvertible,
                progress: ApiProgress?,
                responseType: ApiResponseType<T>,
                validStatusCodes: Set<Int>,
            ): ApiOperationResult<T> {
                val response = postMultipart(request, progress, validStatusCodes)
                return ApiOperationResult(decode(response, responseType), response)
            }

            private suspend fun <T> decode(response: ApiResponse, responseType: ApiResponseType<T>): T =
                try {
                    bodyCodec.decode(response, responseType)
                } catch (error: CancellationException) {
                    throw error
                } catch (error: Exception) {
                    throwError(ApiError.Decoding(error))
                }

            private suspend fun executeRaw(
                apiRequest: ApiRequest,
                validStatusCodes: Set<Int>,
                progress: ApiProgress? = null,
            ): ApiResponse = withContext(Dispatchers.IO) {
                val uploads = UploadStreams()
                try {
                    val url = resolveUrl(apiRequest.path).toHttpUrlOrNull()?.newBuilder()
                        ?: throw ApiError.InvalidUrl
                    apiRequest.queryParameters.forEach { (name, value) -> url.addQueryParameter(name, value) }
                    val headers = linkedMapOf<String, String>()
                    fun addHeader(name: String, value: String) {
                        headers.keys.firstOrNull { it.equals(name, ignoreCase = true) }?.let { headers.remove(it) }
                        headers[name] = value
                    }
                    defaultHttpHeaderProvider.headers().forEach { (name, value) -> addHeader(name, value) }
                    apiRequest.headers.forEach { (name, value) -> addHeader(name, value) }
                    if (headers.keys.none { it.equals("Accept", ignoreCase = true) }) addHeader("Accept", apiRequest.accept)
                    val target = url.build().toString()
                    val method = apiRequest.method.uppercase()
                    val body = if (method in setOf("GET", "HEAD")) {
                        require(apiRequest.body == null) { "$method requests cannot have a body" }
                        null
                    } else {
                        applyBody(apiRequest, uploads).let { if (progress == null) it else ProgressRequestBody(it, progress) }
                    }
                    val raw = when (method) {
                        "GET" -> transport.get(target, headers)
                        "HEAD" -> transport.head(target, headers)
                        "POST" -> transport.post(target, headers, requireNotNull(body))
                        "PUT" -> transport.put(target, headers, requireNotNull(body))
                        "PATCH" -> transport.patch(target, headers, requireNotNull(body))
                        "DELETE" -> transport.delete(target, headers, requireNotNull(body))
                        "OPTIONS" -> transport.options(target, headers, requireNotNull(body))
                        else -> throw IllegalArgumentException("Unsupported HTTP method: $method")
                    }
                    val responseBody = raw.body() ?: raw.errorBody()
                    val response = responseBody.use {
                        ApiResponse(
                            statusCode = raw.code(),
                            headers = raw.headers().toMultimap(),
                            mimeType = raw.headers()["Content-Type"],
                            body = runInterruptible { it?.bytes() ?: byteArrayOf() },
                        )
                    }
                    if (response.statusCode !in validStatusCodes) throw ApiError.UnexpectedStatusCode(response.statusCode, response)
                    response
                } catch (error: CancellationException) {
                    throw error
                } catch (error: ApiError) {
                    throwError(error)
                } catch (error: IOException) {
                    throwError(ApiError.Transport(error))
                } catch (error: Exception) {
                    throwError(ApiError.InvalidRequest(error))
                } finally {
                    uploads.close()
                }
            }

            private suspend fun throwError(error: ApiError): Nothing {
                errorFlow.emit(error)
                throw error
            }

            private suspend fun resolveUrl(path: ApiRequestPath): String =
                when (path) {
                    is ApiRequestPath.Absolute -> path.url
                    is ApiRequestPath.Runtime -> path.requestUrl
                    is ApiRequestPath.Relative -> baseUrlProvider.baseUrl().trimEnd('/') + "/" + path.path.trimStart('/')
                }

            private fun applyBody(request: ApiRequest, uploads: UploadStreams): RequestBody {
                val contentType = (request.contentType ?: "application/octet-stream").toMediaType()
                return when (val body = request.body) {
                    null -> byteArrayOf().toRequestBody(request.contentType?.toMediaType())
                    is ApiUploadSource -> UploadRequestBody(body, contentType, uploads)
                    is ApiFileContent -> UploadRequestBody(body.source, body.contentType.toMediaType(), uploads)
                    is MultipartBody -> okhttp3.MultipartBody.Builder().setType(okhttp3.MultipartBody.FORM).apply {
                        body.parts.forEach { (name, part) ->
                            addFormDataPart(name, part.fileName, UploadRequestBody(part.source, (part.contentType ?: "application/octet-stream").toMediaType(), uploads))
                        }
                    }.build()
                    is ByteArray -> if (request.bodyType == null) body.toRequestBody(contentType) else
                        json.encodeToString(ByteArrayBase64Serializer, body).toRequestBody((request.contentType ?: "application/json").toMediaType())
                    else -> json.encodeToString(request.bodyType ?: throw ApiError.RequestEncodingFailed, body)
                        .toRequestBody((request.contentType ?: "application/json").toMediaType())
                }
            }
        }

        private class UploadStreams {
            private val streams = mutableSetOf<InputStream>()
            private var closed = false

            @Synchronized
            fun register(stream: InputStream) {
                if (closed) {
                    stream.close()
                    throw IOException("Upload was cancelled")
                }
                streams.add(stream)
            }

            @Synchronized
            fun remove(stream: InputStream) {
                streams.remove(stream)
            }

            fun close() {
                val active = synchronized(this) {
                    closed = true
                    streams.toList().also { streams.clear() }
                }
                active.forEach { runCatching { it.close() } }
            }
        }

        private class UploadRequestBody(
            private val source: ApiUploadSource,
            private val mediaType: okhttp3.MediaType,
            private val uploads: UploadStreams,
        ) : RequestBody() {
            override fun contentType(): okhttp3.MediaType = mediaType

            override fun contentLength(): Long = try {
                when (source) {
                    is ApiUploadSource.Bytes -> source.bytes.size.toLong()
                    is ApiUploadSource.FileSource -> source.file.length()
                    is ApiUploadSource.ContentUri -> -1L
                }
            } catch (error: Exception) {
                throw IOException("Upload length could not be read", error)
            }

            override fun writeTo(sink: BufferedSink) {
                try {
                    val stream: InputStream = when (source) {
                        is ApiUploadSource.Bytes -> source.bytes.inputStream()
                        is ApiUploadSource.FileSource -> source.file.inputStream()
                        is ApiUploadSource.ContentUri -> source.contentResolver.openInputStream(source.uri)
                            ?: throw IOException("Content URI could not be opened: ${source.uri}")
                    }
                    uploads.register(stream)
                    try {
                        stream.use { sink.writeAll(it.source()) }
                    } finally {
                        uploads.remove(stream)
                    }
                } catch (error: IOException) {
                    throw error
                } catch (error: Exception) {
                    throw IOException("Upload source failed", error)
                }
            }
        }

        private class ProgressRequestBody(
            private val delegate: RequestBody,
            private val progress: ApiProgress,
        ) : RequestBody() {
            override fun contentType(): okhttp3.MediaType? = delegate.contentType()
            override fun contentLength(): Long = delegate.contentLength()

            override fun writeTo(sink: BufferedSink) {
                try {
                    var sent = 0L
                    val total = contentLength().takeIf { it >= 0 }
                    val counting = object : ForwardingSink(sink) {
                        override fun write(source: okio.Buffer, byteCount: Long) {
                            super.write(source, byteCount)
                            sent += byteCount
                            progress.update(sent, total)
                        }
                    }.buffer()
                    progress.update(0, total)
                    delegate.writeTo(counting)
                    counting.flush()
                } catch (error: IOException) {
                    throw error
                } catch (error: Exception) {
                    throw IOException("Upload progress callback failed", error)
                }
            }
        }

        fun Any?.toApiFormValue(): String =
            when (this) {
                null -> ""
                is Iterable<*> -> joinToString(",") { it.toApiFormValue() }
                is Array<*> -> joinToString(",") { it.toApiFormValue() }
                is Instant -> toApiDateTimeValue()
                is LocalDate -> toString()
                is LocalTime -> toString()
                is Boolean -> toString()
                else -> toString()
            }

        private fun Instant.toApiDateTimeValue(): String =
            toString()

        fun Any?.toApiPathSegment(): String = encodeURLPathPart(toApiFormValue())

        private fun encodeURLPathPart(value: String): String =
            buildString {
                for (byte in value.encodeToByteArray()) {
                    val code = byte.toInt().and(0xff)
                    val char = code.toChar()
                    when {
                        char in 'A'..'Z' || char in 'a'..'z' || char in '0'..'9' || char in "-._~" -> append(char)
                        else -> {
                            append('%')
                            append(code.toString(16).uppercase().padStart(2, '0'))
                        }
                    }
                }
            }

        fun Map<String, String>.toCookieHeader(): String? =
            entries
                .sortedBy { it.key }
                .joinToString("; ") { (name, value) ->
                    "${name.toApiPathSegment()}=${value.toApiPathSegment()}"
                }.takeIf { it.isNotBlank() }

        private fun String.toMultipartHeaderValue(): String =
            replace("\\\\", "\\\\\\\\")
                .replace("\\"", "\\\\\\"")
                .replace("\\r", "%0D")
                .replace("\\n", "%0A")
        """
    }
}
