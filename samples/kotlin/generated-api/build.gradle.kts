// Generated code. Do not edit.
plugins {
    alias(libs.plugins.kotlin.multiplatform)
    alias(libs.plugins.kotlin.serialization)
    alias(libs.plugins.android.kotlin.multiplatform.library)
    alias(libs.plugins.native.coroutines)
    alias(libs.plugins.ktlint)
}

group = "com.example"
version = "1.0.0"

kotlin {
    android {
        namespace = "com.example.api"
        compileSdk = 36
        minSdk = 23
    }

    compilerOptions {
        optIn.add("kotlin.time.ExperimentalTime")
        optIn.add("kotlin.experimental.ExperimentalObjCName")
    }

    jvmToolchain(21)

    sourceSets {
        commonMain.dependencies {
            implementation(libs.ktor.client.core)
            implementation(libs.ktor.client.content.negotiation)
            implementation(libs.ktor.serialization.kotlinx.json)
            implementation(project.dependencies.platform(libs.koin.bom))
            implementation(libs.koin.core)
            implementation(libs.kotlinx.coroutines.core)
            implementation(libs.kotlinx.datetime)
            implementation(libs.kotlinx.serialization.json)
        }
        androidMain.dependencies {
            implementation(libs.ktor.client.okhttp)
        }
    }
}

ktlint {
    version.set("1.7.1")
    filter {
        exclude("src/**")
    }
}

val generatedSourceSetKtlintTasks =
    tasks.matching { task ->
        task.name.contains("SourceSet") && task.name.contains("ktlint", ignoreCase = true)
    }
generatedSourceSetKtlintTasks.configureEach {
    enabled = false
}
