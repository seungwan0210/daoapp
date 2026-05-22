# -------------------------------------------------------------------------
# DAO Darts - ProGuard Rules (배포 모드 코드 가위질 방지 규칙)
# -------------------------------------------------------------------------

# Firebase Storage & Firestore 데이터 모델 직렬화 깨짐 방지
-keep class com.google.firebase.** { *; }
-keep class io.firebase.** { *; }
-dontwarn com.google.firebase.**

# MediaPipe AI 핸드 트래킹 네이티브 라이브러리 소실 방지
-keep class com.google.mediapipe.** { *; }
-dontwarn com.google.mediapipe.**

# 안드로이드 고유의 그래픽/카메라 서피스 버퍼 클래스 보존
-keep class androidx.camera.** { *; }
-dontwarn androidx.camera.**