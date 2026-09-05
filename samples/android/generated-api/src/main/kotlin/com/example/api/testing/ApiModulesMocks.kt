// Generated code. Do not edit.
package com.example.api.testing

import com.example.api.AdminApiModule
import com.example.api.ApiModules
import com.example.api.ApiOperationResult
import com.example.api.ApiProgress
import com.example.api.ApiResponse
import com.example.api.ApiUploadSource
import com.example.api.LocationApiModule
import com.example.api.MultipartBody
import com.example.api.PagedResults
import com.example.api.ShowcaseApiModule
import com.example.api.TenantApiModule
import com.example.api.admin.group.AdminGroupApi
import com.example.api.admin.role.AdminRoleApi
import com.example.api.admin.user.AdminUserApi
import com.example.api.location.structure.LocationStructureApi
import com.example.api.showcase.samplemodels.ShowcaseSampleModelsApi
import com.example.api.showcase.transport.ShowcaseTransportApi
import com.example.api.tenant.project.TenantProjectApi
import com.example.api.tenant.projecttask.TenantProjectTaskApi

class AdminUserApiMock : AdminUserApi {
    val createCalls = mutableListOf<com.example.api.admin.user.CreateOperation.Request>()

    var createHandler: suspend (com.example.api.admin.user.CreateOperation.Request) -> ApiOperationResult<com.example.api.admin.user.models.IdUser> = {
        error("No mock handler for create")
    }

    override suspend fun create(
        body: com.example.api.admin.user.models.User,
    ): ApiOperationResult<com.example.api.admin.user.models.IdUser> {
            val request = com.example.api.admin.user.CreateOperation.Request(body = body)
        createCalls += request
        return createHandler(request)
    }

    val updateCalls = mutableListOf<com.example.api.admin.user.UpdateOperation.Request>()

    var updateHandler: suspend (com.example.api.admin.user.UpdateOperation.Request) -> ApiOperationResult<com.example.api.admin.user.models.IdUser> = {
        error("No mock handler for update")
    }

    override suspend fun update(
        userId: Long,
        body: com.example.api.admin.user.models.User,
    ): ApiOperationResult<com.example.api.admin.user.models.IdUser> {
            val request = com.example.api.admin.user.UpdateOperation.Request(userId = userId, body = body)
        updateCalls += request
        return updateHandler(request)
    }

    val patchCalls = mutableListOf<com.example.api.admin.user.PatchOperation.Request>()

    var patchHandler: suspend (com.example.api.admin.user.PatchOperation.Request) -> ApiOperationResult<com.example.api.admin.user.models.IdUser> = {
        error("No mock handler for patch")
    }

    override suspend fun patch(
        userId: Long,
        body: com.example.api.admin.user.models.PatchedUser,
    ): ApiOperationResult<com.example.api.admin.user.models.IdUser> {
            val request = com.example.api.admin.user.PatchOperation.Request(userId = userId, body = body)
        patchCalls += request
        return patchHandler(request)
    }

    val deleteCalls = mutableListOf<com.example.api.admin.user.DeleteOperation.Request>()

    var deleteHandler: suspend (com.example.api.admin.user.DeleteOperation.Request) -> ApiResponse = {
        error("No mock handler for delete")
    }

    override suspend fun delete(
        userId: Long,
    ): ApiResponse {
            val request = com.example.api.admin.user.DeleteOperation.Request(userId = userId)
        deleteCalls += request
        return deleteHandler(request)
    }

    val listCalls = mutableListOf<com.example.api.admin.user.ListOperation.Request>()

    var listHandler: suspend (com.example.api.admin.user.ListOperation.Request) -> ApiOperationResult<PagedResults<com.example.api.admin.user.models.IdentifiedUser>> = {
        error("No mock handler for list")
    }

    override suspend fun list(
        text: String?,
    ): ApiOperationResult<PagedResults<com.example.api.admin.user.models.IdentifiedUser>> {
            val request = com.example.api.admin.user.ListOperation.Request(text = text)
        listCalls += request
        return listHandler(request)
    }

    val getCalls = mutableListOf<com.example.api.admin.user.GetOperation.Request>()

    var getHandler: suspend (com.example.api.admin.user.GetOperation.Request) -> ApiOperationResult<com.example.api.admin.user.models.IdentifiedUser> = {
        error("No mock handler for `get`")
    }

    override suspend fun `get`(
        userId: Long,
    ): ApiOperationResult<com.example.api.admin.user.models.IdentifiedUser> {
            val request = com.example.api.admin.user.GetOperation.Request(userId = userId)
        getCalls += request
        return getHandler(request)
    }

    data class GetNextPageForListOperationCall(
        val currentPage: PagedResults<com.example.api.admin.user.models.IdentifiedUser>,
        val request: com.example.api.admin.user.ListOperation.Request,
    )
    val getNextPageForListOperationCalls = mutableListOf<GetNextPageForListOperationCall>()

    var getNextPageForListOperationHandler: suspend (
        PagedResults<com.example.api.admin.user.models.IdentifiedUser>,
        com.example.api.admin.user.ListOperation.Request,
    ) -> ApiOperationResult<PagedResults<com.example.api.admin.user.models.IdentifiedUser>> = { _, _ ->
        error("No mock handler for getNextPage")
    }

    override suspend fun getNextPageForListOperation(
        currentPage: PagedResults<com.example.api.admin.user.models.IdentifiedUser>,
        text: String?,
    ): ApiOperationResult<PagedResults<com.example.api.admin.user.models.IdentifiedUser>> {
        val request = com.example.api.admin.user.ListOperation.Request(text = text)
        getNextPageForListOperationCalls += GetNextPageForListOperationCall(currentPage, request)
        return getNextPageForListOperationHandler(currentPage, request)
    }

