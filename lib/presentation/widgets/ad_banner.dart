import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import '../../core/utils/ad_manager.dart';

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
    // 중복 로드 방지를 위해 _bannerAd가 null일 때만 로드 시도
    if (!kAdMobSuspended && _bannerAd == null) {
      _loadAd();
    }
  }

  Future<void> _loadAd() async {
    // ⚠️ [정책 위반 해결 포인트 1]
    // 화면 전체 너비(MediaQuery)에서 부모 위젯의 좌우 패딩(16 + 16 = 32)을 뺀 실제 가용 너비를 계산합니다.
    // 구글에 "화면 너비"를 주면 패딩 영역 때문에 광고가 잘리게 되고, 이를 '코드 수정'으로 간주하여 정지시킵니다.
    final double screenWidth = MediaQuery.of(context).size.width;
    final int adWidth = (screenWidth - 32).truncate();

    if (adWidth <= 0) return;

    // 계산된 adWidth를 사용하여 적응형 사이즈를 가져옵니다.
    final size = await AdSize.getAnchoredAdaptiveBannerAdSize(
      Orientation.portrait,
      adWidth,
    );

    if (size == null) return;

    if (!mounted) return;
    setState(() => _adSize = size);

    _bannerAd = BannerAd(
      adUnitId: AdManager.bannerUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) return;
          setState(() => _isLoaded = true);
        },
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
      // ⚠️ [정책 위반 해결 포인트 2]
      // 구글에서 준 _adSize와 정확히 일치하는 너비/높이를 Container에 강제 설정합니다.
      // 상하 여백(vertical: 12)을 주어 주변 UI와 겹치는 것을 확실히 방지합니다.
      return Container(
        alignment: Alignment.center,
        width: _adSize!.width.toDouble(),
        height: _adSize!.height.toDouble(),
        margin: const EdgeInsets.symmetric(vertical: 12),
        child: AdWidget(ad: _bannerAd!),
      );
    }

    // ⚠️ [정책 위반 해결 포인트 3]
    // 광고가 로딩 중일 때 shrink()나 빈 박스를 쓰면 광고 로드 직후 화면이 출렁(Layout Shift)입니다.
    // 최소 높이(50)를 미리 확보해두는 것이 정책 준수에 유리합니다.
    return const SizedBox(height: 50);
  }
}