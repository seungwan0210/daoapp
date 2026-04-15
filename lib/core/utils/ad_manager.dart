import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdManager {
  // ==========================================
  // 🤖 Android 광고 단위 ID (승완님 제공)
  // ==========================================
  static String get androidBannerId => kDebugMode
      ? 'ca-app-pub-3940256099942544/6300978111' // 테스트
      : 'ca-app-pub-5180429166023258/2238891690'; // 실광고

  static String get androidMrecId => kDebugMode
      ? 'ca-app-pub-3940256099942544/6300978111' // 테스트
      : 'ca-app-pub-5180429166023258/8399618129'; // 실광고

  static String get androidInterstitialId => kDebugMode
      ? 'ca-app-pub-3940256099942544/1033173712' // 테스트
      : 'ca-app-pub-5180429166023258/2986659287'; // 실광고

  // ==========================================
  // 🍎 iOS 광고 단위 ID (승완님 제공)
  // ==========================================
  static String get iosBannerId => kDebugMode
      ? 'ca-app-pub-3940256099942544/2934735716' // 테스트
      : 'ca-app-pub-5180429166023258/8644517940'; // 실광고

  static String get iosMrecId => kDebugMode
      ? 'ca-app-pub-3940256099942544/2934735716' // 테스트
      : 'ca-app-pub-5180429166023258/4871189236'; // 실광고

  static String get iosInterstitialId => kDebugMode
      ? 'ca-app-pub-3940256099942544/4411468910' // 테스트
      : 'ca-app-pub-5180429166023258/1484470385'; // 실광고

  // ==========================================
  // 🔄 플랫폼별 자동 유닛 ID 반환
  // ==========================================

  static String get bannerUnitId => Platform.isAndroid ? androidBannerId : iosBannerId;
  static String get mrecUnitId => Platform.isAndroid ? androidMrecId : iosMrecId;
  static String get interstitialUnitId => Platform.isAndroid ? androidInterstitialId : iosInterstitialId;

  // ==========================================
  // 📏 적응형 배너 사이즈 계산 로직
  // ==========================================

  /// ✅ [정책 준수 핵심 수정]
  /// 화면 전체 너비가 아닌, 실제 레이아웃 패딩(16*2=32)을 제외한 가용 너비를 요청합니다.
  /// 안드로이드에서 광고 프레임이 잘리거나 압축되어 정책 위반이 뜨는 것을 방지합니다.
  static Future<AnchoredAdaptiveBannerAdSize?> getAdaptiveSize(BuildContext context) async {
    // ⚠️ 수정 포인트: MediaQuery에서 전체 너비를 가져온 뒤, 좌우 패딩 값인 32를 뺍니다.
    final double screenWidth = MediaQuery.of(context).size.width;
    final double availableWidth = screenWidth - 32;

    // 가용 너비가 비정상적일 경우 null 반환
    if (availableWidth <= 0) return null;

    // 현재는 세로 모드(Portrait) 기준으로만 계산
    return await AdSize.getAnchoredAdaptiveBannerAdSize(
      Orientation.portrait,
      availableWidth.truncate(),
    );
  }
}