    fun resetMock() {
        createCalls.clear()
        createHandler = { error("No mock handler for create") }
        updateCalls.clear()
        updateHandler = { error("No mock handler for update") }
        patchCalls.clear()
        patchHandler = { error("No mock handler for patch") }
        deleteCalls.clear()
        deleteHandler = { error("No mock handler for delete") }
        listCalls.clear()
        listHandler = { error("No mock handler for list") }
        getNextPageForListOperationCalls.clear()
        getNextPageForListOperationHandler = { _, _ -> error("No mock handler for getNextPage") }
        getCalls.clear()
        getHandler = { error("No mock handler for `get`") }
    }
}

class AdminRoleApiMock : AdminRoleApi {
    val createCalls = mutableListOf<com.example.api.admin.role.CreateOperation.Request>()

    var createHandler: suspend (com.example.api.admin.role.CreateOperation.Request) -> ApiOperationResult<com.example.api.admin.role.models.IdRole> = {
        error("No mock handler for create")
    }

    override suspend fun create(
        body: com.example.api.admin.role.models.Role,
    ): ApiOperationResult<com.example.api.admin.role.models.IdRole> {
            val request = com.example.api.admin.role.CreateOperation.Request(body = body)
        createCalls += request
        return createHandler(request)
    }

    val updateCalls = mutableListOf<com.example.api.admin.role.UpdateOperation.Request>()

    var updateHandler: suspend (com.example.api.admin.role.UpdateOperation.Request) -> ApiOperationResult<com.example.api.admin.role.models.IdRole> = {
        error("No mock handler for update")
    }

    override suspend fun update(
        roleId: Long,
        body: com.example.api.admin.role.models.Role,
    ): ApiOperationResult<com.example.api.admin.role.models.IdRole> {
            val request = com.example.api.admin.role.UpdateOperation.Request(roleId = roleId, body = body)
        updateCalls += request
        return updateHandler(request)
    }

    val patchCalls = mutableListOf<com.example.api.admin.role.PatchOperation.Request>()

    var patchHandler: suspend (com.example.api.admin.role.PatchOperation.Request) -> ApiOperationResult<com.example.api.admin.role.models.IdRole> = {
        error("No mock handler for patch")
    }

    override suspend fun patch(
        roleId: Long,
        body: com.example.api.admin.role.models.PatchedRole,
    ): ApiOperationResult<com.example.api.admin.role.models.IdRole> {
            val request = com.example.api.admin.role.PatchOperation.Request(roleId = roleId, body = body)
        patchCalls += request
        return patchHandler(request)
    }

    val deleteCalls = mutableListOf<com.example.api.admin.role.DeleteOperation.Request>()

    var deleteHandler: suspend (com.example.api.admin.role.DeleteOperation.Request) -> ApiResponse = {
        error("No mock handler for delete")
    }

    override suspend fun delete(
        roleId: Long,
    ): ApiResponse {
            val request = com.example.api.admin.role.DeleteOperation.Request(roleId = roleId)
        deleteCalls += request
        return deleteHandler(request)
    }

    val listCalls = mutableListOf<com.example.api.admin.role.ListOperation.Request>()

    var listHandler: suspend (com.example.api.admin.role.ListOperation.Request) -> ApiOperationResult<PagedResults<com.example.api.admin.role.models.IdentifiedRole>> = {
        error("No mock handler for list")
    }

    override suspend fun list(
        text: String?,
    ): ApiOperationResult<PagedResults<com.example.api.admin.role.models.IdentifiedRole>> {
            val request = com.example.api.admin.role.ListOperation.Request(text = text)
        listCalls += request
        return listHandler(request)
    }

    val getCalls = mutableListOf<com.example.api.admin.role.GetOperation.Request>()

    var getHandler: suspend (com.example.api.admin.role.GetOperation.Request) -> ApiOperationResult<com.example.api.admin.role.models.IdentifiedRole> = {
        error("No mock handler for `get`")
    }

    override suspend fun `get`(
        roleId: Long,
    ): ApiOperationResult<com.example.api.admin.role.models.IdentifiedRole> {
            val request = com.example.api.admin.role.GetOperation.Request(roleId = roleId)
        getCalls += request
        return getHandler(request)
    }

    data class GetNextPageForListOperationCall(
        val currentPage: PagedResults<com.example.api.admin.role.models.IdentifiedRole>,
        val request: com.example.api.admin.role.ListOperation.Request,
    )
    val getNextPageForListOperationCalls = mutableListOf<GetNextPageForListOperationCall>()

    var getNextPageForListOperationHandler: suspend (
        PagedResults<com.example.api.admin.role.models.IdentifiedRole>,
        com.example.api.admin.role.ListOperation.Request,
    ) -> ApiOperationResult<PagedResults<com.example.api.admin.role.models.IdentifiedRole>> = { _, _ ->
        error("No mock handler for getNextPage")
    }

    override suspend fun getNextPageForListOperation(
        currentPage: PagedResults<com.example.api.admin.role.models.IdentifiedRole>,
        text: String?,
    ): ApiOperationResult<PagedResults<com.example.api.admin.role.models.IdentifiedRole>> {
        val request = com.example.api.admin.role.ListOperation.Request(text = text)
        getNextPageForListOperationCalls += GetNextPageForListOperationCall(currentPage, request)
        return getNextPageForListOperationHandler(currentPage, request)
    }

