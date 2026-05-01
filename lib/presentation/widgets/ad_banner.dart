import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import '../../core/utils/ad_manager.dart';

/// 정책 위반이 해결되고 광고 게재 제한이 풀릴 때까지 true로 설정하면
/// 실제 광고 대신 회색 박스가 표시됩니다.
const bool kAdMobSuspended = false;

class AdBanner extends StatefulWidget {
  final AdBannerType type;

  const AdBanner({
    super.key,
    this.type = AdBannerType.main,
  });

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _isLoading = false; // 중복 로드 방지 플래그
  AnchoredAdaptiveBannerAdSize? _adSize;

  @override
  void initState() {
    super.initState();
    // 홈 화면의 비동기 로딩(캘린더 등)과 충돌을 피하기 위해
    // 첫 프레임 렌더링 이후에 광고 로드를 시작합니다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!kAdMobSuspended) _loadAd();
    });
  }

  Future<void> _loadAd() async {
    if (_isLoading || _bannerAd != null || !mounted) return;

    setState(() => _isLoading = true);

    try {
      // 1. 가용 너비 확인 (비동기 로딩 중 Context가 불안정할 경우 대비)
      final double screenWidth = MediaQuery.of(context).size.width;

      // 화면 너비가 확보되지 않았다면 잠시 후 다시 시도 (MethodChannel 에러 방지)
      if (screenWidth <= 0) {
        Future.delayed(const Duration(milliseconds: 200), _loadAd);
        setState(() => _isLoading = false);
        return;
      }

      final int adWidth = (screenWidth - 32).truncate();
      if (adWidth <= 0) {
        setState(() => _isLoading = false);
        return;
      }

      // 2. 적응형 사이즈 계산
      final size = await AdSize.getAnchoredAdaptiveBannerAdSize(
        Orientation.portrait,
        adWidth,
      );

      if (size == null || !mounted) {
        setState(() => _isLoading = false);
        return;
      }

      setState(() => _adSize = size);

      // 3. 광고 객체 생성 및 로드
      final String unitId = AdManager.getBannerUnitId(widget.type);

      _bannerAd = BannerAd(
        adUnitId: unitId,
        size: size,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (!mounted) {
              ad.dispose();
              return;
            }
            setState(() {
              _isLoaded = true;
              _isLoading = false;
            });
            debugPrint('✅ [AdBanner] 로드 성공: ${widget.type}');
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('❌ [AdBanner] 로드 실패 (${widget.type}): $error');
            ad.dispose();
            if (mounted) {
              setState(() {
                _bannerAd = null;
                _isLoaded = false;
                _isLoading = false;
              });
            }
          },
        ),
      );

      await _bannerAd!.load();
    } catch (e) {
      debugPrint('⚠️ [AdBanner] 예외 발생: $e');
      if (mounted) setState(() => _isLoading = false);
    }
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
        child: const Center(
          child: Text("AD", style: TextStyle(color: Colors.grey, fontSize: 10)),
        ),
      );
    }

    // 광고가 로드된 경우 표시
    if (_isLoaded && _bannerAd != null && _adSize != null) {
      return Container(
        alignment: Alignment.center,
        width: double.infinity,
        height: _adSize!.height.toDouble(),
        margin: const EdgeInsets.symmetric(vertical: 12),
        child: AdWidget(ad: _bannerAd!),
      );
    }

    // 로딩 중이거나 로드 전일 때:
    // 레이아웃 시프트(갑자기 화면이 밀리는 현상) 방지를 위해 최소 높이 확보
    return SizedBox(height: _adSize?.height.toDouble() ?? 60);
  }
}