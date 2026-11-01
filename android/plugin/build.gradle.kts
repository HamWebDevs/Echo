plugins {
    id("com.android.library") version "8.6.1"
    id("org.jetbrains.kotlin.android") version "2.1.21"
}

android {
    namespace = "com.projectecho.services"
    compileSdk = 36
    buildToolsVersion = "36.0.0"
    defaultConfig { minSdk = 28; consumerProguardFiles("consumer-rules.pro") }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = "17" }
}

dependencies {
    compileOnly("org.godotengine:godot:4.6.3.stable")
    implementation("com.revenuecat.purchases:purchases:10.15.1")
    implementation("com.google.firebase:firebase-analytics:23.0.0")
    implementation("androidx.core:core-ktx:1.15.0")
}
