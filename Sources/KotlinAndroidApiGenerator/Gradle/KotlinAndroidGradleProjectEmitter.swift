import Foundation

/// Emits an Android-only library project. Android Gradle plugin supplies Kotlin support;
/// the Kotlin Gradle dependency keeps that compiler aligned with the serialization plugin.
public struct KotlinAndroidGradleProjectEmitter: Sendable, Equatable {
    public let options: KotlinAndroidGeneratorOptions

    public init(options: KotlinAndroidGeneratorOptions = .init()) {
        self.options = options
    }

    public func generatedFiles() -> [KotlinAndroidGeneratedTextFile] {
        let gradle = options.gradle
        return [
            file("settings.gradle.kts", """
            pluginManagement {
                repositories {
                    google()
                    mavenCentral()
                    gradlePluginPortal()
                }
            }

            dependencyResolutionManagement {
                repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
                repositories {
                    google()
                    mavenCentral()
                }
            }

            rootProject.name = \(gradle.projectName.kotlinStringLiteral)
            include(\(":\(gradle.moduleName)".kotlinStringLiteral))
            """),
            file("build.gradle.kts", """
            buildscript {
                repositories {
                    google()
                    mavenCentral()
                }
                dependencies {
                    classpath(libs.kotlin.gradle.plugin)
                }
            }

            plugins {
                alias(libs.plugins.android.library) apply false
                alias(libs.plugins.kotlin.serialization) apply false
                alias(libs.plugins.ktlint) apply false
            }
            """),
            file("gradle/libs.versions.toml", versionCatalog(), prefix: "#"),
            file("gradle.properties", """
            org.gradle.jvmargs=-Xmx2g -Dfile.encoding=UTF-8
            android.useAndroidX=true
            kotlin.code.style=official
            """, prefix: "#"),
            file("gradle/wrapper/gradle-wrapper.properties", """
            distributionBase=GRADLE_USER_HOME
            distributionPath=wrapper/dists
            distributionUrl=https\\://services.gradle.org/distributions/gradle-9.5.1-bin.zip
            networkTimeout=10000
            validateDistributionUrl=true
            zipStoreBase=GRADLE_USER_HOME
            zipStorePath=wrapper/dists
            """, prefix: "#"),
            KotlinAndroidEditorConfigEmitter(
                sections: KotlinAndroidEditorConfigEmitter.defaultSections(ktlintCodeStyle: gradle.ktlintCodeStyle),
            ).file(),
            file("\(gradle.moduleName)/build.gradle.kts", moduleBuild()),
            KotlinAndroidGeneratedTextFile(
                relativePath: "\(gradle.moduleName)/src/main/AndroidManifest.xml",
                contents: """
                <!-- Generated code. Do not edit. -->
                <manifest xmlns:android="http://schemas.android.com/apk/res/android">
                    <uses-permission android:name="android.permission.INTERNET" />
                </manifest>
                """,
            )
        ]
    }

    private func file(_ path: String, _ contents: String, prefix: String = "//") -> KotlinAndroidGeneratedTextFile {
        KotlinAndroidGeneratedTextFile(relativePath: path, contents: "\(prefix) Generated code. Do not edit.\n\(contents)")
    }