    fun resetMock() {
        createCalls.clear()
        createHandler = { error("No mock handler for create") }
        updateCalls.clear()
        updateHandler = { error("No mock handler for update") }
        patchCalls.clear()
        patchHandler = { error("No mock handler for patch") }
        deleteCalls.clear()
        deleteHandler = { error("No mock handler for delete") }
        listCalls.clear()
        listHandler = { error("No mock handler for list") }
        getNextPageForListOperationCalls.clear()
        getNextPageForListOperationHandler = { _, _ -> error("No mock handler for getNextPage") }
        getCalls.clear()
        getHandler = { error("No mock handler for `get`") }
    }
}

class AdminGroupApiMock : AdminGroupApi {
    val createCalls = mutableListOf<com.example.api.admin.group.CreateOperation.Request>()

    var createHandler: suspend (com.example.api.admin.group.CreateOperation.Request) -> ApiOperationResult<com.example.api.admin.group.models.IdGroup> = {
        error("No mock handler for create")
    }

    override suspend fun create(
        body: com.example.api.admin.group.models.Group,
    ): ApiOperationResult<com.example.api.admin.group.models.IdGroup> {
            val request = com.example.api.admin.group.CreateOperation.Request(body = body)
        createCalls += request
        return createHandler(request)
    }

    val updateCalls = mutableListOf<com.example.api.admin.group.UpdateOperation.Request>()

    var updateHandler: suspend (com.example.api.admin.group.UpdateOperation.Request) -> ApiOperationResult<com.example.api.admin.group.models.IdGroup> = {
        error("No mock handler for update")
    }

    override suspend fun update(
        groupId: Long,
        body: com.example.api.admin.group.models.Group,
    ): ApiOperationResult<com.example.api.admin.group.models.IdGroup> {
            val request = com.example.api.admin.group.UpdateOperation.Request(groupId = groupId, body = body)
        updateCalls += request
        return updateHandler(request)
    }

    val patchCalls = mutableListOf<com.example.api.admin.group.PatchOperation.Request>()

    var patchHandler: suspend (com.example.api.admin.group.PatchOperation.Request) -> ApiOperationResult<com.example.api.admin.group.models.IdGroup> = {
        error("No mock handler for patch")
    }

    override suspend fun patch(
        groupId: Long,
        body: com.example.api.admin.group.models.PatchedGroup,
    ): ApiOperationResult<com.example.api.admin.group.models.IdGroup> {
            val request = com.example.api.admin.group.PatchOperation.Request(groupId = groupId, body = body)
        patchCalls += request
        return patchHandler(request)
    }

    val deleteCalls = mutableListOf<com.example.api.admin.group.DeleteOperation.Request>()

    var deleteHandler: suspend (com.example.api.admin.group.DeleteOperation.Request) -> ApiResponse = {
        error("No mock handler for delete")
    }

    override suspend fun delete(
        groupId: Long,
    ): ApiResponse {
            val request = com.example.api.admin.group.DeleteOperation.Request(groupId = groupId)
        deleteCalls += request
        return deleteHandler(request)
    }

    val listCalls = mutableListOf<com.example.api.admin.group.ListOperation.Request>()

    var listHandler: suspend (com.example.api.admin.group.ListOperation.Request) -> ApiOperationResult<PagedResults<com.example.api.admin.group.models.IdentifiedGroup>> = {
        error("No mock handler for list")
    }

    override suspend fun list(
        text: String?,
    ): ApiOperationResult<PagedResults<com.example.api.admin.group.models.IdentifiedGroup>> {
            val request = com.example.api.admin.group.ListOperation.Request(text = text)
        listCalls += request
        return listHandler(request)
    }

    val getCalls = mutableListOf<com.example.api.admin.group.GetOperation.Request>()

    var getHandler: suspend (com.example.api.admin.group.GetOperation.Request) -> ApiOperationResult<com.example.api.admin.group.models.IdentifiedGroup> = {
        error("No mock handler for `get`")
    }

    override suspend fun `get`(
        groupId: Long,
    ): ApiOperationResult<com.example.api.admin.group.models.IdentifiedGroup> {
            val request = com.example.api.admin.group.GetOperation.Request(groupId = groupId)
        getCalls += request
        return getHandler(request)
    }

    data class GetNextPageForListOperationCall(
        val currentPage: PagedResults<com.example.api.admin.group.models.IdentifiedGroup>,
        val request: com.example.api.admin.group.ListOperation.Request,
    )
    val getNextPageForListOperationCalls = mutableListOf<GetNextPageForListOperationCall>()

    var getNextPageForListOperationHandler: suspend (
        PagedResults<com.example.api.admin.group.models.IdentifiedGroup>,
        com.example.api.admin.group.ListOperation.Request,
    ) -> ApiOperationResult<PagedResults<com.example.api.admin.group.models.IdentifiedGroup>> = { _, _ ->
        error("No mock handler for getNextPage")
    }

    override suspend fun getNextPageForListOperation(
        currentPage: PagedResults<com.example.api.admin.group.models.IdentifiedGroup>,
        text: String?,
    ): ApiOperationResult<PagedResults<com.example.api.admin.group.models.IdentifiedGroup>> {
        val request = com.example.api.admin.group.ListOperation.Request(text = text)
        getNextPageForListOperationCalls += GetNextPageForListOperationCall(currentPage, request)
        return getNextPageForListOperationHandler(currentPage, request)
    }

