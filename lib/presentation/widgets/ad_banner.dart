import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import '../../core/utils/ad_manager.dart'; // 방금 만든 유틸 임포트

// 정책 위반이 해결되고 광고 게재 제한이 풀릴 때까지는
// 이 값을 true로 두어 가짜 영역만 보여줄 수도 있습니다.
const bool kAdMobSuspended = false;

class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  AnchoredAdaptiveBannerAdSize? _adSize;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!kAdMobSuspended) {
      _loadAd();
    }
  }

  Future<void> _loadAd() async {
    // 1. 화면 너비에 맞는 적응형 사이즈 가져오기 (정책 위반 해결 포인트)
    final size = await AdSize.getAnchoredAdaptiveBannerAdSize(
      Orientation.portrait,
      MediaQuery.of(context).size.width.truncate(),
    );

    if (size == null) return;

    setState(() => _adSize = size);

    _bannerAd = BannerAd(
      adUnitId: AdManager.bannerUnitId, // 유틸에서 ID 가져옴
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => setState(() => _isLoaded = true),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('BannerAd 로드 실패: $error');
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 정지/점검 중일 때 보여줄 가짜 UI
    if (kAdMobSuspended) {
      return Container(
        height: 60,
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(child: Text("광고 준비 중", style: TextStyle(color: Colors.grey))),
      );
    }

    if (_isLoaded && _bannerAd != null && _adSize != null) {
      return Container(
        alignment: Alignment.center,
        width: _adSize!.width.toDouble(),
        height: _adSize!.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    }

    return const SizedBox.shrink();
  }
}