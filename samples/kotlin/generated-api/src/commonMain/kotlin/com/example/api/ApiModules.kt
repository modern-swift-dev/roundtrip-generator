// Generated code. Do not edit.
package com.example.api

import com.example.api.admin.group.AdminGroupApi
import com.example.api.admin.group.AdminGroupApiService
import com.example.api.admin.role.AdminRoleApi
import com.example.api.admin.role.AdminRoleApiService
import com.example.api.admin.user.AdminUserApi
import com.example.api.admin.user.AdminUserApiService
import com.example.api.location.structure.LocationStructureApi
import com.example.api.location.structure.LocationStructureApiService
import com.example.api.showcase.samplemodels.ShowcaseSampleModelsApi
import com.example.api.showcase.samplemodels.ShowcaseSampleModelsApiService
import com.example.api.showcase.transport.ShowcaseTransportApi
import com.example.api.showcase.transport.ShowcaseTransportApiService
import com.example.api.tenant.project.TenantProjectApi
import com.example.api.tenant.project.TenantProjectApiService
import com.example.api.tenant.projecttask.TenantProjectTaskApi
import com.example.api.tenant.projecttask.TenantProjectTaskApiService
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow

data class AdminApiModule(
    val userApi: AdminUserApi,
    val roleApi: AdminRoleApi,
    val groupApi: AdminGroupApi,
) {
    constructor(client: RestClient) : this(
        userApi = AdminUserApiService(client = client),
        roleApi = AdminRoleApiService(client = client),
        groupApi = AdminGroupApiService(client = client),
    )
}

data class LocationApiModule(
    val structureApi: LocationStructureApi,
) {
    constructor(client: RestClient) : this(
        structureApi = LocationStructureApiService(client = client),
    )
}

data class ShowcaseApiModule(
    val sampleModelsApi: ShowcaseSampleModelsApi,
    val transportApi: ShowcaseTransportApi,
) {
    constructor(client: RestClient) : this(
        sampleModelsApi = ShowcaseSampleModelsApiService(client = client),
        transportApi = ShowcaseTransportApiService(client = client),
    )
}

data class TenantApiModule(
    val projectApi: TenantProjectApi,
    val projectTaskApi: TenantProjectTaskApi,
) {
    constructor(client: RestClient) : this(
        projectApi = TenantProjectApiService(client = client),
        projectTaskApi = TenantProjectTaskApiService(client = client),
    )
}

data class ApiModules(
    val adminModule: AdminApiModule,
    val locationModule: LocationApiModule,
    val showcaseModule: ShowcaseApiModule,
    val tenantModule: TenantApiModule,
    val errors: SharedFlow<ApiError> = MutableSharedFlow(),
) {
    constructor(client: RestClient) : this(
        adminModule = AdminApiModule(client = client),
        locationModule = LocationApiModule(client = client),
        showcaseModule = ShowcaseApiModule(client = client),
        tenantModule = TenantApiModule(client = client),
        errors = client.errors,
    )
}
