import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:daoapp/core/utils/ad_manager.dart';
import 'package:daoapp/presentation/widgets/ad_banner.dart';
import 'package:daoapp/presentation/providers/training/pose_analysis_provider.dart';
import 'package:daoapp/presentation/screens/training/pose_analysis/screens/pose_analysis_result_screen.dart';
import 'package:daoapp/l10n/app_localizations.dart'; // 🔹 추가

class PoseAnalysisProcessScreen extends ConsumerStatefulWidget {
  const PoseAnalysisProcessScreen({super.key});

  @override
  ConsumerState<PoseAnalysisProcessScreen> createState() => _PoseAnalysisProcessScreenState();
}

class _PoseAnalysisProcessScreenState extends ConsumerState<PoseAnalysisProcessScreen> {
  Timer? _timer;
  int _elapsedSeconds = 0;
  double _progressValue = 0.0;

  BannerAd? _mrecAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();

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

  void _loadAd() {
    if (kAdMobSuspended) return;

    _mrecAd = BannerAd(
      adUnitId: AdManager.mrecUnitId,
      size: AdSize.mediumRectangle,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _isAdLoaded = true),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('MREC Load Failed: $error');
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _mrecAd?.dispose();
    super.dispose();
  }

  Future<void> _startAnalysis() async {
    final s = AppLocalizations.of(context)!;
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
            SnackBar(content: Text(s.pose_proc_failed))
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final percent = (_progressValue * 100).toInt();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),

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

              Text(s.pose_proc_title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 8),
              Text(s.pose_proc_time(_elapsedSeconds.toString()), // 🔹 변수 전달
                  style: TextStyle(color: Colors.grey[600], fontSize: 14)
              ),

              const SizedBox(height: 30),

              _buildAdContent(s),

              const SizedBox(height: 30),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  s.pose_proc_guide,
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

  Widget _buildAdContent(AppLocalizations s) {
    if (kAdMobSuspended) {
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
          children: [
            const Icon(Icons.developer_mode, color: Colors.grey),
            const SizedBox(height: 8),
            Text(s.pose_proc_ad_dev,
                style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)
            ),
          ],
        ),
      );
    }

    if (_isAdLoaded && _mrecAd != null) {
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

    return Container(
      width: 300, height: 250,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(s.pose_proc_ad_loading,
          style: const TextStyle(color: Colors.grey)
      ),
    );
  }
}