// lib/presentation/widgets/ad_banner.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// ⚠️ [긴급] main.dart의 설정과 동일하게 true로 설정하세요.
// 정지가 풀리면 false로 바꾸시면 됩니다.
const bool kAdMobSuspended = true;

class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  /// ✅ 실제 배너 광고 단위 ID
  String get _bannerUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-5180429166023258/2238891690';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-5180429166023258/8644517940';
    }
    return '';
  }

  @override
  void initState() {
    super.initState();

    // ⛔ 정지 기간이거나, ID가 없으면 로드하지 않음 (안전 장치)
    if (kAdMobSuspended) return;

    final adUnitId = _bannerUnitId;
    if (adUnitId.isEmpty) {
      debugPrint('Unsupported platform for banner ads');
      return;
    }

    _bannerAd = BannerAd(
      size: AdSize.banner,
      adUnitId: adUnitId,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('BannerAd failed to load: $error');
        },
      ),
      request: const AdRequest(),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🛠 [개발 모드] 정지 기간 동안은 '가짜 회색 박스'를 보여줌
    // 이렇게 해야 광고 자리를 확보한 상태로 디자인을 잡을 수 있음
    if (kAdMobSuspended) {
      return Container(
        alignment: Alignment.center,
        width: double.infinity,
        height: 50, // 표준 배너 높이
        color: Colors.grey[300], // 회색 배경
        child: const Text(
          '배너 광고 영역 (개발중)',
          style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold),
        ),
      );
    }

    // [정상 모드] 로딩 실패 시 숨김
    if (!_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    // [정상 모드] 광고 표시
    return Center(
      child: SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }
}