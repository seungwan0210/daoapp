plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.daoapp"
    compileSdk = flutter.compileSdkVersion

    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    // 이 부분 전부 삭제!!!
    // signingConfigs { ... }
    // buildTypes { getByName("debug") { signingConfig = ... } }

    defaultConfig {
        applicationId = "com.example.daoapp"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        getByName("release") {
            // 릴리즈는 나중에 설정
        }
    }
}

flutter {
    source = "../.."
}

apply(plugin = "com.google.gms.google-services")