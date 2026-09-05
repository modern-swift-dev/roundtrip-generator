// Generated code. Do not edit.
plugins {
    alias(libs.plugins.android.library)
    alias(libs.plugins.kotlin.serialization)
    alias(libs.plugins.ktlint)
    `maven-publish`
}

group = "com.example"
version = "1.0.0"

android {
    namespace = "com.example.api"
    compileSdk = 36

    defaultConfig {
        minSdk = 23
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
    jvmToolchain(21)
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
    api(platform(libs.koin.bom))
    api(libs.koin.core)
    coreLibraryDesugaring(libs.desugar.jdk.libs)
    testImplementation(libs.junit)
    testImplementation(libs.okhttp.mockwebserver)
    testImplementation(libs.kotlinx.coroutines.test)
    testImplementation(libs.robolectric)
}

ktlint {
    version.set("1.7.1")
    filter {
        exclude { it.file.invariantSeparatorsPath.contains("/src/main/") }
    }
}

publishing {
    publications {
        register<MavenPublication>("release") {
            artifactId = "generated-api"
            afterEvaluate {
                from(components["release"])
            }
        }
    }
}
