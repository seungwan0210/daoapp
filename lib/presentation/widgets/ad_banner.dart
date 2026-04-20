import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import '../../core/utils/ad_manager.dart';

// 정책 위반이 해결되고 광고 게재 제한이 풀릴 때까지는
// 이 값을 true로 두어 가짜 영역만 보여줄 수도 있습니다.
const bool kAdMobSuspended = false;

class AdBanner extends StatefulWidget {
  // 1️⃣ 광고 타입을 선택할 수 있는 파라미터 추가
  final AdBannerType type;

  const AdBanner({
    super.key,
    this.type = AdBannerType.main, // 기본값은 메인 배너
  });

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
    // 중복 로드 방지를 위해 _bannerAd가 null일 때만 로드 시도
    if (!kAdMobSuspended && _bannerAd == null) {
      _loadAd();
    }
  }

  Future<void> _loadAd() async {
    // [정책 위반 해결 포인트 1] 가용 너비 계산
    final double screenWidth = MediaQuery.of(context).size.width;
    final int adWidth = (screenWidth - 32).truncate();

    if (adWidth <= 0) return;

    final size = await AdSize.getAnchoredAdaptiveBannerAdSize(
      Orientation.portrait,
      adWidth,
    );

    if (size == null) return;

    if (!mounted) return;
    setState(() => _adSize = size);

    // 2️⃣ AdManager에서 전달받은 타입(widget.type)에 맞는 ID를 가져옵니다.
    final String unitId = AdManager.getBannerUnitId(widget.type);

    _bannerAd = BannerAd(
      adUnitId: unitId, // 분리된 전용 ID 사용
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) return;
          setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('BannerAd [${widget.type}] 로드 실패: $error');
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
      // [정책 위반 해결 포인트 2] 레이아웃 시프트 방지 및 중앙 정렬
      return Container(
        alignment: Alignment.center,
        width: double.infinity, // 부모 너비에 맞춤
        height: _adSize!.height.toDouble(),
        margin: const EdgeInsets.symmetric(vertical: 12),
        child: AdWidget(ad: _bannerAd!),
      );
    }

    // [정책 위반 해결 포인트 3] 로딩 중 최소 높이 확보
    return const SizedBox(height: 50);
  }
}