import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

val keystoreProperties = Properties()
val keystoreFile = rootProject.file("key.properties")
val hasKeystore = if (keystoreFile.exists()) {
    keystoreProperties.load(FileInputStream(keystoreFile)); true
} else {
    false
}

android {
    namespace = "kr.comong.daoapp"
    compileSdk = flutter.compileSdkVersion

    ndkVersion = "28.2.13676358"

    defaultConfig {
        applicationId = "kr.comong.daoapp"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    packaging {
        jniLibs {
            useLegacyPackaging = false
        }
        resources {
            excludes += "META-INF/*"
        }
    }

    compileOptions {
        // ✅ 디슈가링 활성화
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions { jvmTarget = "17" }

    if (hasKeystore) {
        signingConfigs {
            create("release") {
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
            }
        }
    }

    buildTypes {
        getByName("release") {
            isMinifyEnabled = false
            isShrinkResources = false

            if (hasKeystore) {
                signingConfig = signingConfigs.getByName("release")
            }

            @Suppress("DEPRECATION")
            manifestPlaceholders["extractNativeLibs"] = "false"
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // ✅ 디슈가링 라이브러리 추가
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")

    implementation("androidx.multidex:multidex:2.0.1")
    debugImplementation("com.google.firebase:firebase-appcheck-debug:17.2.0")
    releaseImplementation("com.google.firebase:firebase-appcheck-playintegrity:17.2.0")

    implementation("com.google.mediapipe:tasks-vision:0.10.14")
    implementation("androidx.camera:camera-core:1.3.0")
    implementation("androidx.camera:camera-camera2:1.3.0")
    implementation("androidx.camera:camera-lifecycle:1.3.0")
    implementation("androidx.camera:camera-view:1.3.0")

    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.1")
}