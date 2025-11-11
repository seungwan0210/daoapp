// android/build.gradle.kts

plugins {
    // 루트에서만 버전 선언, 각 모듈(app)에서는 apply false 적용된 걸 사용
    id("com.android.application") version "8.7.0" apply false
    id("org.jetbrains.kotlin.android") version "1.9.24" apply false
    id("com.google.gms.google-services") version "4.4.2" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// 빌드 산출물 폴더 정리(Flutter 기본 관례와 동일)
rootProject.buildDir = File("../build")
subprojects {
    project.buildDir = File(rootProject.buildDir, project.name)
    project.evaluationDependsOn(":app")
}

// gradle clean
tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}