    fun resetMock() {
        createCalls.clear()
        createHandler = { error("No mock handler for create") }
        updateCalls.clear()
        updateHandler = { error("No mock handler for update") }
        patchCalls.clear()
        patchHandler = { error("No mock handler for patch") }
        deleteCalls.clear()
        deleteHandler = { error("No mock handler for delete") }
        listCalls.clear()
        listHandler = { error("No mock handler for list") }
        getNextPageForListOperationCalls.clear()
        getNextPageForListOperationHandler = { _, _ -> error("No mock handler for getNextPage") }
        getCalls.clear()
        getHandler = { error("No mock handler for `get`") }
    }
}

class LocationStructureApiMock : LocationStructureApi {
    val createCalls = mutableListOf<com.example.api.location.structure.CreateOperation.Request>()

    var createHandler: suspend (com.example.api.location.structure.CreateOperation.Request) -> ApiOperationResult<com.example.api.location.structure.models.IdStructure> = {
        error("No mock handler for create")
    }

    override suspend fun create(
        body: com.example.api.location.structure.models.Structure,
    ): ApiOperationResult<com.example.api.location.structure.models.IdStructure> {
            val request = com.example.api.location.structure.CreateOperation.Request(body = body)
        createCalls += request
        return createHandler(request)
    }

    val updateCalls = mutableListOf<com.example.api.location.structure.UpdateOperation.Request>()

    var updateHandler: suspend (com.example.api.location.structure.UpdateOperation.Request) -> ApiOperationResult<com.example.api.location.structure.models.IdStructure> = {
        error("No mock handler for update")
    }

    override suspend fun update(
        structureId: Long,
        body: com.example.api.location.structure.models.Structure,
    ): ApiOperationResult<com.example.api.location.structure.models.IdStructure> {
            val request = com.example.api.location.structure.UpdateOperation.Request(structureId = structureId, body = body)
        updateCalls += request
        return updateHandler(request)
    }

    val patchCalls = mutableListOf<com.example.api.location.structure.PatchOperation.Request>()

    var patchHandler: suspend (com.example.api.location.structure.PatchOperation.Request) -> ApiOperationResult<com.example.api.location.structure.models.IdStructure> = {
        error("No mock handler for patch")
    }

    override suspend fun patch(
        structureId: Long,
        body: com.example.api.location.structure.models.PatchedStructure,
    ): ApiOperationResult<com.example.api.location.structure.models.IdStructure> {
            val request = com.example.api.location.structure.PatchOperation.Request(structureId = structureId, body = body)
        patchCalls += request
        return patchHandler(request)
    }

    val deleteCalls = mutableListOf<com.example.api.location.structure.DeleteOperation.Request>()

    var deleteHandler: suspend (com.example.api.location.structure.DeleteOperation.Request) -> ApiResponse = {
        error("No mock handler for delete")
    }

    override suspend fun delete(
        structureId: Long,
    ): ApiResponse {
            val request = com.example.api.location.structure.DeleteOperation.Request(structureId = structureId)
        deleteCalls += request
        return deleteHandler(request)
    }

    val listCalls = mutableListOf<com.example.api.location.structure.ListOperation.Request>()

    var listHandler: suspend (com.example.api.location.structure.ListOperation.Request) -> ApiOperationResult<PagedResults<com.example.api.location.structure.models.IdentifiedStructure>> = {
        error("No mock handler for list")
    }

    override suspend fun list(
        text: String?,
        type: List<com.example.api.StructureType>,
    ): ApiOperationResult<PagedResults<com.example.api.location.structure.models.IdentifiedStructure>> {
            val request = com.example.api.location.structure.ListOperation.Request(text = text, type = type)
        listCalls += request
        return listHandler(request)
    }

    val getCalls = mutableListOf<com.example.api.location.structure.GetOperation.Request>()

    var getHandler: suspend (com.example.api.location.structure.GetOperation.Request) -> ApiOperationResult<com.example.api.location.structure.models.IdentifiedStructure> = {
        error("No mock handler for `get`")
    }

    override suspend fun `get`(
        structureId: Long,
    ): ApiOperationResult<com.example.api.location.structure.models.IdentifiedStructure> {
            val request = com.example.api.location.structure.GetOperation.Request(structureId = structureId)
        getCalls += request
        return getHandler(request)
    }

    data class GetNextPageForListOperationCall(
        val currentPage: PagedResults<com.example.api.location.structure.models.IdentifiedStructure>,
        val request: com.example.api.location.structure.ListOperation.Request,
    )
    val getNextPageForListOperationCalls = mutableListOf<GetNextPageForListOperationCall>()

    var getNextPageForListOperationHandler: suspend (
        PagedResults<com.example.api.location.structure.models.IdentifiedStructure>,
        com.example.api.location.structure.ListOperation.Request,
    ) -> ApiOperationResult<PagedResults<com.example.api.location.structure.models.IdentifiedStructure>> = { _, _ ->
        error("No mock handler for getNextPage")
    }

    override suspend fun getNextPageForListOperation(
        currentPage: PagedResults<com.example.api.location.structure.models.IdentifiedStructure>,
        text: String?,
        type: List<com.example.api.StructureType>,
    ): ApiOperationResult<PagedResults<com.example.api.location.structure.models.IdentifiedStructure>> {
        val request = com.example.api.location.structure.ListOperation.Request(text = text, type = type)
        getNextPageForListOperationCalls += GetNextPageForListOperationCall(currentPage, request)
        return getNextPageForListOperationHandler(currentPage, request)
    }

    fun resetMock() {
        createCalls.clear()
        createHandler = { error("No mock handler for create") }
        updateCalls.clear()
        updateHandler = { error("No mock handler for update") }
        patchCalls.clear()
        patchHandler = { error("No mock handler for patch") }
        deleteCalls.clear()
        deleteHandler = { error("No mock handler for delete") }
        listCalls.clear()
        listHandler = { error("No mock handler for list") }
        getNextPageForListOperationCalls.clear()
        getNextPageForListOperationHandler = { _, _ -> error("No mock handler for getNextPage") }
        getCalls.clear()
        getHandler = { error("No mock handler for `get`") }
    }
}

