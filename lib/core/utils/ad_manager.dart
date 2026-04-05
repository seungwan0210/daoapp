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
      ? 'ca-app-pub-3940256099942544/6300978111' // 테스트 (MREC용 테스트 ID는 배너와 동일하거나 공식 문서 참조)
      : 'ca-app-pub-5180429166023258/8399618129'; // 실광고 (loading_mrec)

  static String get androidInterstitialId => kDebugMode
      ? 'ca-app-pub-3940256099942544/1033173712' // 테스트
      : 'ca-app-pub-5180429166023258/2986659287'; // 실광고 (전면)

  // ==========================================
  // 🍎 iOS 광고 단위 ID (승완님 제공)
  // ==========================================
  static String get iosBannerId => kDebugMode
      ? 'ca-app-pub-3940256099942544/2934735716' // 테스트
      : 'ca-app-pub-5180429166023258/8644517940'; // 실광고

  static String get iosMrecId => kDebugMode
      ? 'ca-app-pub-3940256099942544/2934735716' // 테스트
      : 'ca-app-pub-5180429166023258/4871189236'; // 실광고 (loading_mrec)

  static String get iosInterstitialId => kDebugMode
      ? 'ca-app-pub-3940256099942544/4411468910' // 테스트
      : 'ca-app-pub-5180429166023258/1484470385'; // 실광고 (전면)

  // ==========================================
  // 🔄 플랫폼별 자동 유닛 ID 반환 (Getter)
  // ==========================================

  /// 배너 광고 ID
  static String get bannerUnitId => Platform.isAndroid ? androidBannerId : iosBannerId;

  /// MREC(중간 사각형) 광고 ID
  static String get mrecUnitId => Platform.isAndroid ? androidMrecId : iosMrecId;

  /// 전면 광고 ID
  static String get interstitialUnitId => Platform.isAndroid ? androidInterstitialId : iosInterstitialId;

  // ==========================================
  // 📏 적응형 배너 사이즈 계산 로직
  // ==========================================

  /// ✅ [정책 준수 핵심] 현재 화면 너비에 가장 적합한 배너 높이를 구글 서버에 요청하여 계산함
  static Future<AnchoredAdaptiveBannerAdSize?> getAdaptiveSize(BuildContext context) async {
    final double width = MediaQuery.of(context).size.width;

    // 현재는 세로 모드(Portrait) 기준으로만 계산
    return await AdSize.getAnchoredAdaptiveBannerAdSize(
      Orientation.portrait,
      width.truncate(),
    );
  }
}