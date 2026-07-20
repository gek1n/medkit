pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.0.1" apply false
    id("org.jetbrains.kotlin.android") version "2.3.20" apply false
    // Підхоплює android/app/google-services.json, коли його додадуть з Firebase Console.
    id("com.google.gms.google-services") version "4.4.2" apply false
    // Потрібен для build-ID mapping/символізації нативних крешів — той самий
    // умовний патерн застосування, що й google-services, у app/build.gradle.kts.
    id("com.google.firebase.crashlytics") version "3.0.2" apply false
}

include(":app")
