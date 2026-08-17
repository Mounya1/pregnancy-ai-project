plugins {
    id("com.android.application")
    // MainActivity is Kotlin, so on AGP 8 the app needs the Kotlin plugin
    // explicitly - AGP 9's built-in Kotlin would have covered it, but that
    // breaks the plugin ecosystem (see settings.gradle.kts).
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.pregnancy_ai_assistant"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // flutter_local_notifications uses java.time to schedule reminders,
        // which needs desugaring to run on older Android versions.
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // Permanent identity of this app on a device and in the Play Store.
        // It can never be changed after the first publish, which is why the
        // com.example.* placeholder had to go before any build was shared -
        // the Play Store rejects it outright.
        applicationId = "com.mounya.pregnancyai"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // flutter_local_notifications 22 requires API 24 as a floor.
        minSdk = maxOf(flutter.minSdkVersion, 24)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Debug keys, deliberately. That is enough to build an APK anyone
            // can sideload, which is what this app needs today. Publishing to
            // the Play Store needs a real upload key instead - the steps are
            // in DEPLOY.md, and they need a keystore only the owner can make.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
