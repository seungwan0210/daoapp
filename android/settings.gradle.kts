// android/settings.gradle.kts

pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
        flutterSdkPath
    }

    // Flutter 도구 연결 (Flutter 템플릿 기본)
    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }

    // (선택) 여기서 플러그인 버전들을 고정 관리할 수도 있음
    // plugins {
    //     id("com.google.gms.google-services") version "4.4.2"
    // }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.7.0" apply false

    // ✅ FlutterFire: Google Services 플러그인 최신 권장 버전
    id("com.google.gms.google-services") version "4.4.2" apply false

    id("org.jetbrains.kotlin.android") version "1.8.22" apply false
}

// (필수) app 모듈 포함
include(":app")

// (선택) 프로젝트 이름 지정하고 싶으면 추가
// rootProject.name = "daoapp"
