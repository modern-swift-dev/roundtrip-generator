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
import io.ktor.client.HttpClient
import org.koin.core.module.Module
import org.koin.dsl.module

fun apiKoinModule(
    httpClient: HttpClient,
    baseUrlProvider: BaseUrlProvider,
    apiKeyProvider: ApiKeyProvider,
    bodyCodec: BodyCodec,
    defaultHttpHeaderProvider: DefaultHttpHeaderProvider = DefaultHttpHeaderProvider { emptyMap() },
): Module =
    module {
        single<HttpClient> { httpClient }
        single<BaseUrlProvider> { baseUrlProvider }
        single<ApiKeyProvider> { apiKeyProvider }
        single<DefaultHttpHeaderProvider> { defaultHttpHeaderProvider }
        single<BodyCodec> { bodyCodec }
        single<RestClient> {
            KtorRestClient(
                httpClient = get(),
                baseUrlProvider = get(),
                apiKeyProvider = get(),
                bodyCodec = get(),
                defaultHttpHeaderProvider = get(),
            )
        }
        single<AdminUserApi> {
            AdminUserApiService(client = get())
        }
        single<AdminRoleApi> {
            AdminRoleApiService(client = get())
        }
        single<AdminGroupApi> {
            AdminGroupApiService(client = get())
        }
        single<LocationStructureApi> {
            LocationStructureApiService(client = get())
        }
        single<ShowcaseSampleModelsApi> {
            ShowcaseSampleModelsApiService(client = get())
        }
        single<ShowcaseTransportApi> {
            ShowcaseTransportApiService(client = get())
        }
        single<TenantProjectApi> {
            TenantProjectApiService(client = get())
        }
        single<TenantProjectTaskApi> {
            TenantProjectTaskApiService(client = get())
        }
        single { AdminApiModule(userApi = get(), roleApi = get(), groupApi = get()) }
        single { LocationApiModule(structureApi = get()) }
        single { ShowcaseApiModule(sampleModelsApi = get(), transportApi = get()) }
        single { TenantApiModule(projectApi = get(), projectTaskApi = get()) }
        single { ApiModules(adminModule = get(), locationModule = get(), showcaseModule = get(), tenantModule = get(), errors = get<RestClient>().errors) }
    }
