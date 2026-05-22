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

    // ✅ NDK 28 버전은 16KB를 기본 지원하므로 유지합니다.
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
            // ✅ 16KB 페이지 지원을 위한 필수 설정 (기존 유지)
            useLegacyPackaging = false
        }
        resources {
            excludes += "META-INF/*"
        }
    }

    compileOptions {
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
            // 🔹 타이밍 및 권한 외에 컴파일러 가위질로 인한 데이터 증발(Serialization 깨짐)을 막기 위해
            // 안전하게 false 기조를 유지합니다.
            isMinifyEnabled = false
            isShrinkResources = false

            // ✅ 혹시 모를 릴리즈 난독화 예외 처리를 위해 프로가드 규칙 파일을 정확히 연결합니다.
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")

            if (hasKeystore) {
                signingConfig = signingConfigs.getByName("release")
            }

            // ✅ 16KB 메모리 정렬을 위해 네이티브 라이브러리 압축을 강제로 해제합니다.
            @Suppress("DEPRECATION")
            manifestPlaceholders["extractNativeLibs"] = "false"
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")

    implementation("androidx.multidex:multidex:2.0.1")
    debugImplementation("com.google.firebase:firebase-appcheck-debug:17.2.0")
    releaseImplementation("com.google.firebase:firebase-appcheck-playintegrity:17.2.0")

    // 🔥 [16KB 구글 플레이 콘솔 거부 에러 완벽 해결]
    // ML Kit Pose Detection 패키지가 내부적으로 옛날 버전의 미디어파이프 파편을 물고 오더라도,
    // 안드로이드 네이티브 빌드 시점에 16KB 메모리 페이지를 완벽하게 공식 지원하는 순정 최신 라이브러리로 덮어씁니다.
    implementation("com.google.mediapipe:tasks-vision:0.10.14")

    implementation("androidx.camera:camera-core:1.3.0")
    implementation("androidx.camera:camera-camera2:1.3.0")
    implementation("androidx.camera:camera-lifecycle:1.3.0")
    implementation("androidx.camera:camera-view:1.3.0")

    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.1")
}