class ShowcaseSampleModelsApiMock : ShowcaseSampleModelsApi {
    val getMatrixCalls = mutableListOf<com.example.api.showcase.samplemodels.GetMatrixOperation.Request>()

    var getMatrixHandler: suspend (com.example.api.showcase.samplemodels.GetMatrixOperation.Request) -> ApiOperationResult<com.example.api.showcase.samplemodels.models.PrimitiveMatrix> = {
        error("No mock handler for getMatrix")
    }

    override suspend fun getMatrix(
        matrixId: String,
        visible: Boolean,
        visibility: com.example.api.showcase.shared.SampleVisibility,
        scores: List<com.example.api.showcase.samplemodels.models.SampleScore>?,
        traceId: String?,
        sampleSession: String?,
        apiKey: String?,
    ): ApiOperationResult<com.example.api.showcase.samplemodels.models.PrimitiveMatrix> {
            val request = com.example.api.showcase.samplemodels.GetMatrixOperation.Request(matrixId = matrixId, visible = visible, visibility = visibility, scores = scores, traceId = traceId, sampleSession = sampleSession, apiKey = apiKey)
        getMatrixCalls += request
        return getMatrixHandler(request)
    }

    val createNotificationCalls = mutableListOf<com.example.api.showcase.samplemodels.CreateNotificationOperation.Request>()

    var createNotificationHandler: suspend (com.example.api.showcase.samplemodels.CreateNotificationOperation.Request) -> ApiOperationResult<com.example.api.showcase.samplemodels.models.NotificationEnvelope> = {
        error("No mock handler for createNotification")
    }

    override suspend fun createNotification(
        idempotencyKey: String?,
        apiKey: String?,
        body: com.example.api.showcase.samplemodels.models.NotificationEnvelope,
    ): ApiOperationResult<com.example.api.showcase.samplemodels.models.NotificationEnvelope> {
            val request = com.example.api.showcase.samplemodels.CreateNotificationOperation.Request(idempotencyKey = idempotencyKey, apiKey = apiKey, body = body)
        createNotificationCalls += request
        return createNotificationHandler(request)
    }

    val followRuntimeUrlCalls = mutableListOf<com.example.api.showcase.samplemodels.FollowRuntimeUrlOperation.Request>()

    var followRuntimeUrlHandler: suspend (com.example.api.showcase.samplemodels.FollowRuntimeUrlOperation.Request) -> ApiOperationResult<PagedResults<com.example.api.showcase.samplemodels.models.PrimitiveMatrix>> = {
        error("No mock handler for followRuntimeUrl")
    }

    override suspend fun followRuntimeUrl(
        requestUrl: String,
        apiKey: String?,
    ): ApiOperationResult<PagedResults<com.example.api.showcase.samplemodels.models.PrimitiveMatrix>> {
            val request = com.example.api.showcase.samplemodels.FollowRuntimeUrlOperation.Request(requestUrl = requestUrl, apiKey = apiKey)
        followRuntimeUrlCalls += request
        return followRuntimeUrlHandler(request)
    }

    data class GetNextPageForFollowRuntimeUrlOperationCall(
        val currentPage: PagedResults<com.example.api.showcase.samplemodels.models.PrimitiveMatrix>,
        val request: com.example.api.showcase.samplemodels.FollowRuntimeUrlOperation.Request,
    )
    val getNextPageForFollowRuntimeUrlOperationCalls = mutableListOf<GetNextPageForFollowRuntimeUrlOperationCall>()

    var getNextPageForFollowRuntimeUrlOperationHandler: suspend (
        PagedResults<com.example.api.showcase.samplemodels.models.PrimitiveMatrix>,
        com.example.api.showcase.samplemodels.FollowRuntimeUrlOperation.Request,
    ) -> ApiOperationResult<PagedResults<com.example.api.showcase.samplemodels.models.PrimitiveMatrix>> = { _, _ ->
        error("No mock handler for getNextPage")
    }

    override suspend fun getNextPageForFollowRuntimeUrlOperation(
        currentPage: PagedResults<com.example.api.showcase.samplemodels.models.PrimitiveMatrix>,
        requestUrl: String,
        apiKey: String?,
    ): ApiOperationResult<PagedResults<com.example.api.showcase.samplemodels.models.PrimitiveMatrix>> {
        val request = com.example.api.showcase.samplemodels.FollowRuntimeUrlOperation.Request(requestUrl = requestUrl, apiKey = apiKey)
        getNextPageForFollowRuntimeUrlOperationCalls += GetNextPageForFollowRuntimeUrlOperationCall(currentPage, request)
        return getNextPageForFollowRuntimeUrlOperationHandler(currentPage, request)
    }

    fun resetMock() {
        getMatrixCalls.clear()
        getMatrixHandler = { error("No mock handler for getMatrix") }
        createNotificationCalls.clear()
        createNotificationHandler = { error("No mock handler for createNotification") }
        followRuntimeUrlCalls.clear()
        followRuntimeUrlHandler = { error("No mock handler for followRuntimeUrl") }
        getNextPageForFollowRuntimeUrlOperationCalls.clear()
        getNextPageForFollowRuntimeUrlOperationHandler = { _, _ -> error("No mock handler for getNextPage") }
    }
}

