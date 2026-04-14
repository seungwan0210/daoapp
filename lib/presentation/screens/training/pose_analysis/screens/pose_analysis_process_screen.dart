import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// ✅ 프로젝트 경로에 맞춰 임포트 확인 필요
import 'package:daoapp/core/utils/ad_manager.dart';
import 'package:daoapp/presentation/widgets/ad_banner.dart'; // kAdMobSuspended 전역 변수가 있는 곳
import 'package:daoapp/presentation/providers/training/pose_analysis_provider.dart';
import 'package:daoapp/presentation/screens/training/pose_analysis/screens/pose_analysis_result_screen.dart';

class PoseAnalysisProcessScreen extends ConsumerStatefulWidget {
  const PoseAnalysisProcessScreen({super.key});

  @override
  ConsumerState<PoseAnalysisProcessScreen> createState() => _PoseAnalysisProcessScreenState();
}

class _PoseAnalysisProcessScreenState extends ConsumerState<PoseAnalysisProcessScreen> {
  Timer? _timer;
  int _elapsedSeconds = 0;
  double _progressValue = 0.0;

  // 💰 광고 관련 변수
  BannerAd? _mrecAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd(); // 광고 로드 시작

    // 시각적 재미를 위한 가짜 프로그레스 바
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted) {
        setState(() {
          _elapsedSeconds = (timer.tick / 2).floor();
          if (_progressValue < 0.9) {
            _progressValue += 0.02;
          }
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAnalysis();
    });
  }

  // ✅ [수정] AdManager를 사용하도록 개선된 광고 로드 함수
  void _loadAd() {
    // ⛔ [차단] AdBanner.dart 등에 정의된 전역 안전장치 확인
    if (kAdMobSuspended) return;

    _mrecAd = BannerAd(
      // 🔥 AdManager에 정의된 MREC 전용 ID 사용
      adUnitId: AdManager.mrecUnitId,
      size: AdSize.mediumRectangle,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _isAdLoaded = true),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('MREC 광고 로드 실패: $error');
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _mrecAd?.dispose(); // 광고 메모리 해제
    super.dispose();
  }

  Future<void> _startAnalysis() async {
    final success = await ref.read(poseAnalysisProvider.notifier).analyzeVideo();
    if (success && mounted) {
      setState(() => _progressValue = 1.0);
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PoseAnalysisResultScreen())
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("분석 실패. 다시 시도해주세요."))
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final percent = (_progressValue * 100).toInt();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),

              // 1. 로딩 아이콘
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 100, height: 100,
                    child: CircularProgressIndicator(
                      value: _progressValue,
                      strokeWidth: 8,
                      color: Colors.cyan,
                      backgroundColor: Colors.grey[100],
                    ),
                  ),
                  Text(
                    "$percent%",
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.cyan
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              const Text("자세를 분석 중입니다",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 8),
              Text("소요 시간: ${_elapsedSeconds}초",
                  style: TextStyle(color: Colors.grey[600], fontSize: 14)
              ),

              const SizedBox(height: 30),

              // 💰 2. 광고 영역 (가장 눈에 잘 띄는 중앙)
              _buildAdContent(),

              const SizedBox(height: 30),

              // 3. 안내 멘트
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  "AI가 영상을 프레임 단위로 분석하고 있습니다.\n영상이 길수록 시간이 조금 더 소요됩니다.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[500], fontSize: 13, height: 1.5),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ 광고 상태에 따른 위젯 분리 (가독성 개선)
  Widget _buildAdContent() {
    if (kAdMobSuspended) {
      // A. 개발 중/정책 위반 대응 기간 (회색 박스)
      return Container(
        width: 300, height: 250,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.developer_mode, color: Colors.grey),
            SizedBox(height: 8),
            Text("MREC 광고 영역 (개발중)",
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)
            ),
          ],
        ),
      );
    }

    if (_isAdLoaded && _mrecAd != null) {
      // B. 실제 광고 로드 성공
      return Container(
        width: _mrecAd!.size.width.toDouble(),
        height: _mrecAd!.size.height.toDouble(),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: AdWidget(ad: _mrecAd!),
      );
    }

    // C. 로딩 중 (빈 박스)
    return Container(
      width: 300, height: 250,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text("광고를 불러오는 중입니다...",
          style: TextStyle(color: Colors.grey)
      ),
    );
  }
}