    private func versionCatalog() -> String {
        let gradle = options.gradle
        /// Kotlin string literals are valid TOML basic strings except for escaped dollar signs.
        func quoted(_ value: String) -> String {
            value.kotlinStringLiteral.replacingOccurrences(of: "\\$", with: "$")
        }
        let koinVersions = options.generateKoinModule ? "koin = \(quoted(gradle.koinVersion))\n" : ""
        let koinLibraries = options.generateKoinModule ? """
        koin-bom = { module = "io.insert-koin:koin-bom", version.ref = "koin" }
        koin-core = { module = "io.insert-koin:koin-core" }

        """ : ""
        return """
        [versions]
        kotlin = \(quoted(gradle.kotlinVersion))
        androidGradlePlugin = \(quoted(gradle.androidGradlePluginVersion))
        retrofit = \(quoted(gradle.retrofitVersion))
        okhttp = \(quoted(gradle.okHttpVersion))
        \(koinVersions)kotlinxSerialization = \(quoted(gradle.kotlinxSerializationVersion))
        kotlinxDateTime = \(quoted(gradle.kotlinxDateTimeVersion))
        kotlinxCoroutines = \(quoted(gradle.kotlinxCoroutinesVersion))
        ktlintGradle = \(quoted(gradle.ktlintGradlePluginVersion))
        robolectric = \(quoted(gradle.robolectricVersion))
        junit = \(quoted(gradle.junitVersion))
        desugarJdkLibs = \(quoted(gradle.desugarJdkLibsVersion))

        [libraries]
        kotlin-gradle-plugin = { module = "org.jetbrains.kotlin:kotlin-gradle-plugin", version.ref = "kotlin" }
        retrofit = { module = "com.squareup.retrofit2:retrofit", version.ref = "retrofit" }
        okhttp = { module = "com.squareup.okhttp3:okhttp", version.ref = "okhttp" }
        \(koinLibraries)kotlinx-coroutines-core = { module = "org.jetbrains.kotlinx:kotlinx-coroutines-core", version.ref = "kotlinxCoroutines" }
        kotlinx-coroutines-test = { module = "org.jetbrains.kotlinx:kotlinx-coroutines-test", version.ref = "kotlinxCoroutines" }
        kotlinx-datetime = { module = "org.jetbrains.kotlinx:kotlinx-datetime", version.ref = "kotlinxDateTime" }
        kotlinx-serialization-json = { module = "org.jetbrains.kotlinx:kotlinx-serialization-json", version.ref = "kotlinxSerialization" }
        okhttp-mockwebserver = { module = "com.squareup.okhttp3:mockwebserver", version.ref = "okhttp" }
        robolectric = { module = "org.robolectric:robolectric", version.ref = "robolectric" }
        junit = { module = "junit:junit", version.ref = "junit" }
        desugar-jdk-libs = { module = "com.android.tools:desugar_jdk_libs", version.ref = "desugarJdkLibs" }

        [plugins]
        android-library = { id = "com.android.library", version.ref = "androidGradlePlugin" }
        kotlin-serialization = { id = "org.jetbrains.kotlin.plugin.serialization", version.ref = "kotlin" }
        ktlint = { id = "org.jlleitschuh.gradle.ktlint", version.ref = "ktlintGradle" }
        """
    }

    private func moduleBuild() -> String {
        let gradle = options.gradle
        let koinDependencies = options.generateKoinModule ? """
            api(platform(libs.koin.bom))
            api(libs.koin.core)

        """ : ""
        return """
        plugins {
            alias(libs.plugins.android.library)
            alias(libs.plugins.kotlin.serialization)
            alias(libs.plugins.ktlint)
            `maven-publish`
        }

        group = \(gradle.group.kotlinStringLiteral)
        version = \(gradle.version.kotlinStringLiteral)

        android {
            namespace = \((gradle.namespace ?? options.basePackage).kotlinStringLiteral)
            compileSdk = \(gradle.compileSdk)

            defaultConfig {
                minSdk = \(gradle.minSdk)
            }

            compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
                isCoreLibraryDesugaringEnabled = true
            }

            testOptions {
                unitTests.isIncludeAndroidResources = true
            }

            publishing {
                singleVariant("release") {
                    withSourcesJar()
                }
            }
        }

        kotlin {
            jvmToolchain(\(gradle.jvmToolchain))
            compilerOptions {
                optIn.add("kotlin.time.ExperimentalTime")
            }
        }

        dependencies {
            api(libs.okhttp)
            api(libs.kotlinx.coroutines.core)
            api(libs.kotlinx.datetime)
            api(libs.kotlinx.serialization.json)
            implementation(libs.retrofit)
        \(koinDependencies)    coreLibraryDesugaring(libs.desugar.jdk.libs)
            testImplementation(libs.junit)
            testImplementation(libs.okhttp.mockwebserver)
            testImplementation(libs.kotlinx.coroutines.test)
            testImplementation(libs.robolectric)
        }

        ktlint {
            version.set(\(gradle.ktlintVersion.kotlinStringLiteral))
            filter {
                exclude { it.file.invariantSeparatorsPath.contains("/src/main/") }
            }
        }

        publishing {
            publications {
                register<MavenPublication>("release") {
                    artifactId = \(gradle.artifactId.kotlinStringLiteral)
                    afterEvaluate {
                        from(components["release"])
                    }
                }
            }
        }
        """
    }
}