class ShowcaseTransportApiMock : ShowcaseTransportApi {
    data class UploadMultipartOperationCall(
        val request: com.example.api.showcase.transport.UploadMultipartOperation.Request,
        val progress: ApiProgress?,
    )
    val uploadMultipartCalls = mutableListOf<UploadMultipartOperationCall>()

    var uploadMultipartHandler: suspend (com.example.api.showcase.transport.UploadMultipartOperation.Request, ApiProgress?) -> ApiOperationResult<com.example.api.showcase.transport.models.UploadReceipt> = { _, _ ->
        error("No mock handler for uploadMultipart")
    }

    override suspend fun uploadMultipart(
        compress: Boolean?,
        apiKey: String?,
        body: MultipartBody,
        progress: ApiProgress?,
    ): ApiOperationResult<com.example.api.showcase.transport.models.UploadReceipt> {
        val request = com.example.api.showcase.transport.UploadMultipartOperation.Request(compress = compress, apiKey = apiKey, body = body)
        uploadMultipartCalls += UploadMultipartOperationCall(request, progress)
        return uploadMultipartHandler(request, progress)
    }

    data class UploadFileOperationCall(
        val request: com.example.api.showcase.transport.UploadFileOperation.Request,
        val progress: ApiProgress?,
    )
    val uploadFileCalls = mutableListOf<UploadFileOperationCall>()

    var uploadFileHandler: suspend (com.example.api.showcase.transport.UploadFileOperation.Request, ApiProgress?) -> ApiOperationResult<com.example.api.showcase.transport.models.UploadReceipt> = { _, _ ->
        error("No mock handler for uploadFile")
    }

    override suspend fun uploadFile(
        apiKey: String?,
        body: ApiUploadSource,
        progress: ApiProgress?,
    ): ApiOperationResult<com.example.api.showcase.transport.models.UploadReceipt> {
        val request = com.example.api.showcase.transport.UploadFileOperation.Request(apiKey = apiKey, body = body)
        uploadFileCalls += UploadFileOperationCall(request, progress)
        return uploadFileHandler(request, progress)
    }

    data class UploadBinaryOperationCall(
        val request: com.example.api.showcase.transport.UploadBinaryOperation.Request,
        val progress: ApiProgress?,
    )
    val uploadBinaryCalls = mutableListOf<UploadBinaryOperationCall>()

    var uploadBinaryHandler: suspend (com.example.api.showcase.transport.UploadBinaryOperation.Request, ApiProgress?) -> ApiResponse = { _, _ ->
        error("No mock handler for uploadBinary")
    }

    override suspend fun uploadBinary(
        contentMd5: String?,
        apiKey: String?,
        body: ByteArray,
        progress: ApiProgress?,
    ): ApiResponse {
        val request = com.example.api.showcase.transport.UploadBinaryOperation.Request(contentMd5 = contentMd5, apiKey = apiKey, body = body)
        uploadBinaryCalls += UploadBinaryOperationCall(request, progress)
        return uploadBinaryHandler(request, progress)
    }

    val deleteWithBodyCalls = mutableListOf<com.example.api.showcase.transport.DeleteWithBodyOperation.Request>()

    var deleteWithBodyHandler: suspend (com.example.api.showcase.transport.DeleteWithBodyOperation.Request) -> ApiOperationResult<com.example.api.showcase.transport.models.UploadReceipt> = {
        error("No mock handler for deleteWithBody")
    }

    override suspend fun deleteWithBody(
        apiKey: String?,
        body: com.example.api.showcase.transport.models.DeleteReceiptRequest,
    ): ApiOperationResult<com.example.api.showcase.transport.models.UploadReceipt> {
            val request = com.example.api.showcase.transport.DeleteWithBodyOperation.Request(apiKey = apiKey, body = body)
        deleteWithBodyCalls += request
        return deleteWithBodyHandler(request)
    }

    fun resetMock() {
        uploadMultipartCalls.clear()
        uploadMultipartHandler = { _, _ -> error("No mock handler for uploadMultipart") }
        uploadFileCalls.clear()
        uploadFileHandler = { _, _ -> error("No mock handler for uploadFile") }
        uploadBinaryCalls.clear()
        uploadBinaryHandler = { _, _ -> error("No mock handler for uploadBinary") }
        deleteWithBodyCalls.clear()
        deleteWithBodyHandler = { error("No mock handler for deleteWithBody") }
    }
}

class TenantProjectApiMock : TenantProjectApi {
    val createCalls = mutableListOf<com.example.api.tenant.project.CreateOperation.Request>()

    var createHandler: suspend (com.example.api.tenant.project.CreateOperation.Request) -> ApiOperationResult<com.example.api.tenant.project.models.IdProject> = {
        error("No mock handler for create")
    }

    override suspend fun create(
        tenantId: String,
        body: com.example.api.tenant.project.models.Project,
    ): ApiOperationResult<com.example.api.tenant.project.models.IdProject> {
            val request = com.example.api.tenant.project.CreateOperation.Request(tenantId = tenantId, body = body)
        createCalls += request
        return createHandler(request)
    }

    val updateCalls = mutableListOf<com.example.api.tenant.project.UpdateOperation.Request>()

    var updateHandler: suspend (com.example.api.tenant.project.UpdateOperation.Request) -> ApiOperationResult<com.example.api.tenant.project.models.IdProject> = {
        error("No mock handler for update")
    }

    override suspend fun update(
        tenantId: String,
        projectId: String,
        body: com.example.api.tenant.project.models.Project,
    ): ApiOperationResult<com.example.api.tenant.project.models.IdProject> {
            val request = com.example.api.tenant.project.UpdateOperation.Request(tenantId = tenantId, projectId = projectId, body = body)
        updateCalls += request
        return updateHandler(request)
    }

