import Foundation
import GeneratorBuilder
import GeneratorModels

struct KotlinAndroidKoinEmitter {
    let package: ApiPackage
    let options: KotlinAndroidGeneratorOptions

    init(package: ApiPackage, options: KotlinAndroidGeneratorOptions = .init()) {
        self.package = package
        self.options = options
    }

    func kotlinCode(packageName: String? = nil, imports: [String] = []) -> any Node {
        let runtimeImports = options.generateRuntime ? ["okhttp3.OkHttpClient"] : []
        return KotlinAndroidFileEmitter.renderNode(
            packageName: packageName,
            imports: (imports + [
                "org.koin.core.module.Module",
                "org.koin.dsl.module"
            ] + runtimeImports).sorted(),
            body: koinDeclaration(),
        )
    }

    func koinDeclaration(functionName: String = "apiKoinModule") -> any Node {
        let modules = package.referencedModules + package.modules
        let modulesWithDefinitions = modules.filter { !$0.definitions.isEmpty }
        let serviceBindings = modulesWithDefinitions
            .flatMap { module in
                module.definitions.map { definition in
                    Block {
                        "single<\(definition.kotlinApiTypeName(moduleName: module.name))> {"
                        Indentation {
                            "\(definition.kotlinApiServiceTypeName(moduleName: module.name))(client = get())"
                        }
                        "}"
                    }
                }
            }

        let moduleBindings: [any Node] = if package.generateApiModules {
            modulesWithDefinitions.map { module in
                let args = module.definitions
                    .map { "\($0.kotlinApiPropertyName) = get()" }
                    .joined(separator: ", ")
                return "single { \(module.kotlinApiModuleTypeName)(\(args)) }" as any Node
            }
        } else {
            []
        }

        let apiModulesArgs = (
            modulesWithDefinitions.map { "\($0.kotlinModulePropertyName) = get()" }
                + ["errors = get<RestClient>().errors"],
        )
        .joined(separator: ", ")
        let apiModulesBinding: (any Node)? = package.generateApiModules && !modulesWithDefinitions.isEmpty
            ? "single { ApiModules(\(apiModulesArgs)) }" as any Node
            : nil

        let header: String
        let restClientBinding: any Node
        if options.generateRuntime {
            header = """
            fun \(functionName)(
                httpClient: OkHttpClient,
                baseUrlProvider: BaseUrlProvider,
                apiKeyProvider: ApiKeyProvider = ApiKeyProvider { null },
                bodyCodec: BodyCodec = JsonBodyCodec(),
                defaultHttpHeaderProvider: DefaultHttpHeaderProvider = DefaultHttpHeaderProvider { emptyMap() },
            ): Module =
            """
            restClientBinding = Block {
                "single<OkHttpClient> { httpClient }"
                "single<BaseUrlProvider> { baseUrlProvider }"
                "single<ApiKeyProvider> { apiKeyProvider }"
                "single<DefaultHttpHeaderProvider> { defaultHttpHeaderProvider }"
                "single<BodyCodec> { bodyCodec }"
                "single<RestClient> {"
                Indentation {
                    "RetrofitRestClient("
                    Indentation {
                        "httpClient = get(),"
                        "baseUrlProvider = get(),"
                        "apiKeyProvider = get(),"
                        "bodyCodec = get(),"
                        "defaultHttpHeaderProvider = get(),"
                    }
                    ")"
                }
                "}"
            }
        } else {
            header = "fun \(functionName)(restClient: RestClient): Module ="
            restClientBinding = "single<RestClient> { restClient }"
        }

        return Block {
            header
            Indentation {
                moduleBody(
                    restClientBinding: restClientBinding,
                    serviceBindings: serviceBindings,
                    moduleBindings: moduleBindings,
                    apiModulesBinding: apiModulesBinding,
                )
            }
        }
    }

    private func moduleBody(
        restClientBinding: any Node,
        serviceBindings: [any Node],
        moduleBindings: [any Node],
        apiModulesBinding: (any Node)?,
    ) -> any Node {
        Block {
            "module {"
            Indentation {
                restClientBinding
                NodeList(serviceBindings)
                NodeList(moduleBindings)
                if let apiModulesBinding {
                    apiModulesBinding
                }
            }
            "}"
        }
    }
}
