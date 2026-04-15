// android/app/build.gradle.kts

import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// ── key.properties 로드 (있을 때만)
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

    // 🔥 여기에 이 줄을 추가하세요! (오류 메시지에 떴던 버전과 일치해야 함)
    ndkVersion = "28.2.13676358"

    defaultConfig {
        applicationId = "kr.comong.daoapp"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    // 🔥 [이 부분을 추가하세요] 네이티브 라이브러리 정렬 설정
    packaging {
        jniLibs {
            // 네이티브 라이브러리를 압축하지 않고 페이지 경계에 맞게 정렬합니다.
            // 16KB 페이지 크기 지원 오류를 해결하는 핵심 설정입니다.
            useLegacyPackaging = true
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = "17" }

    // ── 릴리즈 서명
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
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // [기존] 멀티덱스 및 파이어베이스
    implementation("androidx.multidex:multidex:2.0.1")
    debugImplementation("com.google.firebase:firebase-appcheck-debug:17.2.0")
    releaseImplementation("com.google.firebase:firebase-appcheck-playintegrity:17.2.0")

    // 🔥 [추가됨] MediaPipe & CameraX 필수 라이브러리
    implementation("com.google.mediapipe:tasks-vision:0.10.14")
    implementation("androidx.camera:camera-core:1.3.0")
    implementation("androidx.camera:camera-camera2:1.3.0")
    implementation("androidx.camera:camera-lifecycle:1.3.0")
    implementation("androidx.camera:camera-view:1.3.0")

    // 비동기 처리용 코루틴
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.1")
}