    val deleteCalls = mutableListOf<com.example.api.tenant.project.DeleteOperation.Request>()

    var deleteHandler: suspend (com.example.api.tenant.project.DeleteOperation.Request) -> ApiResponse = {
        error("No mock handler for delete")
    }

    override suspend fun delete(
        tenantId: String,
        projectId: String,
    ): ApiResponse {
            val request = com.example.api.tenant.project.DeleteOperation.Request(tenantId = tenantId, projectId = projectId)
        deleteCalls += request
        return deleteHandler(request)
    }

    val listCalls = mutableListOf<com.example.api.tenant.project.ListOperation.Request>()

    var listHandler: suspend (com.example.api.tenant.project.ListOperation.Request) -> ApiOperationResult<List<com.example.api.tenant.project.models.IdentifiedProject>> = {
        error("No mock handler for list")
    }

    override suspend fun list(
        tenantId: String,
        status: List<com.example.api.tenant.shared.TenantStatus>?,
        includeArchived: Boolean?,
    ): ApiOperationResult<List<com.example.api.tenant.project.models.IdentifiedProject>> {
            val request = com.example.api.tenant.project.ListOperation.Request(tenantId = tenantId, status = status, includeArchived = includeArchived)
        listCalls += request
        return listHandler(request)
    }

    val getCalls = mutableListOf<com.example.api.tenant.project.GetOperation.Request>()

    var getHandler: suspend (com.example.api.tenant.project.GetOperation.Request) -> ApiOperationResult<com.example.api.tenant.project.models.IdentifiedProject> = {
        error("No mock handler for `get`")
    }

    override suspend fun `get`(
        tenantId: String,
        projectId: String,
    ): ApiOperationResult<com.example.api.tenant.project.models.IdentifiedProject> {
            val request = com.example.api.tenant.project.GetOperation.Request(tenantId = tenantId, projectId = projectId)
        getCalls += request
        return getHandler(request)
    }

    val archiveCalls = mutableListOf<com.example.api.tenant.project.ArchiveOperation.Request>()

    var archiveHandler: suspend (com.example.api.tenant.project.ArchiveOperation.Request) -> ApiOperationResult<com.example.api.IdObject> = {
        error("No mock handler for archive")
    }

    override suspend fun archive(
        tenantId: String,
        projectId: String,
        cascade: Boolean?,
        apiKey: String?,
    ): ApiOperationResult<com.example.api.IdObject> {
            val request = com.example.api.tenant.project.ArchiveOperation.Request(tenantId = tenantId, projectId = projectId, cascade = cascade, apiKey = apiKey)
        archiveCalls += request
        return archiveHandler(request)
    }

    fun resetMock() {
        createCalls.clear()
        createHandler = { error("No mock handler for create") }
        updateCalls.clear()
        updateHandler = { error("No mock handler for update") }
        deleteCalls.clear()
        deleteHandler = { error("No mock handler for delete") }
        listCalls.clear()
        listHandler = { error("No mock handler for list") }
        getCalls.clear()
        getHandler = { error("No mock handler for `get`") }
        archiveCalls.clear()
        archiveHandler = { error("No mock handler for archive") }
    }
}

class TenantProjectTaskApiMock : TenantProjectTaskApi {
    val createCalls = mutableListOf<com.example.api.tenant.projecttask.CreateOperation.Request>()

    var createHandler: suspend (com.example.api.tenant.projecttask.CreateOperation.Request) -> ApiOperationResult<com.example.api.tenant.projecttask.models.IdTask> = {
        error("No mock handler for create")
    }

    override suspend fun create(
        tenantId: String,
        projectId: String,
        body: com.example.api.tenant.projecttask.models.Task,
    ): ApiOperationResult<com.example.api.tenant.projecttask.models.IdTask> {
            val request = com.example.api.tenant.projecttask.CreateOperation.Request(tenantId = tenantId, projectId = projectId, body = body)
        createCalls += request
        return createHandler(request)
    }

    val patchCalls = mutableListOf<com.example.api.tenant.projecttask.PatchOperation.Request>()

    var patchHandler: suspend (com.example.api.tenant.projecttask.PatchOperation.Request) -> ApiOperationResult<com.example.api.tenant.projecttask.models.IdTask> = {
        error("No mock handler for patch")
    }

    override suspend fun patch(
        tenantId: String,
        projectId: String,
        taskId: String,
        body: com.example.api.tenant.projecttask.models.PatchedTask,
    ): ApiOperationResult<com.example.api.tenant.projecttask.models.IdTask> {
            val request = com.example.api.tenant.projecttask.PatchOperation.Request(tenantId = tenantId, projectId = projectId, taskId = taskId, body = body)
        patchCalls += request
        return patchHandler(request)
    }

    val listCalls = mutableListOf<com.example.api.tenant.projecttask.ListOperation.Request>()

    var listHandler: suspend (com.example.api.tenant.projecttask.ListOperation.Request) -> ApiOperationResult<PagedResults<com.example.api.tenant.projecttask.models.IdentifiedTask>> = {
        error("No mock handler for list")
    }

    override suspend fun list(
        tenantId: String,
        projectId: String,
        done: Boolean?,
    ): ApiOperationResult<PagedResults<com.example.api.tenant.projecttask.models.IdentifiedTask>> {
            val request = com.example.api.tenant.projecttask.ListOperation.Request(tenantId = tenantId, projectId = projectId, done = done)
        listCalls += request
        return listHandler(request)
    }

    val getCalls = mutableListOf<com.example.api.tenant.projecttask.GetOperation.Request>()

