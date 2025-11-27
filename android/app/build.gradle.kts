// android/app/build.gradle.kts

import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")           // ← Kotlin DSL 올바른 ID
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")         // 루트에서 버전 선언, 여기선 버전 없이 적용
    // ← 플러그인 추가 X! (이게 에러 원인)
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

    defaultConfig {
        applicationId = "kr.comong.daoapp"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // 필요시 멀티덱스:
        // multiDexEnabled = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    kotlinOptions { jvmTarget = "11" }

    // ── 릴리즈 서명 (keystore 있을 때만 구성)
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
        // debug는 기본 디버그 키 사용
    }
}

flutter {
    source = "../.."
}

// ←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←
// 이 블록만 새로 추가! (App Check 의존성)
dependencies {
    // 디버그 빌드용
    debugImplementation("com.google.firebase:firebase-appcheck-debug:17.2.0")
    // 릴리즈 빌드용 Play Integrity
    releaseImplementation("com.google.firebase:firebase-appcheck-playintegrity:17.2.0")
}
// ←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←