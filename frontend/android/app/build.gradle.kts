import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.notteodo.notteodo"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.notteodo.notteodo"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            // A store build must be signed with the real upload key. Without key.properties a
            // release build fails instead of silently shipping with the debug key; pass
            // -PallowDebugSigning=true for a local, never-published test of the release build.
            val allowDebugSigning = (project.findProperty("allowDebugSigning") as String?) == "true"
            signingConfig = when {
                keystorePropertiesFile.exists() -> signingConfigs.getByName("release")
                allowDebugSigning -> signingConfigs.getByName("debug")
                else -> null
            }
            if (!keystorePropertiesFile.exists() && !allowDebugSigning &&
                gradle.startParameter.taskNames.any { it.contains("Release", ignoreCase = true) }
            ) {
                throw GradleException(
                    "Release signing key missing: copy android/key.properties.example to android/key.properties " +
                        "and point it at your upload keystore (or pass -PallowDebugSigning=true for a local test)."
                )
            }
            // Strip unused code and resources, and obfuscate Java/Kotlin class names.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // AppCompat launch theme: required by the biometric prompt on Android 8 and below.
    implementation("androidx.appcompat:appcompat:1.7.0")
}