    var getHandler: suspend (com.example.api.tenant.projecttask.GetOperation.Request) -> ApiOperationResult<com.example.api.tenant.projecttask.models.IdentifiedTask> = {
        error("No mock handler for `get`")
    }

    override suspend fun `get`(
        tenantId: String,
        projectId: String,
        taskId: String,
    ): ApiOperationResult<com.example.api.tenant.projecttask.models.IdentifiedTask> {
            val request = com.example.api.tenant.projecttask.GetOperation.Request(tenantId = tenantId, projectId = projectId, taskId = taskId)
        getCalls += request
        return getHandler(request)
    }

    val completeCalls = mutableListOf<com.example.api.tenant.projecttask.CompleteOperation.Request>()

    var completeHandler: suspend (com.example.api.tenant.projecttask.CompleteOperation.Request) -> ApiOperationResult<com.example.api.IdObject> = {
        error("No mock handler for complete")
    }

    override suspend fun complete(
        tenantId: String,
        projectId: String,
        taskId: String,
        notify: Boolean?,
        apiKey: String?,
        body: com.example.api.tenant.projecttask.models.CompleteTaskRequest,
    ): ApiOperationResult<com.example.api.IdObject> {
            val request = com.example.api.tenant.projecttask.CompleteOperation.Request(tenantId = tenantId, projectId = projectId, taskId = taskId, notify = notify, apiKey = apiKey, body = body)
        completeCalls += request
        return completeHandler(request)
    }

    data class GetNextPageForListOperationCall(
        val currentPage: PagedResults<com.example.api.tenant.projecttask.models.IdentifiedTask>,
        val request: com.example.api.tenant.projecttask.ListOperation.Request,
    )
    val getNextPageForListOperationCalls = mutableListOf<GetNextPageForListOperationCall>()

    var getNextPageForListOperationHandler: suspend (
        PagedResults<com.example.api.tenant.projecttask.models.IdentifiedTask>,
        com.example.api.tenant.projecttask.ListOperation.Request,
    ) -> ApiOperationResult<PagedResults<com.example.api.tenant.projecttask.models.IdentifiedTask>> = { _, _ ->
        error("No mock handler for getNextPage")
    }

    override suspend fun getNextPageForListOperation(
        currentPage: PagedResults<com.example.api.tenant.projecttask.models.IdentifiedTask>,
        tenantId: String,
        projectId: String,
        done: Boolean?,
    ): ApiOperationResult<PagedResults<com.example.api.tenant.projecttask.models.IdentifiedTask>> {
        val request = com.example.api.tenant.projecttask.ListOperation.Request(tenantId = tenantId, projectId = projectId, done = done)
        getNextPageForListOperationCalls += GetNextPageForListOperationCall(currentPage, request)
        return getNextPageForListOperationHandler(currentPage, request)
    }

    fun resetMock() {
        createCalls.clear()
        createHandler = { error("No mock handler for create") }
        patchCalls.clear()
        patchHandler = { error("No mock handler for patch") }
        listCalls.clear()
        listHandler = { error("No mock handler for list") }
        getNextPageForListOperationCalls.clear()
        getNextPageForListOperationHandler = { _, _ -> error("No mock handler for getNextPage") }
        getCalls.clear()
        getHandler = { error("No mock handler for `get`") }
        completeCalls.clear()
        completeHandler = { error("No mock handler for complete") }
    }
}

class ApiModulesMocks {
    lateinit var adminUserApi: AdminUserApiMock
    lateinit var adminRoleApi: AdminRoleApiMock
    lateinit var adminGroupApi: AdminGroupApiMock
    lateinit var locationStructureApi: LocationStructureApiMock
    lateinit var showcaseSampleModelsApi: ShowcaseSampleModelsApiMock
    lateinit var showcaseTransportApi: ShowcaseTransportApiMock
    lateinit var tenantProjectApi: TenantProjectApiMock
    lateinit var tenantProjectTaskApi: TenantProjectTaskApiMock
    lateinit var adminModule: AdminApiModule
    lateinit var locationModule: LocationApiModule
    lateinit var showcaseModule: ShowcaseApiModule
    lateinit var tenantModule: TenantApiModule
    lateinit var apiModules: ApiModules

    fun setUp() {
        adminUserApi = AdminUserApiMock()
        adminRoleApi = AdminRoleApiMock()
        adminGroupApi = AdminGroupApiMock()
        locationStructureApi = LocationStructureApiMock()
        showcaseSampleModelsApi = ShowcaseSampleModelsApiMock()
        showcaseTransportApi = ShowcaseTransportApiMock()
        tenantProjectApi = TenantProjectApiMock()
        tenantProjectTaskApi = TenantProjectTaskApiMock()
        adminModule = AdminApiModule(userApi = adminUserApi, roleApi = adminRoleApi, groupApi = adminGroupApi)
        locationModule = LocationApiModule(structureApi = locationStructureApi)
        showcaseModule = ShowcaseApiModule(sampleModelsApi = showcaseSampleModelsApi, transportApi = showcaseTransportApi)
        tenantModule = TenantApiModule(projectApi = tenantProjectApi, projectTaskApi = tenantProjectTaskApi)
        apiModules = ApiModules(adminModule = adminModule, locationModule = locationModule, showcaseModule = showcaseModule, tenantModule = tenantModule)
    }

    fun tearDown() {
        adminUserApi.resetMock()
        adminRoleApi.resetMock()
        adminGroupApi.resetMock()
        locationStructureApi.resetMock()
        showcaseSampleModelsApi.resetMock()
        showcaseTransportApi.resetMock()
        tenantProjectApi.resetMock()
        tenantProjectTaskApi.resetMock()
    }
}
