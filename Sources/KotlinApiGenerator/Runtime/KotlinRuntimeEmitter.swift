import Foundation
import GeneratorBuilder

struct KotlinRuntimeEmitter {
    func kotlinCode(packageName: String? = nil) -> any Node {
        KotlinFileEmitter.renderNode(
            packageName: packageName,
            imports: [
                "io.ktor.client.HttpClient",
                "io.ktor.client.plugins.expectSuccess",
                "io.ktor.client.plugins.onUpload",
                "io.ktor.client.request.forms.MultiPartFormDataContent",
                "io.ktor.client.request.forms.formData",
                "io.ktor.client.request.HttpRequestBuilder",
                "io.ktor.client.request.header",
                "io.ktor.client.request.request",
                "io.ktor.client.request.setBody",
                "io.ktor.client.statement.bodyAsBytes",
                "io.ktor.http.ContentType",
                "io.ktor.http.Headers",
                "io.ktor.http.HttpMethod",
                "io.ktor.http.content.ByteArrayContent",
                "io.ktor.http.contentType",
                "io.ktor.http.takeFrom",
                "io.ktor.util.reflect.TypeInfo",
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
            body: runtimeDeclaration,
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
            val bytes: ByteArray,
            val fileName: String? = null,
            val contentType: String = "application/octet-stream",
        ) {
            override fun equals(other: Any?): Boolean {
                if (this === other) return true
                if (other !is ApiFileContent) return false
                if (!bytes.contentEquals(other.bytes)) return false
                if (fileName != other.fileName) return false
                if (contentType != other.contentType) return false
                return true
            }

            override fun hashCode(): Int {
                var result = bytes.contentHashCode()
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
            val bodyType: TypeInfo? = null,
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

        sealed class ApiError(message: String) : Exception(message) {
            data object ApiKeyRequired : ApiError("API key is required")
            data object InvalidUrl : ApiError("Invalid URL")
            data object RequestEncodingFailed : ApiError("Request encoding failed")
            data class UnexpectedStatusCode(val statusCode: Int) : ApiError("Unexpected HTTP status $statusCode")
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
                val bytes: ByteArray,
            ) {
                override fun equals(other: Any?): Boolean {
                    if (this === other) return true
                    if (other !is Part) return false
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

        class KtorRestClient(
            private val httpClient: HttpClient,
            private val baseUrlProvider: BaseUrlProvider,
            private val apiKeyProvider: ApiKeyProvider,
            private val bodyCodec: BodyCodec,
            private val defaultHttpHeaderProvider: DefaultHttpHeaderProvider = DefaultHttpHeaderProvider { emptyMap() },
            private val errorFlow: MutableSharedFlow<ApiError> = MutableSharedFlow(extraBufferCapacity = 64),
        ) : RestClient {
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
                return ApiOperationResult(bodyCodec.decode(response, responseType), response)
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
                return ApiOperationResult(bodyCodec.decode(response, responseType), response)
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
                return ApiOperationResult(bodyCodec.decode(response, responseType), response)
            }

            private suspend fun executeRaw(
                apiRequest: ApiRequest,
                validStatusCodes: Set<Int>,
                progress: ApiProgress? = null,
            ): ApiResponse {
                val effectiveHeaders = defaultHttpHeaderProvider.headers() + apiRequest.headers
                val ktorResponse =
                    httpClient.request {
                        expectSuccess = false
                        method = HttpMethod(apiRequest.method)
                        url.takeFrom(resolveUrl(apiRequest.path))
                        for ((name, value) in apiRequest.queryParameters) {
                            url.parameters.append(name, value)
                        }
                        for ((name, value) in effectiveHeaders) {
                            header(name, value)
                        }
                        if (effectiveHeaders.keys.none { it.equals("Accept", ignoreCase = true) }) {
                            header("Accept", apiRequest.accept)
                        }
                        progress?.let { uploadProgress ->
                            onUpload { bytesSent, totalBytes ->
                                uploadProgress.update(bytesSent, totalBytes)
                            }
                        }
                        applyBody(apiRequest)
                    }
                val statusCode = ktorResponse.status.value
                if (statusCode !in validStatusCodes) {
                    throwError(ApiError.UnexpectedStatusCode(statusCode))
                }
                return ApiResponse(
                    statusCode = statusCode,
                    headers = ktorResponse.headers.entries().associate { it.key to it.value },
                    mimeType = ktorResponse.headers["Content-Type"],
                    body = ktorResponse.bodyAsBytes(),
                )
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

            @OptIn(ExperimentalEncodingApi::class)
            private fun HttpRequestBuilder.applyBody(request: ApiRequest) {
                request.contentType?.let { contentType(ContentType.parse(it)) }
                when (val body = request.body) {
                    null -> Unit
                    is ByteArray ->
                        if (request.bodyType != null) {
                            setBody(
                                ByteArrayContent(
                                    ("\\\"" + Base64.Default.encode(body) + "\\\"").encodeToByteArray(),
                                    ContentType.parse(request.contentType ?: "application/json"),
                                ),
                            )
                        } else {
                            setBody(
                                ByteArrayContent(
                                    body,
                                    ContentType.parse(request.contentType ?: "application/octet-stream"),
                                ),
                            )
                        }
                    is ApiFileContent -> setBody(ByteArrayContent(body.bytes, ContentType.parse(body.contentType)))
                    is MultipartBody ->
                        setBody(
                            MultiPartFormDataContent(
                                formData {
                                    body.parts.forEach { (name, value) ->
                                        val partHeaders =
                                            Headers.build {
                                                append(
                                                    "Content-Disposition",
                                                    buildString {
                                                        append("form-data; name=\\"")
                                                        append(name.toMultipartHeaderValue())
                                                        append("\\"")
                                                        value.fileName?.let {
                                                            append("; filename=\\"")
                                                            append(it.toMultipartHeaderValue())
                                                            append("\\"")
                                                        }
                                                    },
                                                )
                                                value.contentType?.let { append("Content-Type", it) }
                                            }
                                        append(
                                            key = name,
                                            value = value.bytes,
                                            headers = partHeaders,
                                        )
                                    }
                                },
                            ),
                        )
                    else -> request.bodyType?.let { setBody(body, it) } ?: setBody(body)
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
