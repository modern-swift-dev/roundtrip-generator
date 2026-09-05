// Generated code. Do not edit.
plugins {
    alias(libs.plugins.spring.boot)
    alias(libs.plugins.spring.dependency.management)
    alias(libs.plugins.kotlin.jvm)
    alias(libs.plugins.kotlin.plugin.spring)
    alias(libs.plugins.kotlin.plugin.serialization)
    alias(libs.plugins.ktlint)
}

group = "com.example"
version = "1.0.0"

kotlin {
    jvmToolchain(21)

    compilerOptions {
        optIn.add("kotlin.time.ExperimentalTime")
    }
}

dependencies {
    implementation(libs.spring.boot.starter.web)
    implementation(libs.kotlin.reflect)
    implementation(libs.kotlinx.datetime)
    implementation(libs.kotlinx.coroutines.reactor)
    implementation(libs.kotlinx.serialization.json)
    testImplementation(libs.spring.boot.starter.test)
}

tasks.withType<Test> {
    useJUnitPlatform()
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
