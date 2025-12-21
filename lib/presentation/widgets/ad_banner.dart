// lib/presentation/widgets/ad_banner.dart
import 'dart:io'; // ✅ 플랫폼 분기용
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  /// ✅ 테스트 배너 광고 단위 ID (플랫폼별)
  /// - Android: ca-app-pub-3940256099942544/6300978111
  /// - iOS   : ca-app-pub-3940256099942544/2934735716
  String get _testBannerUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716';
    }
    // 그 외 플랫폼은 일단 빈 값 → 광고 안 띄움
    return '';
  }

  @override
  void initState() {
    super.initState();

    final adUnitId = _testBannerUnitId;
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
    if (!_isLoaded || _bannerAd == null) {
      // 로딩 중 / 실패 시 → 아무것도 안 보이게
      return const SizedBox.shrink();
    }

    return Center(
      child: SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }
}
