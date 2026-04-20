import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// 광고 타입을 구분하기 위한 열거형
enum AdBannerType { main, arena, detail }

class AdManager {
  // ==========================================
  // 🤖 Android 광고 단위 ID
  // ==========================================
  static String get androidBannerId => kDebugMode
      ? 'ca-app-pub-3940256099942544/6300978111'
      : 'ca-app-pub-5180429166023258/2238891690';

  static String get androidArenaBannerId => kDebugMode
      ? 'ca-app-pub-3940256099942544/6300978111'
      : 'ca-app-pub-5180429166023258/4171825709';

  static String get androidDetailBannerId => kDebugMode
      ? 'ca-app-pub-3940256099942544/6300978111'
      : 'ca-app-pub-5180429166023258/7591136476';

  static String get androidMrecId => kDebugMode
      ? 'ca-app-pub-3940256099942544/6300978111'
      : 'ca-app-pub-5180429166023258/8399618129';

  static String get androidInterstitialId => kDebugMode
      ? 'ca-app-pub-3940256099942544/1033173712'
      : 'ca-app-pub-5180429166023258/2986659287';

  // ==========================================
  // 🍎 iOS 광고 단위 ID
  // ==========================================
  static String get iosBannerId => kDebugMode
      ? 'ca-app-pub-3940256099942544/2934735716'
      : 'ca-app-pub-5180429166023258/8644517940';

  static String get iosArenaBannerId => kDebugMode
      ? 'ca-app-pub-3940256099942544/2934735716'
      : 'ca-app-pub-5180429166023258/7048210997';

  static String get iosDetailBannerId => kDebugMode
      ? 'ca-app-pub-3940256099942544/2934735716'
      : 'ca-app-pub-5180429166023258/3843463150';

  static String get iosMrecId => kDebugMode
      ? 'ca-app-pub-3940256099942544/2934735716'
      : 'ca-app-pub-5180429166023258/4871189236';

  static String get iosInterstitialId => kDebugMode
      ? 'ca-app-pub-3940256099942544/4411468910'
      : 'ca-app-pub-5180429166023258/1484470385';

  // ==========================================
  // 🔄 플랫폼별 및 타입별 자동 유닛 ID 반환
  // ==========================================

  /// 배너 타입에 따라 적절한 ID를 반환합니다.
  static String getBannerUnitId(AdBannerType type) {
    if (Platform.isAndroid) {
      switch (type) {
        case AdBannerType.arena:
          return androidArenaBannerId;
        case AdBannerType.detail:
          return androidDetailBannerId;
        case AdBannerType.main:
        default:
          return androidBannerId;
      }
    } else {
      switch (type) {
        case AdBannerType.arena:
          return iosArenaBannerId;
        case AdBannerType.detail:
          return iosDetailBannerId;
        case AdBannerType.main:
        default:
          return iosBannerId;
      }
    }
  }

  // 기존 getter들 (호환성 유지)
  static String get bannerUnitId => getBannerUnitId(AdBannerType.main);
  static String get mrecUnitId => Platform.isAndroid ? androidMrecId : iosMrecId;
  static String get interstitialUnitId => Platform.isAndroid ? androidInterstitialId : iosInterstitialId;

  // ==========================================
  // 📏 적응형 배너 사이즈 계산 로직
  // ==========================================

  static Future<AnchoredAdaptiveBannerAdSize?> getAdaptiveSize(BuildContext context) async {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double availableWidth = screenWidth - 32;

    if (availableWidth <= 0) return null;

    return await AdSize.getAnchoredAdaptiveBannerAdSize(
      Orientation.portrait,
      availableWidth.truncate(),
    );
  }
}